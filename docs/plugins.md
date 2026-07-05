# Plugins

What's installed, what it does, and any quirks we had to work around to get
it actually working (verified via live container testing, not just reading
plugin descriptions).

| Plugin | What it does | Toggle |
|---|---|---|
| **Geyser** | Lets Bedrock Edition clients (phone/tablet/console/Windows) connect to this Java server at all | `enable_bedrock_support` |
| **Floodgate** | Lets those Bedrock players join *without* needing a separate Java Edition account | `enable_bedrock_support` |
| **EssentialsX** | `/home`, `/spawn`, `/tpa`, basic quality-of-life commands | `enable_essentials` |
| **GriefPrevention** | Kids claim their own build area with a golden shovel; nobody else can build/break inside a claim they don't own | `enable_anti_grief_claims` |
| **CoreProtect** | Logs every world action; `/co rollback` undoes grief or accidents | `enable_coreprotect` |
| **ChatFilter** | Blocks links/IP addresses and known-bad content in chat | `enable_chat_filter` |
| **DiscordSRV** | Mirrors chat to a private Discord channel | `enable_discord_bridge` (off - not used, explicit choice) |

All installed automatically from Modrinth (or directly from GeyserMC's own
download server for Floodgate - see below), matching the pinned Minecraft
version, via `MODRINTH_PROJECTS` in
`roles/minecraft/templates/docker-compose.yml.j2`.

## Quirks we had to work around

These were all found by actually booting the real containers locally
(`make verify-integration`), not by reading documentation:

- **Geyser** only ever publishes `beta`-tagged builds on Modrinth, never
  `release`. Without `MODRINTH_PROJECTS_DEFAULT_VERSION_TYPE: "beta"`,
  resolution fails outright.
- **Floodgate**: the `floodgate` project slug on Modrinth is a *completely
  unrelated* Fabric/NeoForge mod with the same name. The real
  Paper-compatible Floodgate plugin isn't on Modrinth at all - it's fetched
  directly from GeyserMC's own download API via the `PLUGINS` variable
  instead.
- **ChatControl** (the original plan) was dropped entirely: its free
  Modrinth build has no release for our pinned Minecraft version (newest
  supported is ~1.20.1), and crash-loops the server if forced. Replaced
  with **ChatFilter**.
- **ChatFilter**'s shipped config only *registers* its filter categories
  without enabling any of them - installing the plugin alone does nothing.
  `roles/minecraft/files/chatfilter-filter.yml` pre-seeds it with the
  website/IP-address filter and GamerSafer's moderation list switched on
  before first boot, so it's actually active from the start. Verified this
  survives container restarts unmodified (the plugin only writes its
  defaults when no config exists yet).

## Whitelisting Bedrock/Floodgate players

Bedrock players get a literal `.` (dot) prefix on their in-game Bedrock
username in `mc_whitelist`/`mc_ops` - e.g. a Bedrock player named
`aliceplays` is entered as `.aliceplays`, not `aliceplays`. See
[joining.md](joining.md) for the full picture on Bedrock/Microsoft account
requirements.

**How this is actually applied matters** - see the incident below before
assuming the dot prefix alone is sufficient.

### Real incident: a bad whitelist name crash-looped the whole server

