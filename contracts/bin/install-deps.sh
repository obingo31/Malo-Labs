#!/usr/bin/env bash

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect environment
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Geth download URLs
declare -A GETH_URLS=(
    ["linux-x86_64"]="https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-amd64-1.14.6-aadddf3a.tar.gz"
    ["linux-aarch64"]="https://gethstore.blob.core.windows.net/builds/geth-alltools-linux-arm64-1.14.5-0dd173a7.tar.gz"
    ["darwin-x86_64"]="https://gethstore.blob.core.windows.net/builds/geth-alltools-darwin-amd64-1.14.6-aadddf3a.tar.gz"
    ["darwin-arm64"]="https://gethstore.blob.core.windows.net/builds/geth-alltools-darwin-arm64-1.14.6-aadddf3a.tar.gz"
)

install_linux() {
    echo -e "${YELLOW}Installing Linux dependencies...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        make curl git software-properties-common \
        jq build-essential libssl-dev pkg-config \
        clang cmake librocksdb-dev > /dev/null

    install_geth
}

install_macos() {
    echo -e "${YELLOW}Installing macOS dependencies...${NC}"
    if ! command -v brew >/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    
    brew update
    brew install libusb ethereum
}

install_geth() {
    local key="$OS-$ARCH"
    local url=${GETH_URLS[$key]}
    
    if [ -z "$url" ]; then
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        return 1
    fi

    echo -e "${YELLOW}Installing Geth...${NC}"
    curl -sL "$url" | sudo tar -xz -C /usr/local/bin --strip-components=1
}

install_rust() {
    if ! command -v rustup >/dev/null; then
        echo -e "${YELLOW}Installing Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    rustup default stable
    rustup update
}

install_foundry() {
    echo -e "${YELLOW}Installing Foundry...${NC}"
    cargo install --git https://github.com/foundry-rs/foundry \
        --profile local \
        --bins \
        --locked \
        foundry-cli anvil chisel
}

main() {
    echo -e "${GREEN}Starting installation for $OS-$ARCH...${NC}"
    
    case "$OS" in
        linux*) install_linux ;;
        darwin*) install_macos ;;
        *) echo -e "${RED}Unsupported OS: $OS${NC}"; exit 1 ;;
    esac

    install_rust
    install_foundry
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo "Please restart your shell or run:"
    echo "source ~/.bashrc"
}

main "$@"