#!/usr/bin/env python3
"""Render roles/minecraft/templates/docker-compose.yml.j2 standalone (no Ansible run needed).

Used by CI and local integration testing to spin up the actual production
compose file against a throwaway data directory, without touching the real
mini-PC. Uses group_vars/all.yml.example as the variable source, with a
known-real Minecraft account substituted for the whitelist placeholders so
the itzg image's whitelist resolution actually succeeds.
"""
import sys

import jinja2
import yaml

TEMPLATE_PATH = "roles/minecraft/templates/docker-compose.yml.j2"
VARS_PATH = "group_vars/all.yml.example"


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
    # Placeholders can't resolve against Mojang's API - use a real account
    # purely so whitelist/ops resolution succeeds during the smoke test.
    template_vars["mc_whitelist"] = [{"name": "Notch"}]
    template_vars["mc_ops"] = ["Notch"]

    env = jinja2.Environment(undefined=jinja2.StrictUndefined)
    rendered = env.from_string(template_src).render(**template_vars)

    # Fail fast if the template doesn't render to valid YAML.
    yaml.safe_load(rendered)

    with open(output_file, "w") as f:
        f.write(rendered)


if __name__ == "__main__":
    main()
