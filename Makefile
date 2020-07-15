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
	cd c && kitt recreate
	ssh-add -L | grep cardno | (cd c && docker-compose exec -T ssh tee .ssh/authorized_keys)

recycle: # Recycle home container
	docker pull registry.kitt.run/defn/home
	$(MAKE) recreate

ssh: # ssh into home container
	@cloudflared access ssh-gen --hostname kitt.defn.sh
	@ssh -A jojomomojo@kitt.defn.sh

attach:
	@tm app@kitt.defn.sh bash -il

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
