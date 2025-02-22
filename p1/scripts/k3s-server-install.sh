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

if ! grep -q "export KUBECONFIG=" /home/vagrant/.bashrc; then
  echo "export KUBECONFIG=/home/vagrant/.kube/config" | sudo tee -a /home/vagrant/.bashrc
fi

# Attendre la création du fichier token du noeud
echo "En attente de la création du fichier de token du noeud K3s..."
for i in {1..30}; do
  if [ -f "$TOKEN_FILE" ]; then
    echo "Fichier de token trouvé."
    break
  fi
  echo "En attente... ($i/30)"
  sleep 2
done

# Lire le token
TOKEN=$(sudo cat "$TOKEN_FILE")

# Attendre que le dossier partagé /vagrant soit disponible
echo "En attente du dossier partagé /vagrant..."
for i in {1..30}; do
  if [ -d /vagrant ]; then
    echo "Dossier /vagrant disponible."
    break
  fi
  echo "En attente... ($i/30)"
  sleep 1
done

# Stocker le token pour les noeuds workers
echo "Stockage du token dans /vagrant/token..."
echo "$TOKEN" > /vagrant/token
