#!/bin/bash

# YubiKey Smart Card setup for certificate-based auth
# Installs pcscd, yubikey-manager, opensc, and configures NSS database

echo "Setting up YubiKey Smart Card components..."

sudo apt install -y pcscd yubikey-manager
sudo apt install -y opensc libnss3-tools openssl

# Create NSS database for certificate/smart card storage
mkdir -p "$HOME/.pki/nssdb"
chmod 700 "$HOME/.pki"
chmod 700 "$HOME/.pki/nssdb"

# Initialize NSS database
modutil -force -create -dbdir "sql:$HOME/.pki/nssdb"

# Register OpenSC PKCS#11 module for smart card access
modutil -force -dbdir "sql:$HOME/.pki/nssdb" -add 'SC Module' -libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so

echo ""
echo "============================================"
echo "  YubiKey Smart Card setup complete."
echo "  Insert your YubiKey and test with:"
echo "    ykman info"
echo "    pkcs11-tool --module /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so -L"
echo "============================================"
echo ""
