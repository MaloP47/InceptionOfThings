wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y wget gnupg build-essential dkms linux-headers-$(uname -r)

# Add Oracle public keys for VirtualBox
echo "Adding Oracle public keys..."
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# Add the VirtualBox repository for Debian Bookworm
echo "Adding VirtualBox repository..."
echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian bookworm contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

# Update package lists again to include the new repository
echo "Updating package lists after adding VirtualBox repository..."
sudo apt-get update

# Install VirtualBox 7.0
echo "Installing VirtualBox 7.0..."
sudo apt-get install -y virtualbox-7.0

echo "VirtualBox 7.0 installation complete."
