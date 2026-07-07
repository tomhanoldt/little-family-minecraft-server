# Minecraft Family Server – Ansible Setup

A private Minecraft server for your daughter and her friends, locked down via
Tailscale. Runs entirely in Docker, set up reproducibly via Ansible.

## What this setup does

1. Installs **Docker + Docker Compose plugin** on the mini-PC
2. Installs **Tailscale** and connects it to your tailnet
3. **UFW firewall**: Minecraft ports (25565 TCP, 19132 UDP for Bedrock) are
   reachable **only** from the Tailscale network (`100.64.0.0/10`) - no port
   forwarding, no public access, no random players from the internet.
4. **Paper Minecraft server** (Docker image `itzg/minecraft-server`) with:
   - Whitelist + `online-mode` enforced (only real, invited accounts)
   - Geyser + Floodgate (Bedrock/mobile/console compatibility)
   - EssentialsX, GriefPrevention, CoreProtect, ChatFilter (see below)
5. **Automatic backups** (daily, with rotation) via a second container
   (`itzg/mc-backup`)
6. Hardens SSH (key-only login) and sets up passwordless sudo for automation

## Documentation

- [`docs/security.md`](docs/security.md) - what we're concerned about and
  what's been done about it
- [`docs/privacy.md`](docs/privacy.md) - what data exists (chat logs,
  CoreProtect, backups), who can see it, and how it's protected - written
  for the other parents
- [`docs/server-hardware.md`](docs/server-hardware.md) - the mini-PC itself,
  memory budget, OS cleanup
- [`docs/plugins.md`](docs/plugins.md) - what each plugin does and the real
  bugs found getting them working
- [`docs/installing-minecraft.md`](docs/installing-minecraft.md) - getting
  the app itself onto a phone, tablet, or laptop
- [`docs/joining.md`](docs/joining.md) - what a new player/family needs to
  do to join
- [`docs/account-decision.md`](docs/account-decision.md) - Java vs. Bedrock
  account/license comparison for the other parents
- [`docs/device-accounts.md`](docs/device-accounts.md) - creating a secure
  Apple ID/Google Account for your kid, ahead of the Microsoft account
- [`docs/screen-time-controls.md`](docs/screen-time-controls.md) - setting
  up app/time limits on iOS and Android
- [`docs/home-assistant.md`](docs/home-assistant.md) - optional host + game
  stats on a Home Assistant dashboard
- [`AGENT.md`](AGENT.md) - operating notes for anyone (human or AI)
  working in this repo
- [`TODO.md`](TODO.md) - what's still open

## Prerequisites

You need Docker Desktop running locally - all Ansible/Python tooling runs
containerized (see `Dockerfile.ansible` / `docker-compose.yml`), nothing
needs to be installed on your Mac itself. Everything is driven through the
`Makefile`:

```bash
make ansible-build          # build the ansible runner image
make ansible-galaxy         # install the pinned collections into it
```

The mini-PC needs: fresh Ubuntu, SSH access with a sudo-capable user.

## Setup

1. Generate a dedicated SSH keypair for this project (e.g. `~/.ssh/th_rsa`)
   and copy it to the mini-PC:
   ```bash
   make ssh-copy-key user=<ssh-user> host=<mini-pc-hostname>
   ```
   (needs the account password once - password login gets disabled later).
2. Adjust **`inventory.ini`**: IP/hostname + SSH user of the mini-PC, and
   point `ansible_ssh_private_key_file` at your key (container-internal path).
3. Generate a **Tailscale auth key**: https://login.tailscale.com/admin/settings/keys
   → enter it in `group_vars/all.yml` under `tailscale_authkey`.
   (Reusable key recommended so you can run the playbook multiple times.)
4. Go through **`group_vars/all.yml`** and adjust:
   - `mc_whitelist`: Minecraft names of your daughter + her friends
   - `mc_ops`: who gets admin rights (usually just your daughter or you)
   - `mc_rcon_password`: change this from the placeholder to your own value
   - `mc_gamemode`: `creative` or `survival` - non-ops can also self-toggle
     via `/gamemode` (see `docs/plugins.md`)
   - Safety toggles (`enable_chat_filter`, `enable_anti_grief_claims`, ...)
     on/off as you like
   - `mc_memory`: with 16GB total RAM, 6G is a good value for ~8 players

