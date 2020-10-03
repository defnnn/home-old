version: "3.7"

_ip_global: "192.168.195.156"

_network_16: "172.29"

_zones: [ "1", "2"]

services: init: {
	image: "letfn/init"
	command: [
		"bash",
		"-c",
		"""
		set -x
		chown 1001:1001 /var/run/docker.sock
		touch /tmp/done.txt
		exec sleep 86400000

		""",
	]

	volumes:
		[
			"config:/config",
			"/var/run/docker.sock:/var/run/docker.sock",
		] +
		[ for n in _zerotier_svcs {"\(n):/\(n)"}] +
		[ for n in _zones {"nginx\(n):/nginx\(n)"}]

	healthcheck: {
		test: ["CMD", "test", "-f", "/tmp/done.txt"]
		interval: "10s"
		timeout:  "15s"
		retries:  100
	}
}

services: sshd: {
	image: "defn/home:jojomomojo"
	entrypoint: ["/service", "sshd"]
	volumes:
		[
			"/var/run/docker.sock:/var/run/docker.sock",
			"config:/data/home-secret",
			"config:/config",
		] +
		[ for n in _zerotier_svcs {"\(n):/\(n)"}]
}

services: cloudflared: {
	image: "letfn/cloudflared"
	volumes: [
		"config:/app/src/.cloudflared",
	]
}

_kuma_global: {
	image: "letfn/kuma"
	entrypoint: [
		"kuma-cp",
		"run",
	]
	environment: [
		"KUMA_MODE=global",
		"KUMA_STORE_TYPE=postgres",
		"KUMA_STORE_POSTGRES_HOST=postgres0",
		"KUMA_STORE_POSTGRES_PORT=5432",
		"KUMA_STORE_POSTGRES_USER=kuma-user",
		"KUMA_STORE_POSTGRES_PASSWORD=kuma-password",
		"KUMA_STORE_POSTGRES_DB_NAME=kuma-global",
	]
	volumes: [
		"config:/config",
	]
}

_kuma_cp: [N=_]: {
	image: "letfn/kuma"
	entrypoint: [
		"kuma-cp",
		"run",
	]
	environment: [
		"KUMA_MODE=remote",
		"KUMA_MULTICLUSTER_REMOTE_ZONE=farcast\(N)",
		"KUMA_MULTICLUSTER_REMOTE_GLOBAL_ADDRESS=grpcs://\(_ip_global):5685",
		"KUMA_GENERAL_ADVERTISED_HOSTNAME=kuma-cp-\(N)",
		"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_ENABLED=true",
		"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_INTERFACE=0.0.0.0",
		"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_PORT=5684",
		"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_TLS_CERT_FILE=/certs/server/cert.pem",
		"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_TLS_KEY_FILE=/certs/server/key.pem",
		"KUMA_DATAPLANE_TOKEN_SERVER_PUBLIC_CLIENT_CERTS_DIR=/certs/client",
		"KUMA_STORE_TYPE=postgres",
		"KUMA_STORE_POSTGRES_HOST=postgres\(N)",
		"KUMA_STORE_POSTGRES_PORT=5432",
		"KUMA_STORE_POSTGRES_USER=kuma-user",
		"KUMA_STORE_POSTGRES_PASSWORD=kuma-password",
		"KUMA_STORE_POSTGRES_DB_NAME=kuma-cp-\(N)",
	]
	volumes: [
		"config:/config",
	]
}

_kuma_ingress: [N=_]: {
	image: "letfn/kuma"
	command: [
		"kuma-dp",
		"run",
		"--name=kuma-ingress",
		"--cp-address=http://kuma-cp-\(N):5681",
		"--dataplane-token-file=/config/farcast\(N)-ingress-token",
		"--log-level=debug",
	]
	volumes: [
		"config:/config",
	]
}

_kuma_app_pause: {
	image: "gcr.io/google_containers/pause-amd64:3.2"
}

