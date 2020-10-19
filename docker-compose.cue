version: "3.7"

services: [Name=string]: {
	image: "defn/home:home"
	volumes:
	[
		"/var/run/docker.sock:/var/run/docker.sock",
	]
}

networks: default: external: name: "kitt_default"
