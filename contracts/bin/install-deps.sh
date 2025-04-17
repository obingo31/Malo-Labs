#!/usr/bin/env bash

# Exit on error
set -e

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -a | tr '[:upper:]' '[:lower:]')

# URLs for geth tools
LINUX_AMD64="https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-1.14.6-aadddf3a.tar.gz"
LINUX_ARM64="https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-arm64-1.14.5-0dd173a7.tar.gz"

echo "Installing dependencies for OS: $OS, Architecture: $ARCH"

# Linux installation
if [[ "$OS" == "linux" ]]; then
    echo "Installing Linux dependencies..."
    sudo apt-get update
    sudo apt-get install -y make curl git software-properties-common jq

    # Install geth based on architecture
    if [[ $ARCH == *"x86_64"* ]]; then
        curl -L $LINUX_AMD64 | sudo tar -xz -C /usr/local/bin --strip-components=1
    elif [[ $ARCH == *"aarch64"* ]]; then
        curl -L $LINUX_ARM64 | sudo tar -xz -C /usr/local/bin --strip-components=1
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

# MacOS installation
elif [[ "$OS" == "darwin" ]]; then
    echo "Installing MacOS dependencies..."
    brew tap ethereum/ethereum
    brew install libusb ethereum@1.14.5
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Install Foundry
echo "Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
${HOME}/.foundry/bin/foundryup

# Make foundry available system-wide
echo "Making Foundry available system-wide..."
sudo cp -R ${HOME}/.foundry/bin/* /usr/local/bin/

# Install project dependencies
echo "Installing project dependencies..."
forge install

echo "Installation complete!"