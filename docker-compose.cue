version: "3.7"

for k, v in _users {
  services: "\(k)": {
    image: "defn/home:home"
    network_mode: "bridge"
    ports: [ "127.0.0.1:2222:2222" ]
    env_file: ".env"
    environment: {
      "HOME": "$HOME"
    }
    volumes: [
      "./b/service:/service",
      "$HOME/.password-store:/home/app/.password-store",
      "$HOME/work:/home/app/work",
      "/var/run/docker.sock:/var/run/docker.sock",
      "jenkins-docker-certs:/certs/clients"
    ]
  }
}

volumes: "jenkins-docker-certs": external: true
