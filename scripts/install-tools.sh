#!/bin/bash
# Tool Installation Script - CODITECT Infrastructure
# Installs and configures required development tools
# Usage: ./scripts/install-tools.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
log_info "Detected OS: $OS"

# Required versions
TERRAFORM_MIN_VERSION="1.5.0"
KUBECTL_MIN_VERSION="1.28.0"
HELM_MIN_VERSION="3.0.0"

# Installation functions

install_gcloud() {
    log_step "Installing Google Cloud SDK (gcloud)..."

    if command -v gcloud &> /dev/null; then
        log_warn "gcloud already installed. Updating..."
        gcloud components update --quiet
        return 0
    fi

    if [ "$OS" == "macos" ]; then
        if command -v brew &> /dev/null; then
            log_info "Installing via Homebrew..."
            brew install --cask google-cloud-sdk
        else
            log_info "Downloading installer..."
            curl https://sdk.cloud.google.com | bash
            exec -l $SHELL
        fi
    elif [ "$OS" == "linux" ]; then
        log_info "Downloading installer..."
        curl https://sdk.cloud.google.com | bash
        exec -l $SHELL
    else
        log_error "Unsupported OS for automatic gcloud installation"
        echo "Please install manually from: https://cloud.google.com/sdk/docs/install"
        return 1
    fi

    log_info "gcloud installed successfully"
}

install_terraform() {
    log_step "Installing Terraform..."

    if command -v terraform &> /dev/null; then
        CURRENT_VERSION=$(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)
        log_warn "Terraform already installed (version: $CURRENT_VERSION)"
        return 0
    fi

    if [ "$OS" == "macos" ]; then
        if command -v brew &> /dev/null; then
            log_info "Installing via Homebrew..."
            brew tap hashicorp/tap
            brew install hashicorp/tap/terraform
        else
            log_error "Homebrew not found. Install from: https://brew.sh"
            return 1
        fi
    elif [ "$OS" == "linux" ]; then
        log_info "Installing from HashiCorp repository..."

        # Install required packages
        sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

        # Add HashiCorp GPG key
        wget -O- https://apt.releases.hashicorp.com/gpg | \
            gpg --dearmor | \
            sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

        # Add repository
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
            https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
            sudo tee /etc/apt/sources.list.d/hashicorp.list

        # Install Terraform
        sudo apt-get update && sudo apt-get install terraform
    else
        log_error "Unsupported OS for automatic Terraform installation"
        echo "Please install manually from: https://www.terraform.io/downloads"
        return 1
    fi

    log_info "Terraform installed successfully"
}

install_kubectl() {
    log_step "Installing kubectl..."

    if command -v kubectl &> /dev/null; then
        CURRENT_VERSION=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
        log_warn "kubectl already installed (version: $CURRENT_VERSION)"
        return 0
    fi

    # Install via gcloud (preferred method)
    if command -v gcloud &> /dev/null; then
        log_info "Installing via gcloud components..."
        gcloud components install kubectl --quiet
    elif [ "$OS" == "macos" ]; then
        if command -v brew &> /dev/null; then
            log_info "Installing via Homebrew..."
            brew install kubectl
        else
            log_error "Neither gcloud nor Homebrew found"
            return 1
        fi
    elif [ "$OS" == "linux" ]; then
        log_info "Downloading kubectl binary..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    else
        log_error "Unsupported OS for automatic kubectl installation"
        return 1
    fi

    log_info "kubectl installed successfully"
}

install_helm() {
    log_step "Installing Helm..."

    if command -v helm &> /dev/null; then
        CURRENT_VERSION=$(helm version --short 2>/dev/null | awk '{print $1}' || echo "unknown")
        log_warn "Helm already installed (version: $CURRENT_VERSION)"
        return 0
    fi

    if [ "$OS" == "macos" ]; then
        if command -v brew &> /dev/null; then
            log_info "Installing via Homebrew..."
            brew install helm
        else
            log_error "Homebrew not found"
            return 1
        fi
    elif [ "$OS" == "linux" ]; then
        log_info "Installing via official script..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        log_error "Unsupported OS for automatic Helm installation"
        return 1
    fi

    log_info "Helm installed successfully"
}

