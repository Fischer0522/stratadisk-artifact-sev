#!/bin/bash

# Script to install RocksDB on Ubuntu/Debian

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Installing RocksDB${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if already installed
if ldconfig -p | grep -q librocksdb; then
    echo -e "${GREEN}RocksDB is already installed${NC}"
    ldconfig -p | grep rocksdb
    echo ""
    read -p "Reinstall RocksDB? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo -e "${YELLOW}Choose installation method:${NC}"
echo "  1) Install from package manager (recommended, faster)"
echo "  2) Build from source (latest version)"
echo ""
read -p "Enter choice (1 or 2): " choice

if [ "$choice" == "1" ]; then
    echo -e "${YELLOW}Installing RocksDB from package manager...${NC}"
    sudo apt update
    sudo apt install -y librocksdb-dev

    echo ""
    echo -e "${GREEN}✓ RocksDB installed successfully${NC}"
    ldconfig -p | grep rocksdb

elif [ "$choice" == "2" ]; then
    echo -e "${YELLOW}Building RocksDB from source...${NC}"

    # Install dependencies
    echo -e "${YELLOW}Installing build dependencies...${NC}"
    sudo apt update
    sudo apt install -y \
        build-essential \
        libgflags-dev \
        libsnappy-dev \
        zlib1g-dev \
        libbz2-dev \
        liblz4-dev \
        libzstd-dev \
        git

    # Clone RocksDB
    ROCKSDB_DIR="/tmp/rocksdb-build"
    if [ -d "$ROCKSDB_DIR" ]; then
        echo -e "${YELLOW}Removing existing build directory...${NC}"
        rm -rf "$ROCKSDB_DIR"
    fi

    echo -e "${YELLOW}Cloning RocksDB repository...${NC}"
    git clone https://github.com/facebook/rocksdb.git "$ROCKSDB_DIR"
    cd "$ROCKSDB_DIR"

    # Build
    echo -e "${YELLOW}Building RocksDB (this may take 10-15 minutes)...${NC}"
    make shared_lib -j$(nproc)

    # Install
    echo -e "${YELLOW}Installing RocksDB...${NC}"
    sudo make install-shared

    # Update library cache
    sudo ldconfig

    # Cleanup
    cd -
    echo -e "${YELLOW}Cleaning up build directory...${NC}"
    rm -rf "$ROCKSDB_DIR"

    echo ""
    echo -e "${GREEN}✓ RocksDB built and installed successfully${NC}"
    ldconfig -p | grep rocksdb

else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "You can now build cpp-ycsb:"
echo "  cd /home/yxy/ssd/fast26_ae/sev/ycsb/cpp-ycsb"
echo "  ./build.sh"
