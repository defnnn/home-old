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
rebuild: # Rebuild everything from scratch
	$(MAKE) build-latest push-latest build=--no-cache
	$(MAKE) build-brew push-brew build=--no-cache
	$(MAKE) build-home push-home build=--no-cache

build-latest: # Build latest container with lefn/python
	@echo
	docker build $(build) -t defn/home:latest \
		--build-arg HOMEBOOT=app \
		-f b/Dockerfile \
		b

push-latest:
	docker push defn/home:latest

build-brew: # Build brew container with latest
	@echo
	docker build $(build) -t defn/home:brew \
		--build-arg HOMEBOOT=app \
		-f b/Dockerfile.brew \
		b

push-brew:
	docker push defn/home:brew

build-home: b/index b/index-homedir # Build home container with brew
	@echo
	docker build $(build) -t defn/home:home \
		--build-arg HOMEBOOT=app \
		--build-arg HOMEUSER=app \
		--build-arg HOMEDIR=https://github.com/amanibhavam/homedir \
		-f b/Dockerfile.home \
		b

push-home:
	docker push defn/home:home

fmt: # Format cue
	cue fmt *.cue

docker-compose.yml: docker-compose.cue
	cue export --out json docker-compose.cue Homefile.cue | yq -y -S '.'  > docker-compose.yml.1
	mv docker-compose.yml.1 docker-compose.yml

b/index-homedir: $(HOME)/.git/index
	cp -f $(HOME)/.git/index b/index-homedir.1
	mv -f b/index-homedir.1 b/index-homedir

b/index: .git/index
	cp -f .git/index b/index.1
	mv -f b/index.1 b/index

-------------jenkins: # -----------------------------

build-jenkins: # Build Jenkins server
	docker build $(build) -t defn/jenkins \
		-f b/Dockerfile.jenkins .

build-jenkins-job: # Build Jenkins job job
	docker build $(build) -t defn/jenkins-job \
		-f b/Dockerfile.jenkins-job .

build-jenkins-go: # Build Jenkins go job
	docker build $(build) -t defn/jenkins-go \
		-f b/Dockerfile.jenkins-go .

build-jenkins-python: # Build Jenkins python job
	docker build $(build) -t defn/jenkins-python \
		-f b/Dockerfile.jenkins-python .

push-jenkins:
	docker push defn/jenkins

push-jenkins-job:
	docker push defn/jenkins-job

push-jenkins-go:
	docker push defn/jenkins-go

push-jenkins-python:
	docker push defn/jenkins-python

jenkins-recreate: # Recreate Jenkins services
	$(MAKE) fmt config
	$(MAKE) vault-renew
	rm -f etc/jenkins-vault-agent/token
	$(MAKE) recreate
	while true; do if test -f etc/jenkins-vault-agent/token; then break; fi; sleep 1; done
	sleep 1
	$(MAKE) jenkins-casc-env

jenkins-pass:
	@docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

jenkins-casc-env: # Regenerate Jenkins credentials
	echo -n CASC_VAULT_TOKEN= > etc/jenkins/casc.env
	cat etc/jenkins-vault-agent/token >> etc/jenkins/casc.env

jenkins-reload: # Reload Jenkins configuration
	$(MAKE) jenkins-casc-env
	cat etc/jenkins/reload.groovy | docker-compose exec -T home ./env.sh j groovysh

jenkins-bash: # jenkins shell with docker-compose exec
	docker-compose exec -u 0 jenkins bash -il

vault-renew: # Renew vault agent credentials
	v login
	v read -field=role_id auth/approle/role/jenkins/role-id  > etc/jenkins-vault-agent/role_id
	v read -field=role_id auth/approle/role/jenkins/role-id  > etc/vault-agent/role_id
	v write -wrap-ttl=180s -field=wrapping_token -f auth/approle/role/jenkins/secret-id > etc/jenkins-vault-agent/secret_id
	v write -wrap-ttl=180s -field=wrapping_token -f auth/approle/role/jenkins/secret-id > etc/vault-agent/secret_id

vault-revoke: # Revoke vault agent sink token
	docker-compose exec -T vault env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN="$$(cat etc/jenkins-vault-agent/token)" vault token revoke -self

vault-lookup: # Lookup vault agent sink token
	docker-compose exec -T vault env VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN="$$(cat etc/jenkins-vault-agent/token)" vault token lookup

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

------docker-compose: # -----------------------------

bash: # bash shell with docker-compose exec
	docker-compose exec home bash -il

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
