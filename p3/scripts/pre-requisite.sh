#!/usr/bin/env bash
set -e

# Set noninteractive frontend for apt-get
export DEBIAN_FRONTEND=noninteractive

# Detect distribution (Debian or Ubuntu) and codename
distro=$(lsb_release -is)
codename=$(lsb_release -cs)
if [ "$distro" = "Ubuntu" ]; then
    DOCKER_REPO="https://download.docker.com/linux/ubuntu"
else
    DOCKER_REPO="https://download.docker.com/linux/debian"
fi

echo "Detected distribution: $distro ($codename)"
echo "Using Docker repository: $DOCKER_REPO"

# Update and upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Create the vagrant user if it doesn't exist (optional)
if ! id -u vagrant >/dev/null 2>&1; then
    echo "Creating vagrant user..."
    sudo adduser --quiet --disabled-password --gecos "" vagrant
    # Optionally add passwordless sudo for vagrant (if not already set)
    echo "vagrant ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/vagrant
fi

# Ensure vagrant has a home directory and proper permissions
sudo mkdir -p /home/vagrant/.ssh
sudo chown vagrant:vagrant /home/vagrant/.ssh
sudo chmod 700 /home/vagrant/.ssh

# (Optional) Place a public key for SSH access if needed
# sudo curl -fsSL "https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub" -o /home/vagrant/.ssh/authorized_keys
# sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
# sudo chmod 600 /home/vagrant/.ssh/authorized_keys

# Install Git
echo "Installing Git..."
sudo apt-get install -y git

# Install dependencies for Docker
echo "Installing dependencies for Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release make

# Add Docker's official GPG key
echo "Adding Docker's official GPG key..."
curl -fsSL "$DOCKER_REPO/gpg" | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the Docker stable repository
echo "Setting up the Docker stable repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $DOCKER_REPO $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker service
echo "Enabling and starting Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Add both the current user and the vagrant user to the docker group
echo "Adding users to the docker group..."
sudo usermod -aG docker "$USER"
sudo usermod -aG docker vagrant

# Install Zsh
echo "Installing Zsh..."
sudo apt-get install -y zsh

# Install Oh My Zsh non-interactively for the current user
echo "Installing Oh My Zsh for current user..."
sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# Install Oh My Zsh non-interactively for the vagrant user
echo "Installing Oh My Zsh for vagrant user..."
sudo -u vagrant sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'

# Update vagrant user's .zshrc to set the theme to dpoggi
VAGRANT_ZSHRC="/home/vagrant/.zshrc"
echo "Setting Oh My Zsh theme to dpoggi in $VAGRANT_ZSHRC..."
sudo sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="dpoggi"/g' "$VAGRANT_ZSHRC"
sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="dpoggi"/g' "$HOME/.zshrc"

# Ensure Zsh is the default shell for both the current user and vagrant
echo "Setting Zsh as default shell for $USER and vagrant..."
sudo chsh -s "$(which zsh)" "$USER"
sudo chsh -s "$(which zsh)" vagrant

# Install lazydocker
echo "Installing lazydocker..."
LAZYDOCKER_VERSION=$(curl --silent "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" \
    | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION#v}_Linux_x86_64.tar.gz"
tar xzf lazydocker.tar.gz lazydocker
sudo mv lazydocker /usr/local/bin/
rm lazydocker.tar.gz

# Create alias 'lzd' for lazydocker in both .zshrc files
echo "Creating alias 'lzd' -> 'lazydocker'..."
echo "alias lzd='lazydocker'" | sudo tee -a "$VAGRANT_ZSHRC"
echo "alias lzd='lazydocker'" >> "$HOME/.zshrc"

# Attempt to source the current user's .zshrc if we're already in a zsh session
if [ -n "$ZSH_VERSION" ]; then
    echo "Sourcing your .zshrc to load the new configuration..."
    source "$HOME/.zshrc"
else
    echo "Current shell is not zsh; please run 'exec zsh' to use your new configuration."
fi

echo "Setup complete. A reboot is recommended for all changes to take effect."
# Optionally reboot the machine:
# sudo reboot
