version: "3.7"

for k, v in _users {
  services: "\(k)": {
    image: "defn/home:home"
    network_mode: "bridge"
    ports: [ "127.0.0.1:2222:2222" ]
    env_file: ".env"
    environment: {
      "DOCKER_TLS_VERIFY": "1"
      "DOCKER_CERT_PATH": "/certs/client"
      "DOCKER_HOST": "tcp://172.31.0.2:2376"
    }
    volumes: [
      "./b/service:/service",
      "$HOME/.password-store:/home/app/.password-store",
      "$HOME/work:/home/app/work",
      "/var/run/docker.sock:/var/run/docker.sock",
      "jenkins-docker-certs:/certs/client"
    ]
  }
}

volumes: "jenkins-docker-certs": external: true