The first real deploy hit this directly: itzg's image originally resolved
the `WHITELIST`/`OPS` env vars via a live PlayerDB/Mojang lookup *inside
the container at startup*, and that resolution has no skip-on-failure
mode. Adding a Bedrock name (dot-prefixed, correctly) that had never
connected before produced `Could not resolve user from Playerdb: .name`
as a **fatal** error - which crash-looped the *entire* container on every
restart, taking Java players down too, not just rejecting that one entry.
This is a known, unresolved upstream limitation (see
[itzg/docker-minecraft-server#3380](https://github.com/itzg/docker-minecraft-server/issues/3380),
[#2922](https://github.com/itzg/docker-minecraft-server/issues/2922),
[#1436](https://github.com/itzg/docker-minecraft-server/issues/1436)) -
there's no maintainer-added flag to make it log-and-skip instead.

**Fixed by no longer using `WHITELIST`/`OPS` at all.** Ansible now
resolves names itself, before ever touching the running container (see
`roles/minecraft/tasks/resolve_players.yml`):

- **Java names** get a real Mojang API lookup at deploy time. A typo now
  fails the *Ansible run* cleanly, with a clear error naming the bad
  entry - not a live crash-loop.
- **Bedrock (dot-prefixed) names** are skipped from this resolution
  entirely (with a printed warning) - there's no way to turn a Bedrock
  Gamertag into its real UUID before that account has connected at least
  once (see below for why).
- The resolved entries are written directly as `whitelist.json`/
  `ops.json` and handed to the container via itzg's `WHITELIST_FILE`/
  `OPS_FILE` variables, which copy the file byte-for-byte with **no
  PlayerDB/Mojang validation at all** - so nothing at container startup
  can crash from a bad name anymore, by construction.

### The suffixed "modern Gamertag" case (`name#1234`)

Xbox gives out a `name#1234`-style suffix when the plain name was already
taken by someone else. Two things worth knowing:

- **Corrected from an earlier assumption, now verified against a real live
  connection**: the `#1234` suffix is *not* simply dropped - Floodgate
  strips only the `#` character (Minecraft usernames can't contain it) and
  concatenates the rest. A real Xbox gamertag `name#1234` showed up in the
  server's own logs as the connecting player `.name1234` - **not** `.name`.
  Whitelist/ops entries need this exact concatenated form, not the bare
  base name. (An earlier version of this doc claimed the suffix was never
  sent at all, based on inference rather than an observed connection -
  that was wrong; trust the server log's own player-join line over any
  assumption about what Bedrock "should" send.)
- **The real identity Floodgate uses isn't the name at all - it's the
  Xbox User ID (XUID)**, deterministically turned into a UUID. The name
  in `whitelist.json`/`ops.json` is cosmetic; the UUID is what's actually
  checked. This is good for the exact concern that prompted checking it:
  a *different* Xbox account that happens to share the same base name
  (different suffix, different XUID) gets a **different** derived UUID,
  so it cannot match an existing whitelist/ops entry for someone else's
  account, suffix or not.

**The practical catch**: since the UUID is XUID-derived, and nothing
about a plain username string reveals its XUID, there's no way - Ansible
pre-resolution or itzg's own container-startup resolution - to get a
real UUID for a `.name` entry before that player has connected at least
once. That's a first-contact chicken-and-egg problem inherent to
Floodgate, not something either fix works around. A Bedrock player's
whitelist/op entry has to be added **after** they've connected once:

1. Get them connected the first time. Since `mc_whitelist`/`mc_ops` never
   got a resolvable entry for them (deliberately skipped, see above),
   the straightforward way is to temporarily open the server up (comment
   out/loosen `ENFORCE_WHITELIST`, or note this box is Tailscale-gated
   regardless - see [security.md](security.md#network-exposure), so a
   brief window without Minecraft-level whitelist isn't exposing it to
   the internet at large) and let them join once.
2. Once connected, run `/fwhitelist add <name>` in-game/console -
   confirmed (from Floodgate's own source) to resolve through Floodgate's
   real XUID for that connection, not a blind guess, and it writes
   straight to the live `whitelist.json` itself.
3. Run `/op <name>` too if they need admin commands.
4. Turn `ENFORCE_WHITELIST` back on/tight afterward. These entries
   persist across restarts (`EXISTING_WHITELIST_FILE`/`EXISTING_OPS_FILE`
   are set to `SKIP`, so Ansible only seeds `whitelist.json`/`ops.json`
   on the very first-ever boot and never overwrites them afterward) -
   but note this also means `mc_whitelist`/`mc_ops` in `group_vars/all.yml`
   won't reflect Bedrock entries added this way; that's an accepted,
   documented gap rather than a bug.

None of this is specific to having a `#1234` suffix - it applies to any
brand new Bedrock identity's first connection. Picking a **unique
Gamertag without a suffix** (see
[joining.md](joining.md#getting-your-bedrock-username-if-you-dont-have-one-yet))
doesn't avoid this chicken-and-egg step, but does keep the name simpler
to type/verify by hand while debugging it.
