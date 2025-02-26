#!/usr/bin/env bash

# Installer k3d *
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Installer kubectl *
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Créer un cluster
k3d cluster create p3

# Créer dev namespace
kubectl create namespace dev

# Créer argocd namespace
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


# Download argoCD CLI *
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Expose argoCD GUI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Récuperationde mdp. Login: admin
argocd admin initial-password -n argocd

# apply application.yaml
kubectl apply -f application.yaml # In the github IOT-mpeulet repo
