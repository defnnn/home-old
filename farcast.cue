zone: {
	type: "Zone"
}

ingress: {
	type: "Dataplane"
	mesh: "default"
	networking: {
		ingress: {}
		inbound: [
			{
				port: 10001
				tags: {
					"kuma.io/service": "ingress"
				}
			},
		]
	}
}

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

mesh: {
	type: "Mesh"
	name: "default"
	mtls: {
		enabledBackend: "ca-1"
		backends: [
			{
				name: "ca-1"
				type: "builtin"
			},
		]
	}
}

traffic_permission: {
	type: "TrafficPermission"
	name: "allow-all-traffic"
	mesh: "default"
	sources: [
		{
			match: {
				"kuma.io/service": '*'
			}
		},
	]
	destinations: [
		{
			match: {
				"kuma.io/service": '*'
			}
		},
	]
}

zone: name: zone_this
zone: ingress: address: "\(ip_zerotier):10001"

ingress: networking: address: ip_zerotier
ingress: name: "kuma-ingress"

app: networking: address: ip_container
app: name: "app"
