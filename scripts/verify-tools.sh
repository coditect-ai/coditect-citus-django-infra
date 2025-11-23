#!/bin/bash
# Tool Verification Script - CODITECT Infrastructure
# Verifies that all required development tools are installed and properly configured
# Usage: ./scripts/verify-tools.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
log_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Version comparison function
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Check functions

check_gcloud() {
    echo ""
    log_info "Checking Google Cloud SDK (gcloud)..."

    if ! command -v gcloud &> /dev/null; then
        log_fail "gcloud not found"
        echo "   Install from: https://cloud.google.com/sdk/docs/install"
        return 1
    fi

    VERSION=$(gcloud version --format="value(version)" 2>/dev/null || echo "unknown")
    log_pass "gcloud installed (version: $VERSION)"

    # Check authentication
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
        ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)
        if [ -n "$ACCOUNT" ]; then
            log_pass "Authenticated as: $ACCOUNT"
        else
            log_warn "Not authenticated. Run: gcloud auth login"
        fi
    else
        log_warn "Not authenticated. Run: gcloud auth login"
    fi

    # Check default project
    DEFAULT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -n "$DEFAULT_PROJECT" ]; then
        log_pass "Default project: $DEFAULT_PROJECT"
    else
        log_warn "No default project set. Run: gcloud config set project PROJECT_ID"
    fi
}

