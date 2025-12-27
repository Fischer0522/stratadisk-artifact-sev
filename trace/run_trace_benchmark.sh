#!/bin/bash
set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OUTPUT_DIR="${SCRIPT_DIR}/benchmark_results"
TRACE_DIR="${SCRIPT_DIR}/msr-test"

# Trace datasets (only the 0-variants)
TRACES=("hm_0" "mds_0" "prn_0" "wdev_0" "web_0")

# Disk types to test
DISK_TYPES=("sworndisk" "cryptdisk")

# File paths in data directory
declare -A FILE_PATHS
FILE_PATHS["sworndisk"]="/home/yxy/ssd/fast26_ae/sev/data/sworndisk-diskfile"
FILE_PATHS["cryptdisk"]="/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-diskfile"

function check_compiler() {
    if ! command -v g++ &> /dev/null; then
        echo -e "${RED}Error: g++ not found. Please install g++ first.${NC}"
        echo "  sudo apt install -y build-essential"
        exit 1
    fi
    echo -e "${GREEN}Found g++: $(g++ --version | head -1)${NC}"
}

function check_trace_data() {
    if [ ! -d "$TRACE_DIR" ]; then
        echo -e "${YELLOW}Trace data not found at $TRACE_DIR${NC}"
        echo -e "${RED}Please download trace data or copy msr-test directory to ${SCRIPT_DIR}${NC}"
        exit 1
    fi

    # Verify trace files exist
    for trace in "${TRACES[@]}"; do
        if [ ! -f "${TRACE_DIR}/${trace}.csv" ]; then
            echo -e "${RED}Error: Trace file ${trace}.csv not found in ${TRACE_DIR}${NC}"
            exit 1
        fi
    done

    echo -e "${GREEN}All trace files found${NC}"
}

function compile_trace() {
    echo -e "${YELLOW}Compiling trace program...${NC}"
    cd "${SCRIPT_DIR}"
    g++ trace.cpp -std=c++11 -o trace
    echo -e "${GREEN}Compilation successful${NC}"
}

function check_filesystem() {
    local disk_type=$1
    local file_path=${FILE_PATHS[$disk_type]}
    local parent_dir=$(dirname "$file_path")

    if [ ! -d "$parent_dir" ]; then
        echo -e "${RED}Error: Directory $parent_dir not found${NC}"
        echo -e "${YELLOW}Please ensure the filesystem is mounted at $parent_dir${NC}"
        return 1
    fi

    if [ ! -w "$parent_dir" ]; then
        echo -e "${RED}Error: Directory $parent_dir is not writable${NC}"
        return 1
    fi

    echo -e "${GREEN}Filesystem at $parent_dir is accessible${NC}"
    return 0
}

function cleanup_diskfile() {
    local file_path=$1
    echo -e "${YELLOW}Cleaning up disk file ${file_path}...${NC}"
    rm -f "$file_path"
    sync
    echo -e "${GREEN}Cleanup complete${NC}"
}

function run_trace_test() {
    local disk_type=$1
    local trace_file=$2
    local file_path=${FILE_PATHS[$disk_type]}
    local output_file="${OUTPUT_DIR}/${trace_file}_${disk_type}_output.txt"

    echo -e "${GREEN}Running trace [${trace_file}] on ${disk_type}...${NC}"
    echo -e "${GREEN}File path: ${file_path}${NC}"
    echo -e "${GREEN}Trace file: ${TRACE_DIR}/${trace_file}.csv${NC}"

    # Run the trace program
    "${SCRIPT_DIR}/trace" "${file_path}" "${TRACE_DIR}/${trace_file}.csv" 2>&1 | tee "${output_file}"
}

function parse_results() {
    local trace_file=$1
    local disk_type=$2
    local output_file="${OUTPUT_DIR}/${trace_file}_${disk_type}_output.txt"

    local bandwidth=$(grep "^Bandwidth:" "${output_file}" 2>/dev/null | awk '{print $2}' | sed 's/MiB\/s//')

    echo "{\"trace\":\"${trace_file}\",\"disk_type\":\"${disk_type}\",\"bandwidth_mb_s\":${bandwidth:-0}}"
}

function main() {
    mkdir -p "${OUTPUT_DIR}"

    check_compiler
    check_trace_data
    compile_trace

    echo -e "\n${YELLOW}========== Starting Trace Benchmark ==========${NC}\n"

    RESULT_JSON="${OUTPUT_DIR}/result.json"
    all_results=()

    # Iterate disks, then traces
    # For sworndisk and cryptdisk, clean up before each trace run
    for disk_type in "${DISK_TYPES[@]}"; do
        echo -e "\n${YELLOW}===== Testing ${disk_type} =====${NC}\n"

        local file_path=${FILE_PATHS[$disk_type]}

        # Check if filesystem is accessible
        if ! check_filesystem "$disk_type"; then
            echo -e "${RED}Skipping ${disk_type} - filesystem not accessible${NC}"
            continue
        fi

        for trace_file in "${TRACES[@]}"; do
            echo -e "\n${YELLOW}========== Testing ${trace_file} on ${disk_type} ==========${NC}\n"

            # Clean up before each test
            cleanup_diskfile "$file_path"

            # Run trace test
            run_trace_test "$disk_type" "$trace_file"

            # Parse and store results
            all_results+=("$(parse_results "$trace_file" "$disk_type")")

            # Clean up after test
            cleanup_diskfile "$file_path"
        done
    done

    # Generate JSON output
    echo "[" > "${RESULT_JSON}"
    printf '%s\n' "${all_results[@]}" | sed 's/$/,/' | sed '$ s/,$//' >> "${RESULT_JSON}"
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
