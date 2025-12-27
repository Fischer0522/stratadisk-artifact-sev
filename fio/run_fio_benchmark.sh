#!/bin/bash
set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
FIO_CONFIG="reproduce.fio"
OUTPUT_DIR="${SCRIPT_DIR}/benchmark_results"
RESULT_JSON="${OUTPUT_DIR}/result.json"

# Test sections
WRITE_TESTS=("seq-write-256k" "rand-write-4k" "rand-write-32k" "rand-write-256k")
READ_TESTS=("seq-read-256k" "rand-read-4k" "rand-read-32k" "rand-read-256k")

# Map fio sections to result keys and types
declare -A TEST_KEYS=(
    ["seq-write-256k"]="seq_write_256k"
    ["rand-write-4k"]="rand_write_4k"
    ["rand-write-32k"]="rand_write_32k"
    ["rand-write-256k"]="rand_write_256k"
    ["seq-read-256k"]="seq_read_256k"
    ["rand-read-4k"]="rand_read_4k"
    ["rand-read-32k"]="rand_read_32k"
    ["rand-read-256k"]="rand_read_256k"
)

declare -A TEST_TYPES=(
    ["seq-write-256k"]="write"
    ["rand-write-4k"]="write"
    ["rand-write-32k"]="write"
    ["rand-write-256k"]="write"
    ["seq-read-256k"]="read"
    ["rand-read-4k"]="read"
    ["rand-read-32k"]="read"
    ["rand-read-256k"]="read"
)

# Disk types to test
DISK_TYPES=("sworndisk" "cryptdisk")

# Test file paths on mounted filesystems
declare -A TEST_FILE_PATHS
TEST_FILE_PATHS["sworndisk"]="/home/yxy/ssd/fast26_ae/sev/data/sworndisk-fio-test"
TEST_FILE_PATHS["cryptdisk"]="/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-fio-test"

function check_fio() {
    if ! command -v fio &> /dev/null; then
        echo -e "${RED}Error: fio not found. Please install fio first.${NC}"
        echo "  sudo apt install -y fio"
        exit 1
    fi
    echo -e "${GREEN}Found fio: $(fio --version)${NC}"
}

function check_path() {
    local path=$1
    local parent_dir=$(dirname "$path")

    if [ ! -d "$parent_dir" ]; then
        echo -e "${RED}Error: Directory $parent_dir not found${NC}"
        echo -e "${YELLOW}Please ensure the filesystem is mounted at $parent_dir${NC}"
        return 1
    fi

    if [ ! -w "$parent_dir" ]; then
        echo -e "${RED}Error: Directory $parent_dir is not writable${NC}"
        return 1
    fi

    echo -e "${GREEN}Path $parent_dir is accessible${NC}"
    return 0
}

function cleanup_file() {
    local test_file=$1
    echo -e "${YELLOW}Cleaning up test file ${test_file}...${NC}"
    rm -f "$test_file"
    sync
    echo -e "${GREEN}Cleanup complete${NC}"
}

function run_fio_section() {
    local disk_type=$1
    local section=$2
    local test_file=$3
    local output_file=$4
    local config=${5:-$FIO_CONFIG}

    echo -e "${GREEN}Running fio [${section}] on ${disk_type} (file: ${test_file})...${NC}"
    fio --filename="${test_file}" "${SCRIPT_DIR}/configs/${config}" --section="${section}" 2>&1 | tee "${output_file}"
}

function run_fio_all_sections() {
    local disk_type=$1
    local test_file=$2
    local config=$3
    local output_file=$4

    echo -e "${GREEN}Running all fio sections on ${disk_type} (file: ${test_file})...${NC}"
    fio --filename="${test_file}" "${SCRIPT_DIR}/configs/${config}" 2>&1 | tee "${output_file}"
}