## Running

```bash
make ansible-check          # dry run
make ansible-deploy         # actual run
```

Both need `sudo` on the mini-PC to work passwordlessly (see "SSH & sudo
hardening" below) - otherwise pass `args="--ask-become-pass"` and run it in
a real terminal, not through an automated/piped session, since it needs an
interactive password prompt.

Once done, the server is running. On first start it takes 1-3 minutes until
Paper + all plugins are downloaded from Modrinth (check the log with
`docker compose -f /opt/minecraft/docker-compose.yml logs -f mc`).

## SSH & sudo hardening

The playbook (tags `ssh_hardening` and `sudo_nopasswd`) disables SSH password
login and sets up passwordless sudo for the SSH user, so future runs need no
interactive prompts at all. Bootstrap order matters:

1. Copy your key onto the box first (`make ssh-copy-key`, see above) and
   confirm key-based login works before disabling password auth.
2. Note: this Ubuntu image ships `sudo-rs` (Rust reimplementation) selected
   by default, which mangles custom prompts and breaks Ansible's `become`
   password detection (`Timeout waiting for privilege escalation prompt`).
   The playbook switches the `update-alternatives` selection back to classic
   `sudo` - but since that itself needs `become`, do the very first bootstrap
   (enabling passwordless sudo) by hand once, over a plain interactive SSH
   session, then let Ansible take over from there.

## Inviting friends (without opening your whole tailnet)

Tailscale has a dedicated feature for this: **Device Sharing**.

1. Tailscale admin console → Machines → select the mini-PC → **Share**
2. Send the invite link to the friend's family
3. The friend installs Tailscale on their device (phone/PC/console,
   depending on support) and accepts the invite
4. This way they see **only** the mini-PC in their Tailscale client - not
   the rest of your network. The share is additionally "quarantined": the
   shared device can only respond, never initiate connections itself.

Alternative, if that's too much setup for the friends: invite them "normally"
into your tailnet as a member - then they can theoretically see more devices,
unless you restrict that further via Tailscale ACLs. For 2-3 friends, Device
Sharing is the cleaner, more privacy-friendly way.

## Plugin overview

| Plugin | What it does | Why it's good for kids |
|---|---|---|
| **Geyser + Floodgate** | Bedrock/mobile/console players can join the Java server | You don't have to commit to one device type upfront |
| **EssentialsX** | `/home`, `/spawn`, `/tpa`, basic commands | Makes navigation easier for kids without needing admin rights |
| **GriefPrevention** | Kids "claim" their build area themselves with a golden shovel | Nobody can accidentally or deliberately destroy another kid's build |
| **CoreProtect** | Logs every action, allows rollback | If something does go wrong: `/co rollback` undoes it |
| **ChatFilter** | Filters profanity, spam, ad links in chat | Automatic chat hygiene without you having to read along live |
| **SkinsRestorer** | `/skin set <name\|url>` to pick any skin | Kids can look how they want without a paid Java skin |

All plugins are automatically loaded from Modrinth matching the Minecraft
version (`MODRINTH_PROJECTS`) - no manual jar hunting needed, and they're
kept up to date on `docker compose pull && docker compose up -d`.

## Optional: limit play times

Set `enable_playtime_schedule: true` and enter start/stop times in
`group_vars/all.yml` - a cronjob then automatically starts/stops the server
container only within the desired time window.

## Maintenance

```bash
# Server console / logs
docker compose -f /opt/minecraft/docker-compose.yml logs -f mc

# Restart server
docker compose -f /opt/minecraft/docker-compose.yml restart mc

# Backups are located at
/opt/minecraft/backups/

# Re-run the playbook when you change group_vars/all.yml
# (e.g. adding a new friend to the whitelist)
make ansible-deploy
```

## License

[MIT](LICENSE) - © Tom Hanoldt ([www.tomhanoldt.info](https://www.tomhanoldt.info))
