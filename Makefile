SHELL := /bin/bash

.PHONY: docs

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

build-boot: # Build boot container
	$(MAKE) build-docker

build-jojomomojo-ssh: # Build jojomomojo-ssh container
	@echo
	docker build -t defn/home:jojomomojo-ssh \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=ssh.defn.sh \
		c

build-jojomomojo: # Build jojomomojo container
	@echo
	docker build -t defn/home:jojomomojo \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=jojomomojo.defn.sh \
		c

build-lamda: # Build lamda container
	@echo
	docker build -t defn/home:lamda \
		--build-arg HOMEBOOT=boot\
		--build-arg HOMEUSER=lamda \
		--build-arg HOMEHOST=gorillama.defn.sh \
		c

build-docker: # Build boot container with docker build
	@echo
	docker build -t defn/home:boot \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEDIR=https://github.com/amanibhavam/homedir \
		--build-arg DOTFILES=https://github.com/amanibhavam/dotfiles \
		b

build-kaniko: # Build container with kaniko
	@echo
	drone exec --pipeline $@
	docker pull registry.defn.sh/defn/home:latest
	docker tag registry.defn.sh/defn/home:latest defn/home

recreate: # Recreate home container
	kitt recreate
	$(MAKE) ssh-init

recycle: # Recycle home container
	docker pull registry.defn.sh/defn/home
	$(MAKE) recreate

ssh-init:
	ssh-add -L | docker-compose exec -T sshd mkdir -p .ssh
	ssh-add -L | docker-compose exec -T sshd tee .ssh/authorized_keys

bash:
	docker-compose exec sshd bash

bump: # Rebuild with update
	date > b/.bump
	git add b/.bump
	git commit -m 'bump build'

bump-reset: # Rebuild from scratch
	date > b/.reset
	git add b/.reset
	git commit -m 'bump reset build'

bump-brew: # Rebuild homebrew
	date > b/.linuxbrew
	git add b/.linuxbrew
	git commit -m 'bump brew build'

bump-home: # Rebuild home directory
	date > b/.homedir
	git add b/.homedir
	git commit -m 'bump home build'
