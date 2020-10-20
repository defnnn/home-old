version: "3.7"

networks: default: external: name: "kitt_default"

services: [Name=string]: {
	image: "defn/home:home"
	volumes:
	[
		"/var/run/docker.sock:/var/run/docker.sock",
	]
}

for k, v in _users {
  services: "\(k)": labels: dns: v.dns
  services: "\(k)": environment: GITHUB_USER: v.github
  services: "\(k)": networks: default: ipv4_address: v.ip
  services: "\(k)": labels: id: v.id
}
