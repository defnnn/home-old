version: "3.7"

for k, v in _users {
  services: "\(k)": {
    image: "defn/home:\(v.username)"
    ports: [ "127.0.0.1:2222:2222" ]
    env_file: ".env"
    volumes: [ 
      "$HOME/.password-store:/home/app/.password-store",
      "$HOME/work:/home/app/work",
      "$HOME:$HOME",
      "/var/run/docker.sock:/var/run/docker.sock"
    ]
  }
}

networks: default: external: name: "cloudbuild"
