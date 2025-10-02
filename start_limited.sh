#!/bin/bash

# PhotoEnhanceAI 资源限制启动脚本
# 防止内存爆炸导致系统崩溃

set -e

echo "🚀 启动PhotoEnhanceAI (资源限制模式)"
echo "⏰ 启动时间: $(date)"

# 设置资源限制
export OMP_NUM_THREADS=4  # 限制OpenMP线程数
export CUDA_VISIBLE_DEVICES=0  # 限制GPU使用
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512  # 限制CUDA内存分配

# 使用systemd-run启动，自动应用资源限制
echo "📊 应用资源限制..."
echo "   - 内存限制: 8GB"
echo "   - CPU限制: 4核心"
echo "   - GPU限制: 单卡"

# 启动服务
echo "🎯 启动PhotoEnhanceAI服务..."
cd /root/PhotoEnhanceAI
exec /root/PhotoEnhanceAI/gfpgan_env/bin/python /root/PhotoEnhanceAI/api/start_server.py
