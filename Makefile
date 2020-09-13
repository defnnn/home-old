SHELL := /bin/bash

.PHONY: docs

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

menu:
	@perl -ne 'printf("\n") if m{^-}; printf("%20s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

---------------build: # -----------------------------
build-sshd: # Build sshd container with lefn/python
	@echo
	docker build -t defn/home:sshd \
		--build-arg HOMEBOOT=boot \
		-f b/Dockerfile.sshd \
		--no-cache \
		b
	$(MAKE) test-sshd
	docker push defn/home:sshd

build-ssh: # Build ssh container with sshd
	@echo
	docker build -t defn/home:ssh \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=ssh.defn.sh \
		-f b/Dockerfile.sshu \
		--no-cache \
		b
	$(MAKE) test-ssh
	docker push defn/home:ssh

build-boot: # Build boot container with letfn/python
	@echo
	docker build -t defn/home:boot \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEDIR=https://github.com/amanibhavam/homedir \
		--build-arg DOTFILES=https://github.com/amanibhavam/dotfiles \
		-f b/Dockerfile.boot \
		b
	$(MAKE) test-boot
	docker push defn/home:boot

build-jojomomojo: # Build jojomomojo container with boot
	@echo
	docker build -t defn/home:jojomomojo \
		--build-arg HOMEBOOT=boot \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=jojomomojo.defn.sh \
		-f b/Dockerfile.bootu \
		b
	echo "TEST_PY=$(shell cat test.py | base64 -w 0)" > .drone.env
	$(MAKE) test-jojomomojo
	docker push defn/home:jojomomojo

build-lamda: # Build lamda container with boot
	@echo
	docker build -t defn/home:lamda \
		--build-arg HOMEBOOT=boot\
		--build-arg HOMEUSER=lamda \
		--build-arg HOMEHOST=gorillama.defn.sh \
		-f b/Dockerfile.bootu \
		--no-cache \
		b
	docker push defn/home:lamda

----------------test: # -----------------------------

test: # test all images
	$(MAKE) test-sshd
	$(MAKE) test-ssh
	$(MAKE) test-boot
	$(MAKE) test-jojomomojo

test-sshd: # test image sshd
	drone exec --env-file=.drone.env --pipeline test-sshd

test-ssh: # test image ssh
	drone exec --env-file=.drone.env --pipeline test-ssh

test-boot: # test image boot
	drone exec --env-file=.drone.env --pipeline test-boot

test-jojomomojo: # test image jojomomojo
	drone exec --env-file=.drone.env --pipeline test-jojomomojo

----------------bash: # -----------------------------

bash-sshd: # bash shell with sshd
	docker run --rm -ti --entrypoint bash defn/home:sshd

bash-ssh: # bash shell with ssh
	docker run --rm -ti --entrypoint bash defn/home:ssh

bash-boot: # bash shell with boot
	docker run --rm -ti --entrypoint bash defn/home:boot

bash-jojomomojo: # bash shell with jojomomojo
	docker run --rm -ti --entrypoint bash defn/home:jojomomojo

------docker-compose: # -----------------------------
recreate: # Recreate home container
	kitt recreate
	$(MAKE) ssh-init

recycle: # Recycle home container
	docker pull registry.defn.sh/defn/home
	$(MAKE) recreate

ssh-init:
	ssh-add -L | docker-compose exec -T sshd mkdir -p .ssh
	ssh-add -L | docker-compose exec -T sshd tee .ssh/authorized_keys
