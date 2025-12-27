#!/bin/bash

# Script to run PostgreSQL benchmarks using go-ycsb
# Tests workloads a, b, e, f on SwornDisk and CryptDisk instances

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
YCSB_BIN="${SCRIPT_DIR}/go-ycsb/bin/go-ycsb"
WORKLOAD_DIR="${SCRIPT_DIR}/go-ycsb/workloads"
RESULT_FILE="${SCRIPT_DIR}/postgres_results.json"

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

# PostgreSQL connection parameters
PG_USER="root"
PG_PASSWORD="root"
PG_DB="test"
PG_HOST="localhost"

# Port configuration (matching configure_postgres.sh)
SWORNDISK_PORT=5433
CRYPTDISK_PORT=5434

# Data directories (for reference)
DATA_DIR="/home/yxy/ssd/fast26_ae/sev/data"
SWORNDISK_DIR="${DATA_DIR}/sworndisk-postgres"
CRYPTDISK_DIR="${DATA_DIR}/cryptdisk-postgres"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PostgreSQL Benchmark - go-ycsb${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Workloads to test: ${WORKLOADS[@]}"
echo "Results will be saved to: ${RESULT_FILE}"
echo ""

# Initialize JSON results file
echo "{" > "${RESULT_FILE}"
echo "  \"benchmark\": \"PostgreSQL\"," >> "${RESULT_FILE}"
echo "  \"timestamp\": \"$(date -Iseconds)\"," >> "${RESULT_FILE}"
echo "  \"results\": [" >> "${RESULT_FILE}"

FIRST_RESULT=true

# Function to check if PostgreSQL instance is running
check_instance() {
    local name=$1
    local port=$2
    local data_dir=$3

    if [ ! -f "${data_dir}/postmaster.pid" ]; then
        echo -e "${RED}Error: ${name} PostgreSQL instance is not running${NC}"
        echo "Start it with: ./configure_postgres.sh start $(echo $name | tr '[:upper:]' '[:lower:]')"
        return 1
    fi

    local pid=$(head -1 "${data_dir}/postmaster.pid")
    if ! ps -p $pid > /dev/null 2>&1; then
        echo -e "${RED}Error: ${name} PostgreSQL instance is not running${NC}"
        echo "Start it with: ./configure_postgres.sh start $(echo $name | tr '[:upper:]' '[:lower:]')"
        return 1
    fi

    # Check if YCSB database exists
    if ! PGPASSWORD=${PG_PASSWORD} psql -h ${PG_HOST} -p ${port} -U ${PG_USER} -d ${PG_DB} -c '\q' 2>/dev/null; then
        echo -e "${RED}Error: YCSB database not initialized on ${name}${NC}"
        echo "Initialize it with: ./configure_postgres.sh init-ycsb $(echo $name | tr '[:upper:]' '[:lower:]')"
        return 1
    fi

    return 0
}

# Function to clean up YCSB tables
cleanup_ycsb_tables() {
    local port=$1

    echo -e "${YELLOW}Cleaning up YCSB tables...${NC}"
    PGPASSWORD=${PG_PASSWORD} psql -h ${PG_HOST} -p ${port} -U ${PG_USER} -d ${PG_DB} > /dev/null 2>&1 <<EOF
DROP TABLE IF EXISTS usertable;
EOF
}

# Function to run benchmark for a specific workload and instance
run_benchmark() {
    local workload=$1
    local name=$2
    local port=$3

    echo -e "${YELLOW}----------------------------------------${NC}"
    echo -e "${YELLOW}Testing: ${name} - ${workload}${NC}"
    echo -e "${YELLOW}----------------------------------------${NC}"
    echo ""

    # Clean up tables from previous runs
    cleanup_ycsb_tables ${port}

    # Load phase
    echo -e "${GREEN}[1/2] Loading data...${NC}"
    "${YCSB_BIN}" load pg -P "${WORKLOAD_DIR}/${workload}" \
        -p pg.host="${PG_HOST}" \
        -p pg.port="${port}" \
        -p pg.user="${PG_USER}" \
        -p pg.password="${PG_PASSWORD}" \
        -p pg.db="${PG_DB}"

    echo ""

    # Run phase
    echo -e "${GREEN}[2/2] Running benchmark...${NC}"
    local output=$(mktemp)
    "${YCSB_BIN}" run pg -P "${WORKLOAD_DIR}/${workload}" \
        -p pg.host="${PG_HOST}" \
        -p pg.port="${port}" \
        -p pg.user="${PG_USER}" \
        -p pg.password="${PG_PASSWORD}" \
        -p pg.db="${PG_DB}" \
        2>&1 | tee "${output}"

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
    echo "      \"port\": ${port}," >> "${RESULT_FILE}"
    echo "      \"throughput_ops_sec\": ${throughput:-0}" >> "${RESULT_FILE}"
    echo -n "    }" >> "${RESULT_FILE}"

    rm -f "${output}"
}

# Check if both instances are running
echo -e "${YELLOW}Checking PostgreSQL instances...${NC}"
echo ""

SWORNDISK_RUNNING=false
CRYPTDISK_RUNNING=false

if check_instance "SwornDisk" ${SWORNDISK_PORT} "${SWORNDISK_DIR}"; then
    echo -e "${GREEN}✓ SwornDisk instance is ready (port ${SWORNDISK_PORT})${NC}"
    SWORNDISK_RUNNING=true
else
    echo -e "${YELLOW}⚠ SwornDisk instance will be skipped${NC}"
fi
echo ""

if check_instance "CryptDisk" ${CRYPTDISK_PORT} "${CRYPTDISK_DIR}"; then
    echo -e "${GREEN}✓ CryptDisk instance is ready (port ${CRYPTDISK_PORT})${NC}"
    CRYPTDISK_RUNNING=true
else
    echo -e "${YELLOW}⚠ CryptDisk instance will be skipped${NC}"
fi
echo ""

if [ "$SWORNDISK_RUNNING" = false ] && [ "$CRYPTDISK_RUNNING" = false ]; then
    echo -e "${RED}Error: No PostgreSQL instances are running${NC}"
    echo ""
    echo "To set up and start instances:"
    echo "  ./configure_postgres.sh init sworndisk"
    echo "  ./configure_postgres.sh start sworndisk"
    echo "  ./configure_postgres.sh init-ycsb sworndisk"
    echo ""
    echo "  ./configure_postgres.sh init cryptdisk"
    echo "  ./configure_postgres.sh start cryptdisk"
    echo "  ./configure_postgres.sh init-ycsb cryptdisk"
    exit 1
fi

# Test each workload on available instances
for workload in "${WORKLOADS[@]}"; do
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Workload: ${workload}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Test on SwornDisk if running
    if [ "$SWORNDISK_RUNNING" = true ]; then
        run_benchmark "${workload}" "SwornDisk" ${SWORNDISK_PORT}
    fi

    # Test on CryptDisk if running
    if [ "$CRYPTDISK_RUNNING" = true ]; then
        run_benchmark "${workload}" "CryptDisk" ${CRYPTDISK_PORT}
    fi

    echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All PostgreSQL benchmarks completed!${NC}"
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
