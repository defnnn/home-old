version: "3.7"

services: {
	init: {
		image: "ubuntu"
		command: [
			"bash",
			"-c",
			"""
		set -x
		exec sleep 86400000

		""",
		]

		volumes: [
			"config:/config",
			"zerotier0:/zerotier0",
			"zerotier1:/zerotier1",
			"zerotier2:/zerotier2",
		]
		healthcheck: {
			test: ["CMD", "test", "-f", "/tmp/done.txt"]
			interval: "10s"
			timeout:  "15s"
			retries:  100
		}
	}

	sshd: {
		image:        "defn/home:jojomomojo"
		network_mode: "service:init"
		entrypoint: ["/service", "sshd"]
		env_file: ".env"
		volumes: [
			"/var/run/docker.sock:/var/run/docker.sock",
			"config:/data/home-secret",
			"config:/config",
			"zerotier0:/zerotier0",
			"zerotier1:/zerotier1",
			"zerotier2:/zerotier2",
		]
		depends_on: init: condition: "service_healthy"
	}

	cloudflared: {
		image:        "letfn/cloudflared"
		network_mode: "service:init"
		env_file:     ".env"
		volumes: [
			"config:/app/src/.cloudflared",
		]
		depends_on: init: condition: "service_healthy"
	}

	"kuma-global": {
		image:        "letfn/kuma"
		network_mode: "service:zerotier0"
		entrypoint: [
			"kuma-cp",
			"run",
		]
		env_file: ".env"
		environment: [
			"KUMA_MODE=global",
		]
		volumes: [
			"config:/config",
		]
		depends_on: {
			init: condition:      "service_healthy"
			zerotier0: condition: "service_started"
			zerotier1: condition: "service_started"
			zerotier2: condition: "service_started"
		}
	}

	"kuma-cp1": {
		image: "letfn/kuma"
		entrypoint: [
			"kuma-cp",
			"run",
		]
		env_file: ".env"
		environment: [
			"KUMA_MODE=remote",
			"KUMA_MULTICLUSTER_REMOTE_ZONE=farcast1",
			"KUMA_MULTICLUSTER_REMOTE_GLOBAL_ADDRESS=grpcs://192.168.195.156:5685",
			"KUMA_GENERAL_ADVERTISED_HOSTNAME=kuma-cp1",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_ENABLED=true",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_INTERFACE=0.0.0.0",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_PORT=5684",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_TLS_CERT_FILE=/certs/server/cert.pem",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_TLS_KEY_FILE=/certs/server/key.pem",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_CLIENT_CERTS_DIR=/certs/client",
		]
		volumes: [
			"config:/config",
		]
		depends_on: "kuma-global": condition: "service_started"
	}

	"kuma-cp2": {
		image: "letfn/kuma"
		entrypoint: [
			"kuma-cp",
			"run",
		]
		env_file: ".env"
		environment: [
			"KUMA_MODE=remote",
			"KUMA_MULTICLUSTER_REMOTE_ZONE=farcast2",
			"KUMA_MULTICLUSTER_REMOTE_GLOBAL_ADDRESS=grpcs://192.168.195.156:5685",
			"KUMA_GENERAL_ADVERTISED_HOSTNAME=kuma-cp2",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_ENABLED=true",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_INTERFACE=0.0.0.0",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_PORT=5684",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_TLS_CERT_FILE=/certs/server/cert.pem",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_TLS_KEY_FILE=/certs/server/key.pem",
			"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_CLIENT_CERTS_DIR=/certs/client",
		]
		volumes: [
			"config:/config",
		]
		depends_on: "kuma-global": condition: "service_started"
	}

	"kuma-ingress1": {
		image:        "letfn/kuma"
		network_mode: "service:zerotier1"
		entrypoint: [
			"kuma-dp",
			"run",
			"--name=kuma-ingress",
			"--cp-address=http://kuma-cp1:5681",
			"--dataplane-token-file=/config/farcast1-ingress-token",
			"--log-level=debug",
		]
		volumes: [
			"config:/config",
		]
		depends_on: "kuma-cp1": condition: "service_started"
	}

	"kuma-ingress2": {
		image:        "letfn/kuma"
		network_mode: "service:zerotier2"
		entrypoint: [
			"kuma-dp",
			"run",
			"--name=kuma-ingress",
			"--cp-address=http://kuma-cp2:5681",
			"--dataplane-token-file=/config/farcast2-ingress-token",
			"--log-level=debug",
		]
		volumes: [
			"config:/config",
		]
		depends_on: "kuma-cp2": condition: "service_started"
	}

	"kuma-app1-pause": image: "gcr.io/google_containers/pause-amd64:3.2"

	"kuma-app2-pause": image: "gcr.io/google_containers/pause-amd64:3.2"

	"kuma-app1": {
		image:        "nginx"
		network_mode: "service:kuma-app1-pause"
		volumes: [
			"config:/config",
		]
	}

	"kuma-app2": {
		image:        "nginx"
		network_mode: "service:kuma-app2-pause"
		volumes: [
			"config:/config",
		]
	}

	"kuma-app1-dp": {
		image:        "letfn/kuma"
		network_mode: "service:kuma-app1-pause"
		entrypoint: [
			"kuma-dp",
			"run",
			"--name=app",
			"--cp-address=http://kuma-cp1:5681",
			"--dataplane-token-file=/config/farcast1-app-token",
			"--log-level=debug",
		]
		volumes: [
			"config:/config",
		]
		depends_on: "kuma-cp1": condition: "service_started"
	}

	"kuma-app2-dp": {
		image:        "letfn/kuma"
		network_mode: "service:kuma-app2-pause"
		entrypoint: [
			"kuma-dp",
			"run",
			"--name=app",
			"--cp-address=http://kuma-cp2:5681",
			"--dataplane-token-file=/config/farcast2-app-token",
			"--log-level=debug",
		]
		volumes: [
			"config:/config",
		]
		depends_on: "kuma-cp2": condition: "service_started"
	}

	zerotier0: {
		image:    "letfn/zerotier"
		env_file: ".env"
		volumes: [
			"zerotier0:/var/lib/zerotier-one",
			"config:/service.d",
		]
		cap_drop: [
			"NET_RAW",
			"NET_ADMIN",
			"SYS_ADMIN",
		]
		devices: [
			"/dev/net/tun",
		]
		privileged: true
		depends_on: init: condition: "service_healthy"
	}

	zerotier1: {
		image:    "letfn/zerotier"
		env_file: ".env"
		volumes: [
			"zerotier1:/var/lib/zerotier-one",
			"config:/service.d",
		]
		cap_drop: [
			"NET_RAW",
			"NET_ADMIN",
			"SYS_ADMIN",
		]
		devices: [
			"/dev/net/tun",
		]
		privileged: true
		depends_on: init: condition: "service_healthy"
	}

	zerotier2: {
		image:    "letfn/zerotier"
		env_file: ".env"
		volumes: [
			"zerotier2:/var/lib/zerotier-one",
			"config:/service.d",
		]
		cap_drop: [
			"NET_RAW",
			"NET_ADMIN",
			"SYS_ADMIN",
		]
		devices: [
			"/dev/net/tun",
		]
		privileged: true
		depends_on: init: condition: "service_healthy"
	}
}

volumes: {
	config: {}
	zerotier0: {}
	zerotier1: {}
	zerotier2: {}
}
