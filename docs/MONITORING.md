# 📘 监控运维

PhotoEnhanceAI的服务监控和运维管理指南。

## 📊 系统监控

### 基础监控脚本
```bash
# 创建系统监控脚本
cat > /root/PhotoEnhanceAI/monitor_system.sh <<'EOF'
#!/bin/bash
# PhotoEnhanceAI 系统状态监控脚本

echo "🔍 PhotoEnhanceAI 系统状态监控"
echo "=================================="
echo "📅 时间: $(date)"
echo ""

echo "📊 系统负载:"
uptime
echo ""

echo "💾 内存使用:"
free -h
echo ""

echo "🚀 PhotoEnhanceAI 进程状态:"
if pgrep -f "python api/start_server.py" > /dev/null; then
    ps aux | grep "python api/start_server.py" | grep -v grep
else
    echo "❌ PhotoEnhanceAI 服务未运行"
fi
echo ""

echo "🏥 API健康检查:"
API_HEALTH=$(curl -s http://127.0.0.1:8000/health)
if echo "$API_HEALTH" | grep -q "healthy"; then
    echo "✅ API服务健康检查通过"
    echo "$API_HEALTH"
else
    echo "❌ API服务健康检查失败"
    echo "$API_HEALTH"
fi
echo ""

echo "🎛️  Supervisor服务状态:"
supervisorctl status
echo ""

echo "🌐 网络连接状态:"
if command -v ss &> /dev/null; then
    ACTIVE_CONNECTIONS=$(ss -tunap | grep "0.0.0.0:8000" | wc -l)
    echo "活跃连接数: $ACTIVE_CONNECTIONS"
elif command -v netstat &> /dev/null; then
    ACTIVE_CONNECTIONS=$(netstat -tunap | grep "0.0.0.0:8000" | wc -l)
    echo "活跃连接数: $ACTIVE_CONNECTIONS"
else
    echo "❌ 无法检查网络连接状态 (ss/netstat 命令未找到)"
fi
echo ""

echo "✅ 监控完成 - $(date)"
EOF

chmod +x /root/PhotoEnhanceAI/monitor_system.sh
```

### 资源监控脚本
```bash
# 创建资源监控脚本
cat > /root/PhotoEnhanceAI/monitor_resources.sh <<'EOF'
#!/bin/bash
# PhotoEnhanceAI 资源监控脚本

LOG_FILE="/var/log/photoenhanceai_monitor.log"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 系统负载
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # 内存使用
    MEMORY=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # GPU使用率
    if command -v nvidia-smi &> /dev/null; then
        GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")
        GPU_MEMORY=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | awk -F',' '{printf "%.1f", $1/$2 * 100.0}' || echo "0")
    else
        GPU_UTIL="0"
        GPU_MEMORY="0"
    fi
    
    # 活跃连接数
    CONNECTIONS=$(netstat -an | grep :8000 | grep ESTABLISHED | wc -l)
    
    # 服务状态
    if pgrep -f "python api/start_server.py" > /dev/null; then
        SERVICE_STATUS="RUNNING"
    else
        SERVICE_STATUS="STOPPED"
    fi
    
    # 记录日志
    echo "$TIMESTAMP,LOAD:$LOAD,MEMORY:$MEMORY%,GPU_UTIL:$GPU_UTIL%,GPU_MEMORY:$GPU_MEMORY%,CONNECTIONS:$CONNECTIONS,SERVICE:$SERVICE_STATUS" >> $LOG_FILE
    
    # 检查告警条件
    if (( $(echo "$LOAD > 5.0" | bc -l) )); then
        echo "⚠️  系统负载过高: $LOAD" >> $LOG_FILE
    fi
    
    if (( $(echo "$MEMORY > 90.0" | bc -l) )); then
        echo "⚠️  内存使用过高: $MEMORY%" >> $LOG_FILE
    fi
    
    if [ "$SERVICE_STATUS" = "STOPPED" ]; then
        echo "❌ PhotoEnhanceAI 服务停止" >> $LOG_FILE
    fi
    
    sleep 60
done
EOF

chmod +x /root/PhotoEnhanceAI/monitor_resources.sh
```

## 🎮 GPU监控

