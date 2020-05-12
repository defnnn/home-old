SHELL := /bin/bash

.PHONY: docs kind

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

all: # Run everything except build
	$(MAKE) fmt
	$(MAKE) lint
	$(MAKE) docs

fmt: # Format drone fmt
	@echo
	drone exec --pipeline $@

lint: # Run drone lint
	@echo
	drone exec --pipeline $@

docs: # Build docs
	@echo
	drone exec --pipeline $@

requirements: # Compile requirements
	@echo
	drone exec --pipeline $@

build: # Build container
	@echo
	docker system prune -f
	drone exec --pipeline $@ --secret-file ../.drone.secret

warm: # Cache FROM images
	docker run --rm -ti -v $(shell pwd)/cache:/cache gcr.io/kaniko-project/warmer:latest --cache-dir=/cache --image=letfn/python-cli:latest

logs: # Logs for docker-compose
	cd c && docker-compose logs -f

up: # Run home container with docker-compose
	cd c && docker-compose up -d

down: # Shut down home container
	cd c && docker-compose down --remove-orphans

restart: # Restart home container
	cd c && docker-compose restart

recreate: # Recreate home container
	docker system prune -f
	-$(MAKE) down 
	$(MAKE) up
	docker system prune -f

recycle: # Recycle home container
	docker pull defn/home
	$(MAKE) recreate

ssh: # ssh into home container
	@ssh-add -L | grep cardno: | head -1 > .ssh/id_rsa.pub
	@vault write -field=signed_key home/sign/defn public_key=@.ssh/id_rsa.pub \
		> .ssh/id_rsa-cert.pub
	@tm app@ssh.whoa.bot bash

attach:
	@vault write -field=signed_key home/sign/defn public_key=@.ssh/id_rsa.pub \
		> .ssh/id_rsa-cert.pub
	@tm app@ssh.whoa.bot

top: # Monitor hyperkit processes
	top $(shell pgrep hyperkit | perl -pe 's{^}{-pid }')

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

mp-kind:
	multipass exec mp -- ./env bash -c 'cd work/home && make kind'
	multipass exec mp -- cat .kube/config > ~/.kube/config

kind:
	kind delete cluster || true
	docker network rm kind || true
	docker network create --subnet 172.18.0.0/16 kind
	$(MAKE) kind-cluster
	$(MAKE) kind-cilium
	$(MAKE) kind-extras

kind-cluster:
	kind create cluster --config kind/kind.yaml
	$(MAKE) kind-config

kind-config:
	kind export kubeconfig
	perl -pe 's{127.0.0.1:.*}{host.docker.internal:6443}' -i ~/.kube/config
	k cluster-info

kind-cilium:
	$(MAKE) cilium
	while ks get nodes | grep NotReady; do sleep 5; done
	while [[ "$$(ks get -o json pods | jq -r '.items[].status | "\(.phase) \(.containerStatuses[].ready)"' | sort -u)" != "Running true" ]]; do ks get pods; sleep 5; echo; done

kind-extras:
	$(MAKE) metal
	$(MAKE) nginx
	$(MAKE) traefik
	$(MAKE) kong
	$(MAKE) hubble

cilium:
	k apply -f k/cilium.yaml
	while [[ "$$(ks get -o json pods | jq -r '.items[].status | "\(.phase) \(.containerStatuses[].ready)"' | sort -u)" != "Running true" ]]; do ks get pods; sleep 5; echo; done

metal:
	k create ns metallb-system || true
	kn metallb-system apply -f k/metal.yaml

k/cloudflare.yaml:
	cp $@.example $@

traefik: k/cloudflare.yaml
	k create ns traefik || true
	kt apply -f k/crds
	kt apply -f k/cloudflare.yaml
	kt apply -f k/traefik.yaml

argo:
	k create ns argo || true
	kn argo apply -f k/argo.yaml

hubble pihole openvpn nginx registry home kong:
	k apply -f k/$@.yaml

bump:
	date > b/.bump
	git add b/.bump
