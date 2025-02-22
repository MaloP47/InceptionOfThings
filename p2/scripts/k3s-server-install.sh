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
  echo "alias kg='kubectl get pods'" | sudo tee -a /home/vagrant/.profile
  echo "alias kgw='kubectl get pods -o wide'" | sudo tee -a /home/vagrant/.profile
fi
