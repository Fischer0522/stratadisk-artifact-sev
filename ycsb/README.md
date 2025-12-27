# YCSB Benchmark Setup

本目录包含 YCSB (Yahoo Cloud Serving Benchmark) 相关工具的设置和构建脚本。

## 项目说明

- **go-ycsb**: YCSB 的 Go 语言实现，用于测试 BoltDB、SQLite、PostgreSQL 等
- **cpp-ycsb**: 简化的 C++ YCSB 实现，专门用于测试 RocksDB

## 快速开始

### 1. 安装依赖

运行 setup 脚本安装所有必要的依赖并克隆代码仓库：

```bash
cd /home/yxy/ssd/fast26_ae/sev/ycsb
./setup.sh
```

这将安装：
- Go 1.22.0（使用国内镜像源）
- PostgreSQL
- SQLite3

并克隆：
- go-ycsb (feat/sworndisk 分支)

### 2. 构建项目

#### 构建 go-ycsb

```bash
./build.sh
```

或手动构建：

```bash
cd go-ycsb
make
```

#### 构建 cpp-ycsb (用于 RocksDB)

```bash
cd cpp-ycsb
./setup.sh
```

## 数据库测试脚本

本项目提供了针对不同数据库的一键测试脚本：

### BoltDB 测试

```bash
./run_boltdb_benchmark.sh
```

测试 workload a, b, e, f，结果保存到 `boltdb_results.json`

### SQLite 测试

```bash
./run_sqlite_benchmark.sh
```

测试 workload a, b, e, f，结果保存到 `sqlite_results.json`

### PostgreSQL 测试

```bash
# 1. 配置 PostgreSQL 实例
./configure_postgres.sh init sworndisk
./configure_postgres.sh start sworndisk
./configure_postgres.sh init-ycsb sworndisk

./configure_postgres.sh init cryptdisk
./configure_postgres.sh start cryptdisk
./configure_postgres.sh init-ycsb cryptdisk

# 2. 运行测试
./run_postgres_benchmark.sh
```

结果保存到 `postgres_results.json`。详见 [POSTGRES_README.md](POSTGRES_README.md)

### RocksDB 测试

```bash
./run_rocksdb_benchmark.sh
```

测试 workload a, b, e, f，结果保存到 `rocksdb_results.json`

## 使用方法

### go-ycsb

```bash
# 查看帮助
./go-ycsb/bin/go-ycsb --help

# BoltDB
./go-ycsb/bin/go-ycsb load boltdb -P go-ycsb/workloads/workloada \
  -p bolt.path=/path/to/database.db

./go-ycsb/bin/go-ycsb run boltdb -P go-ycsb/workloads/workloada \
  -p bolt.path=/path/to/database.db

# SQLite
./go-ycsb/bin/go-ycsb load sqlite -P go-ycsb/workloads/workloada \
  -p sqlite.db=/path/to/database.db

./go-ycsb/bin/go-ycsb run sqlite -P go-ycsb/workloads/workloada \
  -p sqlite.db=/path/to/database.db

# PostgreSQL
./go-ycsb/bin/go-ycsb load pg -P go-ycsb/workloads/workloada \
  -p pg.host=localhost -p pg.port=5433 \
  -p pg.user=root -p pg.password=root -p pg.db=test

./go-ycsb/bin/go-ycsb run pg -P go-ycsb/workloads/workloada \
  -p pg.host=localhost -p pg.port=5433 \
  -p pg.user=root -p pg.password=root -p pg.db=test
```

### cpp-ycsb (RocksDB)

```bash
# 加载数据
./cpp-ycsb/bin/ycsb load -P cpp-ycsb/workloads/workloada -db /tmp/testdb

# 运行测试
./cpp-ycsb/bin/ycsb run -P cpp-ycsb/workloads/workloada -db /tmp/testdb

# 或使用自动化脚本测试 SwornDisk 和 CryptDisk
./run_rocksdb_benchmark.sh
```

详见 [cpp-ycsb/README.md](cpp-ycsb/README.md)

## 支持的数据库

