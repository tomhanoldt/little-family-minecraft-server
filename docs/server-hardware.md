# Server & hardware

## The box

- Mini-PC, **bare metal** (confirmed via `systemd-detect-virt` returning
  `none` - not a VM, despite it shipping with `open-vm-tools` installed as
  leftover template cruft, which we removed).
- **Ubuntu 26.04 LTS "Resolute Raccoon"**, kernel `7.0.0-27-generic`.
- **16GB RAM total.**
- Reached only via [Tailscale](https://tailscale.com) - see
  [security.md](security.md) for the network/ACL model, and
  [joining.md](joining.md) for how other people actually get access.

## Memory budget (16GB total)

| What | Limit | Why |
|---|---|---|
| OS + Docker + Tailscale + sshd | ~1G (unbounded, no cap) | Small, stable footprint after OS cleanup |
| `mc` container | 7G hard limit, 6G reservation | `MEMORY: 6G` only caps the **JVM heap** - off-heap usage (metaspace, direct buffers, native libs) isn't bounded by that, so the container needs headroom above it or a legitimate 6G-heap JVM gets OOM-killed |
| `mc-backup` container | 1G hard limit | Generous on purpose - compressing a large world folder can spike memory briefly |
| **Slack remaining** | **~7G** | Room for GC spikes, world generation bursts, and just not living at the edge |

Verified locally (not just configured): `docker inspect` confirms the
limits actually take effect, and real usage during a live test sat
comfortably under both caps (51% memory, 95/2048 PIDs).

If `mc_memory` in `group_vars/all.yml` is ever changed, bump
`mc_container_mem_limit` to roughly 1G above it.

## Storage

- Everything lives under `mc_data_dir` (default `/opt/minecraft`) on the
  box's own disk: world data, plugin configs, and `itzg/mc-backup`'s own
  backup archive (`backups/`).
- Since backups currently live on the *same* disk as what they're
  protecting, they're also pulled off-box to the admin's Mac
  (`make backup-pull` → `./backups-offbox/`) - see the root `Makefile` and
  [`../README.md`](../README.md) for the restore flow.

## OS cleanup

The box was provisioned from some template/image that included things
that have nothing to do with running a Minecraft server - found via direct
inspection (731 installed packages, `systemd` defaulting to
`graphical.target` with no display manager ever actually running), not
assumed. Removed:

- Unrelated infra: `lxd`, `etcd`, `prometheus` (snap packages)
- `modemmanager` (no cellular modem on this hardware)
- `open-vm-tools` (bare metal, not a VM)
- Reset the default systemd target to `multi-user` (headless server)

`unattended-upgrades` was already installed and properly enabled - left
as-is. Package count went from 731 → 717 after cleanup.

## Access model

- SSH: key-only (`th_rsa`, itself passphrase-protected), no password auth.
- `sudo`: passwordless for automation - the key's own passphrase is the
  real gate here, not a second sudo password on top of it (see
  [security.md](security.md) for the reasoning).
- Fallback: Tailscale SSH also works as an admin-only path
  (`make tailscale-ssh`), scoped via ACL to just the tailnet admin.
