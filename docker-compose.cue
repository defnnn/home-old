version: "3.7"

volumes: {
	"docker-certs": {}
	"jenkins": {}
	"secrets-jenkins": {}
	"secrets-atlantis": {}
	"secrets-cloudflared": {}
	"secrets-home": {}
}

services: pause: ports: [
	"127.0.0.1:2222:2222",
	"127.0.0.1:8080:8080",
	"127.0.0.1:18250:18250",
	"127.0.0.1:8099:8099",
	"127.0.0.1:4141:4141",
]

services: pause: {
	image: "gcr.io/google_containers/pause-amd64:3.2"
}

services: "vault-agent": {
	image:    "defn/vault-agent"
	env_file: ".env.vault-agent"
	volumes: [
		"secrets-jenkins:/secrets-jenkins",
		"secrets-atlantis:/secrets-atlantis",
		"secrets-cloudflared:/secrets-cloudflared",
		"secrets-home:/secrets-home",
		"./etc/vault-agent:/vault",
	]
}

services: docker: {
	image:        "docker:dind"
	privileged:   true
	env_file:     ".env.home"
	network_mode: "service:pause"
	pid:          "service:pause"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
	]
}

services: "jenkins-vault-agent": {
	image:        "defn/vault-agent"
	env_file:     ".env.jenkins-vault-agent"
	network_mode: "service:pause"
	volumes: [
		"secrets-jenkins:/secrets-jenkins",
		"secrets-atlantis:/secrets-atlantis",
		"secrets-cloudflared:/secrets-cloudflared",
		"secrets-home:/secrets-home",
		"./etc/jenkins-vault-agent:/vault",
	]
}

services: jenkins: {
	image:        "defn/jenkins"
	env_file:     ".env.home"
	network_mode: "service:pause"
	pid:          "service:pause"
	volumes: [
		"secrets-jenkins:/secrets",
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
		"./etc/jenkins:/jenkins",
		"./etc/jenkins-vault-agent:/vault",
	]
	depends_on: [
		"docker",
		"jenkins-vault-agent",
		"vault-agent",
	]
}

services: atlantis: {
	image:        "defn/atlantis"
	env_file:     ".env.home"
	network_mode: "service:pause"
	pid:          "service:pause"
	command: [
		"atlantis",
		"server",
		"--gh-user=${ATLANTIS_GH_USER}",
		"--repo-allowlist=${ATLANTIS_GH_REPO_ALLOWLIST}",
		"--repo-config=/atlantis/repos.yaml",
	]
	volumes: [
		"secrets-atlantis:/secrets",
		"./etc/atlantis:/atlantis",
		"./data/atlantis:/home/atlantis/.atlantis",
	]
	depends_on: [
		"vault-agent",
	]
}

services: cloudflared: {
	image:        "defn/cloudflared"
	env_file:     ".env.home"
	network_mode: "service:pause"
	command: [ "tunnel", "run"]
	volumes: [
		"secrets-cloudflared:/secrets",
		"./etc/cloudflared:/etc/cloudflared",
	]
	depends_on: [
		"vault-agent",
	]
}

for k, v in _users {
	services: "\(k)": {
		image:        "defn/home:home"
		network_mode: "service:pause"
		pid:          "service:pause"
		env_file:     ".env.home"
		volumes: [
			"secrets-home:/secrets",
			"./b/service:/service",
			"$HOME/.password-store:/home/app/.password-store",
			"$HOME/work:/home/app/work",
			"docker-certs:/certs/client",
			"jenkins:/var/jenkins_home",
			"./data/atlantis:/home/atlantis/.atlantis",
			"secrets-jenkins:/secrets-jenkins",
			"secrets-atlantis:/secrets-atlantis",
			"secrets-cloudflared:/secrets-cloudflared",
			"secrets-home:/secrets-home",
		]
	}
}
