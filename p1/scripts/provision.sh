#!/bin/sh
#------------------------------------------------------------
# alpine_provision.sh
#
# This script is intended for use on an Alpine Linux base box.
# It performs the following tasks:
#   1. Updates the apk package repository index.
#   2. Upgrades all installed packages.
#   3. Installs curl.
#
# This can be used as a provisioning step in your Vagrantfile.
#------------------------------------------------------------

set -e  # Exit immediately if a command fails

echo "Updating apk repositories..."
apk update

echo "Upgrading installed packages..."
apk upgrade

echo "Installing curl..."
apk add curl

echo "Provisioning complete."
