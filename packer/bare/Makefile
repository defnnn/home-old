SHELL := bash

packer:
	env \
		DEFN_PACKER_FILTERS_NAME="amzn2-ami-ecs-hvm-*" \
		DEFN_PACKER_AMI_NAME="defn-bare-$(shell date +%s)" \
			packer build -timestamp-ui=true packer.json
