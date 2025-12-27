# Trace Replay Benchmark for SEV

This directory contains scripts to benchmark SwornDisk and CryptDisk using MSR Cambridge traces on the data directory.

## Overview

The benchmark replays real-world I/O traces from Microsoft Research Cambridge datasets on:
- **SwornDisk**: `/home/yxy/ssd/fast26_ae/sev/data/sworndisk-diskfile`
- **CryptDisk**: `/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-diskfile`

## Trace Datasets

Five trace datasets are tested (0-variants):
- **hm_0**: Home directories
- **mds_0**: Media server
- **prn_0**: Print server
- **wdev_0**: Web development
- **web_0**: Web server

Each trace contains real I/O operations (reads/writes) with timestamps, offsets, and sizes.

## Prerequisites

1. Install build tools:
   ```bash
   sudo apt install -y build-essential g++
   ```

2. Install Python dependencies for plotting:
   ```bash
   sudo apt install -y python3-matplotlib python3-numpy
   ```

3. Ensure the data directory exists and is writable:
   ```bash
   mkdir -p /home/yxy/ssd/fast26_ae/sev/data
   ```

4. Trace data files:
   The script will automatically copy trace files from `/home/yxy/ssd/fast26_ae/occlum/eval/trace/msr-test` if they exist. Otherwise, you need to place the `msr-test` directory containing `*.csv` trace files in this directory.

## How It Works

### Trace Program (trace.cpp)

The C++ program:
1. **Phase 1**: Parses the trace file and collects all I/O operations
2. **Phase 2**: Warmup - for SwornDisk, pre-writes blocks that will be read but never written (avoids reading uninitialized data)
3. **Phase 3**: Replays the trace, performing reads/writes as specified
4. **Output**: Reports bandwidth (MiB/s)

### Test Script (run_trace_benchmark.sh)

The script:
1. Checks for compiler and trace data
2. Compiles the trace program
3. For each disk type and trace:
   - Cleans up any existing disk file
   - Runs the trace program
   - Parses bandwidth results
   - Cleans up after test
4. Generates `benchmark_results/result.json`

## Usage

### Run Benchmark

```bash
cd /home/yxy/ssd/fast26_ae/sev/trace
./run_trace_benchmark.sh
```

The script will:
1. Compile trace.cpp
2. Verify trace data files exist
3. Run all 5 traces on both disk types
4. Generate results in `benchmark_results/result.json`

**Note**: Each trace test creates a large file (up to 50GB) on the target filesystem. Make sure you have enough space.

### Plot Results

After the benchmark completes:

```bash
python3 plot_result.py
```

Or with custom paths:

```bash
python3 plot_result.py --input benchmark_results/result.json --output result.png
```

The chart will be saved as `result.png` showing throughput for all traces and an average.

## Output

### JSON Results

The benchmark generates `benchmark_results/result.json`:

```json
[
  {
    "trace": "hm_0",
    "disk_type": "sworndisk",
    "bandwidth_mb_s": 125.4
  },
  {
    "trace": "hm_0",
    "disk_type": "cryptdisk",
    "bandwidth_mb_s": 118.2
  },
  ...
]
```

All bandwidth values are in MiB/s.

### Chart

The plot script generates a bar chart with:
- X-axis: Trace names (hm, mds, prn, wdev, web, avg)
- Y-axis: Throughput (MB/s)
- Two bars per trace: CryptDisk (red) and SwornDisk (blue)

## File Structure

```
trace/
├── trace.cpp                  # C++ trace replay program
├── run_trace_benchmark.sh     # Main benchmark script
├── plot_result.py             # Plotting script
├── msr-test/                  # Trace data files (*.csv)
├── benchmark_results/
│   ├── result.json            # Benchmark results
│   └── *_output.txt           # Raw program output logs
└── README.md                  # This file
```

## Notes

- Tests run on the data directory with regular files
- Test files: `/home/yxy/ssd/fast26_ae/sev/data/sworndisk-diskfile` and `/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-diskfile`
- Files are cleaned up before and after each test
- SwornDisk includes a warmup phase to initialize unwritten blocks
- CryptDisk skips warmup (standard filesystem behavior)
- Test duration depends on trace size (typically 5-30 minutes per trace)
- Disk file size: up to 50GB (sparse file, actual usage depends on trace)

## Customization

To change file paths, edit `run_trace_benchmark.sh` lines 21-22:

```bash
FILE_PATHS["sworndisk"]="/home/yxy/ssd/fast26_ae/sev/data/sworndisk-diskfile"
FILE_PATHS["cryptdisk"]="/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-diskfile"
```

To test different trace variants or add new traces, edit line 11:

```bash
TRACES=("hm_0" "mds_0" "prn_0" "wdev_0" "web_0")
```

## Troubleshooting

### Compilation Errors

If compilation fails:
```bash
g++ --version  # Check g++ is installed
sudo apt install -y build-essential
```

### Trace Files Not Found

If trace files are missing:
```bash
# Copy from occlum eval directory
cp -r /home/yxy/ssd/fast26_ae/occlum/eval/trace/msr-test /home/yxy/ssd/fast26_ae/sev/trace/
```

### Data Directory Not Found

Ensure the data directory exists and is writable:
```bash
mkdir -p /home/yxy/ssd/fast26_ae/sev/data
ls -ld /home/yxy/ssd/fast26_ae/sev/data
```

Should show directory with write permissions.
