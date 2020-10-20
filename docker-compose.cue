version: "3.7"

networks: default: external: name: "kitt_default"

for k, v in _users {
  services: "\(k)": {
    labels: dns: v.dns
    environment: GITHUB_USER: v.github
    networks: default: ipv4_address: v.ip
    labels: id: v.id
    image: "defn/home:\(v.username)"
  }
}
