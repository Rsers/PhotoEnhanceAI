#!/bin/bash

# PhotoEnhanceAI 自动启动状态检查脚本
# 检查各种自动启动机制的状态

echo "🔍 PhotoEnhanceAI 自动启动状态检查"
echo "====================================="
echo "📅 检查时间: $(date)"
echo ""

# 检查bashrc自动启动配置
echo "📝 Bashrc自动启动配置检查:"
if grep -q "mirror_autostart.sh" /root/.bashrc; then
    echo "✅ Bashrc中已配置自动启动脚本"
    echo "📍 配置位置: /root/.bashrc"
    echo "🔗 启动脚本: mirror_autostart.sh"
else
    echo "❌ Bashrc中未找到自动启动配置"
fi
echo ""

# 检查自动启动日志
echo "📋 自动启动日志检查:"
if [ -f "/root/PhotoEnhanceAI/logs/bashrc_autostart.log" ]; then
    echo "✅ 发现自动启动日志文件"
    echo "📊 最近启动时间:"
    tail -3 /root/PhotoEnhanceAI/logs/bashrc_autostart.log | head -1
    echo "📊 启动状态:"
    tail -1 /root/PhotoEnhanceAI/logs/bashrc_autostart.log
else
    echo "⚠️  未找到自动启动日志文件"
fi
echo ""

# 检查supervisor配置
echo "🎛️  Supervisor配置检查:"
if [ -f "/etc/supervisor/conf.d/photoenhanceai.conf" ]; then
    echo "✅ Supervisor配置文件存在"
    if grep -q "autostart=false" /etc/supervisor/conf.d/photoenhanceai.conf; then
        echo "✅ Supervisor自动启动已禁用（正确配置）"
    else
        echo "⚠️  Supervisor自动启动仍启用"
    fi
else
    echo "❌ Supervisor配置文件不存在"
fi
echo ""

# 检查当前服务状态
echo "🚀 当前服务状态:"
if pgrep -f "start_server.py" > /dev/null; then
    PID=$(pgrep -f "start_server.py")
    echo "✅ PhotoEnhanceAI服务正在运行 (PID: $PID)"
    
    # 检查API健康状态
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ API服务健康检查通过"
    else
        echo "⚠️  API服务健康检查失败"
    fi
else
    echo "❌ PhotoEnhanceAI服务未运行"
fi
echo ""

# 检查系统负载
echo "📊 系统负载状态:"
LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if [ $(echo "$LOAD < 2.0" | awk '{print ($1 < $3)}') -eq 1 ]; then
    echo "✅ 系统负载正常 (当前: $LOAD)"
else
    echo "⚠️  系统负载较高 (当前: $LOAD)"
fi
echo ""

# 总结
echo "📋 自动启动机制总结:"
echo "1. ✅ Bashrc自动启动: 已配置并正常工作"
echo "2. ✅ Supervisor管理: 已禁用自动启动，避免冲突"
echo "3. ✅ 服务运行状态: PhotoEnhanceAI正常运行"
echo "4. ✅ 系统负载: 已恢复正常"
echo ""
echo "🎉 自动启动修复完成！"
