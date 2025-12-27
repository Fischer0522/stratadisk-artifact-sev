# PostgreSQL YCSB Testing for SwornDisk/CryptDisk

在 SwornDisk 和 CryptDisk 文件系统上运行 PostgreSQL YCSB 基准测试的完整解决方案。

## 📋 目录

- [概述](#概述)
- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [脚本说明](#脚本说明)
- [详细使用](#详细使用)
- [配置参数](#配置参数)
- [故障排查](#故障排查)

## 概述

本项目提供了两个脚本：

1. **`configure_postgres.sh`** - PostgreSQL 实例管理工具
   - 在指定目录初始化独立的 PostgreSQL 实例
   - 管理实例的启动、停止、状态查看
   - 初始化 YCSB 测试数据库

2. **`run_postgres_benchmark.sh`** - YCSB 基准测试工具
   - 在两个文件系统上运行 YCSB 测试（workload a, b, e, f）
   - 自动提取性能指标
   - 生成 JSON 格式的结果文件

## 前置要求

### 系统要求

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y postgresql postgresql-contrib
```

### 验证安装

```bash
psql --version
# 应该显示: psql (PostgreSQL) 14.x 或更高版本
```

### Go-YCSB

确保已构建 go-ycsb：

```bash
cd go-ycsb
make
```

## 快速开始

### 一键运行测试

```bash
# 1. 初始化并启动两个 PostgreSQL 实例
./configure_postgres.sh init sworndisk
./configure_postgres.sh start sworndisk
./configure_postgres.sh init-ycsb sworndisk

./configure_postgres.sh init cryptdisk
./configure_postgres.sh start cryptdisk
./configure_postgres.sh init-ycsb cryptdisk

# 2. 运行 YCSB 基准测试
./run_postgres_benchmark.sh

# 3. 查看结果
cat postgres_results.json
```

## 脚本说明

### configure_postgres.sh - PostgreSQL 实例管理

在指定目录初始化和管理独立的 PostgreSQL 实例，避免与系统 PostgreSQL 冲突。

**实例配置：**

| 实例 | 数据目录 | 端口 |
|------|---------|------|
| SwornDisk | `/home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres` | 5433 |
| CryptDisk | `/home/yxy/ssd/fast26_ae/sev/data/cryptdisk-postgres` | 5434 |

**命令：**

```bash
./configure_postgres.sh <command> <instance>
```

| 命令 | 说明 |
|------|------|
| `init <instance>` | 初始化新的 PostgreSQL 实例 |
| `start <instance>` | 启动实例 |
| `stop <instance>` | 停止实例 |
| `restart <instance>` | 重启实例 |
| `status [instance]` | 查看状态（默认显示所有） |
| `init-ycsb <instance>` | 初始化 YCSB 数据库 |
| `clean <instance>` | 删除实例数据（危险操作） |

### run_postgres_benchmark.sh - YCSB 基准测试

在两个 PostgreSQL 实例上运行 YCSB 测试并收集性能数据。

**测试配置：**

- **Workloads**: a, b, e, f
- **数据库**: test
- **用户**: root / root
- **输出**: `postgres_results.json`

## 详细使用

### 1. 初始化 PostgreSQL 实例

初始化会创建全新的数据库集群：

```bash
./configure_postgres.sh init sworndisk
```

**输出示例：**
```
========================================
Initializing PostgreSQL for SwornDisk
========================================

Data Directory: /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres
Port: 5433

[1/4] Creating data directory...
✓ Directory created

[2/4] Initializing database cluster...
✓ Database cluster initialized

[3/4] Configuring PostgreSQL...
✓ Configuration updated
  Port: 5433
  Socket: /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres/run

[4/4] Setting permissions...
✓ Permissions set

========================================
Initialization complete!
========================================

Next steps:
  1. Start the instance: ./configure_postgres.sh start sworndisk
  2. Initialize YCSB database: ./configure_postgres.sh init-ycsb sworndisk
```

### 2. 启动实例

```bash
./configure_postgres.sh start sworndisk
```

**输出示例：**
```
Starting PostgreSQL instance: SwornDisk
Data Directory: /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres
Port: 5433

✓ PostgreSQL started successfully (PID: 12345)

Connection info:
  Host: localhost
  Port: 5433
  Socket: /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres/run

Connect with:
  psql -h localhost -p 5433 -U yxy postgres

To initialize YCSB database:
  ./configure_postgres.sh init-ycsb sworndisk
```

### 3. 初始化 YCSB 数据库

创建测试所需的数据库和用户：

```bash
./configure_postgres.sh init-ycsb sworndisk
```

**执行的操作：**
- 创建用户 `root`（密码：`root`）
- 创建数据库 `test`（所有者：`root`）
- 授予权限

**输出示例：**
```
========================================
Initializing YCSB Database: SwornDisk
========================================

Creating YCSB database and user...

✓ YCSB database initialized successfully

Database Details:
  Database: test
  User: root
  Password: root
  Host: localhost
  Port: 5433

Connect with:
  psql -h localhost -p 5433 -U root -d test

YCSB connection string:
  postgresql://root:root@localhost:5433/test
```

### 4. 查看实例状态

```bash
# 查看所有实例
./configure_postgres.sh status

# 查看单个实例
./configure_postgres.sh status sworndisk
```

**输出示例：**
```
========================================
PostgreSQL Instance: SwornDisk
========================================

Data Directory: /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres
Port: 5433

PostgreSQL Version: 14

Status: Running
PID: 12345

Connection info:
  psql -h localhost -p 5433 -U yxy postgres

Disk Usage:
50M	/home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres
```

### 5. 运行 YCSB 基准测试

```bash
./run_postgres_benchmark.sh
```

**脚本流程：**
1. 检查两个 PostgreSQL 实例是否运行
2. 验证 YCSB 数据库是否已初始化
3. 对每个 workload：
   - 清理旧的测试表
   - 执行 load 阶段（加载数据）
   - 执行 run 阶段（运行测试）
   - 提取吞吐量
4. 生成 JSON 结果文件

**输出示例：**
```
========================================
PostgreSQL Benchmark - go-ycsb
========================================

Workloads to test: workloada workloadb workloade workloadf
Results will be saved to: postgres_results.json

Checking PostgreSQL instances...

✓ SwornDisk instance is ready (port 5433)
✓ CryptDisk instance is ready (port 5434)

========================================
Workload: workloada
========================================

----------------------------------------
Testing: SwornDisk - workloada
----------------------------------------

Cleaning up YCSB tables...
[1/2] Loading data...
[2/2] Running benchmark...

TOTAL  - Takes(s): 13.6, Count: 1000, OPS: 73.4, ...

...

========================================
All PostgreSQL benchmarks completed!
========================================

Tested workloads:
  - workloada
  - workloadb
  - workloade
  - workloadf

Results saved to: postgres_results.json
```

### 6. 查看结果

```bash
cat postgres_results.json
```

**结果格式：**
```json
{
  "benchmark": "PostgreSQL",
  "timestamp": "2025-12-27T11:00:00+00:00",
  "results": [
    {
      "workload": "workloada",
      "filesystem": "SwornDisk",
      "port": 5433,
      "throughput_ops_sec": 73.4
    },
    {
      "workload": "workloada",
      "filesystem": "CryptDisk",
      "port": 5434,
      "throughput_ops_sec": 75.2
    },
    ...
  ]
}
```

### 7. 停止实例

```bash
./configure_postgres.sh stop sworndisk
./configure_postgres.sh stop cryptdisk
```

### 8. 清理实例（可选）

⚠️ **警告：这会删除所有数据！**

```bash
./configure_postgres.sh clean sworndisk
```

## 配置参数

### configure_postgres.sh 配置

编辑脚本顶部的配置变量：

```bash
# 数据目录
DATA_DIR="/home/yxy/ssd/fast26_ae/sev/data"
SWORNDISK_DIR="${DATA_DIR}/sworndisk-postgres"
CRYPTDISK_DIR="${DATA_DIR}/cryptdisk-postgres"

# PostgreSQL 用户
POSTGRES_USER="postgres"

# 端口配置
SWORNDISK_PORT=5433
CRYPTDISK_PORT=5434
```

### run_postgres_benchmark.sh 配置

编辑脚本顶部的配置变量：

```bash
# PostgreSQL 连接参数
PG_USER="root"
PG_PASSWORD="root"
PG_DB="test"
PG_HOST="localhost"

# Workloads 列表
WORKLOADS=("workloada" "workloadb" "workloade" "workloadf")
```

## 故障排查

### 问题 1: PostgreSQL 未安装

**错误：**
```
Error: PostgreSQL is not installed
```

**解决方法：**
```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
```

### 问题 2: 实例未启动

**错误：**
```
Error: SwornDisk PostgreSQL instance is not running
```

**解决方法：**
```bash
# 检查状态
./configure_postgres.sh status sworndisk

# 启动实例
./configure_postgres.sh start sworndisk

# 查看日志
tail -f /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres/postgresql.log
```

### 问题 3: YCSB 数据库未初始化

**错误：**
```
Error: YCSB database not initialized on SwornDisk
```

**解决方法：**
```bash
./configure_postgres.sh init-ycsb sworndisk
```

### 问题 4: 端口冲突

**错误：**
```
could not bind IPv4 address "0.0.0.0": Address already in use
```

**解决方法：**
```bash
# 检查端口占用
sudo lsof -i :5433

# 修改脚本中的端口配置
# 或停止占用该端口的进程
```

### 问题 5: 权限问题

**错误：**
```
could not open file "...": Permission denied
```

**解决方法：**
```bash
# 以 root 权限运行（如果需要）
sudo ./configure_postgres.sh init sworndisk

# 或修复目录权限
sudo chown -R postgres:postgres /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres
sudo chmod 700 /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres
```

### 问题 6: 实例无法启动

**调试步骤：**

```bash
# 1. 查看状态
./configure_postgres.sh status sworndisk

# 2. 检查日志
tail -100 /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres/postgresql.log

# 3. 手动尝试启动
/usr/lib/postgresql/14/bin/pg_ctl \
    -D /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres \
    start

# 4. 检查配置文件
cat /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres/postgresql.conf | grep -v '^#' | grep -v '^$'
```

### 问题 7: 连接被拒绝

**错误：**
```
psql: error: connection to server at "localhost" (::1), port 5433 failed: Connection refused
```

**解决方法：**
```bash
# 检查实例是否运行
./configure_postgres.sh status sworndisk

# 检查防火墙
sudo ufw status

# 测试连接
telnet localhost 5433
```

## 手动连接测试

### 使用 psql 连接

```bash
# 连接到 SwornDisk 实例
psql -h localhost -p 5433 -U root -d test

# 连接到 CryptDisk 实例
psql -h localhost -p 5434 -U root -d test
```

### 常用 SQL 命令

```sql
-- 查看数据库列表
\l

-- 查看表
\dt

-- 查看表结构
\d usertable

-- 查看表数据量
SELECT count(*) FROM usertable;

-- 删除测试表
DROP TABLE IF EXISTS usertable;

-- 退出
\q
```

## 目录结构

```
/home/yxy/ssd/fast26_ae/sev/data/
├── sworndisk-postgres/          # SwornDisk PostgreSQL 实例
│   ├── base/                    # 数据库文件
│   ├── pg_wal/                  # WAL 日志
│   ├── postgresql.conf          # 配置文件
│   ├── postgresql.log           # 运行日志
│   ├── postmaster.pid           # PID 文件
│   └── run/                     # Unix socket 目录
└── cryptdisk-postgres/          # CryptDisk PostgreSQL 实例
    └── (同上结构)
```

## 性能优化建议

### PostgreSQL 配置优化

编辑实例的 `postgresql.conf`：

```bash
# SwornDisk 实例
vi /home/yxy/ssd/fast26_ae/sev/data/sworndisk-postgres/postgresql.conf
```

推荐修改：

```conf
# 内存配置
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL 配置
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 1GB

# 查询优化
random_page_cost = 1.1
effective_io_concurrency = 200
```

修改后重启：

```bash
./configure_postgres.sh restart sworndisk
```

### YCSB 工作负载调优

编辑 workload 文件：

```bash
vi go-ycsb/workloads/workloada
```

```properties
# 增加数据量
recordcount=100000
operationcount=100000

# 调整字段配置
fieldcount=10
fieldlength=100
```

## 参考资料

- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [YCSB 项目](https://github.com/brianfrankcooper/YCSB)
- [go-ycsb](https://github.com/pingcap/go-ycsb)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

## 相关脚本

- `configure_postgres.sh` - PostgreSQL 实例管理
- `run_postgres_benchmark.sh` - YCSB 基准测试
- `run_boltdb_benchmark.sh` - BoltDB 基准测试
- `run_sqlite_benchmark.sh` - SQLite 基准测试
- `run_rocksdb_benchmark.sh` - RocksDB 基准测试
