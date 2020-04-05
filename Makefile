SHELL := /bin/bash

.PHONY: docs

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

build: # Build update with homedir/dotfiles
	docker build -t registry.eldri.ch/defn/home -f Dockerfile --no-cache .
	docker push registry.eldri.ch/defn/home

os: # Build os container
	docker build -t registry.eldri.ch/defn/home:os -f Dockerfile.os --no-cache .
	docker push registry.eldri.ch/defn/home:os

update0: # Build base with homedir/dotfiles
	docker build -t registry.eldri.ch/defn/home:update0 -f Dockerfile.update0 --no-cache .
	docker push registry.eldri.ch/defn/home:update0

update1: # Build initial install with homedir/dotfiles
	docker build -t registry.eldri.ch/defn/home:update1 -f Dockerfile.update1 --no-cache .
	docker push registry.eldri.ch/defn/home:update1

warm: # Cache FROM images
	docker run --rm -ti -v $(shell pwd)/cache:/cache gcr.io/kaniko-project/warmer:latest --cache-dir=/cache --image=letfn/python-cli:latest

watch: # Watch for changes
	@trap 'exit' INT; while true; do fswatch -0 src content | while read -d "" event; do case "$$event" in *.py) figlet woke; make lint test; break; ;; *.md) figlet docs; make docs; ;; esac; done; sleep 1; done

zt0: # Launch zt0 multipass machine
	multipass delete --purge $@ || true
	multipass launch -m 4g -d 20g -c 2 -n $@ --cloud-init cloud-init.conf bionic
	multipass mount /tmp/data/$@ $@:/data
	multipass exec $@ -- git clone https://github.com/amanibhavam/homedir homedir
	multipass exec $@ -- mv homedir/.git .
	multipass exec $@ -- rm -rf homedir
	multipass exec $@ -- git reset --hard
	multipass exec $@ -- make update
	multipass exec $@ -- make upgrade
	multipass exec $@ -- make install
	multipass exec $@ -- mkdir -p work
	multipass exec $@ -- git clone https://github.com/letfn/zerotier work/zerotier
	multipass exec $@ -- docker pull letfn/zerotier
	multipass exec $@ -- docker-compose up  -d
	multipass exec $@ -- make daemon.json
	multipass exec $@ -- sudo mv daemon.json /etc/docker/daemon.json
	multipass exec $@ -- sudo systemctl restart docker
