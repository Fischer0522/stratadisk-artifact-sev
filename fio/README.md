# FIO Benchmark for SEV

This directory contains scripts to benchmark SwornDisk and CryptDisk using FIO (Flexible I/O Tester) on the data directory.

## Overview

The benchmark tests filesystem performance by creating test files in the data directory, comparing:
- **SwornDisk**: `/home/yxy/ssd/fast26_ae/sev/data/sworndisk-fio-test`
- **CryptDisk**: `/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-fio-test`

## Test Configuration

### Write Tests
- Sequential Write (256KB blocks)
- Random Write (4KB, 32KB, 256KB blocks)

Each write test removes the test file before running to ensure clean state.

### Read Tests
- Sequential Read (256KB blocks)
- Random Read (4KB, 32KB, 256KB blocks)

Read tests prepare data once, then run all tests sequentially on the same data.

## Prerequisites

1. Install FIO:
   ```bash
   sudo apt install -y fio
   ```

2. Install Python dependencies for plotting:
   ```bash
   sudo apt install -y python3-matplotlib python3-numpy
   ```

3. Ensure the data directory exists and is writable:
   ```bash
   mkdir -p /home/yxy/ssd/fast26_ae/sev/data
   ```

## Usage

### Run Benchmark

```bash
cd /home/yxy/ssd/fast26_ae/sev/fio
./run_fio_benchmark.sh
```

The script will:
1. Check for FIO installation
2. Verify data directory exists and is writable
3. Run write tests (removing test file before each test)
4. Run read tests (preparing data once)
5. Generate results in `benchmark_results/result.json`

### Plot Results

After the benchmark completes:

```bash
python3 plot_result.py
```

Or with custom paths:

```bash
python3 plot_result.py --input benchmark_results/result.json --output result.png
```

The chart will be saved as `result.png` showing:
- (a) Writes in SEV
- (b) Reads in SEV

## Output

### JSON Results

The benchmark generates `benchmark_results/result.json`:

```json
[
  {
    "disk_type": "sworndisk",
    "seq_write_256k": 500.2,
    "rand_write_4k": 45.3,
    "rand_write_32k": 120.5,
    "rand_write_256k": 380.1,
    "seq_read_256k": 600.5,
    "rand_read_4k": 55.2,
    "rand_read_32k": 140.3,
    "rand_read_256k": 450.7
  },
  {
    "disk_type": "cryptdisk",
    ...
  }
]
```

All values are in MiB/s.

### Chart

The plot script generates a bar chart comparing SwornDisk and CryptDisk across all test cases.

## File Structure

```
fio/
├── configs/
│   ├── reproduce.fio          # Write test configuration
│   └── reproduce-read.fio     # Read test configuration
├── benchmark_results/
│   ├── result.json            # Benchmark results
│   └── *_output.txt           # Raw FIO output logs
├── run_fio_benchmark.sh       # Main benchmark script
├── plot_result.py             # Plotting script
└── README.md                  # This file
```

## Notes

- Tests run on the data directory, not raw block devices
- Test files: `/home/yxy/ssd/fast26_ae/sev/data/sworndisk-fio-test` and `/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-fio-test`
- Write tests clean up before each run to ensure fresh state
- Read tests reuse the same prepared data
- Tests run with `direct=1` to bypass page cache
- Default test duration: 10s for writes, 20s for reads
- Default test size: 40GB

## Customization

To adjust test parameters, edit `configs/reproduce.fio` and `configs/reproduce-read.fio`:
- `runtime`: Test duration in seconds
- `size`: File/device size
- `bs`: Block size
- `direct`: Direct I/O flag (1=bypass cache, 0=use cache)

To change file paths, edit `run_fio_benchmark.sh` line 46-47:
```bash
TEST_FILE_PATHS["sworndisk"]="/home/yxy/ssd/fast26_ae/sev/data/sworndisk-fio-test"
TEST_FILE_PATHS["cryptdisk"]="/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-fio-test"
```

