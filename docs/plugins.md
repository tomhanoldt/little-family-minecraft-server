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

Bedrock players whitelisted via Floodgate need a literal `.` (dot) prefix
on their in-game Bedrock username in `mc_whitelist`/`mc_ops` - e.g. a
Bedrock player named `aliceplays` must be entered as `.aliceplays`, not
`aliceplays`. Without the prefix, the server tries to resolve the name as
a real Java/Mojang account and fails
(`Could not resolve user from Playerdb: ...`). See
[joining.md](joining.md) for the full picture on Bedrock/Microsoft account
requirements.
