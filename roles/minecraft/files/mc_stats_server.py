#!/usr/bin/env python3
"""Serve Minecraft player/server stats as JSON for Home Assistant to poll.

Reads vanilla per-player stats directly from world/stats/<uuid>.json (the
authoritative source - RCON has no reliable stats-dump command), matches
UUIDs to names via Paper's own live data/whitelist.json (not the
Ansible-templated managed/whitelist.json - that one only ever has
Java-resolved names, since Bedrock names can't be pre-resolved via
Mojang's API and are added later via /fwhitelist directly into Paper's
copy, never Ansible's), and asks RCON's own "list" command who's online
right now. No secrets are accepted on the command line (visible to any
local user via `ps`) - the RCON password comes from a single,
root-only-readable env file instead.

Deliberately no MQTT broker, no extra Python dependencies beyond the
standard library - Home Assistant's built-in RESTful sensor polls this
directly (see docs/home-assistant.md), so there's no broker credentials
or network path to wire up on the Home Assistant side at all.
"""
import argparse
import json
import re
import socket
import struct
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

RCON_AUTH = 3
RCON_EXEC = 2

# Minecraft's own §-prefixed color/formatting codes (e.g. "§4monotom23") -
# RCON's raw "list" response is full of these, and they're not whitespace
# so a plain .strip() leaves them in place, silently breaking every name
# comparison against the whitelist.
_FORMATTING_CODE = re.compile("§.")


def rcon_command(host, port, password, command, timeout=5):
    with socket.create_connection((host, port), timeout=timeout) as sock:
        _rcon_send(sock, 1, RCON_AUTH, password)
        _rcon_recv(sock)  # auth response packet
        _rcon_send(sock, 2, RCON_EXEC, command)
        return _rcon_recv(sock)


def _rcon_send(sock, request_id, pkt_type, body):
    payload = struct.pack("<ii", request_id, pkt_type) + body.encode("utf8") + b"\x00\x00"
    sock.sendall(struct.pack("<i", len(payload)) + payload)


def _rcon_recv(sock):
    raw_len = sock.recv(4)
    if len(raw_len) < 4:
        return ""
    (length,) = struct.unpack("<i", raw_len)
    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            break
        data += chunk
    return data[8:-2].decode("utf8", errors="replace")


def parse_env_file(path):
    env = {}
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip()
    return env


def load_whitelist_names(data_dir):
    path = Path(data_dir) / "whitelist.json"
    if not path.exists():
        return {}
    entries = json.loads(path.read_text())
    return {e["uuid"].replace("-", ""): e["name"] for e in entries}


def to_dashed_uuid(uuid_nodash):
    u = uuid_nodash
    return f"{u[0:8]}-{u[8:12]}-{u[12:16]}-{u[16:20]}-{u[20:32]}"


def read_player_stats(data_dir, uuid_dashed):
    path = Path(data_dir) / "world" / "stats" / f"{uuid_dashed}.json"
    if not path.exists():
        return None
    data = json.loads(path.read_text())
    custom = data.get("stats", {}).get("minecraft:custom", {})
    return {
        "playtime_hours": round(custom.get("minecraft:play_time", 0) / 20 / 3600, 1),
        "deaths": custom.get("minecraft:deaths", 0),
        "mob_kills": custom.get("minecraft:mob_kills", 0),
    }


def build_stats(rcon_password, data_dir):
    names_by_uuid = load_whitelist_names(data_dir)

    try:
        online_raw = rcon_command("127.0.0.1", 25575, rcon_password, "list")
    except OSError as e:
        print(f"RCON unreachable, skipping online status: {e}", file=sys.stderr)
        online_raw = ""

    online_raw = _FORMATTING_CODE.sub("", online_raw)
    online_names = set()
    if ":" in online_raw:
        _, _, names_part = online_raw.partition(":")
        online_names = {n.strip() for n in names_part.split(",") if n.strip()}
    # Bedrock names may or may not carry their dot prefix over RCON
    # depending on client/Floodgate version - normalize both sides so a
    # mismatch on either end still matches correctly.
    online_names_normalized = {n.lstrip(".") for n in online_names}

    players = {}
    for uuid_nodash, name in names_by_uuid.items():
        is_online = name.lstrip(".") in online_names_normalized
        entry = {"online": is_online}
        stats = read_player_stats(data_dir, to_dashed_uuid(uuid_nodash))
        if stats:
            entry.update(stats)
        players[name.lstrip(".")] = entry

    return {
        "players_online": len(online_names),
        "players": players,
    }


def make_handler(rcon_password, data_dir):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path != "/stats":
                self.send_response(404)
                self.end_headers()
                return
            body = json.dumps(build_stats(rcon_password, data_dir)).encode("utf8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, fmt, *args):
            pass  # journald already captures stdout/stderr; skip the per-request noise

    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", required=True, help="path to root-only-readable file with RCON_PASSWORD")
    parser.add_argument("--data-dir", required=True)
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()

    env = parse_env_file(args.env_file)
    handler = make_handler(env["RCON_PASSWORD"], args.data_dir)
    ThreadingHTTPServer(("0.0.0.0", args.port), handler).serve_forever()


if __name__ == "__main__":
    main()
