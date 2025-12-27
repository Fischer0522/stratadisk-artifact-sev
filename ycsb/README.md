# YCSB Benchmark Setup

本目录包含 YCSB (Yahoo Cloud Serving Benchmark) 相关工具的设置和构建脚本。

## 项目说明

- **go-ycsb**: YCSB 的 Go 语言实现，支持多种数据库
- **YCSB**: YCSB 的官方 Java 实现
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
- Java 17
- Maven
- PostgreSQL
- SQLite3

并克隆：
- go-ycsb (feat/sworndisk 分支)
- YCSB (官方仓库)

### 2. 构建项目

运行 build 脚本编译 go-ycsb 和 YCSB：

```bash
./build.sh
```

构建完成后：
- **go-ycsb** 可执行文件: `./go-ycsb/bin/go-ycsb`
- **YCSB** 可执行文件: `./YCSB/bin/ycsb.sh`

## 使用方法

### go-ycsb

```bash
# 查看帮助
./go-ycsb/bin/go-ycsb --help

# 加载数据到 SQLite
./go-ycsb/bin/go-ycsb load sqlite -P workloads/workloada \
  -p sqlite.db=/path/to/database.db

# 运行测试
./go-ycsb/bin/go-ycsb run sqlite -P workloads/workloada \
  -p sqlite.db=/path/to/database.db
```

### YCSB

```bash
# 查看帮助
./YCSB/bin/ycsb.sh --help

# 加载数据（使用 basic 后端）
./YCSB/bin/ycsb.sh load basic -P workloads/workloada

# 运行测试
./YCSB/bin/ycsb.sh run basic -P workloads/workloada
```

## 支持的数据库

### go-ycsb
- SQLite
- PostgreSQL / CockroachDB
- MySQL / TiDB
- MongoDB
- Redis
- Cassandra
- 更多详见 `go-ycsb/README.md`

### YCSB
- Basic (内存)
- JDBC (通用 SQL 数据库)
- MongoDB
- Cassandra
- HBase
- Redis
- 更多详见 `YCSB/README.md`

## 工作负载

标准 YCSB 工作负载位于：
- go-ycsb: `./go-ycsb/workloads/`
- YCSB: `./YCSB/workloads/`

默认工作负载：
- **workloada**: Update heavy (50% read, 50% update)
- **workloadb**: Read mostly (95% read, 5% update)
- **workloadc**: Read only (100% read)
- **workloadd**: Read latest (95% read, 5% insert)
- **workloade**: Scan short ranges (95% scan, 5% insert)
- **workloadf**: Read-modify-write (50% read, 50% read-modify-write)

## 脚本说明

### setup.sh
- 安装所有必要的依赖（Go, Java, Maven, PostgreSQL, SQLite）
- 克隆 go-ycsb 和 YCSB 代码仓库
- 配置 Go 环境变量和代理

### build.sh
- 检查依赖是否已安装
- 构建 go-ycsb（使用 make）
- 构建 YCSB（使用 mvn clean package）
- 跳过测试以加快构建速度

## cpp-ycsb: C++ 实现用于 RocksDB

如果您只需要测试 RocksDB，推荐使用轻量级的 cpp-ycsb：

```bash
# 1. 安装 RocksDB（如果未安装）
cd cpp-ycsb
./install_rocksdb.sh

# 2. 构建 cpp-ycsb
./build.sh

# 3. 运行测试
./bin/ycsb load -P workloads/workloada -db /tmp/testdb
./bin/ycsb run -P workloads/workloada -db /tmp/testdb

# 或使用自动化脚本测试 SwornDisk 和 CryptDisk
./run_benchmark.sh workloads/workloada
```

详见 [cpp-ycsb/README.md](cpp-ycsb/README.md)

## 目录结构

```
ycsb/
├── setup.sh              # 环境配置脚本
├── build.sh              # 构建脚本
├── README.md             # 本文件
├── go-ycsb/              # go-ycsb 源码（克隆后）
│   ├── bin/go-ycsb       # 编译后的二进制文件
│   └── workloads/        # 工作负载配置
├── YCSB/                 # YCSB 源码（克隆后）
│   ├── bin/ycsb.sh       # 启动脚本
│   └── workloads/        # 工作负载配置
└── cpp-ycsb/             # C++ YCSB 实现（用于 RocksDB）
    ├── bin/ycsb          # 编译后的二进制文件
    ├── src/              # 源代码
    ├── include/          # 头文件
    ├── workloads/        # 工作负载配置
    ├── build.sh          # 构建脚本
    ├── install_rocksdb.sh # RocksDB 安装脚本
    └── run_benchmark.sh  # 自动化测试脚本
```

## 故障排查

### Go 环境变量未生效
```bash
source ~/.bashrc
```

### Maven 下载依赖缓慢
编辑 `~/.m2/settings.xml` 添加国内镜像：
```xml
<mirrors>
  <mirror>
    <id>aliyun</id>
    <mirrorOf>central</mirrorOf>
    <url>https://maven.aliyun.com/repository/public</url>
  </mirror>
</mirrors>
```

### go-ycsb 构建失败
确保 Go 代理已设置：
```bash
go env -w GOPROXY=https://goproxy.cn,direct
```

### YCSB 构建失败
确保使用 Maven 3.x：
```bash
mvn -version  # 应该显示 Maven 3.x
```

## 参考资料

- [YCSB 官方 Wiki](https://github.com/brianfrankcooper/YCSB/wiki)
- [go-ycsb GitHub](https://github.com/pingcap/go-ycsb)
- [YCSB Paper](https://dl.acm.org/doi/10.1145/1807128.1807152)
