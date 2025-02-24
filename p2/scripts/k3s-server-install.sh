#!/bin/bash
# Installation de K3s sur le noeud master avec l'IP de l'interface eth1

# Récupérer l'adresse IP de l'interface eth1
NODE_IP=$(ifconfig eth1 | grep 'inet ' | awk '{print $2}')
echo "Utilisation de l'IP du noeud : ${NODE_IP}"

# Installer K3s en spécifiant l'IP du noeud et donner les droits aux autres users
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--node-ip=${NODE_IP}" sh -

CONFIG_FILE="/etc/rancher/k3s/k3s.yaml"
TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"

# Attendre la création du fichier de configuration K3s
echo "En attente de la création du fichier de configuration K3s..."
for i in {1..30}; do
  if [ -f "$CONFIG_FILE" ]; then
    echo "Fichier de configuration trouvé."
    break
  fi
  echo "En attente... ($i/30)"
  sleep 2
done

# Créer le répertoire kube pour l'utilisateur vagrant et copier la configuration
echo "Configuration de kubectl pour l'utilisateur vagrant..."
sudo mkdir -p /home/vagrant/.kube
sudo cp "$CONFIG_FILE" /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

if ! grep -q "export KUBECONFIG=" /home/vagrant/.profile; then
  echo "export KUBECONFIG=/home/vagrant/.kube/config" | sudo tee -a /home/vagrant/.profile
fi

if ! grep -q "alias k=" /home/vagrant/.profile; then
  echo "alias k='kubectl'" | sudo tee -a /home/vagrant/.profile
  echo "alias kgn='kubectl get nodes'" | sudo tee -a /home/vagrant/.profile
  echo "alias kgnw='kubectl get nodes -o wide'" | sudo tee -a /home/vagrant/.profile
  echo "alias kga='kubectl get all'" | sudo tee -a /home/vagrant/.profile
  echo "alias kgia='kubectl get ingress -A'" | sudo tee -a /home/vagrant/.profile
fi

source /home/vagrant/.profile
sleep 2

kubectl apply -f /vagrant/confs/Deployments/app1-Deployment.yaml
sleep 2
kubectl apply -f /vagrant/confs/Services/app1-Service.yaml
sleep 2
kubectl apply -f /vagrant/confs/Ingress/app1-Ingress.yaml
sleep 2

kubectl apply -f /vagrant/confs/Deployments/app2-Deployment.yaml
sleep 2
kubectl apply -f /vagrant/confs/Services/app2-Service.yaml
sleep 2
kubectl apply -f /vagrant/confs/Ingress/app2-Ingress.yaml
sleep 2

kubectl apply -f /vagrant/confs/Deployments/app3-Deployment.yaml
sleep 2
kubectl apply -f /vagrant/confs/Services/app3-Service.yaml
sleep 2
kubectl apply -f /vagrant/confs/Ingress/app3-Ingress.yaml
sleep 2
