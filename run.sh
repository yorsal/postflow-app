#!/usr/bin/env bash
# run-standalone.sh - Start standalone Next.js server
# Usage: ./scripts/run-standalone.sh [port]
# Supports: macOS, Linux

# Configuration
PORT="${1:-3789}"
STANDALONE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if port is in use
is_port_in_use() {
    lsof -ti:$1 > /dev/null 2>&1
}

# Install Node.js from official source
install_nodejs() {
    log_info "Installing Node.js 24.14.0..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install node@24
        else
            log_info "Downloading Node.js installer..."
            curl -fsSL https://nodejs.org/dist/v24.14.0/node-v24.14.0.pkg -o /tmp/node-installer.pkg && sudo installer -pkg /tmp/node-installer.pkg -target /
        fi
    else
        # Linux - use NodeSource
        log_info "Installing Node.js via NodeSource..."
        curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
        apt-get install -y nodejs
    fi

    # Reload PATH
    export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
    hash -r
}

# Check Node.js version
check_node() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        log_info "Installing Node.js 24.14.0 from https://nodejs.org..."
        install_nodejs
    fi

    NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
    if [ -z "$NODE_VERSION" ]; then
        log_error "Failed to get Node.js version"
        exit 1
    fi

    if [ "$NODE_VERSION" -lt 20 ]; then
        log_warn "Node.js version ($NODE_VERSION) is below 20, this may cause issues"
        log_info "Please upgrade to Node.js 20+ from https://nodejs.org"
    else
        log_info "Using Node.js $(node --version)"
    fi
}

# Start the standalone server
start_server() {
    if [ ! -d "$STANDALONE_DIR" ]; then
        log_error "Standalone directory not found: $STANDALONE_DIR"
        log_error "Please run 'npm run build' first"
        exit 1
    fi

    cd "$STANDALONE_DIR"

    # Find available port
    ORIGINAL_PORT=$PORT
    while is_port_in_use $PORT; do
        log_info "Port $PORT is in use, trying next..."
        PORT=$((PORT + 1))
    done

    if [ $PORT != $ORIGINAL_PORT ]; then
        log_info "Using port $PORT instead"
    fi

    echo ""
    log_info "Starting server at http://localhost:$PORT"
    log_info "Press Ctrl+C to stop"
    echo ""

    # Open browser after a short delay
    sleep 1
    open "http://localhost:$PORT"

    PORT=$PORT node server.js
}

# Main
main() {
    echo "========================================"
    echo "  Next.js Standalone Server Starter"
    echo "========================================"
    echo ""

    check_node

    start_server
}

main
