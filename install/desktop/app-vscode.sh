#!/bin/bash

# VS Code repo — use DEB822 .sources format (Ubuntu 24.04+ standard)
# Remove legacy .list if present to avoid Signed-By conflicts
sudo rm -f /etc/apt/sources.list.d/vscode.list
if [ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]; then
  cd /tmp
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  rm -f packages.microsoft.gpg
  cd -
fi
if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
  sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64 arm64 armhf
Signed-By: /etc/apt/keyrings/packages.microsoft.gpg
EOF
fi

sudo apt update
sudo apt install -y code

mkdir -p ~/.config/Code/User
cp ~/.local/share/omakub/configs/vscode.json ~/.config/Code/User/settings.json

# Install default supported themes
code --install-extension enkia.tokyo-night