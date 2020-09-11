SHELL := /bin/bash

.PHONY: docs

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

build-sshd: # Build sshd container without cache
	@echo
	docker build -t defn/home:sshd \
		--build-arg HOMEBOOT=boot \
		-f b/Dockerfile.sshd \
		b
	docker push defn/home:sshd

build-boot-clean: # Build boot container without cache
	docker system prune -f
	$(MAKE) build-boot

build-boot: # Build boot container
	@echo
	docker build -t defn/home:boot \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEDIR=https://github.com/amanibhavam/homedir \
		--build-arg DOTFILES=https://github.com/amanibhavam/dotfiles \
		-f b/Dockerfile.boot \
		b
	docker push defn/home:boot

build-ssh: # Build ssh container
	@echo
	docker build -t defn/home:ssh \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=ssh.defn.sh \
		-f b/Dockerfile.sshu \
		--no-cache \
		b
	docker push defn/home:ssh

build-jojomomojo: # Build jojomomojo container
	@echo
	docker build -t defn/home:jojomomojo \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=jojomomojo.defn.sh \
		-f b/Dockerfile.user \
		--no-cache \
		b
	docker push defn/home:jojomomojo

build-lamda: # Build lamda container
	@echo
	docker build -t defn/home:lamda \
		--build-arg HOMEBOOT=boot\
		--build-arg HOMEUSER=lamda \
		--build-arg HOMEHOST=gorillama.defn.sh \
		-f b/Dockerfile.user \
		--no-cache \
		b
	docker push defn/home:lamda

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

bump: # Rebuild boot with update
	date > b/.bump
	git add b/.bump
	git commit -m 'bump build'

bump-brew: # Rebuild boot with homebrew
	date > b/.linuxbrew
	git add b/.linuxbrew
	git commit -m 'bump brew build'

bump-home: # Rebuild boot with home directory
	date > b/.homedir
	git add b/.homedir
	git commit -m 'bump home build'