function parse_single_result() {
    local output_file=$1
    local test_type=$2
    local metric_field

    if [ "$test_type" == "write" ]; then
        metric_field=$(grep "WRITE:" "${output_file}" | awk '{print $2}' || true)
    else
        metric_field=$(grep "READ:" "${output_file}" | awk '{print $2}' || true)
    fi

    # Extract number from bw=XXXMiB/s format
    local result=$(echo ${metric_field} | sed 's/bw=//;s/MiB.*//')

    # If result is empty, return 0
    if [ -z "$result" ]; then
        echo "0"
    else
        echo "$result"
    fi
}

function parse_read_results() {
    local output_file=$1
    local section=$2

    # Extract the specific section's read result from combined output
    local result=$(awk "/${section}:.*groupid/{found=1; next} found && /^[[:space:]]+read:/{print \$3; found=0}" "${output_file}" | head -1)
    local bw=$(echo ${result} | sed 's/BW=//;s/MiB.*//')

    # If bw is empty, return 0
    if [ -z "$bw" ]; then
        echo "0"
    else
        echo "$bw"
    fi
}

function main() {
    mkdir -p "${OUTPUT_DIR}"
    check_fio

    echo -e "\n${YELLOW}========== Starting FIO Benchmark ==========${NC}\n"

    local results=()

    for disk_type in "${DISK_TYPES[@]}"; do
        echo -e "\n${YELLOW}========== Testing ${disk_type} ==========${NC}\n"
        local test_file=${TEST_FILE_PATHS[$disk_type]}

        # Check if path is accessible
        if ! check_path "$test_file"; then
            echo -e "${RED}Skipping ${disk_type} - path not accessible${NC}"
            continue
        fi

        declare -A metrics=()

        # Write tests: clean up test file before each test
        for section in "${WRITE_TESTS[@]}"; do
            cleanup_file "$test_file"
            local output_file="${OUTPUT_DIR}/${disk_type}_${section}_output.txt"
            run_fio_section "$disk_type" "$section" "$test_file" "$output_file"
            metrics[${TEST_KEYS[$section]}]=$(parse_single_result "$output_file" "${TEST_TYPES[$section]}")
            echo -e "${GREEN}${section}: ${metrics[${TEST_KEYS[$section]}]} MiB/s${NC}"
        done

        # Read tests: prepare data once, then run all read tests
        cleanup_file "$test_file"
        local read_output_file="${OUTPUT_DIR}/${disk_type}_read_output.txt"
        run_fio_all_sections "$disk_type" "$test_file" "reproduce-read.fio" "$read_output_file"

        # Parse results for each read test from combined output
        for section in "${READ_TESTS[@]}"; do
            metrics[${TEST_KEYS[$section]}]=$(parse_read_results "$read_output_file" "$section")
            echo -e "${GREEN}${section}: ${metrics[${TEST_KEYS[$section]}]} MiB/s${NC}"
        done

        # Cleanup after all tests
        cleanup_file "$test_file"

        results+=("{\"disk_type\":\"${disk_type}\",\"seq_write_256k\":${metrics[seq_write_256k]:-0},\"rand_write_4k\":${metrics[rand_write_4k]:-0},\"rand_write_32k\":${metrics[rand_write_32k]:-0},\"rand_write_256k\":${metrics[rand_write_256k]:-0},\"seq_read_256k\":${metrics[seq_read_256k]:-0},\"rand_read_4k\":${metrics[rand_read_4k]:-0},\"rand_read_32k\":${metrics[rand_read_32k]:-0},\"rand_read_256k\":${metrics[rand_read_256k]:-0}}")
    done

    # Generate final JSON
    echo "[" > "${RESULT_JSON}"
    for i in "${!results[@]}"; do
        if [ $i -gt 0 ]; then echo "," >> "${RESULT_JSON}"; fi
        echo "  ${results[$i]}" >> "${RESULT_JSON}"
    done
    echo "]" >> "${RESULT_JSON}"

    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}Benchmark complete!${NC}"
    echo -e "${GREEN}Results saved to ${RESULT_JSON}${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    cat "${RESULT_JSON}"

    echo -e "\n${YELLOW}To plot results, run:${NC}"
    echo -e "  python3 plot_result.py"
}

main "$@"

