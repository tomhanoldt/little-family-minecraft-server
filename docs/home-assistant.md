# Home Assistant dashboards

Optional, off by default (`enable_home_assistant_stats`). Exposes two
separate kinds of data to Home Assistant, both the same simple way: HA
polls the Minecraft box directly over the tailnet via its built-in
RESTful sensor. No broker, no HA-side credentials to configure at all.

- **Host resources** (CPU/mem/disk of the mini-PC itself) via
  [Glances](https://nicolargo.github.io/glances/), which HA's own
  built-in "Glances" integration polls directly.
- **Game/player stats** (who's online, playtime, deaths, mob kills) via a
  small stdlib-only Python HTTP server that serves a JSON snapshot on
  request - Home Assistant's RESTful sensor polls it the same way it
  polls Glances.

## Setup

1. Apply the Tailscale ACL grant from
   [`tailscale/acl.hujson`](../tailscale/acl.hujson) via the admin console
   (ACLs aren't Ansible-managed - see [security.md](security.md)):
   `tag:home-assistant → tag:minecraft` on `tcp:61208` (Glances) and
   `tcp:25566` (game stats, or whatever `mc_stats_port` is set to).
2. Set `enable_home_assistant_stats: true` in `group_vars/all.yml` and
   `make ansible-deploy`.
3. In Home Assistant, add the **Glances** integration pointed at the
   Minecraft box's Tailscale address, port `61208`, no credentials (see
   "What's deliberately not done" below).
4. For game stats, Home Assistant's `rest` integration is **YAML-only**
   (no UI config flow, confirmed live - Settings → Devices & Services →
   Add Integration → "RESTful" just points you at editing
   `configuration.yaml` instead). Add:
   ```yaml
   rest:
     - resource: "http://<minecraft-box-tailscale-address>:25566/stats"
       scan_interval: 60
       sensor:
         - name: "Minecraft Players Online"
           value_template: "{{ value_json.players_online }}"
         - name: "Daughter Online"
           value_template: "{{ value_json.players['DaughterMCName'].online }}"
           device_class: connectivity
         - name: "Daughter Playtime"
           value_template: "{{ value_json.players['DaughterMCName'].playtime_hours }}"
           unit_of_measurement: "h"
   ```
   The JSON response looks like:
   ```json
   {
     "players_online": 1,
     "players": {
       "DaughterMCName": {"online": true, "playtime_hours": 12.3, "deaths": 4, "mob_kills": 120}
     }
   }
   ```
   All `sensor:` entries under one `resource:` share a single HTTP poll,
   regardless of how many values are pulled out of it. After editing,
   use Developer Tools → YAML → Check Configuration, then either reload
   "REST" from that same page or restart Home Assistant.

## What you get

- **Host**: CPU/RAM/disk usage, uptime, load - whatever HA's Glances
  integration exposes by default.
- **Game**: total players online, and per whitelisted player - online/
  offline, playtime in hours, deaths, and mob kills, all in one JSON
  response, refreshed on every HTTP request (no caching, no polling
  interval of its own - it's driven entirely by however often HA asks).

## How it actually works

- **Glances** runs natively on the host (not in Docker - it needs real
  `/proc` access to report on the *host*, not a container's own limited
  view), installed via `pipx install "glances[web]"` since the Ubuntu
  apt package doesn't bundle the web-server/API extras. Runs as a
  systemd service (`glances.service`).
- **Game stats** come from two sources: Minecraft's own per-player
  `world/stats/<uuid>.json` files (the authoritative, current format -
  not RCON, which has no reliable stats-dump command), and RCON's `list`
  command for who's online right now. UUID → name mapping reuses the
  same `whitelist.json` Ansible already generates - see
  [plugins.md](plugins.md). Both are read fresh on every HTTP request by
  `roles/minecraft/files/mc_stats_server.py`, a stdlib-only
  `http.server` script (no MQTT client, no third-party dependency at
  all) - it runs as its own systemd service (`mc-stats.service`), not in
  a container, so it can read the world data files directly and reach
  RCON without needing Docker exec permissions.

## What's deliberately not done

- **RCON is published to `127.0.0.1:25575` only** (confirmed via
  `docker port` - never touches UFW or the tailnet) so the host-side
  script can speak real RCON without exposing it any further than it
  already effectively was.
- **No secrets ever appear on a process command line** (visible to any
  local user via `ps`) - the RCON credential lives in
  `/etc/minecraft/ha-stats.env` (root-only, mode `0600`), read directly
  by the script via a single `--env-file` path argument.
- **No MQTT broker.** An earlier design pushed stats out to Home
  Assistant's existing Mosquitto broker via MQTT discovery, which would
  have needed broker credentials wired up on both sides and an outbound
  ACL grant. Polling a local JSON endpoint needs none of that - HA
  already knows how to poll a REST resource on a schedule, so the
  broker was unnecessary complexity for this scale.
- **Neither Glances nor the stats server has its own login.** Glances'
  non-interactive password-file format isn't consistently documented
  across versions, and the stats server has no sensitive data beyond
  what's already visible in-game (who's online, playtime). The real
  security boundary is the network layer: UFW only accepts these ports
  from the tailnet CIDR, and the Tailscale ACL grant scopes that down
  further to only `tag:home-assistant`. See [TODO.md](../TODO.md) for
  adding Glances' own `--password` (one-time, interactive) as a second
  layer later.
