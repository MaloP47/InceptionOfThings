#!/usr/bin/env bash

# Installer k3d *
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Installer kubectl *
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Download argoCD CLI *
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Créer un cluster
k3d cluster create p3 -p "8443:443@loadbalancer" -p "8888:80@loadbalancer"

# Créer les ns & installer argoCD
kubectl create namespace dev
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Patch server argocd 
kubectl -n argocd patch deployment argocd-server --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}]'

# Appliquer les ingress
kubectl apply -f /confs/Ingress/wil-playground-Ingress.yaml
kubectl apply -f /confs/Ingress/argoCD-Ingress.yaml

# Cloner le repo & appliquer le deploiment de l'app
gcl https://github.com/MaloP47/IOT-mpeulet.git
kubectl apply -f application.yaml

# Récupérer le mdp de mdp. Login: admin
https://localhost:8443
argocd admin initial-password -n argocd >> mdp

# Détruire le cluster
k3d cluster delete p3
