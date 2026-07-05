# What data exists, who can see it, and how it's protected

Written for the other parents, not just the admin. If you're deciding
whether your kid can join this server, this is the page that answers "so
what actually happens to their data and their messages."

## What's logged, and why

Running any Minecraft server with grief protection and chat moderation
means some logging is unavoidable - this section is about being upfront
about exactly what, rather than leaving it unstated.

- **Chat messages** land in the server's own log files (`data/logs/`),
  the same way any Minecraft server logs console/chat output. This is
  standard Minecraft server behavior, not something added for this setup.
- **CoreProtect** logs world actions (block placed/broken, container
  access, kills) so grief or accidents can be rolled back (`/co rollback`)
  and attributed. It does **not** log chat separately from the above - its
  purpose is world-state history, not conversation monitoring.
- **ChatFilter** actively blocks links, IPs, and known-bad content
  automatically (see [`plugins.md`](plugins.md)) - this happens
  in-the-moment, it doesn't create a separate log of what was blocked.
- **Backups** are full copies of the world (including the logs above),
  taken automatically every 24h.

One gap worth naming plainly: Mojang's own built-in "report a player"
chat-reporting tool **doesn't work on this server** - it requires a
chat-signing feature that's incompatible with Bedrock/Floodgate players
(see [`security.md`](security.md#kid-safety)), so it's turned off for
everyone. There's no Mojang-side reporting safety net here; ChatFilter
and CoreProtect (above) are what stand in for it.

None of this is monitored live or read routinely. It exists so that *if*
something goes wrong (grief, a rules violation, a kid getting a message
they shouldn't), the admin can look back and find out what happened -
the same reason CoreProtect exists on virtually every family/community
Minecraft server. It is not read as a matter of course.

## Who can actually access it

Only the server admin, and only because they hold the one SSH key
(passphrase-protected, key-only login - see
[`security.md`](security.md#network-exposure)) that can reach the box at
all. Concretely, the admin has two Makefile shortcuts that read the chat
log over SSH (`make chat-grep`, `make chat-tail`) - these exist so the
admin doesn't need to leave a terminal open permanently, not because
chat is watched continuously. No one else - not other parents, not
Microsoft/Xbox, not Tailscale (see below) - can read any of this.

## How long it's kept

Being honest about the actual retention, not an idealized one:

- **Chat/server logs**: rotated automatically by Docker (`max-size: 10m`,
  `max-file: 5` - roughly the last 50MB of combined server output, then
  the oldest is deleted). This is not a long window in practice.
- **CoreProtect's database**: kept indefinitely by default - CoreProtect
  doesn't auto-purge unless explicitly configured to, and this setup
  hasn't configured an auto-purge schedule. In practice this means world
  action history (not chat) persists for as long as the server exists,
  the same as it would on any other Minecraft server running this plugin.
- **On-box backups**: pruned automatically after 7 days
  (`backup_retention_days`).
- **Off-box backups** (`make backup-pull`, pulled to the admin's own
  Mac): **not** automatically pruned - these accumulate in a
  gitignored, local-only folder until the admin manually deletes old
  ones. Worth knowing since it means a backup taken today could still
  exist on the admin's machine well past the 7-day on-box window.

## How the "hard security" already built protects this data

Translating the technical hardening in [`security.md`](security.md) into
what it actually means for your kid's data, specifically:

- **Nobody outside the family/invited friends can even reach the
  server** - no public IP, no port forwarding, Tailscale-only access
  (see [`security.md`](security.md#network-exposure)). This is the main
  protection: the data above never leaves a closed, invite-only network
  in the first place.
- **All game/chat traffic is encrypted in transit** by Tailscale's
  WireGuard tunnel between every device and the server - not just "some
  encryption somewhere," actual end-to-end encryption that even
  Tailscale's own infrastructure can't read the contents of (see the
  Tailscale note below for the one thing they *can* see).
- **Only one key holder can reach the box or its logs/backups** - SSH
  password login is fully disabled, so there's no password to guess or
  leak; only the admin's own passphrase-protected private key works.
- **Container hardening** (dropped Linux capabilities, no-new-privileges,
  pinned image digests) means that even in the unlikely case of a
  vulnerability in the Minecraft server software itself, the blast
  radius of what an attacker could do with the logs/data is deliberately
  limited - see [`security.md`](security.md#container-hardening).
- **Automated vulnerability scanning** (Trivy, in CI) checks the exact
  software this data passes through for known CVEs on every change and
  weekly on a schedule - see [`security.md`](security.md#ci--supply-chain).

## The one third party involved: Tailscale

Network access runs through [Tailscale](https://tailscale.com), a
commercial VPN coordination service - worth naming plainly rather than
glossing over, since it's the one company besides the admin with any
visibility at all:

- Tailscale's control plane knows **metadata**: device names, which
  devices are on the tailnet, when they connect. It does **not** see
  chat content, world data, or backups - actual traffic is end-to-end
  encrypted (WireGuard) directly between devices, Tailscale's servers
  never sit in that path.
- Device Sharing invites (used for friends joining, see
  [`joining.md`](joining.md)) are handled the same way - a friend's
  family creates their own Tailscale account to accept the invite;
  their account details are between them and Tailscale, not visible to
  the admin beyond the device showing up as shared.
- This project doesn't control Tailscale's own privacy policy or data
  retention - if that matters to you, it's worth reading
  [Tailscale's privacy policy](https://tailscale.com/privacy-policy)
  directly rather than taking a second-hand summary here.

## If you have concerns

Ask the admin. Retention windows (especially CoreProtect's indefinite
default) can be tightened if parents would prefer that - it just hasn't
been a concern raised yet. This document reflects the setup as it
actually is, not as a promise that it can never change.
