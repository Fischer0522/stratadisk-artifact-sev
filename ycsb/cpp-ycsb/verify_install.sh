#!/bin/bash

# 验证 cpp-ycsb 安装的测试脚本

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}cpp-ycsb 安装验证${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Test 1: Check binary exists
echo -e "${YELLOW}[1/5] 检查可执行文件...${NC}"
if [ -f "${SCRIPT_DIR}/bin/ycsb" ]; then
    echo -e "${GREEN}✓ 找到可执行文件: ${SCRIPT_DIR}/bin/ycsb${NC}"
    echo -e "  文件大小: $(du -h ${SCRIPT_DIR}/bin/ycsb | cut -f1)"
else
    echo -e "${RED}✗ 未找到可执行文件${NC}"
    echo -e "${YELLOW}请先运行: ./setup.sh${NC}"
    exit 1
fi
echo ""

# Test 2: Check RocksDB
echo -e "${YELLOW}[2/5] 检查 RocksDB...${NC}"
if ldconfig -p | grep -q librocksdb; then
    echo -e "${GREEN}✓ RocksDB 已安装${NC}"
    ldconfig -p | grep rocksdb | head -1
else
    echo -e "${RED}✗ RocksDB 未安装${NC}"
    exit 1
fi
echo ""

# Test 3: Check workload files
echo -e "${YELLOW}[3/5] 检查工作负载文件...${NC}"
WORKLOAD_COUNT=$(ls ${SCRIPT_DIR}/workloads/workload* 2>/dev/null | wc -l)
if [ $WORKLOAD_COUNT -ge 5 ]; then
    echo -e "${GREEN}✓ 找到 $WORKLOAD_COUNT 个工作负载文件${NC}"
    ls ${SCRIPT_DIR}/workloads/workload* | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠ 只找到 $WORKLOAD_COUNT 个工作负载文件${NC}"
fi
echo ""

# Test 4: Quick load test
echo -e "${YELLOW}[4/5] 快速加载测试...${NC}"
TEST_DB="/tmp/cpp-ycsb-test-$$"
mkdir -p "$TEST_DB"

if "${SCRIPT_DIR}/bin/ycsb" load -P "${SCRIPT_DIR}/workloads/workloada" -db "$TEST_DB" 2>&1 | grep -q "Loading data phase"; then
    echo -e "${GREEN}✓ 加载测试成功${NC}"
else
    echo -e "${RED}✗ 加载测试失败${NC}"
    rm -rf "$TEST_DB"
    exit 1
fi
echo ""

# Test 5: Quick run test
echo -e "${YELLOW}[5/5] 快速运行测试...${NC}"
if "${SCRIPT_DIR}/bin/ycsb" run -P "${SCRIPT_DIR}/workloads/workloada" -db "$TEST_DB" 2>&1 | grep -q "Run phase completed"; then
    echo -e "${GREEN}✓ 运行测试成功${NC}"
else
    echo -e "${RED}✗ 运行测试失败${NC}"
    rm -rf "$TEST_DB"
    exit 1
fi

# Cleanup
rm -rf "$TEST_DB"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}所有测试通过！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "cpp-ycsb 已正确安装并可以使用。"
echo ""
echo "快速开始:"
echo "  1. 查看快速指南: cat QUICK_START.md"
echo "  2. 运行测试: ./bin/ycsb load -P workloads/workloada -db /tmp/test"
echo "  3. 自动测试: ./run_benchmark.sh workloads/workloada"
echo ""
