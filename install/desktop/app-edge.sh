#!/bin/bash

# Install Microsoft Edge Stable browser
# Repo already configured by app-microsoft-repos.sh

echo "Installing Microsoft Edge..."
sudo apt install -y microsoft-edge-stable

# Set Edge as default browser
xdg-settings set default-web-browser microsoft-edge.desktop
