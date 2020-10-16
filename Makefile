SHELL := /bin/bash

.PHONY: docs

VARIANT ?= latest
HOMEDIR ?= https://github.com/amanibhavam/homedir
DOTFILES ?= https://github.com/amanibhavam/dotfiles

menu:
	@perl -ne 'printf("\n") if m{^-}; printf("%20s: %s\n","$$1","$$2") if m{^([\w+-]+):[^#]+#\s(.+)$$}' Makefile

config:
	rm -f docker-compose.yml
	$(MAKE) docker-compose.yml
	git diff docker-compose.yml

---------------build: # -----------------------------
thing: # Build all the things
	$(MAKE) build-sshd
	$(MAKE) build-brew
	$(MAKE) build-jojomomojo

build-sshd: # Build sshd container with lefn/python
	@echo
	docker build $(build) -t defn/home:sshd \
		--build-arg HOMEBOOT=app \
		-f b/Dockerfile.sshd \
		b
	$(MAKE) test-sshd
	docker push defn/home:sshd

build-brew: # Build brew container with sshd
	@echo
	docker build $(build) -t defn/home:brew \
		--build-arg HOMEBOOT=app \
		-f b/Dockerfile.brew \
		b
	$(MAKE) test-brew
	docker push defn/home:brew

b/index-homedir: $(HOME)/.git/index
	cp -f $(HOME)/.git/index b/index-homedir.1
	mv -f b/index-homedir.1 b/index-homedir

b/index-dotfiles: $(HOME)/.dotfiles/.git/index
	cp -f $(HOME)/.dotfiles/.git/index b/index-dotfiles.1
	mv -f b/index-dotfiles.1 b/index-dotfiles

b/index: .git/index
	cp -f .git/index b/index.1
	mv -f b/index.1 b/index

push: 
	docker push defn/home:jojomomojo

build: 
	$(MAKE) build-jojomomojo

build-jojomomojo: b/index b/index-homedir b/index-dotfiles # Build jojomomojo container with brew
	@echo
	docker build $(build) -t defn/home:jojomomojo \
		--build-arg HOMEBOOT=app \
		--build-arg HOMEUSER=jojomomojo \
		--build-arg HOMEHOST=jojomomojo.defn.sh \
		--build-arg HOMEDIR=https://github.com/amanibhavam/homedir \
		--build-arg DOTFILES=https://github.com/amanibhavam/dotfiles \
		-f b/Dockerfile.home \
		b
	echo "TEST_PY=$(shell cat test.py | (base64 -w 0 2>/dev/null || base64) )" > .drone.env
	$(MAKE) test-jojomomojo
	docker tag defn/home:jojomomojo localhost:5000/defn/home:jojomomojo
	if nc -z -v localhost 5000; then docker push localhost:5000/defn/home:jojomomojo; fi
	if [[ -n "$(EXPECTED_REF)" ]]; then docker tag defn/home:jojomomojo "$(EXPECTED_REF)"; fi

----------------test: # -----------------------------

test: # test all images
	$(MAKE) test-sshd
	$(MAKE) test-brew
	$(MAKE) test-jojomomojo

test-sshd: # test image sshd
	drone exec --env-file=.drone.env --pipeline test-sshd

test-brew: # test image brew
	drone exec --env-file=.drone.env --pipeline test-brew

test-jojomomojo: # test image jojomomojo
	drone exec --env-file=.drone.env --pipeline test-jojomomojo

----------------bash: # -----------------------------

bash-sshd: # bash shell with sshd
	docker run --rm -ti --entrypoint bash defn/home:sshd

bash-brew: # bash shell with brew
	docker run --rm -ti --entrypoint bash defn/home:brew

bash-jojomomojo: # bash shell with jojomomojo
	docker run --rm -ti --entrypoint bash defn/home:jojomomojo

------docker-compose: # -----------------------------

up: # Bring up farcast
	$(MAKE) policy
	docker-compose up -d --remove-orphans

policy:
	cat policy.yml | docker run --rm -i letfn/python-cli yq . | (cd ../cilium && docker-compose exec -T cilium cilium policy import -)

down: # Bring down farcast
	docker-compose down --remove-orphans

recreate: # Recreate home container
	$(MAKE) down
	$(MAKE) up

recycle: # Recycle home container
	docker-compose pull
	$(MAKE) recreate

rebash:
	$(MAKE) down
	$(MAKE) bash

bash:
	docker-compose run --rm --entrypoint bash sshd -il

bash-exec:
	docker-compose exec sshd bash -il

-------------cuelang: # -----------------------------

fmt:
	cue fmt *.cue
	yamlfmt -w docker-compose.yml

docker-compose.yml: docker-compose.cue
	cue export --out json docker-compose.cue | yq -y -S '.'  > docker-compose.yml.1
	yamlfmt -w docker-compose.yml.1
	mv docker-compose.yml.1 docker-compose.yml
	
----------------tilt: # -----------------------------

tilt:
	-tilt down
	tilt up
