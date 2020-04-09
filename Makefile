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

top: # Monitor hyperkit processes
	top $(shell pgrep hyperkit | perl -pe 's{^}{-pid }')

zt0: # Launch zt0 multipass machine
	multipass delete --purge $@ || true
	multipass launch -m 4g -d 40g -c 2 -n $@ --cloud-init cloud-init.conf bionic
	multipass exec $@ -- bash -c 'while ! test -f /tmp/done.txt; do ps axuf; sleep 10; date; done'
	multipass exec $@ -- sudo mkdir -p /data
	multipass exec $@ -- sudo mount -o rw,nolock,hard,nointr 192.168.64.1:/tmp/data/$@ /data
	multipass exec $@ -- mkdir -p work
	multipass exec $@ -- git clone https://github.com/amanibhavam/homedir homedir
	multipass exec $@ -- mv homedir/.git .
	multipass exec $@ -- rm -rf homedir
	multipass exec $@ -- git reset --hard
	multipass exec $@ -- make update
	multipass exec $@ -- make upgrade
	multipass exec $@ -- make install

zt0-kind:
	mkdir -p "$(HOME)/.kube"
	multipass mount "$(HOME)/.kube" zt0:.kube
	multipass mount "$(shell pwd)" zt0:work/home
	multipass exec zt0 -- bash -c "source .bash_profile && cd work/home && make kind"
	multipass exec zt0 -- perl -pe 's{https://(\S+)}{https://kubernetes}' .kube/config

docker: # Build docker os base
	$(MAKE) os
	$(MAKE) update0
	$(MAKE) update1
	$(MAKE) build

kind:
	kind create cluster --config kind.yaml --name kind || true
	echo nameserver 8.8.8.8 | docker exec -i kind-control-plane tee /etc/resolv.conf
	$(MAKE) cilium
	source ~/.bashrc; while ks get nodes | grep NotReady; do sleep 5; done
	source ~/.bashrc; while [[ "$$(ks get -o json pods | jq -r '.items[].status | "\(.phase) \(.containerStatuses[].ready)"' | sort -u)" != "Running true" ]]; do ks get pods; sleep 5; echo; done
	$(MAKE) kind-support

kind-support:
	$(MAKE) metal
	$(MAKE) nginx
	$(MAKE) traefik
	$(MAKE) hubble
	$(MAKE) pihole
	$(MAKE) openvpn
	$(MAKE) registry

cilium:
	source ~/.bashrc; k apply -f cilium.yaml
	source ~/.bashrc; while [[ "$$(ks get -o json pods | jq -r '.items[].status | "\(.phase) \(.containerStatuses[].ready)"' | sort -u)" != "Running true" ]]; do ks get pods; sleep 5; echo; done

metal:
	source ~/.bashrc; k create ns metallb-system || true
	source ~/.bashrc; kn metallb-system  apply -f metal.yaml

hubble:
	source ~/.bashrc; k apply -f hubble.yaml

pihole:
	source ~/.bashrc; k apply -f pihole.yaml

openvpn:
	source ~/.bashrc; k apply -f openvpn.yaml

nginx:
	source ~/.bashrc; k apply -f nginx.yaml

traefik:
	source ~/.bashrc; k create ns traefik || true
	source ~/.bashrc; kt apply -f crds
	source ~/.bashrc; kt apply -f cloudflare.yaml
	source ~/.bashrc; kt apply -f traefik.yaml

registry:
	source ~/.bashrc; k apply -f registry.yaml

defn:
	source ~/.bashrc; k apply -f defn.yaml

argo:
	source ~/.bashrc; k create ns argo || true
	source ~/.bashrc; kn argo apply -f argo.yaml

