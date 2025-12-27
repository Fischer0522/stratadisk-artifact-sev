#!/bin/bash

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
BUILD_DIR="${SCRIPT_DIR}/build"
BIN_DIR="${SCRIPT_DIR}/bin"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Building cpp-ycsb${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check for RocksDB
echo -e "${YELLOW}Checking for RocksDB...${NC}"
if ! ldconfig -p | grep -q librocksdb; then
    echo -e "${RED}RocksDB not found in system libraries.${NC}"
    echo -e "${YELLOW}Please install RocksDB first:${NC}"
    echo -e "  ${GREEN}sudo apt install -y librocksdb-dev${NC}"
    echo -e "  Or build from source: https://github.com/facebook/rocksdb"
    exit 1
fi
echo -e "${GREEN}✓ RocksDB found${NC}"
echo ""

# Create build directory
mkdir -p "${BUILD_DIR}"
mkdir -p "${BIN_DIR}"

# Build with CMake
cd "${BUILD_DIR}"

echo -e "${YELLOW}Running CMake...${NC}"
cmake .. -DCMAKE_BUILD_TYPE=Release

echo ""
echo -e "${YELLOW}Compiling...${NC}"
make -j$(nproc)

echo ""
if [ -f "${BIN_DIR}/ycsb" ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "Executable: ${GREEN}${BIN_DIR}/ycsb${NC}"
    echo ""
    echo "Usage examples:"
    echo "  # Load data"
    echo "  ${BIN_DIR}/ycsb load -P workloads/workloada -db /tmp/testdb"
    echo ""
    echo "  # Run benchmark"
    echo "  ${BIN_DIR}/ycsb run -P workloads/workloada -db /tmp/testdb"
    echo ""
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
