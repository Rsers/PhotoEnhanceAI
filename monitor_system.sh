#!/bin/bash

# PhotoEnhanceAI 系统监控脚本
# 用于监控系统负载和服务状态

echo "🔍 PhotoEnhanceAI 系统状态监控"
echo "=================================="
echo "📅 时间: $(date)"
echo ""

# 系统负载信息
echo "📊 系统负载:"
uptime
echo ""

# 内存使用情况
echo "💾 内存使用:"
free -h
echo ""

# PhotoEnhanceAI进程状态
echo "🚀 PhotoEnhanceAI 进程状态:"
ps aux | grep -E "(start_server.py|photoenhanceai)" | grep -v grep || echo "❌ 未发现PhotoEnhanceAI进程"
echo ""

# API健康检查
echo "🏥 API健康检查:"
curl -s http://localhost:8000/health | python3 -m json.tool 2>/dev/null || echo "❌ API服务不可达"
echo ""

# Supervisor状态
echo "🎛️  Supervisor服务状态:"
supervisorctl status 2>/dev/null || echo "❌ Supervisor不可用"
echo ""

# 网络连接状态
echo "🌐 网络连接状态:"
cat /proc/net/tcp | grep -E ":(0050|01BB|006F|1F90)" | wc -l | xargs -I {} echo "活跃连接数: {}"
echo ""

echo "✅ 监控完成 - $(date)"
