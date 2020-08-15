SHELL := /bin/bash

default:
	$(MAKE) fmt validate

init:
	terraform init

upgrade:
	terraform init -upgrade

fmt:
	for a in *.tf *.tfvars; do if [[ -f $$a ]]; then terraform fmt $$a; fi; done

validate:
	terraform validate

plan:
	terraform plan -out=.plan-$(shell cat .terraform/environment)

apply:
	terraform apply .plan-$(shell cat .terraform/environment)
	rm -f .plan-$(shell cat .terraform/environment)

refresh:
	terraform refresh

shell:
	terraform console

%:
	terraform workspace select $@
