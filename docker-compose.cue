version: "3.7"

networks: default: external: name: "kitt_default"

for k, v in _users {
  services: "\(k)": {
    environment: GITHUB_USER: v.github
    networks: default: ipv4_address: v.ip
    image: "defn/home:\(v.username)"
    ports: [ 2222 ]
    labels: id: v.id
    labels: SERVICE_NAME: "\(k)"
    labels: zone: "kitt"
    labels: app: "home"
  }
}
