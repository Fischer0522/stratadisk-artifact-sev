#!/bin/bash

# Exit on any error
set -e

echo "===================================================="
echo " VM Environment Setup Script (Guest Mode) "
echo "===================================================="

# 0. Fix Hostname and Environment issues
# Solve "unable to resolve host (none)" warnings
hostname dell-vm || true

# Prevent interactive prompts during apt-get
export DEBIAN_FRONTEND=noninteractive

# Ensure the PATH includes standard system directories (critical for init=/bin/bash)
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 1. Install Go
if ! command -v go &> /dev/null; then
    echo "[1/3] Installing Go..."
    
    # Check network connectivity before starting
    if ! ping -c 1 golang.google.cn >/dev/null 2>&1; then
        echo "Error: No internet connection. Please check /etc/resolv.conf"
        # Optional: echo "nameserver 8.8.8.8" > /etc/resolv.conf
        exit 1
    fi

    wget https://golang.google.cn/dl/go1.22.0.linux-amd64.tar.gz -O /tmp/go.tar.gz
    
    # Remove old installation if exists and extract (No sudo needed)
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    # Setup environment variables in .bashrc
    BASHRC="$HOME/.bashrc"
    [ ! -f "$BASHRC" ] && touch "$BASHRC"

    grep -q 'export GOROOT="/usr/local/go"' "$BASHRC" || echo 'export GOROOT="/usr/local/go"' >> "$BASHRC"
    grep -q 'export GOPATH="$HOME/.go"' "$BASHRC" || echo 'export GOPATH="$HOME/.go"' >> "$BASHRC"
    grep -q 'GOROOT/bin' "$BASHRC" || echo 'export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"' >> "$BASHRC"

    # Export for current session
    export GOROOT="/usr/local/go"
    export GOPATH="$HOME/.go"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

    # Configure Go Proxy
    go env -w GOPROXY=https://goproxy.cn,direct
    echo "✓ Go installed successfully: $(go version)"
else
    echo "[1/3] Go is already installed: $(go version)"
fi

# 2. Install PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "[2/3] Installing PostgreSQL..."
    apt-get update
    apt-get install -y postgresql postgresql-client
    echo "✓ PostgreSQL installed successfully"
    echo "Note: Systemd is not running. Start DB manually via pg_ctl if needed."
else
    echo "[2/3] PostgreSQL is already installed, skipping"
fi

# 3. Install SQLite3
if ! command -v sqlite3 &> /dev/null; then
    echo "[3/3] Installing SQLite3..."
    apt-get install -y sqlite3 libsqlite3-dev
    echo "✓ SQLite3 installed successfully"
else
    echo "[3/3] SQLite3 is already installed, skipping"
fi

echo ""
echo "===================================================="
echo " Cloning Repositories "
echo "===================================================="

# Clone go-ycsb
if [ ! -d "go-ycsb" ]; then
    echo "Cloning go-ycsb (feat/sworndisk)..."
    if git clone https://github.com/Fischer0522/go-ycsb.git -b feat/sworndisk; then
        echo "✓ go-ycsb cloned successfully"
    else
        echo "✗ Git clone failed. Check your network or Proxy settings."
        exit 1
    fi
else
    echo "Directory 'go-ycsb' already exists, skipping clone"
fi

echo ""
echo "===================================================="
echo " Setup Completed Successfully "
echo "===================================================="
echo ""
echo "Current Environment Status:"
echo "  - Go: $(go version 2>/dev/null || echo 'Run source ~/.bashrc to load')"
echo "  - PostgreSQL: $(psql --version 2>/dev/null || echo 'Installed')"
echo "  - SQLite3: $(sqlite3 --version 2>/dev/null || echo 'Installed')"
echo ""
echo "IMPORTANT: Run the following command to refresh your shell:"
echo "  source ~/.bashrc"
echo ""