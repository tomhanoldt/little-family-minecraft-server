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
	docker compose run --rm ansible ssh-copy-id -o StrictHostKeyChecking=accept-new -i /root/.ssh/th_rsa.pub $(user)@$(host)

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
