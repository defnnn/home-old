app: {
	type: "Dataplane"
	mesh: "default"
	networking: {
		inbound: [
			{
				port:        1080
				servicePort: 80
				tags: {
					"kuma.io/service": "app_\(zone_this)_svc_80"
				}
			},
		]
		outbound: [
			{
				port: 1000
				tags: {
					"kuma.io/service": "app_\(zone_that)_svc_80"
				}
			},
		]
	}
}

zone: name: zone_this
zone: ingress: address: "\(ip_container):10001"

ingress: networking: address: ip_container
ingress: name: "kuma-ingress"

app: networking: address: ip_container
app: name: "app"
