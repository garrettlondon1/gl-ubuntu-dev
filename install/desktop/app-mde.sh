#!/bin/bash

# Install Microsoft Defender for Endpoint (MDE) on Ubuntu
# Repo already configured by app-microsoft-repos.sh
# Official: https://learn.microsoft.com/en-us/defender-endpoint/linux-install-manually

echo "Installing Microsoft Defender for Endpoint..."

sudo apt install -y curl libplist-utils

# Install mdatp from the prod repo
sudo apt install -y mdatp

echo ""
echo "============================================"
echo "  MDE installed."
echo ""
echo "  ── Onboarding (manual) ──"
echo "  1. Download onboarding package from Defender portal:"
echo "     Settings > Endpoints > Onboarding"
echo "     OS: Linux Server | Method: Local Script"
echo "  2. unzip WindowsDefenderATPOnboardingPackage.zip"
echo "  3. sudo python3 MicrosoftDefenderATPOnboardingLinuxServer.py"
echo ""
echo "  ── Verify ──"
echo "  mdatp health"
echo "    healthy=true, licensed=true, releaseRing=Production"
echo "    app_version >= 101.98.89 or >= 101.23052.0009"
echo ""
echo "  ── Connectivity test ──"
echo "  mdatp connectivity test"
echo ""
echo "  ── Update ──"
echo "  sudo apt-get install --only-upgrade mdatp"
echo ""
echo "  ── Diagnostics (if issues) ──"
echo "  sudo mdatp diagnostic create"
echo "============================================"
echo ""
