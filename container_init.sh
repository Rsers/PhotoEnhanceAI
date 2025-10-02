#!/bin/bash

# PhotoEnhanceAI 容器初始化脚本
# 确保在容器启动时自动运行PhotoEnhanceAI服务

echo "=========================================="
echo "🐳 PhotoEnhanceAI 容器初始化启动"
echo "=========================================="

# 等待系统完全启动
echo "⏳ 等待系统启动完成..."
sleep 5

# 进入项目目录
cd /root/PhotoEnhanceAI

# 检查服务是否已经在运行
if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid 2>/dev/null)
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI 服务已在运行 (PID: $PID)"
        exit 0
    fi
fi

echo "🚀 启动 PhotoEnhanceAI 服务..."

# 启动服务
nohup ./container_autostart.sh > /dev/null 2>&1 &

# 等待启动
sleep 3

# 检查启动状态
if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid 2>/dev/null)
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI 服务启动成功 (PID: $PID)"
    else
        echo "❌ PhotoEnhanceAI 服务启动失败"
        exit 1
    fi
else
    echo "❌ PhotoEnhanceAI 服务启动失败，未找到PID文件"
    exit 1
fi

echo "🎉 PhotoEnhanceAI 容器初始化完成"
