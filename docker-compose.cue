version: "3.7"

volumes: {
	"docker-certs": {}
	"jenkins": {}
}

services: docker: {
	image:      "docker:dind"
	privileged: true
	env_file:   ".env.dind"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
	]
}

services: jenkins: {
	image:        "defn/jenkins"
	network_mode: "service:docker"
	env_file:     ".env.dind"
	volumes: [
		"docker-certs:/certs/client",
		"jenkins:/var/jenkins_home",
	]
}

services: docker: ports: [
	"127.0.0.1:2222:2222",
	"127.0.0.1:8080:8080",
]

for k, v in _users {
	services: "\(k)": {
		image:        "defn/home:home"
		network_mode: "service:docker"
		pid:          "service:jenkins"
		env_file:     ".env.dind"
		volumes: [
			"./b/service:/service",
			"$HOME/.password-store:/home/app/.password-store",
			"$HOME/work:/home/app/work",
			"/var/run/docker.sock:/var/run/docker.sock",
			"docker-certs:/certs/client",
			"jenkins:/var/jenkins_home",
		]
	}
}
