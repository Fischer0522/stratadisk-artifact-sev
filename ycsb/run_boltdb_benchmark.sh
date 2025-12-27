#!/bin/bash

# Script to run BoltDB benchmarks using go-ycsb
# Tests workloads a, b, e, f on SwornDisk and CryptDisk

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
YCSB_BIN="${SCRIPT_DIR}/go-ycsb/bin/go-ycsb"
WORKLOAD_DIR="${SCRIPT_DIR}/go-ycsb/workloads"
RESULT_FILE="${SCRIPT_DIR}/boltdb_results.json"

# Check if go-ycsb binary exists
if [ ! -f "${YCSB_BIN}" ]; then
    echo -e "${RED}Error: go-ycsb binary not found at ${YCSB_BIN}${NC}"
    echo -e "${YELLOW}Please run: cd go-ycsb && make${NC}"
    exit 1
fi

# Check if workload directory exists
if [ ! -d "${WORKLOAD_DIR}" ]; then
    echo -e "${RED}Error: workload directory not found at ${WORKLOAD_DIR}${NC}"
    exit 1
fi

# Workloads to test
WORKLOADS=("workloada" "workloadb" "workloade" "workloadf")

# Test database files (BoltDB is a single-file database)
DATA_DIR="/home/yxy/ssd/fast26_ae/sev/data"
SWORNDISK_FILE="${DATA_DIR}/sworndisk-boltdb.db"
CRYPTDISK_FILE="${DATA_DIR}/cryptdisk-boltdb.db"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}BoltDB Benchmark - go-ycsb${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Workloads to test: ${WORKLOADS[@]}"
echo "Results will be saved to: ${RESULT_FILE}"
echo ""

# Initialize JSON results file
echo "{" > "${RESULT_FILE}"
echo "  \"benchmark\": \"BoltDB\"," >> "${RESULT_FILE}"
echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "${RESULT_FILE}"
echo "  \"results\": [" >> "${RESULT_FILE}"

FIRST_RESULT=true

# Function to run benchmark for a specific workload and database file
run_benchmark() {
    local workload=$1
    local name=$2
    local db_file=$3

    echo -e "${YELLOW}----------------------------------------${NC}"
    echo -e "${YELLOW}Testing: ${name} - ${workload}${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
    echo ""

    # Clean up existing database file
    if [ -f "${db_file}" ]; then
        echo -e "${YELLOW}Cleaning up existing database file...${NC}"
        rm -f "${db_file}"
    fi

    # Load phase
    echo -e "${GREEN}[1/2] Loading data...${NC}"
    "${YCSB_BIN}" load boltdb -P "${WORKLOAD_DIR}/${workload}" -p bolt.path="${db_file}"

    echo ""

    # Run phase
    echo -e "${GREEN}[2/2] Running benchmark...${NC}"
    local output=$(mktemp)
    "${YCSB_BIN}" run boltdb -P "${WORKLOAD_DIR}/${workload}" -p bolt.path="${db_file}" 2>&1 | tee "${output}"

    echo ""

    # Extract throughput from output (OPS from TOTAL line after "Run finished")
    local throughput=$(grep "^TOTAL" "${output}" | tail -1 | sed -n 's/.*OPS: \([0-9.]*\).*/\1/p')

    # Add result to JSON
    if [ "${FIRST_RESULT}" = true ]; then
        FIRST_RESULT=false
    else
        echo "    ," >> "${RESULT_FILE}"
    fi

    echo "    {" >> "${RESULT_FILE}"
    echo "      \"workload\": \"${workload}\"," >> "${RESULT_FILE}"
    echo "      \"filesystem\": \"${name}\"," >> "${RESULT_FILE}"
    echo "      \"throughput_ops_sec\": ${throughput:-0}" >> "${RESULT_FILE}"
    echo -n "    }" >> "${RESULT_FILE}"

    rm -f "${output}"
}

# Create data directory if it doesn't exist
mkdir -p "${DATA_DIR}"

# Test each workload on both filesystems
for workload in "${WORKLOADS[@]}"; do
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Workload: ${workload}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Test on SwornDisk
    run_benchmark "${workload}" "SwornDisk" "${SWORNDISK_FILE}"

    # Test on CryptDisk
    run_benchmark "${workload}" "CryptDisk" "${CRYPTDISK_FILE}"

    echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All BoltDB benchmarks completed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Tested workloads:"
for workload in "${WORKLOADS[@]}"; do
    echo "  - ${workload}"
done
echo ""

# Close JSON file
echo "" >> "${RESULT_FILE}"
echo "  ]" >> "${RESULT_FILE}"
echo "}" >> "${RESULT_FILE}"

echo -e "${GREEN}Results saved to: ${RESULT_FILE}${NC}"
echo ""
