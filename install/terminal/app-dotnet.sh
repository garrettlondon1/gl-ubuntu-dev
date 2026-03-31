#!/bin/bash

# Install .NET SDK (latest LTS) from built-in Ubuntu feed
# Ubuntu 24.04 ships .NET 10.0 and 8.0 in its default feed
# Reference: https://learn.microsoft.com/dotnet/core/install/linux-ubuntu

echo "Installing .NET SDK..."

# Install the latest LTS .NET SDK
sudo apt-get update
sudo apt-get install -y dotnet-sdk-10.0

# Install ASP.NET Core runtime as well
sudo apt-get install -y aspnetcore-runtime-10.0

# Verify installation
echo ""
echo "Installed .NET version:"
dotnet --version
echo ""
dotnet --list-sdks
