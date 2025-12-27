# cpp-ycsb 快速开始指南

## 🎯 一键配置（推荐）

```bash
cd /home/yxy/ssd/fast26_ae/sev/ycsb/cpp-ycsb
./setup.sh
```

**setup.sh 会自动完成：**
- ✅ 安装构建工具（cmake, g++, pkg-config）
- ✅ 安装压缩库（snappy, lz4, zstd, bz2, zlib）
- ✅ 安装 RocksDB（可选包管理器或源码）
- ✅ 编译 cpp-ycsb

**预计时间：** 2-3 分钟（使用包管理器）或 15-20 分钟（源码编译 RocksDB）

---

## 🚀 快速测试

### 基础测试

```bash
# 加载数据
./bin/ycsb load -P workloads/workloada -db /tmp/test-db

# 运行基准测试
./bin/ycsb run -P workloads/workloada -db /tmp/test-db
```

### 测试 SwornDisk 和 CryptDisk

```bash
# 自动测试两个文件系统
./run_benchmark.sh workloads/workloada
```

---

## 📊 工作负载说明

| 工作负载 | 读 | 更新 | 插入 | 扫描 | 场景 |
|---------|---|-----|-----|------|------|
| **workloada** | 50% | 50% | - | - | 会话存储 |
| **workloadb** | 95% | 5% | - | - | 照片标签 |
| **workloadc** | 100% | - | - | - | 用户配置缓存 |
| **workloadd** | 95% | - | 5% | - | 用户状态更新 |
| **workloade** | - | - | 5% | 95% | 线程对话 |

---

## 🛠️ 自定义测试

### 修改工作负载参数

编辑 `workloads/workloada`：

```properties
recordcount=100000      # 记录数量（默认 10000）
operationcount=100000   # 操作次数（默认 10000）
fieldcount=10           # 每条记录的字段数
fieldlength=100         # 每个字段的字节数

readproportion=0.5      # 读操作比例
updateproportion=0.5    # 更新操作比例
```

### 测试不同的数据库路径

```bash
# SwornDisk
./bin/ycsb load -P workloads/workloada \
  -db /home/yxy/ssd/fast26_ae/sev/data/sworndisk-ycsb

./bin/ycsb run -P workloads/workloada \
  -db /home/yxy/ssd/fast26_ae/sev/data/sworndisk-ycsb

# CryptDisk
./bin/ycsb load -P workloads/workloada \
  -db /home/yxy/ssd/fast26_ae/sev/data/cryptdisk-ycsb

./bin/ycsb run -P workloads/workloada \
  -db /home/yxy/ssd/fast26_ae/sev/data/cryptdisk-ycsb
```

---

## 📈 性能指标

测试完成后会显示：

```
[READ] Operations: 5000
[READ] Throughput: 12500.00 ops/sec
[READ] Average Latency: 78.45 us
[READ] Min Latency: 12 us
[READ] Max Latency: 2345 us
[READ] P50 Latency: 65.00 us      ← 中位数延迟
[READ] P95 Latency: 145.00 us     ← 95% 请求的延迟
[READ] P99 Latency: 234.00 us     ← 99% 请求的延迟

[OVERALL] Throughput: 11111.11 ops/sec
Total time: 0.90 seconds
```

**关键指标：**
- **Throughput（吞吐量）**: 每秒操作数，越高越好
- **P50 Latency**: 一半请求的延迟，反映典型性能
- **P99 Latency**: 99% 请求的延迟，反映尾延迟

---

## ❓ 常见问题

### 问题 1: setup.sh 失败

```bash
# 清理并重试
rm -rf build bin
./setup.sh
```

### 问题 2: 找不到 RocksDB

```bash
# 检查安装
ldconfig -p | grep rocksdb

# 如果没有输出，重新安装
./install_rocksdb.sh
```

### 问题 3: 编译错误

```bash
# 安装所有依赖
sudo apt install -y \
    build-essential \
    cmake \
    pkg-config \
    librocksdb-dev \
    libsnappy-dev \
    liblz4-dev \
    libzstd-dev \
    libbz2-dev \
    zlib1g-dev

# 重新构建
rm -rf build
./build.sh
```

### 问题 4: 运行时错误

```bash
# 确保数据库目录存在且可写
mkdir -p /tmp/test-db
chmod 755 /tmp/test-db

# 清空旧数据重新测试
rm -rf /tmp/test-db/*
./bin/ycsb load -P workloads/workloada -db /tmp/test-db
```

---

## 📝 完整示例

```bash
# 1. 配置环境
cd /home/yxy/ssd/fast26_ae/sev/ycsb/cpp-ycsb
./setup.sh

# 2. 快速测试
./bin/ycsb load -P workloads/workloada -db /tmp/quick-test
./bin/ycsb run -P workloads/workloada -db /tmp/quick-test

# 3. 完整测试（所有工作负载）
for workload in workloads/workload{a,b,c,d,e}; do
    echo "Testing $workload..."
    ./bin/ycsb load -P $workload -db /tmp/ycsb-test
    ./bin/ycsb run -P $workload -db /tmp/ycsb-test
    rm -rf /tmp/ycsb-test
done

# 4. 对比测试 SwornDisk vs CryptDisk
./run_benchmark.sh workloads/workloada
```

---

## 📚 更多信息

- 详细文档: [README.md](README.md)
- 源码结构: [src/](src/) 和 [include/](include/)
- 工作负载配置: [workloads/](workloads/)

---

## 💡 提示

1. **首次使用建议使用小数据量测试**（默认配置即可）
2. **测试不同文件系统时**记得每次清空数据库目录
3. **P99 延迟**比平均延迟更能反映用户体验
4. **生产环境建议使用更大的数据量**（recordcount >= 100000）
