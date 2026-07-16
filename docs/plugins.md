# Plugins

What's installed, what it does, and any quirks we had to work around to get
it actually working (verified via live container testing, not just reading
plugin descriptions).

| Plugin | What it does | Toggle |
|---|---|---|
| **Geyser** | Lets Bedrock Edition clients (phone/tablet/console/Windows) connect to this Java server at all | `enable_bedrock_support` |
| **Floodgate** | Lets those Bedrock players join *without* needing a separate Java Edition account | `enable_bedrock_support` |
| **ViaVersion** | Lets this (deliberately older-pinned) server accept the newer Java protocol Geyser now speaks | `enable_bedrock_support` |
| **EssentialsX** | `/home`, `/spawn`, `/tpa`, basic quality-of-life commands | `enable_essentials` |
| **GriefPrevention** | Kids claim their own build area with a golden shovel; nobody else can build/break inside a claim they don't own | `enable_anti_grief_claims` |
| **CoreProtect** | Logs every world action; `/co rollback` undoes grief or accidents | `enable_coreprotect` |
| **ChatFilter** | Blocks links/IP addresses and known-bad content in chat | `enable_chat_filter` |
| **SkinsRestorer** | `/skin set <name\|url>` - pick any skin, independent of your real Mojang skin | `enable_skins_restorer` |

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
- **Mojang changed Minecraft's own versioning scheme in 2026** - after
  `1.21.11` the next releases are `26.1`/`26.2` (year-based, like several
  other software projects have adopted). Geyser is fetched at `latest` on
  every deploy (no version pin), so it started speaking this newer
  protocol while our server stays deliberately pinned at `1.21.4` - which
  showed up as a real, live incident: Bedrock clients got "server needs
  an update or install ViaVersion" and couldn't connect at all, even
  though the server itself was healthy. Checked before just bumping the
  version: **CoreProtect and ChatFilter have no build at all for `26.x`
  yet** (verified against Modrinth's API directly) - bumping `mc_version`
  would have silently dropped grief-rollback and chat moderation, the two
  safety features that matter most here. Installed **ViaVersion** instead
  (verified via Modrinth: one build spans `1.8.9` through `26.2`, tagged
  `beta` like Geyser) - it lets the still-`1.21.4` server accept the
  newer protocol Geyser now uses, without touching the actual server
  version or plugin compatibility. Revisit a real version bump once
  CoreProtect/ChatFilter ship `26.x`-compatible builds.
- **The itzg image's default-gamemode variable is `MODE`, not `GAMEMODE`.**
  Setting `GAMEMODE` silently did nothing - no error, no log line, the
  server just kept its old default - since it isn't a variable the image
  recognizes at all. Caught by checking itzg's own docs after the change
  had no effect, not by guessing from the naming pattern of other
  variables (which otherwise matches, e.g. `DIFFICULTY`, `MOTD`).
- **`CUSTOM_SERVER_PROPERTIES` only accepts strict `KEY=VALUE` lines** -
  no comments inside the block scalar itself. A `#`-prefixed explanatory
  line inside it doesn't get ignored; it fails the *entire* property
  update with `Failed to update server.properties`, silently leaving
  every property in that block unapplied (not just the commented one).
  Same underlying mistake as the `MODRINTH_PROJECTS` block scalar
  earlier - comments belong *outside* any block scalar meant for
  line-based machine input, never inside it.
- **`force-gamemode=true` is required for `MODE` to actually apply to
  already-existing players** - `MODE`/`gamemode` only sets the default
  for brand-new joiners; anyone who already connected once before (e.g.
  in Survival, before this was set to Creative) keeps their old mode
  forever otherwise. Set alongside `MODE` for "everyone always plays in
  the same mode" behavior.
- **Paper creates an empty `permissions.yml` placeholder on first boot.**
  Pre-seeding it the same way as `chatfilter-filter.yml` (`force: false`,
  to avoid clobbering a live admin edit) backfired here: the empty
  placeholder already "exists," so `force: false` skipped writing our
  actual content on every subsequent deploy, silently leaving the file
  permanently empty. Unlike ChatFilter (which the plugin itself
  regenerates with real defaults if missing), Paper never re-populates
  an empty permissions.yml on its own - there's no live-edit risk here,
  so this one always syncs (no `force: false`).
- **SkinsRestorer** resolved from Modrinth (slug `skinsrestorer`,
  supports `1.21.4` directly, no beta-channel workaround needed like
  Geyser) and loaded cleanly in a live boot test, including auto-detecting
  Floodgate ("Floodgate skin listener registered") for some Bedrock skin
  handling - not independently verified in-game, but a promising sign
  given a [separate plugin](https://modrinth.com/plugin/bedrock-skin-restorer)
  otherwise exists specifically because Floodgate's own bridging is
  documented as unreliable. Checked its security history before adding
  it: one historical high-severity RCE
  ([GHSA-mp3v-c49h-86mm](https://github.com/SkinsRestorer/SkinsRestorer/security/advisories/GHSA-mp3v-c49h-86mm)),
  but it only affects "Proxy Mode" (BungeeCord/Velocity) - this server
  runs standalone (confirmed in the boot log) - and was patched in
  15.0.0 regardless; we're on 15.12.4.

## Why the server stays pinned to 1.21.4 (the update chain)

We deliberately do **not** chase the newest Minecraft version, because a
chain of dependencies makes a naive bump silently drop the two safety
features that matter most here. Walking the chain, top to bottom:

1. **`mc_version` is pinned to `1.21.4`** (`VERSION_FROM_MODRINTH_PROJECTS:
   false`, so plugins follow the server, not the other way around).
2. **Because CoreProtect and ChatFilter gate it.** These are grief-rollback
   (`/co rollback`) and chat moderation - the features we least want to lose
   on a kids' server. Both currently have **no build for `26.x`** (Mojang's
   post-`1.21.11` year-based versions), verified against Modrinth's API.
   Bumping `mc_version` past what they support would load the server fine
   but leave those two plugins behind, silently.
3. **Geyser is the odd one out** - it's fetched at `latest` on every deploy
   (no pin, `beta` channel) and now speaks the newer `26.x` Java protocol.
   On its own that broke Bedrock joins ("server needs an update or install
   ViaVersion").
4. **ViaVersion bridges that gap** so the latest Geyser can still talk to
   our `1.21.4` server - letting us hold the version without cutting off
   Bedrock crossplay.
5. **Everything else (EssentialsX, GriefPrevention, SkinsRestorer, ...) is
   held to its newest build that still lists `1.21.4`.** itzg resolves each
   Modrinth slug to the newest version whose `game_versions` includes our
   pinned version and nothing newer - e.g. EssentialsX stays on `2.21.0`
   because `2.21.1`/`2.22.0` dropped `1.21.4` from their compatibility tags,
   even though they'd very likely still run. This is correct, not a bug.

**Exit condition:** the whole chain can finally move up once **both**
CoreProtect and ChatFilter ship a build for the target newer version. That's
the specific thing to watch for.

### Checking for updates without breaking the pin

- **`make server-check-plugin-updates`** (Ansible tag `plugin_update_check`)
  reads the itzg Modrinth manifest and reports, per plugin, the *newest
  build that still supports the pinned `mc_version`* (the safe target) versus
  the *newest overall* and whether it still supports us. Read-only. Watch
  CoreProtect/ChatFilter's "newest overall" line - when it starts covering a
  newer MC version, the exit condition above is met.
- **`make server-update-plugins`** (tag `plugin_update`) restarts the `mc`
  container so itzg re-resolves Modrinth and pulls the newest builds - but
  *only ever ones compatible with the pinned `mc_version`*, which is exactly
  the safety guarantee that respects the chain above. It never pulls an
  incompatible version and never touches `mc_version` itself. Briefly
  disconnects players.

## Letting non-ops use /gamemode and /tp themselves

By default `/gamemode` and `/tp` require op. `roles/minecraft/files/permissions.yml`
grants them to everyone (`default: true`) so whitelisted-but-not-opped
players (a parent or kid who shouldn't have admin commands) can toggle
their own gamemode and teleport.

**The two commands are wired deliberately differently:**

- **`/gamemode` routes through EssentialsX.** Essentials registers its own
  `gamemode` command under vanilla's label and Bukkit gives the plugin
  command priority, so the grant that matters is `essentials.gamemode`, not
  `minecraft.command.gamemode`. Granting only the vanilla node looks correct
  but does nothing with Essentials installed. Traced through EssentialsX
  2.21.0's source to be sure: the dispatcher checks
  `user.isAuthorized(cmd, "essentials.")`, a plain
  `player.hasPermission("essentials.<label>")` with no op fallback - so
  `default: true` on that node is exactly what grants it. The vanilla node
  is kept as a fallback if Essentials is ever disabled. Scope stays
  self-only: `essentials.gamemode.others`/`.all` are left op-only.
- **`/tp` routes to VANILLA, on purpose** - Essentials' `tp` command is put
  in `disabled-commands` (see below and `roles/minecraft/tasks/main.yml`) so
  the label falls through to vanilla, whose target-selector argument is the
  only thing that gives Bedrock/iOS a player picker (see "Bedrock command
  suggestions" below). So the granted node is `minecraft.command.teleport`
  (no `essentials.tp` - that command no longer exists). **Caveat:** vanilla
  `/tp` is a single flat permission with no self-vs-others split, so non-ops
  can now also move *other* players (`/tp Kid1 Kid2`), teleport to
  coordinates, and use `@`-selectors - accepted as the price of the Bedrock
  picker on this small family server.

### The bug that made this silently do nothing for months

This file originally wrapped every node under a top-level `permissions:`
key:

```yaml
permissions:          # WRONG for the server-root permissions.yml
  essentials.tp:
    default: true
```

That `permissions:` wrapper is **plugin.yml** syntax. The *server-root*
`permissions.yml` expects permission nodes at the **top level** of the file
(verified against Paper's `CraftServer.loadCustomPermissions()`, which
parses it as `Map<permissionName, attributes>`). Wrapped, Bukkit registered
a single useless permission literally named `permissions` and silently
ignored every real node - so **both `/gamemode` and `/tp` were dead for
non-ops the entire time** (the earlier "confirmed" note only ever checked
the *node name* against the jar, never an actual in-game non-op use). The
symptom: non-ops get `... was denied access to command` in the server log
while ops work fine. The fix is just to flatten it - nodes at column zero,
no wrapper:

```yaml
essentials.gamemode:  # correct
  default: true
```

Paper reads `permissions.yml` at **startup**, so after editing it the `mc`
container needs a restart (or `/reload permissions`) for the change to take
effect.

## Bedrock command suggestions (why /tp is vanilla, not EssentialsX)

Bedrock/iOS players (via Geyser) get no argument suggestions - no online
player picker - for most plugin commands, so they'd have to type a full
name for `/tp`. This is a hard Geyser/Bedrock limitation, not a config flag:

- Bedrock builds its command UI from a **static** list the server sends
  once (Geyser's translation of the Java command tree). It never
  round-trips per keystroke, so Java's live tab-completion (which is how
  EssentialsX suggests player names) simply isn't available on Bedrock.
- Bedrock *does* render a native picker - listing online players and
  `@`-selectors - but **only for arguments that are a real target selector**
  (`CommandParam.TARGET`), which Geyser maps from a vanilla/Brigadier
  entity argument. **Vanilla `/tp` has one; EssentialsX's `/tp` takes a
  plain greedy string, which gets no picker.**
- Geyser's `command-suggestions: true` (already set) only controls whether
  the tree is sent at all; it does not turn a string argument into a picker.

So to give tablet/iOS players a player picker, `/tp` must be the vanilla
command. We disable EssentialsX's version via `disabled-commands: [tp]` in
its `config.yml`, set idempotently from `roles/minecraft/tasks/main.yml`
(the plugin writes that config on first boot, so on a brand-new server the
task applies on the next deploy; a container restart is needed for the
command-map change to load). Confirmed the handover by running a bare `tp`
in the server console and getting vanilla's Brigadier error
(`Unknown or incomplete command ... minecraft:tp<--[HERE]`) rather than
Essentials' usage text. The trade-off (non-ops can move other players; loss
of Essentials teleport warmup/cooldown/`/back` integration) is covered in
the permission-scope note above and in `permissions.yml`.

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

### The general sanitization pattern (confirmed from two real cases)

Minecraft usernames only allow `[A-Za-z0-9_]`, so Geyser sanitizes
whatever the real Xbox Gamertag contains down to that set - confirmed
from two different real accounts connecting, not just one:

- `#` (the "modern Gamertag" discriminator, e.g. `name#1234`) is
  **stripped**, not replaced - a real `name#1234` connected as `name1234`.
- A **space** (an older "Classic Gamertag" made of two words, e.g.
  `name 1234`) is **replaced with an underscore** - a real `name 1234`
  connected as `name_1234`. Note this is a *different* transformation
  than the `#` case (replace vs. strip) - don't assume one pattern
  covers both.
- Floodgate's own `.` whitelist prefix is then added on top of whichever
  sanitized form results.

**There's no way to compute this in advance from the Gamertag alone
with full confidence** - always confirm via the server's own log line
(`Floodgate player logged in as .name joined`) rather than guessing,
same as the general chicken-and-egg problem below.

**Operational gotcha when the sanitized name contains a space**: passing
it to `/fwhitelist add` or `/op` over RCON needs the name wrapped in
*literal* double quotes as part of the Minecraft command text itself
(Brigadier's quoted-string argument), not just shell/SSH quoting - e.g.
the actual RCON payload needs to be `fwhitelist add "name 1234"`
(quotes included), or Minecraft's command parser splits it into two
separate (wrong) arguments at the space.

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
