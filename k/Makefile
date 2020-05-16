cilium:
	helm repo add cilium https://helm.cilium.io/
	helm template cilium/cilium --version 1.7.4 \
		--namespace=kube-system \
		--set global.cni.chainingMode=portmap \
		> cilium.yaml
