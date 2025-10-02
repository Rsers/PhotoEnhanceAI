# 📘 部署指南

PhotoEnhanceAI的生产环境部署方案和最佳实践。

## 🚀 部署方式概览

| 部署方式 | 适用场景 | 特点 | 推荐度 |
|----------|----------|------|--------|
| **常驻服务** | 生产环境 | 后台运行，稳定可靠 | ⭐⭐⭐⭐⭐ |
| **Docker容器** | 云服务器 | 环境隔离，易于管理 | ⭐⭐⭐⭐ |
| **系统服务** | 专用服务器 | 系统级管理，功能完整 | ⭐⭐⭐⭐ |
| **前台调试** | 开发环境 | 实时日志，便于调试 | ⭐⭐⭐ |

## 🔧 常驻服务部署（推荐）

### 后台常驻服务
```bash
# 启动后台常驻服务（不占用终端，关闭终端后继续运行）
./start_backend_daemon.sh

# 查看服务状态
./status_service.sh

# 停止服务
./stop_service.sh

# 查看服务日志（实时）
tail -f logs/photoenhanceai.log

# 开发调试时使用前台启动（占用终端，实时查看日志）
./start_frontend_only.sh
```

### 服务特性
- ✅ **后台常驻**: 关闭终端后继续运行，不占用终端窗口
- ✅ **前台调试**: 开发时可使用前台模式，实时查看日志输出
- ✅ **日志记录**: 后台模式所有输出保存到日志文件
- ✅ **PID 管理**: 通过 PID 文件管理进程，安全停止服务
- ✅ **清晰提示**: 启动时显示模式说明和切换提示
- ✅ **自动注册**: 启动后自动查询公网IP并注册到API网关

## 🐳 Docker部署

### 构建镜像
```bash
# 构建镜像
docker build -t photoenhanceai .

# 查看镜像
docker images photoenhanceai
```

### 运行容器
```bash
# 基础运行
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  photoenhanceai

# 生产环境运行（推荐）
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  -v /data/models:/app/models \
  -v /data/logs:/app/logs \
  -e OMP_NUM_THREADS=4 \
  -e CUDA_VISIBLE_DEVICES=0 \
  --restart unless-stopped \
  photoenhanceai
```

### 容器管理
```bash
# 查看容器状态
docker ps -a

# 查看容器日志
docker logs photoenhanceai

# 进入容器
docker exec -it photoenhanceai bash

# 停止容器
docker stop photoenhanceai

# 重启容器
docker restart photoenhanceai

# 删除容器
docker rm photoenhanceai
```

### Docker Compose部署
```yaml
version: '3.8'
services:
  photoenhanceai:
    build: .
    container_name: photoenhanceai
    ports:
      - "8000:8000"
    volumes:
      - /data/models:/app/models
      - /data/logs:/app/logs
    environment:
      - OMP_NUM_THREADS=4
      - CUDA_VISIBLE_DEVICES=0
      - PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

```bash
# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 🔧 系统服务部署

### 执行生产部署脚本
```bash
# 执行生产部署脚本
sudo chmod +x deploy/production_setup.sh
sudo ./deploy/production_setup.sh

# 服务管理
sudo supervisorctl status photoenhanceai
sudo supervisorctl restart photoenhanceai
```

### 系统服务配置
```bash
# 创建systemd服务文件
sudo tee /etc/systemd/system/photoenhanceai.service > /dev/null <<EOF
[Unit]
Description=PhotoEnhanceAI Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/PhotoEnhanceAI
ExecStart=/root/PhotoEnhanceAI/start_backend_daemon.sh
Restart=always
RestartSec=10
Environment=PATH=/root/PhotoEnhanceAI/gfpgan_env/bin

# 资源限制
MemoryLimit=8G
CPUQuota=400%

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd配置
sudo systemctl daemon-reload

# 启用并启动服务
sudo systemctl enable photoenhanceai
sudo systemctl start photoenhanceai

# 查看服务状态
sudo systemctl status photoenhanceai
```

## 🌐 生产环境配置

