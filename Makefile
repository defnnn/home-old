SHELL := /bin/bash

.PHONY: docs

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

build: # Build container
	@echo
	docker system prune -f
	drone exec --pipeline $@

recreate: # Recreate home container
	docker system prune -f
	kitt recreate
	ssh-add -L | grep cardno | docker-compose exec -T ssh tee .ssh/authorized_keys

recycle: # Recycle home container
	docker pull registry.defn.sh/defn/home
	$(MAKE) recreate

access: # ssh into home container via access@cloudflared
	@cloudflared access ssh-gen --hostname kitt.defn.sh
	@ssh -A jojomomojo@kitt.defn.sh

attach: # attach to home container via app@cloudflared
	@tm app@kitt.defn.sh bash -il

ssh-init: # ssh to home container via zerotier
	ssh-add -L | docker-compose exec -T ssh tee .ssh/authorized_keys

ssh-connect: # connect bridge to home container
	docker network connect bridge "$(shell docker-compose ps -q ssh)"

ssh:
	@ssh -A -p 2222 app@$(shell docker inspect "$(shell docker-compose ps -q ssh)" | jq -r '.[] | .NetworkSettings.Networks.bridge.GlobalIPv6Address')

bump: # Refresh build
	date > b/.bump
	git add b/.bump
	git commit -m 'bump build'

bump-brew: # Rebuild homebrew
	date > b/.linuxbrew
	git add b/.linuxbrew
	git commit -m 'bump brew build'

bump-home: # Rebuild home directory
	date > b/.homedir
	git add b/.homedir
	git commit -m 'bump home build'
