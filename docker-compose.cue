version: "3.7"

_ip_global: "192.168.195.156"

_zones: [ "1", "2", "3"]

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
		[ for n in _zerotier_svcs {"\(n):/\(n)"}]

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
	]
	volumes: [
		"config:/config",
	]
}

_kuma_ingress: [N=_]: {
	image: "letfn/kuma"
	entrypoint: [
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
	]
}

_kuma_app_dp: [N=_]: {
	image: "letfn/kuma"
	entrypoint: [
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

services: {
	"kuma-global": _kuma_global
	"kuma-global": network_mode: "service:\(_zerotier_global)"
}

services: "kuma-done": image: "gcr.io/google_containers/pause-amd64:3.2"
services: "kuma-done": depends_on: [
  for n in _zones { "kuma-app-dp-\(n)" }
]

services: {
	for n in _zones {
		"kuma-cp-\(n)": (_kuma_cp & {"\(n)": {}})[n]
		"kuma-cp-\(n)": depends_on: "kuma-global": condition: "service_started"

		"kuma-ingress-\(n)": (_kuma_ingress & {"\(n)": {}})[n]
		"kuma-ingress-\(n)": network_mode: "service:zerotier\(n)"
		"kuma-ingress-\(n)": depends_on: "kuma-cp-\(n)": condition: "service_started"

		"kuma-app-dp-\(n)": (_kuma_app_dp & {"\(n)": {}})[n]
		"kuma-app-dp-\(n)": network_mode: "service:kuma-app-pause-\(n)"
		"kuma-app-dp-\(n)": depends_on: "kuma-ingress-\(n)": condition: "service_started"

		"kuma-app-pause-\(n)": _kuma_app_pause

		"kuma-app-\(n)": (_kuma_app & {"\(n)": {}})[n]
		"kuma-app-\(n)": network_mode: "service:kuma-app-pause-\(n)"
	}
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
	if Service =~ "^(cloudflared|kuma-global)$" {
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
services: sshd: network_mode:        "service:\(_zerotier_sshd)"
services: cloudflared: network_mode: "service:\(_zerotier_sshd)"

services: "\(_zerotier_global)": {}
services: {
	for n in _zones {
		"zerotier\(n)": {}
	}
}

volumes: config: {}
volumes: {
	for n in _zerotier_svcs {
		"\(n)": {}
	}
}
