# Agent notes

Operating context for any AI agent (or human) working in this repo. See also
[`docs/`](docs/) for the human-facing writeups this file points into, and
[`TODO.md`](TODO.md) for what's actually still open.

## What this is

Ansible-managed private Minecraft family server: Paper + Geyser/Floodgate
(Bedrock crossplay) + a handful of moderation/QoL plugins, reachable only
via Tailscale, running on a home mini-PC. See `README.md` for the
user-facing setup guide.

## How to run things

**Everything goes through the dockerized `ansible` service - never install
Ansible/Python locally.** `docker compose run --rm ansible <cmd>`, or use
the `Makefile` targets (`make help` lists them all, grouped and commented).

Key ones:
- `make ansible-syntax-check` / `make ansible-check` / `make ansible-deploy`
- `make verify-integration` - actually boots the real production
  `docker-compose.yml.j2` (rendered via `scripts/render_compose.py`)
  against a throwaway local dir, via Docker Desktop. **Run this before
  trusting any change to the Minecraft compose template** - it's caught
  real bugs (broken Modrinth resolution, capability misconfiguration)
  that pure review missed.
- `make backup-pull` / `make backup-restore` / `make chat-grep` /
  `make chat-tail` / `make server-check-updates` /
  `make server-check-paper-updates`

## Non-negotiable before committing

1. Run the full lint suite and confirm it's clean:
   `ansible-playbook --syntax-check`, `yamllint -c .yamllint .`,
   `ansible-lint`, `hadolint < Dockerfile.ansible`.
2. **Never commit without being explicitly asked**, even after finishing
   a chunk of work - wait for the user to say so.
