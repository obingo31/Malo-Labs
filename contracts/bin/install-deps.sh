#!/usr/bin/env bash
set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detect environment
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Function: Ensure Homebrew is installed
ensure_brew() {
    if ! command -v brew >/dev/null; then
        echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ "$OS" = "linux" ]; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ "$OS" = "darwin" ]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo -e "${GREEN}Homebrew is installed.${NC}"
    fi
}

install_echidna() {
    echo -e "${YELLOW}Installing Echidna...${NC}"
    
    # Try to use brew if available (or attempt to install it)
    ensure_brew
    if command -v brew >/dev/null; then
        echo -e "${YELLOW}Installing Echidna using Homebrew...${NC}"
        brew update && brew install echidna
    else
        # Fallback: manual installation if brew is still not available.
        local tmp_dir
        tmp_dir=$(mktemp -d)
        cd "$tmp_dir"
        
        echo "Downloading Echidna..."
        curl -L https://github.com/crytic/echidna/releases/download/v2.2.1/echidna-2.2.1-Linux.zip -o echidna.zip
        unzip echidna.zip
        
        # Extract the tarball contained in the ZIP
        tar -xzf echidna.tar.gz
        
        if [ ! -f echidna ]; then
            echo -e "${RED}Error: Echidna binary not found after extracting tarball.${NC}"
            exit 1
        fi
        
        mkdir -p "$HOME/.local/bin"
        mv echidna "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/echidna"
        
        if ! grep -q "$HOME/.local/bin" "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        
        cd - > /dev/null
        rm -rf "$tmp_dir"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    echo -e "${GREEN}Echidna installation completed!${NC}"
    if command -v echidna >/dev/null; then
        echo -e "${GREEN}Echidna installation verified!${NC}"
        echidna --version
    else
        echo -e "${RED}Echidna installation failed - not in PATH${NC}"
        echo "Current PATH: $PATH"
    fi
}

install_medusa() {
    echo -e "${YELLOW}Installing Medusa...${NC}"
    
    # Try to use brew if available (or attempt to install it)
    ensure_brew
    if command -v brew >/dev/null; then
        echo -e "${YELLOW}Installing Medusa using Homebrew...${NC}"
        brew update && brew install medusa
    else
        # Fallback: use Cargo installation
        if ! command -v rustup >/dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        cargo install medusa --locked
    fi

    if command -v medusa >/dev/null; then
        echo -e "${GREEN}Medusa installation verified!${NC}"
        medusa --version
    else
        echo -e "${RED}Medusa not found in PATH. You may need to add ~/.cargo/bin to your PATH.${NC}"
        echo "Try running: source \$HOME/.cargo/env"
        if ! grep -q ".cargo/env" "$HOME/.bashrc"; then
            echo 'source "$HOME/.cargo/env"' >> "$HOME/.bashrc"
        fi
    fi
}

install_foundry() {
    echo -e "${YELLOW}Installing Foundry...${NC}"
    
    # Use foundryup for Foundry installation
    curl -L https://foundry.paradigm.xyz | bash
    source "$HOME/.bashrc"
    "$HOME/.foundry/bin/foundryup"
    
    if command -v forge >/dev/null; then
        echo -e "${GREEN}Foundry installation verified!${NC}"
        forge --version
    else
        echo -e "${RED}Foundry not found in PATH.${NC}"
        echo "Try running: source ~/.bashrc"
    fi
}

install_dependencies() {
    echo -e "${YELLOW}Installing system dependencies...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        make curl git software-properties-common \
        jq build-essential libssl-dev pkg-config \
        clang cmake zip unzip > /dev/null
    echo -e "${GREEN}System dependencies installed!${NC}"
}

main() {
    echo -e "${GREEN}Starting installation...${NC}"
    
    install_dependencies
    install_echidna
    install_medusa
    install_foundry
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo "Please restart your shell or run:"
    echo "source ~/.bashrc"
    echo "source ~/.cargo/env"
}

main "$@"
