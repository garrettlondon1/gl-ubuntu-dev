#!/bin/bash

# Microsoft/.NET focused setup — no language or DB choices needed
echo "This will install a Microsoft enterprise development environment:"
echo "  • Microsoft Edge, VS Code, .NET SDK"
echo "  • Intune enrollment, Microsoft Defender for Endpoint"
echo "  • YubiKey smart card support"
echo "  • Docker, core CLI tools, GNOME desktop tweaks"
echo ""
gum confirm "Continue with installation?" || exit 1
