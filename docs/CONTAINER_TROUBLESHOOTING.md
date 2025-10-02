# 📘 容器环境故障排除

PhotoEnhanceAI在容器环境中的特殊问题和解决方案。

## 🐳 容器环境问题

### 1. 容器启动失败

#### 问题现象
- 容器无法启动
- 容器启动后立即退出
- 容器内服务无法访问

#### 解决方案
```bash
# 检查容器日志
docker logs photoenhanceai

# 检查镜像构建
docker build -t photoenhanceai . --no-cache

# 检查GPU支持
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi

# 重新运行容器
docker run -d --name photoenhanceai --gpus all -p 8000:8000 photoenhanceai
```

### 2. GPU在容器中不可用

#### 问题现象
- nvidia-smi命令不可用
- CUDA不可用
- 模型加载失败

#### 解决方案
```bash
# 检查NVIDIA Docker支持
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi

# 安装NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# 验证GPU支持
docker run --rm --gpus all photoenhanceai nvidia-smi
```

### 3. 服务在容器中无法访问

#### 问题现象
- 端口无法访问
- 连接被拒绝
- 网络不通

#### 解决方案
```bash
# 检查端口映射
docker port photoenhanceai

# 检查网络配置
docker network ls
docker network inspect bridge

# 测试容器内连接
docker exec photoenhanceai curl http://localhost:8000/health

# 检查防火墙
sudo ufw status
sudo iptables -L
```

## 🔧 腾讯云容器环境问题

### 环境特征
- 使用 `dumb-init` 作为PID 1进程
- 没有 systemd 服务管理
- rc.local 可能不会自动执行
- 需要多重启动保障机制

### 常见问题

#### 1. 开机自启动失败
```bash
# 检查自动启动配置
./check_autostart.sh

# 重新配置自动启动
sudo ./setup_container_autostart.sh

# 检查bashrc配置
grep -n "PhotoEnhanceAI" ~/.bashrc

# 手动测试启动脚本
./start_backend_daemon.sh
```

#### 2. 服务启动后立即停止
```bash
# 检查服务日志
tail -f logs/photoenhanceai.log

# 检查系统日志
journalctl -u photoenhanceai -f

# 检查资源使用
free -h && ps aux --sort=-%mem | head -5

# 重新启动服务
./stop_service.sh
./start_backend_daemon.sh
```

#### 3. 网络连接问题
```bash
# 检查网络状态
ping google.com
curl -v http://localhost:8000/health

# 检查DNS配置
cat /etc/resolv.conf

# 重启网络服务
sudo systemctl restart networking
```

## 🛠️ 容器诊断工具

### 容器环境诊断脚本
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
    if command -v docker &> /dev/null; then
        docker stats photoenhanceai --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    fi
    
    # 服务状态
    if pgrep -f "python api/start_server.py" > /dev/null; then
        echo "✅ PhotoEnhanceAI 服务运行正常"
    else
        echo "❌ PhotoEnhanceAI 服务未运行"
    fi
    
    # API健康检查
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ API服务健康"
    else
        echo "❌ API服务异常"
    fi
    
    echo ""
    sleep 60
done
EOF

chmod +x /root/PhotoEnhanceAI/container_monitor.sh
```

## 🔄 容器恢复流程

### 完全重置容器
```bash
# 1. 停止并删除容器
docker stop photoenhanceai
docker rm photoenhanceai

# 2. 重新构建镜像
docker build -t photoenhanceai .

# 3. 重新运行容器
docker run -d --name photoenhanceai --gpus all -p 8000:8000 photoenhanceai

# 4. 验证容器状态
docker ps -a
docker logs photoenhanceai
```

### 部分恢复
```bash
# 1. 重启容器
docker restart photoenhanceai

# 2. 进入容器
docker exec -it photoenhanceai bash

# 3. 重启服务
./stop_service.sh
./start_backend_daemon.sh

# 4. 验证服务状态
curl http://localhost:8000/health
```

## 📊 容器性能优化

### 资源限制
```bash
# 限制容器资源使用
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  --memory=8g \
  --cpus=4.0 \
  --ulimit nofile=65536:65536 \
  photoenhanceai
```

### 存储优化
```bash
# 使用数据卷
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  -v /data/models:/app/models \
  -v /data/logs:/app/logs \
  photoenhanceai
```

### 网络优化
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

## 🔗 相关链接

- [容器部署](CONTAINER_DEPLOYMENT.md)
- [故障排除](TROUBLESHOOTING.md)
- [自动启动配置](AUTOSTART.md)
- [监控运维](MONITORING.md)
