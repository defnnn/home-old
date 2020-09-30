version: "3.7"

zerotiers: [ "zerotier0", "zerotier1", "zerotier2"]

zones: [ "1", "2"]

ip_global: "192.168.195.156"

#zerotier: {
	image:    "letfn/zerotier"
	env_file: ".env"
	volumes: [...]
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

serviceo: {
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
			init: condition: "service_healthy"
			{
				for n in zerotiers {
					"\(n)": condition: "service_started"
				}
			}
		}
	}

	{
		for n in zones {
			"kuma-cp\(n)": {
				image: "letfn/kuma"
				entrypoint: [
					"kuma-cp",
					"run",
				]
				env_file: ".env"
				environment: [
					"KUMA_MODE=remote",
					"KUMA_MULTICLUSTER_REMOTE_ZONE=farcast\(n)",
					"KUMA_MULTICLUSTER_REMOTE_GLOBAL_ADDRESS=grpcs://\(ip_global):5685",
					"KUMA_GENERAL_ADVERTISED_HOSTNAME=kuma-cp\(n)",
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

			"kuma-ingress\(n)": {
				image:        "letfn/kuma"
				network_mode: "service:zerotier\(n)"
				entrypoint: [
					"kuma-dp",
					"run",
					"--name=kuma-ingress",
					"--cp-address=http://kuma-cp\(n):5681",
					"--dataplane-token-file=/config/farcast\(n)-ingress-token",
					"--log-level=debug",
				]
				volumes: [
					"config:/config",
				]
				depends_on: "kuma-cp\(n)": condition: "service_started"
			}

			"kuma-app\(n)-pause": image: "gcr.io/google_containers/pause-amd64:3.2"

			"kuma-app\(n)": {
				image:        "nginx"
				network_mode: "service:kuma-app\(n)-pause"
				volumes: [
					"config:/config",
				]
			}

			"kuma-app\(n)-dp": {
				image:        "letfn/kuma"
				network_mode: "service:kuma-app\(n)-pause"
				entrypoint: [
					"kuma-dp",
					"run",
					"--name=app",
					"--cp-address=http://kuma-cp\(n):5681",
					"--dataplane-token-file=/config/farcast\(n)-app-token",
					"--log-level=debug",
				]
				volumes: [
					"config:/config",
				]
				depends_on: "kuma-cp\(n)": condition: "service_started"
			}
		}
	}

	{
		for n in zerotiers {
			"\(n)": #zerotier & {
				volumes: [
					"\(n):/var/lib/zerotier-one",
					"config:/service.d",
				]
			}
		}
	}

}

volumes: {
	config: {}
	{
		for n in zerotiers {
			"\(n)": {}
		}
	}
}
