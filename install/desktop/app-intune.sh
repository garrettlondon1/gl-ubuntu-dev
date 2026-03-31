#!/bin/bash

# Install Microsoft Intune Portal and Identity Broker for device enrollment
# Repo already configured by app-microsoft-repos.sh
# Reference: https://learn.microsoft.com/intune/intune-service/user-help/microsoft-intune-app-linux

echo "Installing Microsoft Identity Broker and Intune Portal..."

sudo apt install -y microsoft-identity-broker
sudo apt install -y intune-portal

echo ""
echo "============================================"
echo "  Intune installed successfully!"
echo "  After reboot, open the Microsoft Intune app"
echo "  and sign in with your work account to enroll."
echo "============================================"
echo ""