3. Prefer several small, sensibly-grouped commits over one large one when
   the work has distinct concerns (use `git add -p` to split a single
   file's diff when the concerns land in the same file).

## Verify claims, don't just read docs

This project's history is full of cases where the documented/expected
behavior didn't match reality - `sudo-rs` silently breaking Ansible's
`become`, Geyser/Floodgate's Modrinth listings being wrong or entirely
unrelated projects, `deploy.resources` limits being silently ignored
outside Swarm. **When something matters, actually run it** (locally via
Docker Desktop, or against the real host) rather than trusting a plugin's
description or a module's docs at face value.

## Ansible role tag conventions

Tasks that shouldn't run during a normal full deploy are tagged so they
only fire when explicitly requested:
`tailscale`, `firewall`, `ssh_hardening`, `sudo_nopasswd`, `os_cleanup`,
`vuln_check`, `system_update`, `paper_update_check`. Destructive ones
additionally carry the special `never` tag (currently just
`backup_restore`) - so not even `--tags all` can trigger them by accident.

## Known environment quirks (don't re-discover these)

- **Ubuntu 26.04 on the mini-PC ships `sudo-rs`** (Rust reimplementation)
  selected by default via `update-alternatives`, which mangles custom
  prompts and breaks Ansible's `become` entirely. Already switched back to
  classic `sudo` in `roles/common/tasks/sudo.yml` - don't reintroduce
  sudo-rs assumptions.
- **Fresh Ubuntu ISO installs leave a stale
  `/etc/apt/sources.list.d/cdrom.sources`** with no Release file, which
  fails `apt-get update` hard. Removed unconditionally via the `always`
  tag in `roles/common/tasks/main.yml` - keep that task first.
- **`docker compose` (non-Swarm) silently ignores `deploy.resources.limits`**
  unless `--compatibility` is passed. Use the plain `mem_limit`/
  `pids_limit` service-level fields instead (already done in
  `docker-compose.yml.j2`).
- **Dependabot cannot parse Jinja templates.** The two production image
  digests live in `roles/minecraft/templates/docker-compose.yml.j2`, which
  Dependabot can't read. `.github/dependabot-refs/docker-compose.yml` is a
  plain, non-functional stand-in purely so Dependabot tracks those two
  digests - if it opens a PR bumping a digest there, mirror the same
  `image:tag@sha256` value into the real template and re-verify locally
  before deploying.
- **`group_vars/all.yml` (real, gitignored) vs `group_vars/all.yml.example`
  (tracked template)**: keep them in sync structurally, but never let a
  real secret leak into the `.example` file.
- Git history here was deliberately rewritten once already (author
  identity, stray `Co-Authored-By` trailers) before considering this repo
  publishable - don't assume the machine's default git config identity is
  what should go on new commits without checking.
- **itzg's `WHITELIST`/`OPS` env vars can crash-loop the whole server** -
  a real production incident, not theoretical: they resolve names via a
  live PlayerDB/Mojang call inside the container at startup with no
  skip-on-failure mode, so one unresolvable name (e.g. a Bedrock/Floodgate
  identity that's never connected before) is a **fatal** error that
  restarts the entire container in a loop, taking every player down, not
  just rejecting that one entry. Fixed by not using those env vars at
  all - `roles/minecraft/tasks/resolve_players.yml` resolves Java names
  via Mojang's API at Ansible-run time (failing the run cleanly on a
  typo) and writes `whitelist.json`/`ops.json` directly, handed to the
  container via `WHITELIST_FILE`/`OPS_FILE` (no validation, can't crash).
  Bedrock names can't be pre-resolved (their UUID needs a real XUID from
  an actual connection) - see `docs/plugins.md` for the post-connect
  `/fwhitelist`/`/op` procedure. Don't reintroduce `WHITELIST`/`OPS` in
  the compose template.
- **Never put `#`-comments inside a YAML block scalar (`|`) meant for
  line-based machine input** (env vars like `MODRINTH_PROJECTS` or
  `CUSTOM_SERVER_PROPERTIES` in `docker-compose.yml.j2`) - happened
  *twice*: once crash-looped the server (a comment got parsed as a
  plugin name), once broke `CUSTOM_SERVER_PROPERTIES` entirely (fails
  the whole property update, not just the commented line). Explanatory
  comments always go *outside* the block scalar, immediately above the
  env var key.
- **itzg's default-gamemode variable is `MODE`, not `GAMEMODE`** - the
  latter is silently ignored (no error), despite matching the naming
  pattern of `DIFFICULTY`/`MOTD`/etc. Also needs `force-gamemode=true`
  (via `CUSTOM_SERVER_PROPERTIES`) to actually apply to players who
  already joined once before - `MODE` alone only sets the default for
  brand-new joiners.
- **Paper writes an empty `permissions.yml` placeholder on first boot.**
  Pre-seeding a file with `force: false` (the `chatfilter-filter.yml`
  pattern) assumes the *plugin* would otherwise regenerate real defaults
  if missing - that's true for ChatFilter, not for `permissions.yml`,
  where an empty file left by Paper itself means `force: false` never
  actually writes anything, forever. Check whether "already exists"
  really means "already has real content" before reusing this pattern.
- **`tailscale_hostname: "little-family-mincraft-server"` is spelled with
  "mincraft" (missing the "e") on purpose, not a typo to fix** - it's the
  real, already-deployed Tailscale device name/DNS entry, shared with and
  used by other players already. "Correcting" it would rename the actual
  device and break everyone's saved server address.

## Docs map

- [`docs/security.md`](docs/security.md) - what we're actually concerned
  about and what's been done/accepted/left open
- [`docs/privacy.md`](docs/privacy.md) - parent-facing disclosure: what
  data is logged (chat, CoreProtect, backups), retention, who can access
  it, and how the security work above protects it. Keep this in sync with
  `security.md` when logging/retention behavior actually changes.
- [`docs/server-hardware.md`](docs/server-hardware.md) - the box itself,
  memory budget, OS cleanup
- [`docs/plugins.md`](docs/plugins.md) - what each plugin does and the
  real bugs found getting them working
- [`docs/installing-minecraft.md`](docs/installing-minecraft.md) - getting
  the client itself installed per device (iOS/Android/Windows/Mac)
- [`docs/joining.md`](docs/joining.md) - what a new player/family
  actually needs to do
- [`docs/account-decision.md`](docs/account-decision.md) - Java vs.
  Bedrock account/license comparison
- [`docs/device-accounts.md`](docs/device-accounts.md) - creating the
  child's Apple ID/Google Account (separate from the Microsoft account)
- [`docs/screen-time-controls.md`](docs/screen-time-controls.md) - iOS/
  Android app/time limit setup
- [`LICENSE`](LICENSE) - MIT
