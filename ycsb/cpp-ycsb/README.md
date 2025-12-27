# cpp-ycsb: C++ YCSB for RocksDB

A simplified C++ implementation of YCSB (Yahoo Cloud Serving Benchmark) specifically designed for testing RocksDB performance.

## 🎯 一键开始

```bash
# 1. 一键配置环境
./setup.sh

# 2. 验证安装
./verify_install.sh

# 3. 运行测试
./bin/ycsb load -P workloads/workloada -db /tmp/test-db
./bin/ycsb run -P workloads/workloada -db /tmp/test-db
```

**📖 快速指南**: 查看 [QUICK_START.md](QUICK_START.md) 获取详细的快速开始指南。

---

## Features

- **Lightweight**: Pure C++ implementation with minimal dependencies
- **RocksDB optimized**: Direct integration with RocksDB C++ API
- **Standard YCSB workloads**: Supports workloads A-E
- **Detailed metrics**: Throughput, latency (avg, min, max, P50, P95, P99)
- **Simple interface**: Command-line tool similar to original YCSB

## Architecture

```
cpp-ycsb/
├── include/
│   ├── db.h              # Abstract database interface
│   ├── rocksdb_db.h      # RocksDB implementation
│   ├── workload.h        # Workload configuration and generator
│   └── statistics.h      # Performance statistics
├── src/
│   ├── main.cpp          # Main entry point
│   ├── rocksdb_db.cpp    # RocksDB implementation
│   └── workload.cpp      # Workload implementation
├── workloads/            # YCSB workload files
│   ├── workloada         # 50% read, 50% update
│   ├── workloadb         # 95% read, 5% update
│   ├── workloadc         # 100% read
│   ├── workloadd         # 95% read, 5% insert
│   └── workloade         # 95% scan, 5% insert
├── build.sh              # Build script
├── CMakeLists.txt        # CMake configuration
└── README.md             # This file
```

## Prerequisites

### 快速安装（推荐）

使用提供的 setup.sh 脚本一键配置所有依赖：

```bash
./setup.sh
```

### 手动安装依赖

如果需要手动安装，以下是详细步骤：

#### 构建工具
```bash
sudo apt update
sudo apt install -y build-essential cmake pkg-config
```

#### 压缩库（RocksDB 依赖）

```bash
sudo apt install -y \
    libsnappy-dev \
    liblz4-dev \
    libzstd-dev \
    libbz2-dev \
    zlib1g-dev \
    libgflags-dev
```

#### RocksDB

**选项 1: 从包管理器安装（推荐）**
```bash
sudo apt update
sudo apt install -y librocksdb-dev
```

**选项 2: 从源码编译**
```bash
# 使用提供的脚本
./install_rocksdb.sh

# 或手动编译
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
make shared_lib -j$(nproc)
sudo make install-shared
sudo ldconfig
```

## Building

```bash
cd /home/yxy/ssd/fast26_ae/sev/ycsb/cpp-ycsb
./build.sh
```

This will:
1. Check for RocksDB installation
2. Create build directory
3. Run CMake
4. Compile the project
5. Generate executable at `bin/ycsb`

## Usage

### Basic Usage

```bash
# Load data into database
./bin/ycsb load -P workloads/workloada -db /path/to/dbdir

# Run benchmark
./bin/ycsb run -P workloads/workloada -db /path/to/dbdir
```

### Command-line Options

```
Usage: ycsb <command> [options]

Commands:
  load    - Load data into database
  run     - Run benchmark workload

Options:
  -P <file>    Workload property file (required)
  -db <path>   RocksDB database path (default: /tmp/rocksdb-ycsb)
```

### Example: Running Workload A

```bash
# Create database directory
mkdir -p /tmp/testdb

# Load 10,000 records
./bin/ycsb load -P workloads/workloada -db /tmp/testdb

# Run 10,000 operations (50% read, 50% update)
./bin/ycsb run -P workloads/workloada -db /tmp/testdb
```

## Workloads

### Workload A: Update Heavy
- **Read**: 50%
- **Update**: 50%
- **Use case**: Session store recording recent actions

### Workload B: Read Mostly
- **Read**: 95%
- **Update**: 5%
- **Use case**: Photo tagging; add a tag is an update, but most operations are to read tags

### Workload C: Read Only
- **Read**: 100%
- **Use case**: User profile cache

### Workload D: Read Latest
- **Read**: 95%
- **Insert**: 5%
- **Use case**: User status updates; people want to read the latest

### Workload E: Scan
- **Scan**: 95%
- **Insert**: 5%
- **Use case**: Threaded conversations

## Workload Configuration

Each workload file supports the following properties:

```properties
# Number of records to load
recordcount=10000

# Number of operations to perform in run phase
operationcount=10000

# Number of fields per record
fieldcount=10

# Length of each field value (bytes)
fieldlength=100

# Operation proportions (must sum to 1.0)
readproportion=0.5
updateproportion=0.5
scanproportion=0
insertproportion=0

# Maximum number of records to scan
maxscanlength=100
```

## Output Metrics

The benchmark reports the following metrics for each operation type:

- **Operations**: Total number of operations
- **Throughput**: Operations per second
- **Average Latency**: Mean latency in microseconds
- **Min/Max Latency**: Minimum and maximum latency
- **P50/P95/P99**: 50th, 95th, and 99th percentile latency

Example output:
```
========================================
Run phase completed
========================================
[READ] Operations: 5000
[READ] Throughput: 12500.00 ops/sec
[READ] Average Latency: 78.45 us
[READ] Min Latency: 12 us
[READ] Max Latency: 2345 us
[READ] P50 Latency: 65.00 us
[READ] P95 Latency: 145.00 us
[READ] P99 Latency: 234.00 us

[UPDATE] Operations: 5000
[UPDATE] Throughput: 10000.00 ops/sec
[UPDATE] Average Latency: 95.23 us
...

[OVERALL] Throughput: 11111.11 ops/sec
Total time: 0.90 seconds
```

## Testing on Different Filesystems

To test RocksDB on different filesystems (e.g., SwornDisk, CryptDisk):

```bash
# Test on SwornDisk
./bin/ycsb load -P workloads/workloada -db /home/yxy/ssd/fast26_ae/sev/data/sworndisk-ycsb
./bin/ycsb run -P workloads/workloada -db /home/yxy/ssd/fast26_ae/sev/data/sworndisk-ycsb

# Test on CryptDisk
./bin/ycsb load -P workloads/workloada -db /home/yxy/ssd/fast26_ae/sev/data/cryptdisk-ycsb
./bin/ycsb run -P workloads/workloada -db /home/yxy/ssd/fast26_ae/sev/data/cryptdisk-ycsb
```

## Performance Tuning

### RocksDB Options

The implementation uses the following RocksDB settings (modifiable in `src/rocksdb_db.cpp`):

```cpp
options_.write_buffer_size = 64 * 1024 * 1024;        // 64MB
options_.max_write_buffer_number = 3;
options_.target_file_size_base = 64 * 1024 * 1024;
options_.max_bytes_for_level_base = 256 * 1024 * 1024;
```

### Workload Scaling

To increase workload intensity, edit the workload file:

```properties
recordcount=100000      # Increase from 10000
operationcount=100000   # Increase from 10000
```

## Troubleshooting

### 一键修复所有问题

如果遇到任何问题，重新运行 setup.sh 通常可以解决：

```bash
./setup.sh
```

### 具体问题排查

### RocksDB not found
```
Error: RocksDB not found in system libraries
```
**Solution**:
```bash
# 方法 1: 使用 setup 脚本
./setup.sh

# 方法 2: 手动安装
./install_rocksdb.sh

# 方法 3: 使用包管理器
sudo apt install -y librocksdb-dev
```

### Linker errors
```
undefined reference to `rocksdb::DB::Open(...)'
```
**Solution**: Make sure RocksDB shared library is installed and ldconfig is run:
```bash
sudo ldconfig
ldconfig -p | grep rocksdb
```

### Missing compression libraries
```
undefined reference to `LZ4_compress_default'
cannot find -lsnappy
```
**Solution**:
```bash
# 安装所有压缩库
sudo apt install -y \
    libsnappy-dev \
    liblz4-dev \
    libzstd-dev \
    libbz2-dev \
    zlib1g-dev

# 或运行 setup 脚本
./setup.sh
```

### CMake configuration errors
**Solution**: 确保安装了所有依赖后重新构建
```bash
rm -rf build
./build.sh
```

## Comparison with go-ycsb

| Feature | cpp-ycsb | go-ycsb |
|---------|----------|---------|
| Language | C++ | Go |
| Database Support | RocksDB only | 20+ databases |
| Performance | Native speed | Good |
| Binary Size | ~500KB | ~20MB |
| Dependencies | RocksDB | Go runtime + DB drivers |
| Workloads | A-E | A-F + custom |

## License

This is a simplified implementation for educational and benchmarking purposes. The original YCSB is licensed under Apache 2.0.

## References

- [YCSB Project](https://github.com/brianfrankcooper/YCSB)
- [go-ycsb](https://github.com/pingcap/go-ycsb)
- [RocksDB](https://rocksdb.org/)
- [YCSB Paper](https://dl.acm.org/doi/10.1145/1807128.1807152)
