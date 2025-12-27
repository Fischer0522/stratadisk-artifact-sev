#!/bin/bash

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}cpp-ycsb 完整环境配置${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Step 1: Install build tools
echo -e "${YELLOW}[1/4] 检查构建工具...${NC}"
if ! command -v cmake &> /dev/null || ! command -v g++ &> /dev/null; then
    echo -e "${YELLOW}安装构建工具...${NC}"
    sudo apt update
    sudo apt install -y build-essential cmake pkg-config
    echo -e "${GREEN}✓ 构建工具已安装${NC}"
else
    echo -e "${GREEN}✓ 构建工具已存在${NC}"
fi
echo ""

# Step 2: Install compression libraries (required by RocksDB)
echo -e "${YELLOW}[2/4] 检查压缩库...${NC}"
MISSING_LIBS=0

for lib in libsnappy-dev liblz4-dev libzstd-dev libbz2-dev zlib1g-dev; do
    if ! dpkg -l | grep -q "^ii  $lib"; then
        MISSING_LIBS=1
        break
    fi
done

if [ $MISSING_LIBS -eq 1 ]; then
    echo -e "${YELLOW}安装压缩库...${NC}"
    sudo apt install -y \
        libsnappy-dev \
        liblz4-dev \
        libzstd-dev \
        libbz2-dev \
        zlib1g-dev \
        libgflags-dev
    echo -e "${GREEN}✓ 压缩库已安装${NC}"
else
    echo -e "${GREEN}✓ 压缩库已存在${NC}"
fi
echo ""

# Step 3: Install RocksDB
echo -e "${YELLOW}[3/4] 检查 RocksDB...${NC}"
if ! ldconfig -p | grep -q librocksdb; then
    echo -e "${YELLOW}RocksDB 未安装，开始安装...${NC}"
    echo ""
    echo "选择安装方式:"
    echo "  1) 从包管理器安装 (推荐，快速)"
    echo "  2) 从源码编译 (最新版本，需要 10-15 分钟)"
    echo ""
    read -p "请选择 (1 或 2，默认 1): " choice
    choice=${choice:-1}

    if [ "$choice" == "1" ]; then
        echo -e "${YELLOW}从包管理器安装 RocksDB...${NC}"
        sudo apt update
        sudo apt install -y librocksdb-dev
    else
        echo -e "${YELLOW}从源码编译 RocksDB...${NC}"
        ROCKSDB_DIR="/tmp/rocksdb-build-$$"
        git clone https://github.com/facebook/rocksdb.git "$ROCKSDB_DIR"
        cd "$ROCKSDB_DIR"
        make shared_lib -j$(nproc)
        sudo make install-shared
        cd - > /dev/null
        rm -rf "$ROCKSDB_DIR"
    fi

    sudo ldconfig
    echo -e "${GREEN}✓ RocksDB 已安装${NC}"
else
    echo -e "${GREEN}✓ RocksDB 已存在${NC}"
fi

# Verify RocksDB installation
if ldconfig -p | grep -q librocksdb; then
    echo -e "${GREEN}  RocksDB 库路径:${NC}"
    ldconfig -p | grep rocksdb | head -3
else
    echo -e "${RED}✗ RocksDB 安装失败${NC}"
    exit 1
fi
echo ""

# Step 4: Build cpp-ycsb
echo -e "${YELLOW}[4/4] 构建 cpp-ycsb...${NC}"
cd "${SCRIPT_DIR}"

# Clean previous build
if [ -d "build" ]; then
    echo -e "${YELLOW}清理旧的构建文件...${NC}"
    rm -rf build
fi

mkdir -p build bin

# Run CMake
cd build
echo -e "${YELLOW}运行 CMake...${NC}"
if cmake .. -DCMAKE_BUILD_TYPE=Release; then
    echo -e "${GREEN}✓ CMake 配置成功${NC}"
else
    echo -e "${RED}✗ CMake 配置失败${NC}"
    exit 1
fi

# Compile
echo ""
echo -e "${YELLOW}编译中...${NC}"
if make -j$(nproc); then
    echo -e "${GREEN}✓ 编译成功${NC}"
else
    echo -e "${RED}✗ 编译失败${NC}"
    exit 1
fi

cd ..

# Verify binary
if [ -f "bin/ycsb" ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}环境配置完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "可执行文件: ${GREEN}${SCRIPT_DIR}/bin/ycsb${NC}"
    echo -e "文件大小: $(du -h bin/ycsb | cut -f1)"
    echo ""
    echo "快速测试:"
    echo "  ./bin/ycsb load -P workloads/workloada -db /tmp/test-ycsb"
    echo "  ./bin/ycsb run -P workloads/workloada -db /tmp/test-ycsb"
    echo ""
    echo "测试 SwornDisk 和 CryptDisk:"
    echo "  ./run_benchmark.sh workloads/workloada"
    echo ""
else
    echo -e "${RED}✗ 构建失败，未找到可执行文件${NC}"
    exit 1
fi
