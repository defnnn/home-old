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
	drone exec --pipeline $@ --secret-file ../.drone.secret

recreate: # Recreate home container
	docker system prune -f
	cd c && kitt recreate
	ssh-add -L | grep cardno | (cd c && docker-compose exec -T ssh tee .ssh/authorized_keys)

recycle: # Recycle home container
	docker pull defn/home
	$(MAKE) recreate

ssh: # ssh into home container
	@cloudflared access ssh-gen --hostname kitt.defn.sh
	@ssh -A jojomomojo@kitt.defn.sh

attach:
	@tm app@kitt.defn.sh bash -il

mp:
	multipass delete --purge mp || true
	$(MAKE) mp-cluster
	$(MAKE) mp-extras

mp-cluster: # Launch multipass machine
	multipass launch -m 4g -d 40g -c 2 -n mp --cloud-init multipass/cloud-init.conf focal
	multipass exec mp -- bash -c 'while ! test -f /tmp/done.txt; do ps axuf; sleep 10; date; done'

mp-extras:
	if ! test -d $(PWD)/data/mp/home/.git; then \
		git clone https://github.com/amanibhavam/homedir $(PWD)/data/mp/home/homedir; \
		(pushd $(PWD)/data/mp/home && mv homedir/.git . && git reset --hard && rm -rf homedir); \
	fi
	multipass exec mp -- sudo mkdir -p /data
	mkdir -p $(PWD)/data/mp/home/venv
	mkdir -p $(PWD)/data/mp/home/.asdf
	multipass mount $(PWD)/data/mp mp:/data
	multipass mount $(PWD)/data/mp/home/.git mp:.git
	multipass mount $(PWD)/data/mp/home/.asdf mp:.asdf
	multipass mount $(PWD)/data/mp/home/venv mp:venv
	multipass mount $(HOME)/work mp:work
	multipass exec mp -- git reset --hard
	cat ~/.dotfiles-repo | multipass exec mp -- tee .dotfiles-repo
	multipass exec mp -- make update
	multipass exec mp -- make upgrade
	multipass exec mp -- make install

bump:
	date > b/.bump
	git add b/.bump
	git commit -m 'bump build'
	$(MAKE) build

bump-brew:
	date > b/.linuxbrew
	git add b/.linuxbrew
	git commit -m 'bump brew build'
	$(MAKE) build

bump-home:
	date > b/.homedir
	git add b/.homedir
	git commit -m 'bump home build'
	$(MAKE) build
