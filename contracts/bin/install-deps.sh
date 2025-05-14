#!/usr/bin/env bash

# Exit on error
set -e

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')

# URLs for geth tools
LINUX_AMD64="https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-1.14.6-aadddf3a.tar.gz"
LINUX_ARM64="https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-arm64-1.14.5-0dd173a7.tar.gz"

echo "Installing dependencies for OS: $OS, Architecture: $ARCH"

# Linux installation
if [[ "$OS" == "linux" ]]; then
    echo "Installing Linux dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        make \
        curl \
        git \
        software-properties-common \
        jq \
        build-essential \
        libssl-dev \
        pkg-config \
        clang \
        cmake \
        librocksdb-dev

    # Install geth based on architecture
    if [[ "$ARCH" == "x86_64" ]]; then
        curl -L $LINUX_AMD64 | sudo tar -xz -C /usr/local/bin --strip-components=1
    elif [[ "$ARCH" == "aarch64" ]]; then
        curl -L $LINUX_ARM64 | sudo tar -xz -C /usr/local/bin --strip-components=1
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    # Install Rust
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup default stable
    rustup update

    # Install Foundry from source
    echo "Installing Foundry from source..."
    cargo install --git https://github.com/foundry-rs/foundry \
        --profile local \
        --bins \
        --locked \
        --force \
        foundry-cli anvil chisel

    # Add to PATH
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

# MacOS installation
elif [[ "$OS" == "darwin" ]]; then
    echo "Installing MacOS dependencies..."
    brew tap ethereum/ethereum
    brew install libusb ethereum@1.14.5
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# Verify installation
echo "Verifying Foundry installation..."
forge --version || (echo "Forge installation failed"; exit 1)
cast --version || (echo "Cast installation failed"; exit 1)

# Install project dependencies
echo "Installing project dependencies..."
forge install

echo "Installation complete!"