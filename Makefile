#!make
SHELL=/bin/bash
TOPDIR=$(PWD)

# Defaults matching inventory.ini/group_vars/all.yml - override on the
# command line if those ever change, e.g.: make chat-grep SSH_HOST=other
SSH_USER      ?= mono
SSH_HOST      ?= minecraft-server
MC_DATA_DIR   ?= /opt/minecraft
TAILSCALE_HOST ?= little-family-mincraft-server

BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
CYAN         := $(shell tput -Txterm setaf 6)
BOLD         := $(shell tput -Txterm bold)
RESET 		   := $(shell tput -Txterm sgr0)

.PHONY: help
help:
	@echo -e "$(BOLD)Minecraft family server - command reference$(RESET)"
	@awk ' \
		function wrap(text, width,    n, words, i, line, nlines) { \
			n = split(text, words, " "); \
			line = ""; nlines = 0; \
			for (i = 1; i <= n; i++) { \
				if (line != "" && length(line) + length(words[i]) + 1 > width) { \
					lines[nlines++] = line; line = words[i]; \
				} else { \
					line = (line == "" ? words[i] : line " " words[i]); \
				} \
			} \
			if (line != "") lines[nlines++] = line; \
			return nlines; \
		} \
		/^##@/ { printf "\n$(BOLD)$(YELLOW)%s$(RESET)\n", substr($$0, 5); next } \
		/^#/ { \
			line = $$0; sub(/^# ?/, "", line); \
			desc = (desc == "") ? line : desc " " line; \
			next \
		} \
		/^[a-zA-Z0-9_-]+:/ { \
			target = $$0; sub(/:.*/, "", target); \
			if (target !~ /^\./ && target != "help") { \
				count = wrap(desc, 48); \
				if (count == 0) { printf "  $(CYAN)%-26s$(RESET)\n", target; } \
				for (i = 0; i < count; i++) { \
					if (i == 0) { printf "  $(CYAN)%-26s$(RESET) %s\n", target, lines[i]; } \
					else { printf "  %-26s %s\n", "", lines[i]; } \
				} \
			} \
			desc = ""; next \
		} \
		{ desc = "" } \
	' Makefile

###############################################################################
# generic docker-compose project scaffold - leftover from the template this
# Makefile started from, not used by this repo. Kept but hidden (dot-prefix)
# rather than deleted.
###############################################################################
.start: .dc-start

.stop: .dc-stop

.restart: .stop .start

.dc-start:
	make .docker-compose cmd="up -d --remove-orphans"

.dc-restart:
	@if [ "$(container)" == "" ]; then \
    make .start; \
	else \
		make .docker-compose cmd="up -d --force-recreate --remove-orphans $(container)"; \
	fi

.dc-stop:
	make .docker-compose cmd="stop $(container)"

.dc-destroy:
	make .docker-compose cmd="down -v --rmi all --remove-orphans"

.docker-prune:
	docker builder prune

.dc-logs:
	make .docker-compose cmd="logs --tail=10 -f $(container)"

.build-docker-files:
	@echo "cd packages/python-executor/vm && docker build ."

.dc-run:
	make .docker-compose cmd="run --rm $(container) bash"

.dc-run-with-ports:
	@make .print-header msg="for ex: make run-with-ports container=backend\n  -> on bash run: MAX_THREADS=1 rails server -b 0.0.0.0 -p 5000"
	make .dc-stop container=$(container)
	make .docker-compose cmd="run --rm --use-aliases --service-ports $(container) bash"

##@ Ansible (runs containerized - no local python/ansible install needed)
# Build the local ansible tooling image.
ansible-build:
	docker compose build ansible

# Install/update the pinned ansible-galaxy collections.
ansible-galaxy:
	docker compose run --rm ansible ansible-galaxy collection install -r requirements.yml

# Syntax-check the playbook only - no connection to the mini-PC needed.
ansible-syntax-check:
	docker compose run --rm ansible ansible-playbook playbook.yml --syntax-check

# Dry-run the playbook (--check --diff).
# Extra flags, e.g.: make ansible-check tags=ssh_hardening args="--ask-become-pass"
ansible-check:
	docker compose run --rm ansible ansible-playbook playbook.yml --check --diff $(if $(tags),--tags $(tags)) $(args)

# Run the playbook for real. Same tags=/args= support as ansible-check.
ansible-deploy:
	docker compose run --rm ansible ansible-playbook playbook.yml $(if $(tags),--tags $(tags)) $(args)

# Open a bash shell in the ansible tooling container.
ansible-shell:
	docker compose run --rm ansible bash

# Copies any public key to any host (password auth must still be enabled).
# make ssh-copy-key user=mono host=minecraft-server pubkey="$(cat ~/.ssh/th_rsa.pub)"
ssh-copy-key:
	@if [ -z "$(pubkey)" ] || [ -z "$(user)" ] || [ -z "$(host)" ]; then \
		echo 'Usage: make ssh-copy-key user=<ssh-user> host=<hostname> pubkey="$$(cat ~/.ssh/your_key.pub)"'; \
		exit 1; \
	fi
	docker compose run --rm ansible bash -c 'echo "$(pubkey)" > /tmp/key.pub && ssh-copy-id -o StrictHostKeyChecking=accept-new -i /tmp/key.pub $(user)@$(host)'

# Dry-run check for pending OS security updates on the mini-PC (no changes made).
server-check-updates:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags vuln_check

# Compares the installed Paper build against the latest available upstream.
server-check-paper-updates:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags paper_update_check

# Reports, per plugin, the newest Modrinth build that still supports the
# pinned mc_version (safe to take) vs the newest overall (may have moved
# past us). Read-only - see docs/plugins.md for how the version pin works.
server-check-plugin-updates:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags plugin_update_check

