# 📘 容器部署

PhotoEnhanceAI的Docker和容器环境部署指南。

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

## 🐙 Docker Compose部署

### docker-compose.yml
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

### 使用Docker Compose
```bash
# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重新构建
docker-compose up -d --build
```

## 🔧 容器环境配置

### 腾讯云容器环境

#### 环境特征
- 使用 `dumb-init` 作为PID 1进程
- 没有 systemd 服务管理
- 需要多重启动保障机制

#### 配置的自动启动方式
```bash
# 已配置的启动机制：
✅ .bashrc 自动启动 - 每次shell启动时检查服务状态
✅ /etc/profile.d 自动启动 - 系统级启动检查  
✅ rc.local 自动启动 - 容器启动时执行（备用）
✅ 容器初始化脚本 - 专用容器启动脚本
```

#### 一键配置
```bash
# 一键配置容器自动启动（推荐）
./setup_container_autostart.sh

# 或手动使用容器启动脚本
./container_autostart.sh
```

### 容器启动脚本特性
- 自动等待网络就绪
- 启动主服务、模型预热、webhook注册
- 服务监控和自动重启
- 适合腾讯云容器、Docker 容器或非 systemd 环境

## 🛠️ 容器故障排除

### 常见问题

#### 1. 容器启动失败
```bash
# 检查容器日志
docker logs photoenhanceai

# 检查镜像构建
docker build -t photoenhanceai . --no-cache

# 检查GPU支持
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
```

#### 2. GPU在容器中不可用
```bash
# 检查NVIDIA Docker支持
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi

# 安装NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

#### 3. 服务在容器中无法访问
```bash
# 检查端口映射
docker port photoenhanceai

# 检查网络配置
docker network ls
docker network inspect bridge

# 测试容器内连接
docker exec photoenhanceai curl http://localhost:8000/health
```

### 容器诊断工具
```bash
# 创建容器诊断脚本
cat > /root/PhotoEnhanceAI/container_diagnostics.sh <<'EOF'
#!/bin/bash
# 容器环境诊断脚本

echo "🔍 容器环境诊断"
echo "================"

# 容器信息
echo "📦 容器信息:"
echo "容器ID: $(hostname)"
echo "容器类型: $(cat /proc/1/comm)"
echo ""

# 系统信息
echo "💻 系统信息:"
uname -a
cat /etc/os-release
echo ""

# GPU信息
echo "🎮 GPU信息:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
else
    echo "❌ NVIDIA驱动未安装"
fi
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

# 网络状态
echo "🌐 网络状态:"
netstat -tulpn | grep :8000
echo ""

# 环境变量
echo "🔧 环境变量:"
echo "CUDA_VISIBLE_DEVICES: $CUDA_VISIBLE_DEVICES"
echo "OMP_NUM_THREADS: $OMP_NUM_THREADS"
echo "PYTORCH_CUDA_ALLOC_CONF: $PYTORCH_CUDA_ALLOC_CONF"
echo ""

echo "✅ 诊断完成"
EOF

chmod +x /root/PhotoEnhanceAI/container_diagnostics.sh
```

## 🔒 容器安全配置

### 安全运行容器
```bash
# 创建非root用户
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  --user 1000:1000 \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/tmp \
  photoenhanceai
```

### 资源限制
```bash
# 限制资源使用
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  --memory=8g \
  --cpus=4.0 \
  --ulimit nofile=65536:65536 \
  photoenhanceai
```

### 网络安全
```bash
# 创建自定义网络
docker network create photoenhanceai-network

# 运行容器
docker run -d \
  --name photoenhanceai \
  --network photoenhanceai-network \
  --gpus all \
  -p 8000:8000 \
  photoenhanceai
```

## 📊 容器监控

### 容器监控脚本
```bash
# 创建容器监控脚本
cat > /root/PhotoEnhanceAI/container_monitor.sh <<'EOF'
#!/bin/bash
# 容器监控脚本

while true; do
    echo "📊 容器监控 - $(date)"
    echo "=================="
    
    # 容器资源使用
    docker stats photoenhanceai --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    # 服务状态
    if docker exec photoenhanceai curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ 服务健康"
    else
        echo "❌ 服务异常"
    fi
    
    echo ""
    sleep 60
done
EOF

chmod +x /root/PhotoEnhanceAI/container_monitor.sh
```

### 日志收集
```bash
# 配置日志收集
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  photoenhanceai
```

## 🔄 容器更新

### 滚动更新
```bash
# 使用Docker Compose滚动更新
docker-compose pull
docker-compose up -d --no-deps photoenhanceai
```

### 备份和恢复
```bash
# 备份容器
docker commit photoenhanceai photoenhanceai:backup-$(date +%Y%m%d)

# 导出镜像
docker save photoenhanceai:backup-$(date +%Y%m%d) | gzip > photoenhanceai-backup-$(date +%Y%m%d).tar.gz

# 恢复镜像
gunzip -c photoenhanceai-backup-$(date +%Y%m%d).tar.gz | docker load
```

## 🔗 相关链接

- [部署指南](DEPLOYMENT.md)
- [自动启动配置](AUTOSTART.md)
- [故障排除](TROUBLESHOOTING.md)
- [容器自动启动配置](../CONTAINER_AUTOSTART_CONFIG.md)