install_docker() {
    log_step "Checking Docker installation..."

    if command -v docker &> /dev/null; then
        CURRENT_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
        log_warn "Docker already installed (version: $CURRENT_VERSION)"
        return 0
    fi

    log_warn "Docker not found"

    if [ "$OS" == "macos" ]; then
        echo "Please install Docker Desktop from: https://docs.docker.com/desktop/install/mac-install/"
    elif [ "$OS" == "linux" ]; then
        echo "Please install Docker Engine from: https://docs.docker.com/engine/install/"
    fi

    log_info "Docker installation requires manual download and installation"
}

install_python_tools() {
    log_step "Installing Python development tools..."

    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 not found. Please install Python 3.10+ first"
        return 1
    fi

    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    log_info "Python version: $PYTHON_VERSION"

    # Install pip if not available
    if ! command -v pip3 &> /dev/null; then
        log_info "Installing pip..."
        python3 -m ensurepip --upgrade
    fi

    # Install poetry for dependency management
    if ! command -v poetry &> /dev/null; then
        log_info "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
        export PATH="$HOME/.local/bin:$PATH"
    else
        log_warn "Poetry already installed"
    fi

    # Install pre-commit
    if ! command -v pre-commit &> /dev/null; then
        log_info "Installing pre-commit..."
        pip3 install pre-commit
    else
        log_warn "pre-commit already installed"
    fi

    log_info "Python tools installed successfully"
}

# Main installation flow
main() {
    log_info "================================"
    log_info "CODITECT Development Tools Setup"
    log_info "================================"
    echo ""

    # Check for required permissions
    if [ "$EUID" -eq 0 ]; then
        log_error "Do not run this script as root"
        exit 1
    fi

    # Install tools
    install_gcloud || log_warn "gcloud installation skipped"
    echo ""

    install_terraform || log_warn "Terraform installation skipped"
    echo ""

    install_kubectl || log_warn "kubectl installation skipped"
    echo ""

    install_helm || log_warn "Helm installation skipped"
    echo ""

    install_docker || log_warn "Docker installation skipped"
    echo ""

    install_python_tools || log_warn "Python tools installation skipped"
    echo ""

    # Post-installation configuration
    log_step "Post-installation configuration..."

    # Initialize gcloud if installed
    if command -v gcloud &> /dev/null; then
        log_info "gcloud is installed. Run 'gcloud init' to configure authentication"
    fi

    # Setup kubectl completion
    if command -v kubectl &> /dev/null; then
        if [ "$OS" == "macos" ]; then
            if command -v brew &> /dev/null; then
                log_info "Setting up kubectl completion for zsh..."
                echo 'source <(kubectl completion zsh)' >> ~/.zshrc || true
            fi
        fi
    fi

    # Setup helm completion
    if command -v helm &> /dev/null; then
        if [ "$OS" == "macos" ]; then
            log_info "Setting up helm completion for zsh..."
            echo 'source <(helm completion zsh)' >> ~/.zshrc || true
        fi
    fi

    echo ""
    log_info "================================"
    log_info "Installation Summary"
    log_info "================================"
    echo ""

    # Run verification
    if [ -f "./scripts/verify-tools.sh" ]; then
        log_info "Running verification script..."
        ./scripts/verify-tools.sh
    else
        log_warn "Verification script not found. Run manually: ./scripts/verify-tools.sh"
    fi

    echo ""
    log_info "Next steps:"
    echo "  1. Restart your terminal to load new environment variables"
    echo "  2. Run: gcloud init (to configure authentication)"
    echo "  3. Run: ./scripts/verify-tools.sh (to verify installation)"
    echo "  4. Run: ./scripts/gcp-setup.sh dev (to setup GCP project)"
    echo ""
}

# Run main function
main