_kuma_app: [N=_]: {
	image: "nginx"
	volumes: [
		"config:/config",
		"nginx\(N):/usr/share/nginx/html",
	]
}

_kuma_app_dp: [N=_]: {
	image: "letfn/kuma"
	command: [
		"kuma-dp",
		"run",
		"--name=app",
		"--cp-address=http://kuma-cp-\(N):5681",
		"--dataplane-token-file=/config/farcast\(N)-app-token",
		"--log-level=debug",
	]
	volumes: [
		"config:/config",
	]
}

services: "kuma-global": {
	_kuma_global
	network_mode: "service:\(_zerotier_global)"
}

services: done: image: "gcr.io/google_containers/pause-amd64:3.2"
services: done: depends_on: [
	for n in _zones {"app-dp-\(n)"},
]

services: {
	for n in _zones {
		"kuma-cp-\(n)": {
			(_kuma_cp & {"\(n)": {}})[n]
			depends_on: "kuma-global": condition: "service_started"
			networks: default: ipv4_address:      "\(_network_16).88.2\(n)"
		}

		"kuma-ingress-\(n)": {
			(_kuma_ingress & {"\(n)": {}})[n]
			network_mode: "service:zerotier\(n)"
			depends_on: "kuma-cp-\(n)": condition: "service_started"
		}

		"app-dp-\(n)": {
			(_kuma_app_dp & {"\(n)": {}})[n]
			network_mode: "service:app-pause-\(n)"
			depends_on: "kuma-ingress-\(n)": condition: "service_started"
		}

		"app-pause-\(n)": {
			_kuma_app_pause
			networks: default: ipv4_address: "\(_network_16).88.3\(n)"
		}

		"app-\(n)": {
			(_kuma_app & {"\(n)": {}})[n]
			network_mode: "service:app-pause-\(n)"
		}

		"postgres\(n)": {
			image: "postgres"
			volumes: [ "postgres\(n):/var/lib/postgresql/data"]
			environment: [
				"POSTGRES_DB=kuma-cp-\(n)",
			]
		}

	}
}

services: postgres0: {
	image: "postgres"
	volumes: [ "postgres0:/var/lib/postgresql/data"]
	environment: [
		"POSTGRES_DB=kuma-global",
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

		depends_on: init: condition: "service_healthy"

		volumes: [
			"\(Zerotier):/var/lib/zerotier-one",
		]
	}
}

services: [Service=string]: {
	if Service =~ "^(kuma-global)$" {
		depends_on: init: condition: "service_healthy"
		for n in _zerotier_svcs {
			depends_on: "\(n)": condition: "service_started"
		}
	}
}

_zerotier_sshd: "zerotier"

_zerotier_global: "zerotier0"

_zerotier_svcs:
	[ _zerotier_sshd] +
	[ _zerotier_global] +
	[ for n in _zones {"zerotier\(n)"}]

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

services: "\(_zerotier_sshd)": {}

services: sshd: depends_on: "\(_zerotier_sshd)": condition: "service_started"
services: sshd: network_mode: "service:\(_zerotier_sshd)"

services: cloudflared: depends_on: "\(_zerotier_sshd)": condition: "service_started"
services: cloudflared: network_mode: "service:\(_zerotier_sshd)"

services: "\(_zerotier_global)": {
	networks: default: ipv4_address: "\(_network_16).88.10"
}
services: {
	for n in _zones {
		"zerotier\(n)": {
			networks: default: ipv4_address: "\(_network_16).88.1\(n)"
		}
	}
}

volumes: {
	for n in _zones {
		"postgres\(n)": {}
	}
}

volumes: config: {}
volumes: postgres0: {}
volumes: {
	for n in _zerotier_svcs {
		"\(n)": {}
	}
}

volumes: {
	for n in _zones {
		"nginx\(n)": {}
	}
}

networks: default: ipam: {
	driver: "default"
	config: [
		{
			subnet: "\(_network_16).0.0/16"
		},
	]
}
