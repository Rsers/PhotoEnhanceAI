#!/bin/bash

# SSH连接性能测试脚本
# 用于测试SSH连接的响应速度

echo "🔍 SSH连接性能测试"
echo "=================="
echo "📅 测试时间: $(date)"
echo ""

# 测试系统响应速度
echo "⚡ 系统响应速度测试:"
echo -n "测试命令执行速度... "
START_TIME=$(date +%s%N)
echo "test" > /dev/null
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "${DURATION}ms"
echo ""

# 测试文件系统访问速度
echo "💾 文件系统访问速度测试:"
echo -n "测试文件读取速度... "
START_TIME=$(date +%s%N)
cat /proc/version > /dev/null
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "${DURATION}ms"
echo ""

# 测试网络连接速度
echo "🌐 网络连接速度测试:"
echo -n "测试本地API连接... "
START_TIME=$(date +%s%N)
curl -s http://localhost:8000/health > /dev/null
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "${DURATION}ms"
echo ""

# 测试进程查找速度
echo "🔍 进程查找速度测试:"
echo -n "测试进程搜索... "
START_TIME=$(date +%s%N)
ps aux | grep python > /dev/null
END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
echo "${DURATION}ms"
echo ""

# 系统负载状态
echo "📊 当前系统负载:"
uptime
echo ""

# 内存使用情况
echo "💾 内存使用情况:"
free -h | head -2
echo ""

# 总结性能状态
echo "📋 SSH性能评估:"
if [ $DURATION -lt 100 ]; then
    echo "✅ 系统响应速度优秀 (< 100ms)"
elif [ $DURATION -lt 500 ]; then
    echo "✅ 系统响应速度良好 (< 500ms)"
elif [ $DURATION -lt 1000 ]; then
    echo "⚠️  系统响应速度一般 (< 1000ms)"
else
    echo "❌ 系统响应速度较慢 (> 1000ms)"
fi

LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if [ $(echo "$LOAD < 1.0" | awk '{print ($1 < $3)}') -eq 1 ]; then
    echo "✅ 系统负载正常"
else
    echo "⚠️  系统负载较高，可能影响SSH响应速度"
fi

echo ""
echo "🎉 SSH性能测试完成！"
