#!/bin/bash
# Installation du noeud worker K3s en joignant le master avec l'IP de l'interface eth1

# Récupérer l'IP du master passé en argument
MASTER_IP=$1

# Lire le token depuis le dossier partagé
TOKEN=$(cat /vagrant/token)

# Récupérer l'adresse IP de l'interface eth1
NODE_IP=$(ifconfig eth1 | grep 'inet ' | awk '{print $2}')
echo "Worker utilise l'IP : ${NODE_IP}"

# Installer l'agent K3s en spécifiant l'IP du nœud et en joignant le master
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="--node-ip=${NODE_IP}" sh -
