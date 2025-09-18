#!/bin/bash

# PhotoEnhanceAI 服务状态检查脚本

echo "🔍 PhotoEnhanceAI 服务状态检查..."

if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ 服务正在运行 (PID: $PID)"
        echo "📊 进程信息:"
        ps -p $PID -o pid,ppid,cmd,etime,pcpu,pmem
        echo ""
        echo "🌐 端口监听状态:"
        netstat -tlnp | grep :8000 || echo "⚠️  端口 8000 未监听"
    else
        echo "❌ 服务未运行 (PID 文件存在但进程不存在)"
        rm -f photoenhanceai.pid
    fi
else
    echo "❌ 服务未运行 (未找到 PID 文件)"
fi

echo ""
echo "📝 最近日志 (最后10行):"
if [ -f "logs/photoenhanceai.log" ]; then
    tail -10 logs/photoenhanceai.log
else
    echo "⚠️  日志文件不存在"
fi
