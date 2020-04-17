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

os: # Build os container
	docker build -t registry.eldri.ch/defn/home:os -f Dockerfile.os --no-cache .

update0: # Build base with homedir/dotfiles
	docker build -t registry.eldri.ch/defn/home:update0 -f Dockerfile.update0 --no-cache .

update1: # Build initial install with homedir/dotfiles
	docker build -t registry.eldri.ch/defn/home:update1 -f Dockerfile.update1 --no-cache .

warm: # Cache FROM images
	docker run --rm -ti -v $(shell pwd)/cache:/cache gcr.io/kaniko-project/warmer:latest --cache-dir=/cache --image=letfn/python-cli:latest

watch: # Watch for changes
	@trap 'exit' INT; while true; do fswatch -0 src content | while read -d "" event; do case "$$event" in *.py) figlet woke; make lint test; break; ;; *.md) figlet docs; make docs; ;; esac; done; sleep 1; done

top: # Monitor hyperkit processes
	top $(shell pgrep hyperkit | perl -pe 's{^}{-pid }')

zt0 zt1: # Launch multipass machine
	if ! test -d /tmp/data/$@/home/.git; then \
		git clone https://github.com/amanibhavam/homedir /tmp/data/$@/home/homedir; \
		(pushd /tmp/data/$@/home && mv homedir/.git . && git reset --hard && rm -rf homedir); \
	fi
	mkdir -p /tmp/data/$@/home/.asdf
	multipass delete --purge $@ || true
	multipass launch -m 4g -d 40g -c 1 -n $@ --cloud-init cloud-init.conf bionic
	multipass exec $@ -- bash -c 'while ! test -f /tmp/done.txt; do ps axuf; sleep 10; date; done'
	multipass exec $@ -- sudo mkdir -p /data
	multipass mount /tmp/data/$@ $@:/data
	multipass mount /tmp/data/$@/home/.git $@:.git
	multipass mount /tmp/data/$@/home/.asdf $@:.asdf
	multipass mount /tmp/data/$@/home/venv $@:venv
	multipass exec $@ -- git reset --hard
	multipass exec $@ -- make update
	multipass exec $@ -- make upgrade
	multipass exec $@ -- make install
	multipass exec $@ -- mkdir -p work
	multipass mount "$(shell pwd)" $@:work/home
	multipass exec $@ -- bash -c "source .bash_profile && cd work/home && make NAME=$@ kind-cluster"
	multipass exec $@ cat .kube/config | perl -pe 's{127.0.0.1:.*}{$@:6443}; s{kind-kind}{$@}' > ~/.kube/$@.conf
	multipass unmount $@:work/home
	$(MAKE) NAME=$@ kind-minimal"

docker: # Build docker os base
	$(MAKE) os
	$(MAKE) update0
	$(MAKE) update1
	$(MAKE) build

kind-cluster:
	env KUBECONFIG=$(HOME)/.kube/config kind create cluster --config $(NAME).yaml --name kind || true
	echo nameserver 8.8.8.8 | docker exec -i kind-control-plane tee /etc/resolv.conf

kind-minimal:
	$(NAME)
	$(MAKE) cilium
	while ks get nodes | grep NotReady; do sleep 5; done
	while [[ "$$(ks get -o json pods | jq -r '.items[].status | "\(.phase) \(.containerStatuses[].ready)"' | sort -u)" != "Running true" ]]; do ks get pods; sleep 5; echo; done
	$(MAKE) metal
	$(MAKE) nginx
	$(MAKE) traefik
	$(MAKE) hubble

cilium:
	k apply -f cilium.yaml
	while [[ "$$(ks get -o json pods | jq -r '.items[].status | "\(.phase) \(.containerStatuses[].ready)"' | sort -u)" != "Running true" ]]; do ks get pods; sleep 5; echo; done

metal:
	k create ns metallb-system || true
	kn metallb-system  apply -f metal.yaml

hubble pihole openvpn nginx registry home kong:
	k apply -f $@.yaml

eldri.ch defn.sh:
	kt apply -f $@.yaml

cloudflare.yaml:
	cp $@.example $@

traefik: cloudflare.yaml
	k create ns traefik || true
	kt apply -f crds
	kt apply -f cloudflare.yaml
	kt apply -f traefik.yaml

argo:
	k create ns argo || true
	kn argo apply -f argo.yaml
