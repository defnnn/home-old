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
				"kuma.io/service": "*"
			}
		},
	]
	destinations: [
		{
			match: {
				"kuma.io/service": "*"
			}
		},
	]
}
