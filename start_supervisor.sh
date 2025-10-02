#!/bin/bash

# PhotoEnhanceAI - Supervisor兼容启动脚本
# 专门为supervisor环境设计，不使用nohup和后台运行

set -e

# 进程锁机制 - 防止多个实例同时运行
LOCK_FILE="/root/PhotoEnhanceAI/photoenhanceai.lock"
PID_FILE="/root/PhotoEnhanceAI/photoenhanceai.pid"

# 检查是否已有实例在运行
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && ps -p "$LOCK_PID" > /dev/null 2>&1; then
        echo "⚠️  PhotoEnhanceAI服务已在运行 (PID: $LOCK_PID)"
        echo "🚫 跳过重复启动，避免内存溢出"
        exit 0
    else
        echo "🧹 清理过期的锁文件"
        rm -f "$LOCK_FILE"
    fi
fi

# 创建锁文件
echo $$ > "$LOCK_FILE"
echo $$ > "$PID_FILE"

# 设置退出时清理锁文件
trap 'rm -f "$LOCK_FILE" "$PID_FILE"' EXIT

echo "🚀 启动PhotoEnhanceAI (Supervisor模式)"
echo "⏰ 启动时间: $(date)"
echo "📁 工作目录: $(pwd)"

# 激活虚拟环境
if [ -f "gfpgan_env/bin/activate" ]; then
    echo "🐍 激活Python虚拟环境..."
    source gfpgan_env/bin/activate
else
    echo "⚠️  虚拟环境不存在，使用系统Python"
fi

# 创建日志目录
if command -v mkdir >/dev/null 2>&1; then
    mkdir -p logs
else
    echo "⚠️  mkdir命令不可用，跳过日志目录创建"
fi

# 设置环境变量
export OMP_NUM_THREADS=4
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

echo "📊 环境配置:"
echo "   - OMP_NUM_THREADS: $OMP_NUM_THREADS"
echo "   - CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "   - Python路径: $(which python)"

# 启动主服务
echo "🎯 启动PhotoEnhanceAI API服务..."
exec python api/start_server.py
