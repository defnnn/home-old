version: "3.7"

services: sshd: {
	image: "defn/home:jojomomojo"
	entrypoint: ["/service", "sshd"]
	volumes:
		[
			"/var/run/docker.sock:/var/run/docker.sock",
      "$HOME/.password-store:/home/app/.password-store",
      "$HOME/work:/home/app/work",
			"config:/data/home-secret",
      "zerotier:/zerotier"
		]
}

services: cloudflared: {
	image: "letfn/cloudflared"
	volumes: [
		"config:/app/src/.cloudflared",
	]
}

services: [Service=string]: {
	if Service != "zt" {
		env_file: ".env"
	}
}

services: [Zerotier=string]: {
	if Zerotier =~ "^zerotier" {
		_zerotier

		volumes: [
			"\(Zerotier):/var/lib/zerotier-one",
		]
	}
}

_zerotier: {
	image: "letfn/zerotier"
	cap_drop: [
		"NET_RAW",
		"NET_ADMIN",
		"SYS_ADMIN",
	]
	devices: [
		"/dev/net/tun",
	]
	privileged: true
}

services: zerotier: {
  ports: [
    "2222:2222"
  ]
}

services: sshd: depends_on: zerotier: condition: "service_started"
services: sshd: network_mode: "service:zerotier"

services: cloudflared: depends_on: zerotier: condition: "service_started"
services: cloudflared: network_mode: "service:zerotier"

volumes: config: {}
volumes: zerotier: {}

networks: default: driver: "cilium"
