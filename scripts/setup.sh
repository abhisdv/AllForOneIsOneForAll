#!/bin/bash

# Polyglot App Framework Setup Script
# Installs all necessary language runtimes and dependencies

set -e

echo "🚀 Setting up Polyglot App Framework..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install with brew (macOS)
install_with_brew() {
    if command_exists brew; then
        echo -e "${BLUE}Installing $1 with Homebrew...${NC}"
        brew install "$1"
    else
        echo -e "${RED}Homebrew not found. Please install Homebrew first.${NC}"
        exit 1
    fi
}

# Function to install Node.js
install_node() {
    if ! command_exists node; then
        echo -e "${YELLOW}Installing Node.js...${NC}"
        if command_exists brew; then
            brew install node
        else
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    else
        echo -e "${GREEN}Node.js already installed: $(node --version)${NC}"
    fi
}

# Function to install Python
install_python() {
    if ! command_exists python3; then
        echo -e "${YELLOW}Installing Python 3...${NC}"
        if command_exists brew; then
            brew install python
        else
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
        fi
    else
        echo -e "${GREEN}Python 3 already installed: $(python3 --version)${NC}"
    fi
}

# Function to install Go
install_go() {
    if ! command_exists go; then
        echo -e "${YELLOW}Installing Go...${NC}"
        if command_exists brew; then
            brew install go
        else
            wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
            sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
            source ~/.bashrc
        fi
    else
        echo -e "${GREEN}Go already installed: $(go version)${NC}"
    fi
}

# Function to install Flutter
install_flutter() {
    if ! command_exists flutter; then
        echo -e "${YELLOW}Installing Flutter...${NC}"
        if command_exists brew; then
            brew install --cask flutter
        else
            git clone https://github.com/flutter/flutter.git -b stable ~/flutter
            echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
            source ~/.bashrc
        fi
    else
        echo -e "${GREEN}Flutter already installed: $(flutter --version | head -n 1)${NC}"
    fi
}

# Function to install Kotlin
install_kotlin() {
    if ! command_exists kotlin; then
        echo -e "${YELLOW}Installing Kotlin...${NC}"
        if command_exists brew; then
            brew install kotlin
        else
            curl -s "https://get.sdkman.io" | bash
            source "$HOME/.sdkman/bin/sdkman-init.sh"
            sdk install kotlin
        fi
    else
        echo -e "${GREEN}Kotlin already installed: $(kotlin --version)${NC}"
    fi
}

# Function to install Docker
install_docker() {
    if ! command_exists docker; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        if command_exists brew; then
            brew install --cask docker
        else
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
        fi
    else
        echo -e "${GREEN}Docker already installed: $(docker --version)${NC}"
    fi
}

# Main installation process
echo -e "${BLUE}Checking and installing language runtimes...${NC}"

# Install language runtimes
install_node
install_python
install_go
install_flutter
install_kotlin
install_docker

# Install global npm packages
echo -e "${BLUE}Installing global npm packages...${NC}"
npm install -g typescript @types/node jest ts-jest

# Install Python packages
echo -e "${BLUE}Installing Python packages...${NC}"
pip3 install pytest pytest-cov black flake8 mypy

# Install Go tools
echo -e "${BLUE}Installing Go tools...${NC}"
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Create necessary directories
echo -e "${BLUE}Creating framework directories...${NC}"
mkdir -p scripts
mkdir -p docs
mkdir -p logs
mkdir -p .cache

# Make scripts executable
chmod +x scripts/*.sh

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run: ${YELLOW}./scripts/install-dev-tools.sh${NC}"
echo -e "2. Run: ${YELLOW}./scripts/dev.sh${NC}"
echo -e "3. Check: ${YELLOW}./scripts/test.sh${NC}" 