# Restarts the mc container so itzg re-resolves Modrinth and pulls the
# newest mc_version-COMPATIBLE plugin builds (never an incompatible one -
# that's the whole safety guarantee). Briefly disconnects players.
server-update-plugins:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags plugin_update

# Applies pending OS package updates on the mini-PC.
server-update:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags system_update

# Boots the real Minecraft stack against a throwaway local data dir.
# Never touches the real mini-PC - same check CI runs on every push.
verify-integration:
	@make .print-header msg="rendering compose file + booting the real Minecraft stack against a throwaway dir"
	@mkdir -p .ci-test-scratch/data .ci-test-scratch/backups
	docker compose run --rm -v $(PWD)/.ci-test-scratch:/ci-test ansible python3 scripts/render_compose.py $(PWD)/.ci-test-scratch /ci-test/docker-compose.yml
	cd .ci-test-scratch && docker compose up -d
	@echo "Waiting for the server to become healthy (this can take ~1-2 minutes)..."
	@cd .ci-test-scratch && for i in $$(seq 1 60); do \
		status=$$(docker inspect minecraft --format '{{.State.Health.Status}}' 2>/dev/null || echo starting); \
		state=$$(docker inspect minecraft --format '{{.State.Status}}' 2>/dev/null || echo unknown); \
		if [ "$$status" = "healthy" ]; then echo "Healthy."; exit 0; fi; \
		if [ "$$state" = "restarting" ] || [ "$$state" = "exited" ]; then echo "Crashed:"; docker logs minecraft; exit 1; fi; \
		sleep 5; \
	done; echo "Timed out."; docker logs minecraft; exit 1

# Tears down and removes the verify-integration throwaway test stack.
verify-integration-clean:
	cd .ci-test-scratch && docker compose down -v
	rm -rf .ci-test-scratch

##@ Chat logs
# Searches chat messages across plain + rotated/gzipped logs on the mini-PC.
# e.g.: make chat-grep pattern="some text"
chat-grep:
	@if [ -z "$(pattern)" ]; then echo 'Usage: make chat-grep pattern="search text"'; exit 1; fi
	@docker compose run --rm ansible ssh $(SSH_USER)@$(SSH_HOST) 'zgrep -h -i "]: <" $(MC_DATA_DIR)/data/logs/latest.log $(MC_DATA_DIR)/data/logs/*.log.gz 2>/dev/null' \
		| grep -i --color=never -- "$(pattern)" || echo "No matches found."

# Shows the last N chat messages from the live log (n defaults to 20).
# e.g.: make chat-tail n=50
chat-tail:
	@docker compose run --rm ansible ssh $(SSH_USER)@$(SSH_HOST) 'grep -i "]: <" $(MC_DATA_DIR)/data/logs/latest.log 2>/dev/null | tail -n $(if $(n),$(n),20)'

##@ Backups
# Pulls backups off the mini-PC to ./backups-offbox/ (accumulates only - no
# --delete - so the box's own retention/compromise can't wipe these too).
backup-pull:
	@make .print-header msg="pulling backups from the mini-PC to ./backups-offbox/ (independent of the box's own disk/retention)"
	@mkdir -p backups-offbox
	docker compose run --rm -v $(PWD)/backups-offbox:/backups-offbox ansible rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" $(SSH_USER)@$(SSH_HOST):$(MC_DATA_DIR)/backups/ /backups-offbox/

# Interactively restore a backup from ./backups-offbox/ onto the live server.
# STOPS the server and REPLACES current world/plugin data - the current
# state is tar'd aside on the mini-PC first (pre-restore-safety/ under
# mc_data_dir), so this can be undone.
backup-restore:
	@ls -1t backups-offbox/*.tgz backups-offbox/*.tar.gz 2>/dev/null | nl -w2 -s') ' || \
		(echo "No backup files found in ./backups-offbox/ - run 'make backup-pull' first." && exit 1)
	@read -p "Enter the number of the backup to restore: " num; \
	file=$$(ls -1t backups-offbox/*.tgz backups-offbox/*.tar.gz 2>/dev/null | sed -n "$${num}p"); \
	if [ -z "$$file" ]; then echo "Invalid selection."; exit 1; fi; \
	echo "Selected: $$file"; \
	read -p "This STOPS the live server and REPLACES all current world/plugin data with this backup (current data is saved aside first on the mini-PC). Type 'yes' to continue: " confirm; \
	if [ "$$confirm" != "yes" ]; then echo "Aborted."; exit 1; fi; \
	docker compose run --rm ansible ansible-playbook playbook.yml --tags backup_restore -e restore_backup_file=$$file

##@ Tailscale (runs on this Mac directly, not in Docker - it's a native daemon)
# Connect/reconnect this Mac to Tailscale.
tailscale-up:
	tailscale up

# Disconnect this Mac from Tailscale.
tailscale-down:
	tailscale down

# Show this Mac's Tailscale connection status.
tailscale-status:
	tailscale status

# SSH into the mini-PC via Tailscale SSH (admin-only fallback path).
tailscale-ssh:
	tailscale ssh $(SSH_USER)@$(TAILSCALE_HOST)

###############################################################################
# hidden tasks
###############################################################################
.print-header:
	@echo -e "\n$(YELLOW)$(msg)$(RESET)"

.print-sub-header:
	@echo -e "\n$(YELLOW)$(msg) $(RESET)"

.docker-compose:
	@if [ "$(CPU_ARCHITECTURE)" == "x86_64" ]; then \
		docker compose --file docker-compose.yml $(cmd); \
	else \
		docker compose --file docker-compose.yml $(cmd); \
	fi

.in-folder-do:
	@make .print-header msg="$$folder / $$cmd" && echo "" && cd "$(folder)" && $(cmd) && cd ..
