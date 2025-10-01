#!/bin/bash

# PhotoEnhanceAI - 前台启动脚本（仅用于调试和开发）
# ⚠️  前台模式特点：
#   - 占用终端窗口，可看到实时日志输出
#   - 按 Ctrl+C 或关闭终端会停止服务
#   - 适合调试和测试
# 💡 生产环境请使用: start_backend_daemon.sh

echo "=========================================="
echo "🚀 前台模式启动 PhotoEnhanceAI API 服务"
echo "⚠️  注意：此模式会占用终端窗口"
echo "⚠️  关闭终端或按 Ctrl+C 将停止服务"
echo "💡 后台运行请使用: ./start_backend_daemon.sh"
echo "=========================================="
echo ""

# 进入项目目录
cd /root/PhotoEnhanceAI

# 激活虚拟环境
source gfpgan_env/bin/activate

# 前台启动API服务（会占用终端）
python api/start_server.py

