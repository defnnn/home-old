version: "3.7"

volumes: {
	"docker-certs": {}
	"jenkins": {}
}

services: jenkins: ports: [
	"127.0.0.1:2222:2222",
	"127.0.0.1:8080:8080",
]

services: jenkins: {
	image:    "defn/jenkins"
	env_file: ".env.dind"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
	]
}

services: docker: {
	image:        "docker:dind"
	privileged:   true
	env_file:     ".env.dind"
	network_mode: "service:jenkins"
	pid:          "service:jenkins"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
	]
}

services: cloudflared: {
	image:        "defn/cloudflared"
	env_file:     ".env.dind"
	network_mode: "service:jenkins"
	volumes: [
		"./etc/cloudflared:/certs/cloudflared",
	]
}

services: vault: {
	image:        "defn/vault"
	env_file:     ".env.dind"
	network_mode: "service:jenkins"
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
		network_mode: "service:jenkins"
		pid:          "service:jenkins"
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
