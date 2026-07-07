# Security

What we're actually concerned about with this setup, what we did about it, and
what's still open. This is a private family server, not a public one - the
threat model is "don't let this box become a liability for the rest of the
home network or the kids' safety," not "withstand nation-state attackers."

## Network exposure

- The Minecraft ports (`25565` TCP, `19132` UDP) are reachable **only** from
  the Tailscale tailnet (`100.64.0.0/10`), enforced by UFW. No port
  forwarding, no public internet exposure.
- SSH (`22`) is open to the whole internet by design (so a broken Tailscale
  connection can't lock us out of recovery), but password authentication is
  fully disabled - only the `th_rsa` key (itself passphrase-protected) can
  authenticate at all.
- The box shares a tailnet with other home devices (e.g. Home Assistant), so
  it's tagged (`tag:minecraft`) and scoped via ACL grants: other tailnet
  members can only reach it on the game ports, and it has no grant to reach
  anything else on the tailnet - if it's ever compromised, it can't pivot
  sideways into the rest of the home network.
- Per-person access is tagged too, not just left as one broad "any tailnet
  member" grant: the admin's own devices (`tag:tom-personal`) keep full
  mutual access to each other plus Home Assistant; a kid's device
  (`tag:kid-restricted`) gets *only* the Minecraft ports and nothing else,
  even though it's added under the admin's own Tailscale account rather
  than a separate Device-Shared identity. A real gotcha hit while setting
  this up: tagging a device removes it from `autogroup:member` entirely -
  any broad `autogroup:member`-based grant (e.g. "members reach each
  other's devices," or Minecraft access itself) silently stops applying to
  a device the moment it's tagged, so each tag needs its own **explicit**
  grant for everything it should still be able to reach, not just the new
  restriction being added. A reference copy of the current policy lives at
  [`tailscale/acl.hujson`](../tailscale/acl.hujson) - it has to be applied
  manually via the Tailscale admin console (ACLs aren't Ansible-managed),
  so treat that file as documentation of intent, not a live source of truth
  - check the admin console for what's actually applied.
- The optional Home Assistant stats feature (off by default) adds one more
  narrow grant, inbound only - HA polling both Glances and the game-stats
  JSON server on the Minecraft box, nothing pushed the other way (no
  broker) - see [home-assistant.md](home-assistant.md) for the full
  reasoning. Neither Glances nor the stats server has a login of its
  own; the ACL grant plus UFW's tailnet-only rule are the actual
  boundary for those ports.
- RCON (used internally by `mc-backup` to coordinate backups) is never
  published to any network interface by default - it only exists on
  Docker's internal bridge network between `mc` and `mc-backup`. It's
  also given a real, generated password (`mc_rcon_password`) rather than
  relying on the image's default, which has a documented history of
  falling back to a weak value. If `enable_home_assistant_stats` is on,
  it's additionally published to `127.0.0.1:25575` only (confirmed via
  `docker port`, never the tailnet or LAN) - see
  [home-assistant.md](home-assistant.md).

## Container hardening

- Both Minecraft images (`itzg/minecraft-server`, `itzg/mc-backup`) are
  pinned by SHA-256 digest, not a floating tag - what runs today is exactly
  what ran yesterday unless we deliberately bump it.
- Both run with `cap_drop: ALL` and only the specific Linux capabilities
  their entrypoints actually need re-added back (verified by actually
  running them, not assumed).
- Both have `no-new-privileges`, memory/PID limits sized for the box's 16GB
  (see [server-hardware.md](server-hardware.md)), and capped log rotation so
  runaway logging can't fill the disk.
- The local Ansible tooling container (used to manage the server, never
  itself exposed to anything) runs as a non-root user with `cap_drop: ALL`
  too, since it doesn't need any capabilities at all.

## Kid safety

- `ONLINE_MODE` + `ENFORCE_WHITELIST` mean only specifically invited,
  authenticated accounts can ever join - see
  [joining.md](joining.md) for what that actually requires.
- ChatFilter is configured (not just installed) to actively block links/IP
  addresses and known-bad content via GamerSafer's moderation list - see
  [plugins.md](plugins.md) for details on why ChatControl was dropped in
  favor of this.
- CoreProtect logs every world action, so if something does go wrong
  (grief, an accidental build, a rules violation) it can be rolled back and
  attributed rather than just disappearing.
- **`enforce-secure-profile` is deliberately off** (`ENFORCE_SECURE_PROFILE:
  "FALSE"`) - a real, confirmed incompatibility: Bedrock/Floodgate players
  have no Mojang chat-signing key, so with this on their chat silently
  gets disabled entirely ("Chat disabled due to missing profile public
  key"). The tradeoff: this also disables Mojang's own built-in
  chat-reporting tool - moderation for this server relies entirely on
  ChatFilter (above) and CoreProtect's logging/rollback rather than
  Mojang's reporting pipeline.
  This is a narrower loss than it first sounds, given what this feature
  actually is: cryptographic proof of *who sent* a chat message (anti-
  impersonation) plus a hook into Mojang's centralized reporting, not
  transport encryption - Java's protocol already encrypts the connection
  independently of chat-signing, and everything additionally runs inside
  Tailscale's WireGuard tunnel regardless (see "Network exposure" above).
  On a server nobody unwhitelisted can even reach, the impersonation risk
  this feature guards against is negligible; the actual loss is just
  Mojang's reporting pipeline, which is why ChatFilter/CoreProtect are the
  compensating control rather than a network- or encryption-level one.
- What's logged (chat, CoreProtect, backups), how long it's kept, and who
  can access it is spelled out in full, parent-facing terms in
  [privacy.md](privacy.md) - this section is the technical summary, that
  one is the disclosure.

## OS hardening

- Removed unrelated bloat found via direct inspection of the box: leftover
  `lxd`/`etcd`/`prometheus` snaps, `modemmanager`, `open-vm-tools` (confirmed
  bare metal, not a VM) - see [server-hardware.md](server-hardware.md).
- `unattended-upgrades` was already installed and enabled; verified it's
  actually configured to auto-apply (not just present).
- Passwordless sudo is enabled for automation - deliberately: the SSH key is
  already passphrase-protected, so this isn't removing a real second factor,
  it's removing a second password prompt on top of one that's already there.
- Ubuntu 26.04 ships `sudo-rs` (a Rust reimplementation) selected by default,
  which mangles custom prompts and broke Ansible's `become` entirely. Fixed
  by switching the `update-alternatives` selection back to classic `sudo` -
  this is unrelated to any of the above, just a compatibility fix we had to
  make to automate this box at all.

## CI / supply chain

- `security.yml` runs Trivy against both production images, the local
  tooling image, our own IaC (Dockerfiles/compose), and the full git history
  for secrets - on every push and weekly on a schedule, since vulnerability
  databases move independently of our own commits.
- Dependabot tracks the tooling image's base, `ansible-core`
  (`requirements.txt`), our GitHub Actions (pinned by SHA), and the two
  production images via a plain stand-in file Dependabot can parse (see
  `.github/dependabot-refs/`, since the real reference lives inside a Jinja
  template Dependabot can't read).
- `lint.yml` runs yamllint, ansible-lint, and hadolint on every push.

## Known accepted risk

`itzg/minecraft-server` currently bundles `gosu` built against a Go stdlib
with a CRITICAL CVE (`CVE-2025-68121`, TLS certificate validation) and 13
associated HIGH findings. Investigated rather than blanket-ignored:
confirmed via `trivy image --format json` that all 14 are attributed to
`usr/local/bin/gosu` specifically, and gosu (per its own docs) never makes
network connections at all - the vulnerable code is dead weight from Go's
static linking. Documented and suppressed in `.trivyignore`, which expires
**2026-10-04** to force a genuine re-check rather than a silent permanent
suppression.

## Known open risk (deliberately not suppressed)

Clearing the gosu noise revealed a second CRITICAL, `CVE-2022-36944` (a
Scala deserialization gadget chain) in `mc-image-helper`'s bundled
`scala-library`. Its exploit precondition (deserializing an untrusted
`LazyList` via Java's *native* object serialization) doesn't match how
`mc-image-helper` actually talks to Modrinth/GeyserMC (HTTP+JSON via
Jackson) - but that's an inference, not something verified from
`mc-image-helper`'s source the way gosu's was. It stays visible in CI scans
until itzg bumps the dependency. See [TODO.md](../TODO.md).

## Publishing this repo

This repo is intended to be public. Before that: full git history was
audited (not just current files) for secrets, real names, real IPs, and
the real tailnet identifier - clean. Commit author identity was rewritten
from a personal Gmail address to a deliberately-chosen public contact
address. Real secrets (Tailscale authkey, RCON password) live only in the
gitignored `group_vars/all.yml`, never committed - `group_vars/all.yml.example`
carries only placeholders. Licensed MIT (see [`LICENSE`](../LICENSE)).

GitHub's own **secret scanning alerts** are automatic for public repos at
no cost - no action needed there. **Push protection** (blocking a push
that contains a detected secret before it's even accepted) is a separate
toggle, off by default even on public repos, and needs to be turned on
manually once the repo exists on GitHub (Settings → Code security and
analysis) - tracked in [TODO.md](../TODO.md).
