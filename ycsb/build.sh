#!/bin/bash

set -e  # 遇到错误立即退出

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "================================"
echo "开始构建 YCSB 相关项目"
echo "================================"
echo ""

# 检查必要的工具
echo -e "${YELLOW}[检查依赖]${NC}"

if ! command -v go &> /dev/null; then
    echo -e "${RED}✗ Go 未安装${NC}"
    echo -e "${YELLOW}请先运行 ./setup.sh 安装依赖${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Go 已安装: $(go version)${NC}"

echo ""

# 构建 go-ycsb
if [ -d "${SCRIPT_DIR}/go-ycsb" ]; then
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}构建 go-ycsb${NC}"
    echo -e "${YELLOW}========================================${NC}"

    cd "${SCRIPT_DIR}/go-ycsb"

    # 设置 Go 代理（如果尚未设置）
    export GOPROXY=https://goproxy.cn,direct

    echo -e "${YELLOW}开始编译 go-ycsb...${NC}"
    if make; then
        echo -e "${GREEN}✓ go-ycsb 构建成功${NC}"
        echo -e "${GREEN}  可执行文件位置: ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb${NC}"

        # 验证构建结果
        if [ -f "${SCRIPT_DIR}/go-ycsb/bin/go-ycsb" ]; then
            echo -e "${GREEN}  版本信息:${NC}"
            "${SCRIPT_DIR}/go-ycsb/bin/go-ycsb" --help | head -5 || true
        fi
    else
        echo -e "${RED}✗ go-ycsb 构建失败${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ go-ycsb 目录不存在${NC}"
    echo -e "${YELLOW}请先运行 ./setup.sh 克隆代码仓库${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "已构建的项目："
echo -e "  ${GREEN}✓ go-ycsb${NC}: ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb"
echo ""
echo "使用示例："
echo "  # BoltDB"
echo "  ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb load boltdb -P workloads/workloada -p bolt.path=/tmp/test.db"
echo "  ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb run boltdb -P workloads/workloada -p bolt.path=/tmp/test.db"
echo ""
echo "  # SQLite"
echo "  ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb load sqlite -P workloads/workloada -p sqlite.db=/tmp/test.db"
echo "  ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb run sqlite -P workloads/workloada -p sqlite.db=/tmp/test.db"
echo ""
echo "  # PostgreSQL"
echo "  ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb load pg -P workloads/workloada -p pg.user=root -p pg.password=root"
echo "  ${SCRIPT_DIR}/go-ycsb/bin/go-ycsb run pg -P workloads/workloada -p pg.user=root -p pg.password=root"
echo ""
echo "RocksDB 测试使用 cpp-ycsb:"
echo "  cd ${SCRIPT_DIR}/cpp-ycsb && ./build.sh"
echo ""
