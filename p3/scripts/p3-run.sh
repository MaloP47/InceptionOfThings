# #!/usr/bin/env bash

k3d cluster create p3 -p "8080:80@loadbalancer" -p "8888:8888@loadbalancer"

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=ready --timeout=600s pod --all -n argocd

git clone https://github.com/MaloP47/IOT-mpeulet.git
sleep 2
kubectl apply -f IOT-mpeulet/application.yaml
sleep 2
kubectl wait --for=condition=ready --timeout=600s pod --all -n dev

kubectl apply -f ./confs/Ingress/argoCD-Ingress.yaml
sleep 2

kubectl patch configmap argocd-cmd-params-cm -n argocd -p '{"data": {"server.insecure": "true", "server.basehref": "/"}}'
sleep 2
kubectl rollout restart deployment argocd-server -n argocd
kubectl wait --for=condition=ready --timeout=600s pod --all -n argocd

argocd admin initial-password -n argocd > mdp

ngrok http --url=fair-flounder-completely.ngrok-free.app 8080 --host-header=localhost > /dev/null &

# killall ngrok
# k3d cluster delete p3
# rm mdp
# rm -rf IOT-mpeulet
