version: "3.7"

volumes: {
	"docker-certs": {}
	"jenkins": {}
}

services: pause: ports: [
	"127.0.0.1:2222:2222",
	"127.0.0.1:8080:8080",
]

services: pause: {
	image: "gcr.io/google_containers/pause-amd64:3.2"
}

services: jenkins: {
	image:        "defn/jenkins"
	env_file:     ".env.dind"
	network_mode: "service:pause"
	pid:          "service:pause"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
		"./etc/jenkins:/jenkins",
		"./etc/vault:/vault",
	]
	depends_on: [
		"docker",
		"vault",
	]
}

services: docker: {
	image:        "docker:dind"
	privileged:   true
	env_file:     ".env.dind"
	network_mode: "service:pause"
	pid:          "service:pause"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
	]
}

services: cloudflared: {
	image:        "defn/cloudflared"
	env_file:     ".env.dind"
	network_mode: "service:pause"
	volumes: [
		"./etc/cloudflared:/certs/cloudflared",
	]
}

services: vault: {
	image:        "defn/vault"
	env_file:     ".env.dind"
	network_mode: "service:pause"
	entrypoint: [
		"vault", "agent",
		"-config", "/vault/vault-agent.hcl",
		"-log-level", "debug",
	]
	volumes: [
		"./etc/vault:/vault",
	]
}

for k, v in _users {
	services: "\(k)": {
		image:        "defn/home:home"
		network_mode: "service:pause"
		pid:          "service:pause"
		env_file:     ".env.dind"
		volumes: [
			"./b/service:/service",
			"$HOME/.password-store:/home/app/.password-store",
			"$HOME/work:/home/app/work",
			"docker-certs:/certs/client",
			"jenkins:/var/jenkins_home",
			"./etc/vault:/vault",
		]
	}
}
