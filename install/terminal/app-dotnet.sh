#!/bin/bash

# Install .NET SDK (latest LTS) from Microsoft repositories
# Repo already configured by app-microsoft-repos.sh
# Reference: https://learn.microsoft.com/dotnet/core/install/linux-ubuntu

echo "Installing .NET SDK..."

# Install the latest LTS .NET SDK
sudo apt install -y dotnet-sdk-9.0

# Install ASP.NET Core runtime as well
sudo apt install -y aspnetcore-runtime-9.0

# Verify installation
echo ""
echo "Installed .NET version:"
dotnet --version
echo ""
dotnet --list-sdks
