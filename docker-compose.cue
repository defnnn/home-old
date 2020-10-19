version: "3.7"

services: [Name=string]: {
	image: "defn/home:home"
	volumes:
	[
		"/var/run/docker.sock:/var/run/docker.sock",
	]
}

services: defn: networks: default: ipv4_address: "${KITT_NETWORK_PREFIX}.99"
services: dgwyn: networks: default: ipv4_address: "${KITT_NETWORK_PREFIX}.98"

networks: default: external: name: "kitt_default"
