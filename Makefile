cluster-re-create:
	k3d cluster delete k3s-default
	k3d cluster create k3s-default \
    		--api-port 6550 -p "80:80@loadbalancer" -p "443:443@loadbalancer" \
    		--servers 1 --k3s-arg "--no-deploy=traefik@server:*"

helm-install:
	helm install istio-base istio/base -n istio-system --wait --create-namespace
	helm install istiod istio/istiod -n istio-system --wait
	helm install istio-ingressgateway istio/gateway -n istio-ingress --wait --create-namespace

set-up-ingressgateway:
	kubectl apply -f istio-ingress -n istio-ingress

install-my-app-com:
	kubectl apply --kustomize new-my-app-com
	kubectl apply --kustomize old-my-app-com


add-etc-hosts:
	@sudo grep -q "127.0.0.1 new.my-app.com" /etc/hosts || echo "127.0.0.1 new.my-app.com" | sudo tee -a /etc/hosts > /dev/null
	@sudo grep -q "127.0.0.1 old.my-app.com" /etc/hosts || echo "127.0.0.1 old.my-app.com" | sudo tee -a /etc/hosts > /dev/null
	@sudo grep -q "127.0.0.1 my-app.com" /etc/hosts || echo "127.0.0.1 my-app.com" | sudo tee -a /etc/hosts > /dev/null

delete-etc-hosts:
	@sudo grep -v "127.0.0.1 new.my-app.com" /etc/hosts > /tmp/hosts.tmp && sudo mv /tmp/hosts.tmp /etc/hosts
	@sudo grep -v "127.0.0.1 old.my-app.com" /etc/hosts > /tmp/hosts.tmp && sudo mv /tmp/hosts.tmp /etc/hosts
	@sudo grep -v "127.0.0.1 my-app.com" /etc/hosts > /tmp/hosts.tmp && sudo mv /tmp/hosts.tmp /etc/hosts

all: cluster-re-create helm-install set-up-ingressgateway install-my-app-com add-etc-hosts
clean:
	k3d cluster delete k3s-default
	make delete-etc-hosts


to-do:
	yq eval -i '.images[0].newTag = "1.23.0"' old-my-app-com/kustomization.yaml
	kubectl apply --kustomize old-my-app-com