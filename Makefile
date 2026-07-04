#!make
SHELL=/bin/bash
TOPDIR=$(PWD)

BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
RESET 		   := $(shell tput -Txterm sgr0)

.PHONY: help
help:
	@echo -e "\n$(YELLOW)Commands for $(USE_DOCKER_STRING): $(RESET)"
	@sh -c "$(MAKE) -pRrq | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | grep -v 'Makefile' | sort"

start: dc-start

stop: dc-stop

restart: stop start

###############################################################################
# docker compose tasks
###############################################################################
dc-start:
	make .docker-compose cmd="up -d --remove-orphans"

dc-restart:
	@if [ "$(container)" == "" ]; then \
    make start; \
	else \
		make .docker-compose cmd="up -d --force-recreate --remove-orphans $(container)"; \
	fi

dc-stop:
	make .docker-compose cmd="stop $(container)"

dc-destroy:
	make .docker-compose cmd="down -v --rmi all --remove-orphans"

docker-prune:
	docker builder prune

dc-logs:
	make .docker-compose cmd="logs --tail=10 -f $(container)"

build-docker-files:
	@echo "cd packages/python-executor/vm && docker build ."


###############################################################################
# run
###############################################################################
dc-run:
	make .docker-compose cmd="run --rm $(container) bash"

dc-run-with-ports:
	@make .print-header msg="for ex: make run-with-ports container=backend\n  -> on bash run: MAX_THREADS=1 rails server -b 0.0.0.0 -p 5000"
	make dc-stop container=$(container)
	make .docker-compose cmd="run --rm --use-aliases --service-ports $(container) bash"

###############################################################################
# ansible (runs containerized - no local python/ansible install needed)
###############################################################################
ansible-build:
	docker compose build ansible

ansible-galaxy:
	docker compose run --rm ansible ansible-galaxy collection install -r requirements.yml

ansible-syntax-check:
	docker compose run --rm ansible ansible-playbook playbook.yml --syntax-check

# extra flags, e.g.: make ansible-check tags=ssh_hardening args="--ask-become-pass"
ansible-check:
	docker compose run --rm ansible ansible-playbook playbook.yml --check --diff $(if $(tags),--tags $(tags)) $(args)

ansible-deploy:
	docker compose run --rm ansible ansible-playbook playbook.yml $(if $(tags),--tags $(tags)) $(args)

ansible-shell:
	docker compose run --rm ansible bash

ssh-copy-key:
	@make .print-header msg="copies ~/.ssh/th_rsa.pub to the mini-PC - needs host= and user= (password auth still enabled at this point)"
	docker compose run --rm ansible ssh-copy-id -o StrictHostKeyChecking=accept-new -i /home/ansible/.ssh/th_rsa.pub $(user)@$(host)

server-check-updates:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags vuln_check

server-check-paper-updates:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags paper_update_check

# Pulls backups off the mini-PC to ./backups-offbox/ - deliberately no
# --delete, so this only ever accumulates: if the box's own retention prunes
# an old backup (or the box is compromised/dies entirely), the copies we've
# already pulled here stay put instead of getting wiped along with it.
backup-pull:
	@make .print-header msg="pulling backups from the mini-PC to ./backups-offbox/ (independent of the box's own disk/retention)"
	@mkdir -p backups-offbox
	docker compose run --rm -v $(PWD)/backups-offbox:/backups-offbox ansible rsync -az -e "ssh -o StrictHostKeyChecking=accept-new" mono@minecraft-server:/opt/minecraft/backups/ /backups-offbox/

# Interactively pick a backup from ./backups-offbox/ (newest first) and
# restore it onto the live server. STOPS the server and REPLACES current
# world/plugin data - the current state is tar'd aside on the mini-PC first
# (see pre-restore-safety/ under mc_data_dir) so this can be undone.
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

# Spins up the real itzg images against a throwaway local data dir (never the
# real mini-PC) to catch broken plugin resolution etc. before deploying -
# same check CI runs on every push.
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

verify-integration-clean:
	cd .ci-test-scratch && docker compose down -v
	rm -rf .ci-test-scratch

server-update:
	docker compose run --rm ansible ansible-playbook playbook.yml --tags system_update

###############################################################################
# tailscale (runs on this Mac directly, not in Docker - it's a native daemon)
###############################################################################
tailscale-up:
	tailscale up

tailscale-down:
	tailscale down

tailscale-status:
	tailscale status

tailscale-ssh:
	tailscale ssh mono@little-family-mincraft-server

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
