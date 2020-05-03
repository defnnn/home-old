SHELL := /bin/bash

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

.PHONY: docs kind

menu:
	@perl -ne 'printf("%10s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

all: # Run everything except build
	$(MAKE) fmt
	$(MAKE) lint
	$(MAKE) docs
	$(MAKE) test

fmt: # Format with isort, black
	@echo
	drone exec --pipeline $@

lint: # Run pyflakes, mypy
	@echo
	drone exec --pipeline $@

test: # Run tests
	@echo
	drone exec --pipeline $@

docs: # Build docs
	@echo
	drone exec --pipeline $@

requirements: # Compile requirements
	@echo
	drone exec --pipeline $@

push: # Push to defn/home
	docker push defn/home

kaniko-os: # Buld home:os with kaniko
	drone exec --pipeline build-os --secret-file ../.drone.secret

kaniko: # Build home with kaniko
	drone exec --pipeline build --secret-file ../.drone.secret

build: # Build home Docker image
	$(MAKE) os
	$(MAKE) update0
	$(MAKE) update1
	$(MAKE) variant

os: # Build os container
	cd b && docker build -t registry.eldri.ch/defn/home:$@ -f Dockerfile.$@ --no-cache .

update0: # Build base with homedir/dotfiles
	cd b && docker build -t registry.eldri.ch/defn/home:$@ -f Dockerfile.$@ --no-cache \
		--build-arg HOMEDIR="$(HOMEDIR)" \
		--build-arg DOTFILES="$(DOTFILES)" \
		.

update1: # Build initial install with homedir/dotfiles
	cd b && docker build -t registry.eldri.ch/defn/home:$@ -f Dockerfile.$@ --no-cache .

latest: # Build latest variant
	make VARIANT=latest variant

variant: # Build update with homedir/dotfiles
	cd b && docker build -t registry.eldri.ch/defn/home:$(VARIANT) -f Dockerfile.$(VARIANT) --no-cache .
	docker tag registry.eldri.ch/defn/home:$(VARIANT) defn/home:$(VARIANT)

warm: # Cache FROM images
	docker run --rm -ti -v $(shell pwd)/cache:/cache gcr.io/kaniko-project/warmer:latest --cache-dir=/cache --image=letfn/python-cli:latest

watch: # Watch for changes
	@trap 'exit' INT; while true; do fswatch -0 src content | while read -d "" event; do case "$$event" in *.py) figlet woke; make lint test; break; ;; *.md) figlet docs; make docs; ;; esac; done; sleep 1; done

logs: # Logs for docker-compose
	cd c && docker-compose logs -f

up: # Run home container with docker-compose
	ssh-keygen -R [localhost]:2222 || true
	cd c && docker-compose up -d

down: # Shut down home container
	cd c && docker-compose down

restart: # Restart home container
	cd c && docker-compose restart

recreate: # Recreate home container
	-$(MAKE) down 
	$(MAKE) up

recycle: # Rebuild and recreate home container
	$(MAKE) build
	$(MAKE) recreate

ssh: # ssh into home container
	ssh -A -p 2222 -o StrictHostKeyChecking=no app@localhost

top: # Monitor hyperkit processes
	top $(shell pgrep hyperkit | perl -pe 's{^}{-pid }')

multipass: # Launch multipass machine
	if ! test -d $(PWD)/data/$@/home/.git; then \
		git clone https://github.com/amanibhavam/homedir $(PWD)/data/$@/home/homedir; \
		(pushd $(PWD)/data/$@/home && mv homedir/.git . && git reset --hard && rm -rf homedir); \
	fi
	mkdir -p $(PWD)/data/$@/home/.asdf
	multipass delete --purge $@ || true
	multipass launch -m 4g -d 40g -c 2 -n $@ --cloud-init multipass/cloud-init.conf focal
	$@ exec bash -c 'while ! test -f /tmp/done.txt; do ps axuf; sleep 10; date; done'
	$@ exec sudo mkdir -p /data
	multipass mount $(PWD)/data/$@ $@:/data
	multipass mount $(PWD)/data/$@/home/.git $@:.git
	multipass mount $(PWD)/data/$@/home/.asdf $@:.asdf
	multipass mount $(PWD)/data/$@/home/venv $@:venv
	$@ exec git reset --hard
	cat ~/.dotfiles-repo | $@ exec tee .dotfiles-repo
	$@ exec make update
	$@ exec make upgrade
	$@ exec make install
	$@ exec mkdir -p work
	multipass mount "$(shell pwd)" $@:work/home
	$(MAKE) kind-cluster
	$@ bash -c "echo nameserver 8.8.8.8 | docker exec -i kind-control-plane tee /etc/resolv.conf"
	$@ cat .kube/config | perl -pe 's{127.0.0.1:.*}{kind:6443}; s{kind-kind}{kind}' > ~/.kube/config
	$(MAKE) kind-extras
	multipass unmount $@:work/home

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
