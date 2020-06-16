cilium:
	helm repo add cilium https://helm.cilium.io/
	helm template cilium/cilium --version 1.8.0-rc3 \
		--namespace=kube-system \
		--set global.cni.chainingMode=portmap \
		--set global.hubble.enabled=true \
		--set global.hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,http}" \
		> cilium.yaml

connectivity-check:
	kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.8.0-rc3/examples/kubernetes/connectivity-check/connectivity-check.yaml