### go-ycsb
- BoltDB (嵌入式 KV 数据库)
- SQLite (嵌入式关系数据库)
- PostgreSQL / CockroachDB
- MySQL / TiDB
- MongoDB
- Redis
- Cassandra

### cpp-ycsb
- RocksDB (嵌入式 LSM 数据库)

## 工作负载

标准 YCSB 工作负载配置文件位于：
- go-ycsb: `./go-ycsb/workloads/`
- cpp-ycsb: `./cpp-ycsb/workloads/`

默认工作负载：
- **workloada**: Update heavy (50% read, 50% update)
- **workloadb**: Read mostly (95% read, 5% update)
- **workloadc**: Read only (100% read)
- **workloadd**: Read latest (95% read, 5% insert)
- **workloade**: Scan short ranges (95% scan, 5% insert)
- **workloadf**: Read-modify-write (50% read, 50% read-modify-write)

## 脚本说明

### setup.sh
- 安装所有必要的依赖（Go, PostgreSQL, SQLite）
- 克隆 go-ycsb 代码仓库
- 配置 Go 环境变量和代理

### build.sh
- 检查依赖是否已安装
- 构建 go-ycsb（使用 make）

### configure_postgres.sh
- PostgreSQL 实例管理工具
- 在 SwornDisk/CryptDisk 上初始化独立的 PostgreSQL 实例
- 管理实例的启动、停止、状态查看
- 初始化 YCSB 测试数据库

### run_*_benchmark.sh
- 自动化测试脚本，用于不同数据库
- 在 SwornDisk 和 CryptDisk 上运行测试
- 提取性能数据并保存为 JSON 格式

## 目录结构

```
ycsb/
├── setup.sh                    # 环境配置脚本
├── build.sh                    # go-ycsb 构建脚本
├── configure_postgres.sh       # PostgreSQL 实例管理
├── run_boltdb_benchmark.sh     # BoltDB 测试脚本
├── run_sqlite_benchmark.sh     # SQLite 测试脚本
├── run_postgres_benchmark.sh   # PostgreSQL 测试脚本
├── run_rocksdb_benchmark.sh    # RocksDB 测试脚本
├── README.md                   # 本文件
├── POSTGRES_README.md          # PostgreSQL 详细文档
├── go-ycsb/                    # go-ycsb 源码（克隆后）
│   ├── bin/go-ycsb             # 编译后的二进制文件
│   └── workloads/              # 工作负载配置
└── cpp-ycsb/                   # C++ YCSB 实现（用于 RocksDB）
    ├── bin/ycsb                # 编译后的二进制文件
    ├── src/                    # 源代码
    ├── include/                # 头文件
    ├── workloads/              # 工作负载配置
    ├── build.sh                # 构建脚本
    ├── setup.sh                # 一键配置脚本
    └── README.md               # cpp-ycsb 文档
```

## 测试结果

所有测试脚本会生成 JSON 格式的结果文件：

- `boltdb_results.json` - BoltDB 测试结果
- `sqlite_results.json` - SQLite 测试结果
- `postgres_results.json` - PostgreSQL 测试结果
- `rocksdb_results.json` - RocksDB 测试结果

结果格式示例：

```json
{
  "benchmark": "BoltDB",
  "timestamp": "2025-12-27T...",
  "results": [
    {
      "workload": "workloada",
      "filesystem": "SwornDisk",
      "throughput_ops_sec": 73.4
    },
    ...
  ]
}
```

## 故障排查

### Go 环境变量未生效
```bash
source ~/.bashrc
```

### go-ycsb 构建失败
确保 Go 代理已设置：
```bash
go env -w GOPROXY=https://goproxy.cn,direct
```

### PostgreSQL 连接问题
检查实例是否运行：
```bash
./configure_postgres.sh status
```

详见 [POSTGRES_README.md](POSTGRES_README.md) 的故障排查章节。

### RocksDB 编译问题
确保已安装依赖：
```bash
cd cpp-ycsb
./setup.sh
```

详见 [cpp-ycsb/README.md](cpp-ycsb/README.md)

