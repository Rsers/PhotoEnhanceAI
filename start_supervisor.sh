#!/bin/bash

# PhotoEnhanceAI - Supervisor兼容启动脚本
# 专门为supervisor环境设计，不使用nohup和后台运行

set -e

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