### GPU状态监控
```bash
# 创建GPU监控脚本
cat > /root/PhotoEnhanceAI/monitor_gpu.sh <<'EOF'
#!/bin/bash
# GPU监控脚本

while true; do
    echo "🎮 GPU状态监控 - $(date)"
    echo "========================"
    
    if command -v nvidia-smi &> /dev/null; then
        # GPU基本信息
        echo "📊 GPU基本信息:"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
        
        # GPU使用情况
        echo "📈 GPU使用情况:"
        nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits
        
        # 进程信息
        echo "🔍 GPU进程:"
        nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader
        
        # 检查GPU健康状态
        TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        if [ "$TEMP" -gt 80 ]; then
            echo "⚠️  GPU温度过高: ${TEMP}°C"
        fi
        
        MEMORY_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
        MEMORY_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
        MEMORY_PERCENT=$((MEMORY_USED * 100 / MEMORY_TOTAL))
        
        if [ "$MEMORY_PERCENT" -gt 90 ]; then
            echo "⚠️  GPU显存使用过高: ${MEMORY_PERCENT}%"
        fi
        
    else
        echo "❌ NVIDIA驱动未安装或nvidia-smi命令不可用"
    fi
    
    echo ""
    sleep 30
done
EOF

chmod +x /root/PhotoEnhanceAI/monitor_gpu.sh
```

## 📈 性能监控

### 性能监控脚本
```bash
# 创建性能监控脚本
cat > /root/PhotoEnhanceAI/performance_monitor.sh <<'EOF'
#!/bin/bash
# 性能监控脚本

LOG_FILE="/var/log/photoenhanceai_performance.log"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 系统负载
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # 内存使用
    MEMORY=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    # GPU使用率
    GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0")
    
    # 活跃连接数
    CONNECTIONS=$(netstat -an | grep :8000 | grep ESTABLISHED | wc -l)
    
    # 记录日志
    echo "$TIMESTAMP,LOAD:$LOAD,MEMORY:$MEMORY%,GPU:$GPU_UTIL%,CONNECTIONS:$CONNECTIONS" >> $LOG_FILE
    
    sleep 60
done
EOF

chmod +x /root/PhotoEnhanceAI/performance_monitor.sh
```

## 🚨 告警系统

### 告警配置
```bash
# 创建告警脚本
cat > /root/PhotoEnhanceAI/alert_system.sh <<'EOF'
#!/bin/bash
# 告警系统脚本

ALERT_LOG="/var/log/photoenhanceai_alerts.log"
EMAIL="admin@example.com"

send_alert() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] $message" >> $ALERT_LOG
    
    # 发送邮件告警（需要配置邮件服务）
    # echo "$message" | mail -s "PhotoEnhanceAI Alert" $EMAIL
    
    # 发送到日志文件
    logger -t photoenhanceai "$message"
    
    # 可以添加其他告警方式，如钉钉、企业微信等
}

check_service() {
    if ! pgrep -f "python api/start_server.py" > /dev/null; then
        send_alert "CRITICAL: PhotoEnhanceAI service is down"
        return 1
    fi
    return 0
}

check_api() {
    if ! curl -s http://localhost:8000/health | grep -q "healthy"; then
        send_alert "CRITICAL: PhotoEnhanceAI API is not responding"
        return 1
    fi
    return 0
}

check_resources() {
    # 检查内存使用
    MEMORY=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    if (( $(echo "$MEMORY > 90.0" | bc -l) )); then
        send_alert "WARNING: Memory usage is high: ${MEMORY}%"
    fi
    
    # 检查系统负载
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    if (( $(echo "$LOAD > 5.0" | bc -l) )); then
        send_alert "WARNING: System load is high: $LOAD"
    fi
    
    # 检查GPU温度
    if command -v nvidia-smi &> /dev/null; then
        TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        if [ "$TEMP" -gt 80 ]; then
            send_alert "WARNING: GPU temperature is high: ${TEMP}°C"
        fi
    fi
}

# 主检查循环
while true; do
    check_service
    check_api
    check_resources
    sleep 300  # 每5分钟检查一次
done
EOF

chmod +x /root/PhotoEnhanceAI/alert_system.sh
```

## 📊 日志管理

### 日志轮转配置
```bash
# 配置logrotate
sudo tee /etc/logrotate.d/photoenhanceai <<EOF
/var/log/photoenhanceai*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    postrotate
        /bin/kill -USR1 \$(cat /var/run/photoenhanceai.pid 2>/dev/null) 2>/dev/null || true
    endscript
}

/root/PhotoEnhanceAI/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
```

