cilium:
	helm repo add cilium https://helm.cilium.io/
	helm template cilium/cilium --version 1.8.0-rc4 \
		--namespace kube-system \
		--set global.nodeinit.enabled=true \
		--set global.kubeProxyReplacement=partial \
		--set global.hostServices.enabled=false \
		--set global.externalIPs.enabled=true \
		--set global.nodePort.enabled=true \
		--set global.hostPort.enabled=true \
		--set global.pullPolicy=IfNotPresent \
		--set config.ipam=kubernetes \
		--set global.hubble.enabled=true \
		--set global.hubble.listenAddress=":4244" \
		--set global.hubble.relay.enabled=true \
		--set global.hubble.ui.enabled=true \
		--set global.hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}" \
		--set global.cni.chainingMode=portmap \
		> cilium.yaml

connectivity-check:
	kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.8.0-rc4/examples/kubernetes/connectivity-check/connectivity-check.yaml
