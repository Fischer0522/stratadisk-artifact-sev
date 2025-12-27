# Filebench Benchmark for SEV

This directory contains scripts to benchmark SwornDisk and CryptDisk using Filebench workloads on the data directory.

## Overview

Filebench is a file system and storage benchmark that can generate complex workloads. This benchmark tests:
- **SwornDisk**: `/home/yxy/ssd/fast26_ae/sev/data/sworndisk-filebench/`
- **CryptDisk**: `/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-filebench/`

## Workloads

Four Filebench workloads are tested:
- **fileserver**: File server workload (create, write, read, delete operations)
  - 10000 files, 16 threads, 60 seconds runtime
- **varmail**: Mail server workload (create, write, read, delete operations)
  - 8000 files, 16 threads, 60 seconds runtime
- **oltp**: OLTP database workload (random read/write)
  - 100 data files, 10 writers + 20 readers, 60 seconds runtime
- **videoserver**: Video server workload (read/write)
  - 35 video files (1GB each), 48 reader threads + 1 writer, 60 seconds runtime

## Prerequisites

1. Install Filebench (choose one method):

   **Method 1: From package manager (recommended for quick start)**
   ```bash
   sudo apt install -y filebench
   ```

   **Method 2: Build from source (for latest version)**
   ```bash
   cd /home/yxy/ssd/fast26_ae/sev/filebench
   ./download_and_build_filebench.sh
   ```

   This will:
   - Install build dependencies (bison, flex, libtool, automake)
   - Download Filebench 1.5-alpha3 source
   - Build and install to /usr/local/bin

2. Install Python dependencies for plotting:
   ```bash
   sudo apt install -y python3-matplotlib python3-numpy
   ```

3. Ensure the data directory exists and is writable:
   ```bash
   mkdir -p /home/yxy/ssd/fast26_ae/sev/data
   ```

## How It Works

### Workload Templates

Workload template files (in `workloads/`) contain Filebench configuration with a placeholder `$BENCHMARK_DIR$`. The test script replaces this with the actual test directory path for each disk type.

### Test Script (run_filebench_benchmark.sh)

The script:
1. Checks for Filebench installation
2. For each workload and disk type:
   - Generates a workload file with the correct path
   - Cleans up the test directory
   - Runs Filebench
   - Collects output
   - Cleans up after test
3. Parses results using `parse_filebench_results.sh`
4. Generates `benchmark_results/result.json`

### Parse Script (parse_filebench_results.sh)

Extracts metrics from Filebench output:
- Throughput (MB/s)
- Operations per second (ops/s)
- Latency (ms/op)

### Plot Script (plot_result.py)

Generates a bar chart comparing SwornDisk and CryptDisk across all workloads.

## Usage

### Run All Workloads

```bash
cd /home/yxy/ssd/fast26_ae/sev/filebench
./run_filebench_benchmark.sh
```

This will run all 4 workloads on both disk types (8 tests total).

### Run Single Workload

```bash
./run_filebench_benchmark.sh fileserver
./run_filebench_benchmark.sh oltp
./run_filebench_benchmark.sh varmail
./run_filebench_benchmark.sh videoserver
```

### Plot Results

After the benchmark completes:

```bash
python3 plot_result.py
```

Or with custom paths:

```bash
python3 plot_result.py --input benchmark_results/result.json --output result.png
```

The chart will be saved as `result.png`.

## Output

### JSON Results

The benchmark generates `benchmark_results/result.json`:

```json
[
  {
    "workload": "fileserver",
    "disk_type": "sworndisk",
    "throughput_mb_s": 165.0,
    "ops_per_s": 6845.3,
    "latency_ms": 7.8
  },
  {
    "workload": "fileserver",
    "disk_type": "cryptdisk",
    "throughput_mb_s": 158.2,
    "ops_per_s": 6512.1,
    "latency_ms": 8.2
  },
  ...
]
```

### Chart

The plot script generates a bar chart with:
- X-axis: Workload names (fileserver, varmail, oltp, videoserver)
- Y-axis: Throughput (MB/s)
- Two bars per workload: CryptDisk (red) and SwornDisk (blue)

## File Structure

```
filebench/
├── workloads/
│   ├── fileserver-template.f      # Fileserver workload template
│   ├── oltp-template.f             # OLTP workload template
│   ├── varmail-template.f          # Varmail workload template
│   ├── videoserver-template.f      # Videoserver workload template
│   └── *-{disk}.f                  # Generated workload files
├── benchmark_results/
│   ├── result.json                 # Parsed benchmark results
│   └── *_output.txt                # Raw Filebench output logs
├── run_filebench_benchmark.sh      # Main benchmark script
├── parse_filebench_results.sh      # Result parsing script
├── plot_result.py                  # Plotting script
├── download_and_build_filebench.sh # Build filebench from source
├── preinstall_deps.sh              # Install build dependencies
└── README.md                       # This file
```

## Notes

- Tests run on the data directory with regular directories
- Test directories are cleaned before and after each test
- Each workload runs for **60 seconds**
- **Multi-threaded** workloads (16-48 threads depending on workload)
- **File pre-allocation** enabled for most workloads
- Complex file operations including writewholefile, appendfilerand, fsync
- **Estimated test duration: ~5-10 minutes for all workloads**

## Customization

### Change Test Directory

Edit `run_filebench_benchmark.sh` lines 18-19:

```bash
TEST_DIRS["sworndisk"]="${DATA_DIR}/sworndisk-filebench"
TEST_DIRS["cryptdisk"]="${DATA_DIR}/cryptdisk-filebench"
```

### Modify Workload Parameters

Edit the template files in `workloads/`. For example, in `fileserver-template.f`:

```bash
set $nfiles=10000         # Number of files
set $nthreads=16          # Number of threads
set $filesize=128k        # File size
run 60                    # Runtime in seconds
```

**To reduce test intensity for faster testing:**
- Reduce file count: `set $nfiles=1000`
- Reduce threads: `set $nthreads=4`
- Reduce runtime: `run 20`

**To increase test intensity:**
- Increase file count: `set $nfiles=20000`
- Increase threads: `set $nthreads=32`
- Increase runtime: `run 120`

### Add New Workloads

1. Copy an existing template file
2. Modify parameters as needed
3. Add the workload name to `WORKLOADS` array in `run_filebench_benchmark.sh`

## Troubleshooting

### Filebench Not Found

If filebench is not installed:
```bash
sudo apt install -y filebench
```

### Permission Denied

Ensure the data directory is writable:
```bash
ls -ld /home/yxy/ssd/fast26_ae/sev/data
chmod 755 /home/yxy/ssd/fast26_ae/sev/data
```

### Filebench Crashes or Hangs

- Check if there's enough disk space (videoserver needs ~35GB+ per disk)
- Try reducing the number of files or threads in template files
- Try reducing prealloc percentage or removing it: `prealloc=50` or no prealloc parameter
- For videoserver, reduce file size: `set $filesize=128m` instead of 1g
- Check system logs: `dmesg | tail`

### No Results in JSON

Check the raw output files in `benchmark_results/*_output.txt` for errors. The parse script looks for "IO Summary" lines in the output.