check_terraform() {
    echo ""
    log_info "Checking Terraform..."

    if ! command -v terraform &> /dev/null; then
        log_fail "terraform not found"
        echo "   Install from: https://www.terraform.io/downloads"
        return 1
    fi

    VERSION=$(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*' | cut -d'"' -f4 || echo "unknown")
    MIN_VERSION="1.5.0"

    if [ "$VERSION" == "unknown" ]; then
        log_warn "terraform installed but version unknown"
    elif version_gt "$VERSION" "$MIN_VERSION" || [ "$VERSION" == "$MIN_VERSION" ]; then
        log_pass "terraform installed (version: $VERSION)"
    else
        log_warn "terraform version $VERSION is below recommended $MIN_VERSION"
    fi

    # Check Terraform plugins
    if [ -d "$HOME/.terraform.d/plugins" ]; then
        log_pass "Terraform plugin directory exists"
    fi
}

check_kubectl() {
    echo ""
    log_info "Checking kubectl..."

    if ! command -v kubectl &> /dev/null; then
        log_fail "kubectl not found"
        echo "   Install via: gcloud components install kubectl"
        return 1
    fi

    VERSION=$(kubectl version --client --short 2>/dev/null | grep -o 'v[0-9.]*' | head -n 1 || echo "unknown")
    MIN_VERSION="v1.28.0"

    if [ "$VERSION" == "unknown" ]; then
        log_warn "kubectl installed but version unknown"
    else
        log_pass "kubectl installed (version: $VERSION)"
    fi

    # Check kubeconfig
    if [ -f "$HOME/.kube/config" ]; then
        CONTEXTS=$(kubectl config get-contexts -o name 2>/dev/null | wc -l)
        if [ "$CONTEXTS" -gt 0 ]; then
            CURRENT=$(kubectl config current-context 2>/dev/null || echo "none")
            log_pass "kubeconfig configured ($CONTEXTS contexts, current: $CURRENT)"
        else
            log_warn "kubeconfig exists but no contexts configured"
        fi
    else
        log_warn "No kubeconfig found. Run: gcloud container clusters get-credentials CLUSTER_NAME"
    fi
}

check_helm() {
    echo ""
    log_info "Checking Helm..."

    if ! command -v helm &> /dev/null; then
        log_fail "helm not found"
        echo "   Install from: https://helm.sh/docs/intro/install/"
        return 1
    fi

    VERSION=$(helm version --short 2>/dev/null | grep -o 'v[0-9.]*' | head -n 1 || echo "unknown")
    MIN_VERSION="v3.0.0"

    if [ "$VERSION" == "unknown" ]; then
        log_warn "helm installed but version unknown"
    else
        log_pass "helm installed (version: $VERSION)"
    fi

    # Check helm repos
    REPOS=$(helm repo list 2>/dev/null | tail -n +2 | wc -l || echo "0")
    if [ "$REPOS" -gt 0 ]; then
        log_pass "Helm repos configured ($REPOS repos)"
    else
        log_warn "No helm repos configured. Consider adding stable repo"
    fi
}

check_docker() {
    echo ""
    log_info "Checking Docker..."

    if ! command -v docker &> /dev/null; then
        log_fail "docker not found"
        echo "   Install Docker Desktop from: https://docs.docker.com/get-docker/"
        return 1
    fi

    VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")

    if [ "$VERSION" == "unknown" ]; then
        log_warn "docker installed but not running or version unknown"
        echo "   Make sure Docker Desktop is running"
    else
        log_pass "docker installed (version: $VERSION)"

        # Check if docker daemon is running
        if docker ps &> /dev/null; then
            log_pass "Docker daemon is running"
        else
            log_warn "Docker daemon not running. Start Docker Desktop"
        fi
    fi
}

check_python() {
    echo ""
    log_info "Checking Python..."

    if ! command -v python3 &> /dev/null; then
        log_fail "python3 not found"
        echo "   Install Python 3.10+ from: https://www.python.org/downloads/"
        return 1
    fi

    VERSION=$(python3 --version | awk '{print $2}')
    MIN_VERSION="3.10.0"

    log_pass "python3 installed (version: $VERSION)"

    # Check pip
    if command -v pip3 &> /dev/null; then
        PIP_VERSION=$(pip3 --version | awk '{print $2}')
        log_pass "pip3 installed (version: $PIP_VERSION)"
    else
        log_warn "pip3 not found. Install via: python3 -m ensurepip"
    fi

    # Check poetry
    if command -v poetry &> /dev/null; then
        POETRY_VERSION=$(poetry --version 2>/dev/null | awk '{print $3}' || echo "unknown")
        log_pass "poetry installed (version: $POETRY_VERSION)"
    else
        log_warn "poetry not found. Recommended for dependency management"
    fi

    # Check pre-commit
    if command -v pre-commit &> /dev/null; then
        PRECOMMIT_VERSION=$(pre-commit --version | awk '{print $2}')
        log_pass "pre-commit installed (version: $PRECOMMIT_VERSION)"
    else
        log_warn "pre-commit not found. Install via: pip3 install pre-commit"
    fi
}

check_git() {
    echo ""
    log_info "Checking Git..."

    if ! command -v git &> /dev/null; then
        log_fail "git not found"
        return 1
    fi

    VERSION=$(git --version | awk '{print $3}')
    log_pass "git installed (version: $VERSION)"

    # Check git configuration
    if git config user.name &> /dev/null && git config user.email &> /dev/null; then
        USER_NAME=$(git config user.name)
        USER_EMAIL=$(git config user.email)
        log_pass "git configured (name: $USER_NAME, email: $USER_EMAIL)"
    else
        log_warn "git not fully configured. Set name and email:"
        echo "   git config --global user.name 'Your Name'"
        echo "   git config --global user.email 'your.email@example.com'"
    fi
}

check_environment() {
    echo ""
    log_info "Checking environment configuration..."

    # Check for .env file
    if [ -f ".env" ]; then
        log_pass ".env file exists"
    else
        if [ -f ".env.example" ]; then
            log_warn ".env file not found. Copy from .env.example"
        else
            log_warn "Neither .env nor .env.example found"
        fi
    fi

    # Check for Google credentials
    if [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
        if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
            log_pass "GOOGLE_APPLICATION_CREDENTIALS set and file exists"
        else
            log_warn "GOOGLE_APPLICATION_CREDENTIALS set but file not found: $GOOGLE_APPLICATION_CREDENTIALS"
        fi
    else
        log_warn "GOOGLE_APPLICATION_CREDENTIALS not set"
        echo "   Set via: export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json"
    fi

    # Check terraform directory
    if [ -d "terraform" ]; then
        log_pass "terraform directory exists"
    else
        log_warn "terraform directory not found"
    fi

    # Check scripts directory
    if [ -d "scripts" ]; then
        SCRIPT_COUNT=$(find scripts -name "*.sh" -type f | wc -l)
        log_pass "scripts directory exists ($SCRIPT_COUNT scripts)"
    else
        log_warn "scripts directory not found"
    fi
}

check_network() {
    echo ""
    log_info "Checking network connectivity..."

    # Check internet connectivity
    if ping -c 1 google.com &> /dev/null; then
        log_pass "Internet connectivity OK"
    else
        log_warn "Cannot reach google.com. Check internet connection"
    fi

    # Check GCP API connectivity
    if curl -s https://cloudresourcemanager.googleapis.com &> /dev/null; then
        log_pass "GCP API reachable"
    else
        log_warn "Cannot reach GCP APIs. Check firewall/proxy settings"
    fi
}

# Main verification flow
main() {
    echo ""
    echo "========================================"
    echo "CODITECT Development Tools Verification"
    echo "========================================"

    check_git
    check_gcloud
    check_terraform
    check_kubectl
    check_helm
    check_docker
    check_python
    check_environment
    check_network

    # Summary
    echo ""
    echo "========================================"
    echo "Verification Summary"
    echo "========================================"
    echo ""
    echo -e "${GREEN}Passed:${NC}   $PASSED"
    echo -e "${RED}Failed:${NC}   $FAILED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo ""

    if [ $FAILED -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ All checks passed! Environment is ready.${NC}"
            exit 0
        else
            echo -e "${YELLOW}⚠ Environment is mostly ready but has warnings.${NC}"
            echo "Review warnings above and address as needed."
            exit 0
        fi
    else
        echo -e "${RED}✗ Some required tools are missing or misconfigured.${NC}"
        echo "Please install missing tools and re-run this script."
        exit 1
    fi
}

# Run main function
main
