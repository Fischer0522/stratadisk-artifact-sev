#!/bin/bash

# Example script to run YCSB benchmarks on different filesystems

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
YCSB_BIN="${SCRIPT_DIR}/bin/ycsb"

# Check if ycsb binary exists
if [ ! -f "${YCSB_BIN}" ]; then
    echo -e "${RED}Error: ycsb binary not found${NC}"
    echo -e "${YELLOW}Please run ./build.sh first${NC}"
    exit 1
fi

# Workload to test
WORKLOAD="${1:-workloads/workloada}"

# Test directories
DATA_DIR="/home/yxy/ssd/fast26_ae/sev/data"
SWORNDISK_DIR="${DATA_DIR}/sworndisk-ycsb"
CRYPTDISK_DIR="${DATA_DIR}/cryptdisk-ycsb"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}YCSB Benchmark - RocksDB${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Workload: ${WORKLOAD}"
echo ""

# Function to run benchmark on a specific directory
run_benchmark() {
    local name=$1
    local db_dir=$2

    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Testing: ${name}${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    # Clean up existing database
    if [ -d "${db_dir}" ]; then
        echo -e "${YELLOW}Cleaning up existing database...${NC}"
        rm -rf "${db_dir}"
    fi

    mkdir -p "${db_dir}"

    # Load phase
    echo -e "${GREEN}[1/2] Loading data...${NC}"
    "${YCSB_BIN}" load -P "${WORKLOAD}" -db "${db_dir}"

    echo ""

    # Run phase
    echo -e "${GREEN}[2/2] Running benchmark...${NC}"
    "${YCSB_BIN}" run -P "${WORKLOAD}" -db "${db_dir}"

    echo ""
}

# Create data directory if it doesn't exist
mkdir -p "${DATA_DIR}"

# Test on SwornDisk
run_benchmark "SwornDisk" "${SWORNDISK_DIR}"

# Test on CryptDisk
run_benchmark "CryptDisk" "${CRYPTDISK_DIR}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All benchmarks completed!${NC}"
echo -e "${GREEN}========================================${NC}"
