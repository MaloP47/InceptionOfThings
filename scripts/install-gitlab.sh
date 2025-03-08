#!/usr/bin/env bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y curl openssh-server ca-certificates tzdata perl

curl -fsSL https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# Définition du port GitLab (modifiable)
GITLAB_PORT=8929

# Récupérer l'adresse IP de la machine (excluant 127.0.0.1)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Vérifier si l'IP a bien été récupérée
if [ -z "$IP_ADDRESS" ]; then
    echo "❌ Impossible de récupérer l'adresse IP. Vérifiez votre connexion réseau."
    exit 1
fi

# Affichage de l'adresse IP détectée
echo "✅ Adresse IP détectée : $IP_ADDRESS"
echo "📌 Installation de GitLab avec EXTERNAL_URL=http://$IP_ADDRESS:$GITLAB_PORT"

# Installation de GitLab avec EXTERNAL_URL configuré
sudo GITLAB_ROOT_EMAIL="<admin@mail.adress.com>" \
GITLAB_ROOT_PASSWORD="<A random password>" \
EXTERNAL_URL="http://$IP_ADDRESS:$GITLAB_PORT" \
apt install -y gitlab-ce

# Modifier le fichier de configuration GitLab
sudo sed -i "s|^external_url .*|external_url \"http://$IP_ADDRESS:$GITLAB_PORT\"|" /etc/gitlab/gitlab.rb

# Vérifier si les paramètres Nginx existent et les modifier ou ajouter
sudo sed -i "/nginx\['enable'\]/d" /etc/gitlab/gitlab.rb
sudo sed -i "/nginx\['listen_port'\]/d" /etc/gitlab/gitlab.rb
sudo sed -i "/nginx\['listen_https'\]/d" /etc/gitlab/gitlab.rb

echo "
nginx['enable'] = true
nginx['listen_port'] = $GITLAB_PORT
nginx['listen_https'] = false
" | sudo tee -a /etc/gitlab/gitlab.rb > /dev/null

# Appliquer la configuration et redémarrer GitLab
echo "🔄 Reconfiguration de GitLab..."
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart

# Ouvrir le port dans le pare-feu (UFW ou iptables)
if command -v ufw &>/dev/null; then
    echo "🛠 Ouverture du port $GITLAB_PORT sur UFW..."
    sudo ufw allow $GITLAB_PORT/tcp
elif command -v iptables &>/dev/null; then
    echo "🛠 Ajout de la règle iptables pour le port $GITLAB_PORT..."
    sudo iptables -A INPUT -p tcp --dport $GITLAB_PORT -j ACCEPT
    sudo iptables-save | sudo tee /etc/iptables/rules.v4
fi

# Vérification du port utilisé par Nginx
echo "🔍 Vérification du service GitLab sur le port $GITLAB_PORT..."
sudo ss -tlnp | grep $GITLAB_PORT

# Affichage du statut de GitLab
echo "📌 Statut de GitLab :"
sudo gitlab-ctl status

# Message de fin
echo "🚀 GitLab est configuré et accessible à : http://$IP_ADDRESS:$GITLAB_PORT"
