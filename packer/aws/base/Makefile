SHELL := bash

packer:
	env \
		DEFN_PACKER_FILTERS_NAME="defn-bare-*" \
		DEFN_PACKER_AMI_NAME="defn-base-$(shell date +%s)" \
			packer build -timestamp-ui=true packer.json

latest:
	source .env \
	&& env \
		DEFN_PACKER_FILTERS_NAME="defn-base-*" \
		DEFN_PACKER_AMI_NAME="defn-latest-$(shell date +%s)" \
		DEFN_AMI_REGIONS="us-west-1,us-west-2,us-east-1,us-east-2" \
		DEFN_KMS_KEY_ID="alias/ami" \
			packer build -timestamp-ui=true packer-update.json
