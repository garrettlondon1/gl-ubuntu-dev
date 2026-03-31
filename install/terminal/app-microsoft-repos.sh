#!/bin/bash

# Microsoft package signing keys and apt repositories
# This must run before Edge, Intune, .NET, and MDE installers
# Official: https://learn.microsoft.com/en-us/defender-endpoint/linux-install-manually

echo "Setting up Microsoft package repositories..."

sudo apt install -y curl gpg apt-transport-https

# Microsoft GPG key for Ubuntu 24.04+ (official: microsoft-prod.gpg)
if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
  curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft-prod.gpg > /dev/null
  sudo chmod o+r /usr/share/keyrings/microsoft-prod.gpg
fi

# Edge-specific key
if [ ! -f /usr/share/keyrings/microsoft-edge.gpg ]; then
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-edge.gpg
fi

# Edge repository (with signed-by)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-edge.gpg] https://packages.microsoft.com/repos/edge stable main" \
  | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null

# Microsoft prod repository — official method: download from Microsoft's config endpoint
# (covers Intune, Identity Broker, .NET SDK, MDE/mdatp)
curl -sSL "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list" \
  | sudo tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null

# Microsoft insiders-fast repository (optional — for early MDE/Intune updates)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/$(lsb_release -rs)/prod insiders-fast main" \
  | sudo tee /etc/apt/sources.list.d/microsoft-ubuntu-$(lsb_release -cs)-insiders-fast.list > /dev/null

sudo apt update
