#!/usr/bin/env python3
"""Render roles/minecraft/templates/docker-compose.yml.j2 standalone (no Ansible run needed).

Used by CI and local integration testing to spin up the actual production
compose file against a throwaway data directory, without touching the real
mini-PC. Uses group_vars/all.yml.example as the variable source.

The template consumes WHITELIST_FILE/OPS_FILE (pre-built whitelist.json/
ops.json), not the plain WHITELIST/OPS name-list env vars - those resolve
names via a live PlayerDB/Mojang call inside the container with no
skip-on-failure mode (see roles/minecraft/tasks/resolve_players.yml for why
that's no longer used). This script mimics what that Ansible task does: it
writes whitelist.json/ops.json into <mc_data_dir>/managed/ itself, using
Notch's well-known public UUID rather than making a live API call.
"""
import json
import sys
from pathlib import Path

import jinja2
import yaml

TEMPLATE_PATH = "roles/minecraft/templates/docker-compose.yml.j2"
VARS_PATH = "group_vars/all.yml.example"

# Notch's UUID is public knowledge (the very first Minecraft account) -
# using it avoids a live Mojang API call just to smoke-test the compose file.
NOTCH_UUID = "069a79f4-44e9-4726-a5be-fca90e38aaf5"
NOTCH_NAME = "Notch"


def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <mc_data_dir> <output_file>", file=sys.stderr)
        sys.exit(1)
    mc_data_dir, output_file = sys.argv[1], sys.argv[2]

    with open(TEMPLATE_PATH) as f:
        template_src = f.read()
    with open(VARS_PATH) as f:
        template_vars = yaml.safe_load(f)

    template_vars["mc_data_dir"] = mc_data_dir

    managed_dir = Path(mc_data_dir) / "managed"
    managed_dir.mkdir(parents=True, exist_ok=True)
    whitelist_entry = {"uuid": NOTCH_UUID, "name": NOTCH_NAME}
    ops_entry = {**whitelist_entry, "level": 4, "bypassesPlayerLimit": False}
    (managed_dir / "whitelist.json").write_text(json.dumps([whitelist_entry]))
    (managed_dir / "ops.json").write_text(json.dumps([ops_entry]))

    env = jinja2.Environment(undefined=jinja2.StrictUndefined)
    rendered = env.from_string(template_src).render(**template_vars)

    # Fail fast if the template doesn't render to valid YAML.
    yaml.safe_load(rendered)

    with open(output_file, "w") as f:
        f.write(rendered)


if __name__ == "__main__":
    main()
