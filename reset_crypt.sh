#!/bin/bash

# --- Configuration ---
BACKEND_DISK="/dev/vdb"
INTEGRITY_DEV="test-integrity"
CRYPT_DEV="test-crypt"
KEY="12345678123456781234567812345678"
TAG_SIZE=28

echo "==== Initializing Integrity + Crypt Layers ===="

# 1. 环境准备
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p /run/cryptsetup
[ ! -b /dev/vdb ] && mknod /dev/vdb b 253 16
[ ! -c /dev/mapper/control ] && dmsetup mknodes

# 2. 清理旧设备
echo "[*] Cleaning up..."
dmsetup remove "$CRYPT_DEV" >/dev/null 2>&1
dmsetup remove "$INTEGRITY_DEV" >/dev/null 2>&1

# 3. 擦除开头
dd if=/dev/zero of="$BACKEND_DISK" bs=1M count=10 conv=notrunc status=none

# 4. 探测最大容量
echo "[*] Probing max usable sectors..."
dmsetup create "$INTEGRITY_DEV" --table "0 1 integrity $BACKEND_DISK 0 $TAG_SIZE D 0"

# 获取 status
STATUS_LINE=$(dmsetup status "$INTEGRITY_DEV")
# 重点修正：在 6.6 内核中，可用大小通常在第 5 列
MAX_SECTORS=$(echo "$STATUS_LINE" | awk '{print $5}')

dmsetup remove "$INTEGRITY_DEV"

# 增加检查逻辑：如果第5列不是数字，尝试第4列
if ! [[ "$MAX_SECTORS" =~ ^[0-9]+$ ]]; then
    MAX_SECTORS=$(echo "$STATUS_LINE" | awk '{print $4}')
fi

if [ -z "$MAX_SECTORS" ] || [ "$MAX_SECTORS" -eq 0 ]; then
    echo "[!] Error: Failed to parse MAX_SECTORS. Status was: $STATUS_LINE"
    exit 1
fi
echo "[*] Detected Max Sectors: $MAX_SECTORS"

# 5. 正式创建 Integrity 层
echo "[*] Creating dm-integrity layer..."
dmsetup create "$INTEGRITY_DEV" --table "0 $MAX_SECTORS integrity $BACKEND_DISK 0 $TAG_SIZE D 0"
dmsetup mknodes "$INTEGRITY_DEV"

# 6. 创建 Crypt 层
echo "[*] Creating dm-crypt layer..."
echo "$KEY" | cryptsetup open --type plain --key-file - --cipher aes-xts-plain64 "/dev/mapper/$INTEGRITY_DEV" "$CRYPT_DEV"

# 7. 验证
if [ -b "/dev/mapper/$CRYPT_DEV" ]; then
    echo "==== Success: /dev/mapper/$CRYPT_DEV is ACTIVE ===="
    # 打印最终大小确认
    REAL_SIZE=$(blockdev --getsize64 /dev/mapper/$CRYPT_DEV | awk '{print $1/1024/1024/1024 " GiB"}')
    echo "Total Usable Capacity: $REAL_SIZE"
else
    echo "[!] Failure: Check dmesg."
    dmesg | tail -n 10
fi
