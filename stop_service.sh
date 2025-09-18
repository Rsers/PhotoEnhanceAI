#!/bin/bash

# PhotoEnhanceAI 服务停止脚本

echo "🛑 停止 PhotoEnhanceAI 服务..."

if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid)
    if ps -p $PID > /dev/null 2>&1; then
        kill $PID
        echo "✅ 服务已停止 (PID: $PID)"
        rm -f photoenhanceai.pid
    else
        echo "⚠️  进程不存在，可能已经停止"
        rm -f photoenhanceai.pid
    fi
else
    echo "⚠️  未找到 PID 文件，尝试查找进程..."
    pkill -f "python api/start_server.py"
    echo "✅ 已尝试停止相关进程"
fi