### 日志分析工具
```bash
# 创建日志分析脚本
cat > /root/PhotoEnhanceAI/analyze_logs.sh <<'EOF'
#!/bin/bash
# 日志分析脚本

LOG_DIR="/var/log"
APP_LOG_DIR="/root/PhotoEnhanceAI/logs"

echo "📊 PhotoEnhanceAI 日志分析"
echo "=========================="

# 分析错误日志
echo "❌ 错误统计:"
grep -i "error\|exception\|failed" $LOG_DIR/photoenhanceai*.log $APP_LOG_DIR/*.log | wc -l

# 分析警告日志
echo "⚠️  警告统计:"
grep -i "warning" $LOG_DIR/photoenhanceai*.log $APP_LOG_DIR/*.log | wc -l

# 分析处理统计
echo "📈 处理统计:"
grep -i "completed\|finished" $APP_LOG_DIR/photoenhanceai.log | wc -l

# 分析性能数据
echo "⚡ 性能分析:"
grep -i "processing time" $APP_LOG_DIR/photoenhanceai.log | tail -10

# 分析内存使用
echo "💾 内存使用分析:"
grep -i "memory" $LOG_DIR/photoenhanceai_monitor.log | tail -10

echo "✅ 日志分析完成"
EOF

chmod +x /root/PhotoEnhanceAI/analyze_logs.sh
```

## 🔄 自动恢复

### 自动恢复脚本
```bash
# 创建自动恢复脚本
cat > /root/PhotoEnhanceAI/auto_recovery.sh <<'EOF'
#!/bin/bash
# 自动恢复脚本

LOG_FILE="/var/log/photoenhanceai_recovery.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

check_and_recover() {
    # 检查服务状态
    if ! pgrep -f "python api/start_server.py" > /dev/null; then
        log_message "Service is down, attempting to restart..."
        
        # 清理旧进程
        pkill -f "python api/start_server.py"
        rm -f *.pid
        
        # 重启服务
        ./start_backend_daemon.sh
        sleep 10
        
        # 验证重启
        if pgrep -f "python api/start_server.py" > /dev/null; then
            log_message "Service restarted successfully"
        else
            log_message "Failed to restart service"
        fi
    fi
    
    # 检查API健康状态
    if ! curl -s http://localhost:8000/health | grep -q "healthy"; then
        log_message "API is not healthy, attempting to restart..."
        ./stop_service.sh
        sleep 5
        ./start_backend_daemon.sh
        sleep 10
        
        if curl -s http://localhost:8000/health | grep -q "healthy"; then
            log_message "API restarted successfully"
        else
            log_message "Failed to restart API"
        fi
    fi
}

# 主循环
while true; do
    check_and_recover
    sleep 60  # 每分钟检查一次
done
EOF

chmod +x /root/PhotoEnhanceAI/auto_recovery.sh
```

## 📱 监控面板

### 简单监控面板
```html
<!DOCTYPE html>
<html>
<head>
    <title>PhotoEnhanceAI 监控面板</title>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .healthy { background-color: #d4edda; color: #155724; }
        .warning { background-color: #fff3cd; color: #856404; }
        .error { background-color: #f8d7da; color: #721c24; }
        .metric { display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🔍 PhotoEnhanceAI 监控面板</h1>
    <p>最后更新: <span id="timestamp"></span></p>
    
    <div id="status"></div>
    <div id="metrics"></div>
    
    <script>
        function updateTimestamp() {
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        }
        
        function checkStatus() {
            fetch('/health')
                .then(response => response.json())
                .then(data => {
                    const statusDiv = document.getElementById('status');
                    if (data.status === 'healthy') {
                        statusDiv.innerHTML = '<div class="status healthy">✅ 服务健康</div>';
                    } else {
                        statusDiv.innerHTML = '<div class="status error">❌ 服务异常</div>';
                    }
                })
                .catch(error => {
                    document.getElementById('status').innerHTML = '<div class="status error">❌ 无法连接到服务</div>';
                });
        }
        
        updateTimestamp();
        checkStatus();
    </script>
</body>
</html>
```

## 🔗 相关链接

- [部署指南](DEPLOYMENT.md)
- [故障排除](TROUBLESHOOTING.md)
- [性能优化](PERFORMANCE.md)
- [自动启动配置](AUTOSTART.md)
