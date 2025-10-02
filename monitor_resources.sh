#!/bin/bash

# PhotoEnhanceAI 资源监控脚本
# 实时监控内存和CPU使用，防止系统崩溃

echo "🔍 PhotoEnhanceAI 资源监控启动"
echo "⏰ 监控开始时间: $(date)"
echo "=================================="

# 设置告警阈值
MEMORY_WARNING_THRESHOLD=80  # 内存使用超过80%告警
MEMORY_CRITICAL_THRESHOLD=95 # 内存使用超过95%告警
CPU_WARNING_THRESHOLD=90     # CPU使用超过90%告警

monitor_resources() {
    while true; do
        # 获取系统内存信息
        MEMORY_INFO=$(free | grep Mem)
        TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
        USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
        MEMORY_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))
        
        # 获取CPU使用率
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        
        # 获取PhotoEnhanceAI进程信息
        PHOTOENHANCEAI_PID=$(pgrep -f "start_server.py" | head -1)
        if [ ! -z "$PHOTOENHANCEAI_PID" ]; then
            PHOTOENHANCEAI_MEM=$(ps -p $PHOTOENHANCEAI_PID -o rss= | awk '{print $1/1024/1024}')
            PHOTOENHANCEAI_CPU=$(ps -p $PHOTOENHANCEAI_PID -o %cpu= | awk '{print $1}')
        else
            PHOTOENHANCEAI_MEM=0
            PHOTOENHANCEAI_CPU=0
        fi
        
        # 显示监控信息
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$TIMESTAMP] 系统内存: ${MEMORY_PERCENT}% | CPU: ${CPU_USAGE}% | PhotoEnhanceAI内存: ${PHOTOENHANCEAI_MEM}GB | CPU: ${PHOTOENHANCEAI_CPU}%"
        
        # 内存告警检查
        if [ $MEMORY_PERCENT -gt $MEMORY_CRITICAL_THRESHOLD ]; then
            echo "🚨 严重告警: 系统内存使用超过 ${MEMORY_CRITICAL_THRESHOLD}%!"
            echo "⚠️  建议立即重启PhotoEnhanceAI服务"
        elif [ $MEMORY_PERCENT -gt $MEMORY_WARNING_THRESHOLD ]; then
            echo "⚠️  警告: 系统内存使用超过 ${MEMORY_WARNING_THRESHOLD}%"
        fi
        
        # CPU告警检查
        if (( $(echo "$CPU_USAGE > $CPU_WARNING_THRESHOLD" | bc -l) )); then
            echo "⚠️  警告: CPU使用率超过 ${CPU_WARNING_THRESHOLD}%"
        fi
        
        # 检查PhotoEnhanceAI内存使用
        if (( $(echo "$PHOTOENHANCEAI_MEM > 6" | bc -l) )); then
            echo "⚠️  警告: PhotoEnhanceAI内存使用超过6GB"
        fi
        
        sleep 10
    done
}

# 启动监控
monitor_resources