### 环境变量配置
```bash
# 创建环境配置文件
cat > /root/PhotoEnhanceAI/.env <<EOF
# 服务配置
API_HOST=0.0.0.0
API_PORT=8000
WORKERS=1

# GPU配置
CUDA_VISIBLE_DEVICES=0
OMP_NUM_THREADS=4
PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# 资源限制
MEMORY_LIMIT=8GB
CPU_LIMIT=400%

# 日志配置
LOG_LEVEL=INFO
LOG_FILE=/var/log/photoenhanceai.log
EOF
```

### 反向代理配置（Nginx）
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 文件上传配置
        client_max_body_size 50M;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # 静态文件缓存
    location /static/ {
        alias /root/PhotoEnhanceAI/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### SSL证书配置
```bash
# 使用Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 监控和日志

### 系统监控
```bash
# 创建监控脚本
cat > /root/PhotoEnhanceAI/monitor_production.sh <<'EOF'
#!/bin/bash
# 生产环境监控脚本

echo "🔍 PhotoEnhanceAI 生产环境监控"
echo "==============================="
echo "📅 时间: $(date)"
echo ""

# 系统资源
echo "📊 系统资源:"
echo "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')"
echo "内存使用: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "磁盘使用: $(df -h / | awk 'NR==2{printf "%s", $5}')"
echo ""

# 服务状态
echo "🚀 服务状态:"
if pgrep -f "python api/start_server.py" > /dev/null; then
    echo "✅ PhotoEnhanceAI 服务运行正常"
    echo "PID: $(pgrep -f "python api/start_server.py")"
else
    echo "❌ PhotoEnhanceAI 服务未运行"
fi
echo ""

# API健康检查
echo "🏥 API健康检查:"
API_HEALTH=$(curl -s http://localhost:8000/health)
if echo "$API_HEALTH" | grep -q "healthy"; then
    echo "✅ API服务健康"
else
    echo "❌ API服务异常"
    echo "$API_HEALTH"
fi
echo ""

# GPU状态
echo "🎮 GPU状态:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits
else
    echo "❌ NVIDIA驱动未安装"
fi
echo ""

echo "✅ 监控完成 - $(date)"
EOF

chmod +x /root/PhotoEnhanceAI/monitor_production.sh
```

### 日志轮转配置
```bash
# 配置logrotate
sudo tee /etc/logrotate.d/photoenhanceai <<EOF
/var/log/photoenhanceai.log {
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
EOF
```

### 性能监控
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

# 启动性能监控
nohup /root/PhotoEnhanceAI/performance_monitor.sh > /dev/null 2>&1 &
```

## 🔒 安全配置

### 防火墙配置
```bash
# UFW防火墙配置
sudo ufw allow ssh
sudo ufw allow 8000/tcp
sudo ufw enable

# iptables配置
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
sudo iptables -A INPUT -j DROP
```

### 访问控制
```bash
# 创建访问控制脚本
cat > /root/PhotoEnhanceAI/access_control.sh <<'EOF'
#!/bin/bash
# 访问控制脚本

# 允许的IP地址列表
ALLOWED_IPS=(
    "192.168.1.0/24"
    "10.0.0.0/8"
    "your.trusted.ip.address"
)

# 检查IP是否在允许列表中
check_ip() {
    local client_ip=$1
    for allowed_ip in "${ALLOWED_IPS[@]}"; do
        if [[ $client_ip == $allowed_ip ]]; then
            return 0
        fi
    done
    return 1
}

# 记录访问日志
log_access() {
    local ip=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - Access from $ip" >> /var/log/photoenhanceai_access.log
}
EOF

chmod +x /root/PhotoEnhanceAI/access_control.sh
```

## 📈 性能优化

### 系统优化
```bash
# 内核参数优化
sudo tee -a /etc/sysctl.conf <<EOF
# PhotoEnhanceAI 性能优化
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
vm.swappiness = 10
EOF

# 应用配置
sudo sysctl -p
```

### GPU优化
```bash
# GPU性能模式
sudo nvidia-smi -pm 1
sudo nvidia-smi -ac 1215,1410  # 根据GPU调整

# 环境变量优化
export CUDA_CACHE_DISABLE=0
export CUDA_CACHE_MAXSIZE=2147483648
```

## 🔗 相关链接

- [安装指南](INSTALLATION.md)
- [自动启动配置](AUTOSTART.md)
- [容器部署](CONTAINER_DEPLOYMENT.md)
- [性能优化](PERFORMANCE.md)
- [故障排除](TROUBLESHOOTING.md)
