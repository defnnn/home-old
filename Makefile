SHELL := /bin/bash

.PHONY: docs

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir

menu:
	@perl -ne 'printf("\n") if m{^-}; printf("%20s: %s\n","$$1","$$2") if m{^([\s\w+-]+):[^#]+#\s(.+)$$}' Makefile

setup:
	$(MAKE) recreate

config:
	rm -f docker-compose.yml
	$(MAKE) docker-compose.yml
	git diff docker-compose.yml

logs:
	docker-compose logs -f

---------------build: # -----------------------------
build-latest: # Build latest container with lefn/python
	@echo
	podman build $(build) -t defn/home:latest \
		--build-arg HOMEBOOT=app \
		-f b/Dockerfile \
		b
	$(MAKE) test-latest
	podman push defn/home:latest

build-brew: # Build brew container with latest
	@echo
	podman build $(build) -t defn/home:brew \
		--build-arg HOMEBOOT=app \
		-f b/Dockerfile.brew \
		b
	$(MAKE) test-brew
	podman push defn/home:brew

build-home: b/index b/index-homedir # Build home container with brew
	@echo
	podman build $(build) -t defn/home:home \
		--build-arg HOMEBOOT=app \
		--build-arg HOMEUSER=app \
		--build-arg HOMEDIR=https://github.com/amanibhavam/homedir \
		-f b/Dockerfile.home \
		b
	echo "TEST_PY=$(shell cat test.py | (base64 -w 0 2>/dev/null || base64) )" > .drone.env
	podman push defn/home:home

b/index-homedir: $(HOME)/.git/index
	cp -f $(HOME)/.git/index b/index-homedir.1
	mv -f b/index-homedir.1 b/index-homedir

b/index: .git/index
	cp -f .git/index b/index.1
	mv -f b/index.1 b/index

push: 
	podman push defn/home:home

build: 
	$(MAKE) build-home

----------------test: # -----------------------------

test: # test all images
	$(MAKE) test-latest
	$(MAKE) test-brew
	$(MAKE) test-app

test-latest: # test image latest
	echo drone exec --env-file=.drone.env --pipeline test-latest

test-brew: # test image brew
	echo drone exec --env-file=.drone.env --pipeline test-brew

test-app: # test image app
	echo drone exec --env-file=.drone.env --pipeline $@

----------------bash: # -----------------------------

bash-latest: # bash shell with latest
	podman run --rm -ti --entrypoint bash defn/home:latest

bash-brew: # bash shell with brew
	podman run --rm -ti --entrypoint bash defn/home:brew

bash-home: # bash shell with home
	podman run --rm -ti --entrypoint bash defn/home:home

bash: # bash shell with docker-compose exec
	docker-compose exec home bash -il

------docker-compose: # -----------------------------

up: # Bring up homd
	docker-compose up -d --remove-orphans

down: # Bring down home
	docker-compose down --remove-orphans

recreate: # Recreate home container
	$(MAKE) down
	$(MAKE) up

recycle: # Recycle home container
	$(MAKE) pull
	$(MAKE) recreate

rebash:
	$(MAKE) down
	$(MAKE) bash

pull:
	docker-compose pull

-------------cuelang: # -----------------------------

fmt:
	cue fmt *.cue

docker-compose.yml: docker-compose.cue
	cue export --out json docker-compose.cue Homefile.cue | yq -y -S '.'  > docker-compose.yml.1
	mv docker-compose.yml.1 docker-compose.yml
	
----------------tilt: # -----------------------------

tilt:
	-tilt down
	tilt up
