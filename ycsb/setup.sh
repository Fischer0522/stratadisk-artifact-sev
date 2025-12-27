#!/bin/bash

set -e  # 遇到错误立即退出

echo "================================"
echo "环境配置脚本开始执行"
echo "================================"

# 检查并安装 Go
if ! command -v go &> /dev/null; then
    echo "[1/3] 开始安装 Go..."
    wget https://golang.google.cn/dl/go1.22.0.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    # 配置环境变量
    if ! grep -q 'export GOROOT="/usr/local/go"' ~/.bashrc; then
        echo 'export GOROOT="/usr/local/go"' >> ~/.bashrc
    fi
    if ! grep -q 'export GOPATH="$HOME/.go"' ~/.bashrc; then
        echo 'export GOPATH="$HOME/.go"' >> ~/.bashrc
    fi
    if ! grep -q 'GOROOT/bin:.*GOPATH/bin' ~/.bashrc; then
        echo 'export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"' >> ~/.bashrc
    fi

    # 在当前脚本中设置环境变量
    export GOROOT="/usr/local/go"
    export GOPATH="$HOME/.go"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

    # 配置 Go 代理
    $GOROOT/bin/go env -w GOPROXY=https://goproxy.cn,direct
    echo "✓ Go 安装成功"
else
    echo "[1/3] Go 已安装，跳过"
fi

# 检查并安装 PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "[2/3] 开始安装 PostgreSQL..."
    sudo apt update
    sudo apt-get install -y postgresql postgresql-client
    echo "✓ PostgreSQL 安装成功"
else
    echo "[2/3] PostgreSQL 已安装，跳过"
fi

# 检查并安装 SQLite3
if ! command -v sqlite3 &> /dev/null; then
    echo "[3/3] 开始安装 SQLite3..."
    sudo apt install -y sqlite3 libsqlite3-dev
    echo "✓ SQLite3 安装成功"
else
    echo "[3/3] SQLite3 已安装，跳过"
fi

echo ""
echo "================================"
echo "克隆代码仓库"
echo "================================"

# 克隆 go-ycsb
if [ ! -d "go-ycsb" ]; then
    echo "正在克隆 go-ycsb..."
    if git clone https://github.com/Fischer0522/go-ycsb.git -b feat/sworndisk 2>/dev/null; then
        echo "✓ go-ycsb 克隆成功"
    else
        echo "⚠ go-ycsb 克隆失败，尝试使用 SSH..."
        git clone git@github.com:Fischer0522/go-ycsb.git -b feat/sworndisk || {
            echo "✗ go-ycsb 克隆失败，请检查网络或 SSH 密钥配置"
            exit 1
        }
    fi
else
    echo "go-ycsb 目录已存在，跳过克隆"
fi

echo ""
echo "================================"
echo "环境配置完成！"
echo "================================"
echo ""
echo "已安装的组件："
echo "  - Go: $(go version 2>/dev/null || echo '请重新打开终端以加载环境变量')"
echo "  - PostgreSQL: $(psql --version)"
echo "  - SQLite3: $(sqlite3 --version)"
echo ""
echo "注意：如果 Go 命令不可用，请执行以下命令："
echo "  source ~/.bashrc"
echo ""
echo "下一步："
echo "  1. 构建 go-ycsb: cd go-ycsb && make"
echo "  2. 构建 cpp-ycsb: cd cpp-ycsb && ./build.sh"
echo ""
