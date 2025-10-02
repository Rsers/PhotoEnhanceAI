# 📘 镜像部署

PhotoEnhanceAI的镜像文件部署和问题解决方案。

## 🖼️ 镜像环境问题

### 问题背景
使用镜像文件在新服务器上开机部署时，可能出现以下问题：
- 服务未自动启动
- 网络环境变化
- 硬件环境变化
- 系统环境变化
- 旧PID文件中的进程ID在新服务器上不存在

### 环境特征
- 使用镜像文件在新服务器上部署
- 网络环境、硬件环境、系统环境发生变化
- 旧PID文件中的进程ID在新服务器上不存在
- 可能出现"address already in use"错误

## 🔧 解决方案

### 一键配置镜像环境自动启动
```bash
# 一键配置镜像环境自动启动（推荐）
./setup_mirror_autostart.sh

# 手动启动镜像环境服务
./mirror_autostart.sh

# 检查服务状态
./status_service.sh

# 查看启动日志
tail -f logs/mirror_autostart.log
```

### 核心特性
- 🧠 **智能检测**: 根据系统运行时间判断环境类型
- 🧹 **环境清理**: 自动清理旧PID文件和进程状态
- 🌐 **网络适配**: 延长网络初始化等待时间
- 🎮 **硬件检测**: 检查GPU和CUDA环境状态
- 🔄 **多重保障**: 配置多种自动启动机制
- 📝 **详细日志**: 记录启动过程和问题诊断

## 📊 启动流程

```
1. 系统开机 → 2. 智能检测环境 → 3. 清理旧状态 → 4. 等待网络就绪
   ↓
5. 检查硬件环境 → 6. 启动主服务 → 7. 模型预热 → 8. Webhook注册
```

## ⚙️ 配置特点

- **运行时间<10分钟**: 使用镜像环境启动脚本
- **运行时间>10分钟**: 使用标准启动检查
- **自动清理**: 清理旧PID文件和进程状态
- **延长等待**: 网络等待20秒，硬件检测15秒
- **状态验证**: 检查服务、API、GPU状态

## 📁 日志文件

- `logs/mirror_autostart.log` - 镜像启动日志
- `logs/mirror_warmup.log` - 模型预热日志
- `logs/mirror_webhook.log` - Webhook注册日志
- `logs/profile_autostart.log` - 配置启动日志

## 🛠️ 故障排除

### 常见问题

#### 1. 服务未自动启动
```bash
# 检查服务状态
./status_service.sh

# 查看启动日志
tail -f logs/mirror_autostart.log

# 手动启动
./mirror_autostart.sh

# 重新配置
./setup_mirror_autostart.sh
```

#### 2. 网络环境变化
```bash
# 检查网络状态
ping google.com
curl -v http://localhost:8000/health

# 检查DNS配置
cat /etc/resolv.conf

# 重启网络服务
sudo systemctl restart networking
```

#### 3. 硬件环境变化
```bash
# 检查GPU状态
nvidia-smi

# 检查CUDA环境
python3 -c "import torch; print(torch.cuda.is_available())"

# 重新安装驱动（如果需要）
sudo apt update
sudo apt install nvidia-driver-470
```

#### 4. 端口绑定失败
```bash
# 检查端口占用
netstat -tulpn | grep :8000
lsof -i :8000

# 杀死占用端口的进程
sudo kill -9 $(lsof -t -i:8000)

# 重新启动服务
./start_backend_daemon.sh
```

## 🔍 镜像环境诊断

### 诊断脚本
```bash
# 创建镜像环境诊断脚本
cat > /root/PhotoEnhanceAI/mirror_diagnostics.sh <<'EOF'
#!/bin/bash
# 镜像环境诊断脚本

echo "🔍 镜像环境诊断"
echo "================"

# 系统运行时间
UPTIME=$(uptime -p)
echo "📅 系统运行时间: $UPTIME"

# 网络环境
echo "🌐 网络环境:"
echo "IP地址: $(hostname -I)"
echo "主机名: $(hostname)"
echo ""

# 硬件环境
echo "💻 硬件环境:"
echo "CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)"
echo "内存: $(free -h | grep Mem | awk '{print $2}')"
echo ""

# GPU环境
echo "🎮 GPU环境:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
    echo "❌ NVIDIA驱动未安装"
fi
echo ""

# 服务状态
echo "🚀 服务状态:"
if pgrep -f "python api/start_server.py" > /dev/null; then
    echo "✅ PhotoEnhanceAI 服务运行正常"
else
    echo "❌ PhotoEnhanceAI 服务未运行"
fi
echo ""

# PID文件状态
echo "📁 PID文件状态:"
if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ PID文件有效: $PID"
    else
        echo "❌ PID文件无效: $PID (进程不存在)"
    fi
else
    echo "❌ PID文件不存在"
fi
echo ""

echo "✅ 诊断完成"
EOF

chmod +x /root/PhotoEnhanceAI/mirror_diagnostics.sh
```

## 🔄 镜像环境恢复

### 完全重置
```bash
# 1. 停止所有服务
./stop_service.sh
pkill -f "python api/start_server.py"

# 2. 清理旧状态
rm -f *.pid
rm -rf logs/*

# 3. 重新配置
./setup_mirror_autostart.sh

# 4. 重新启动
./mirror_autostart.sh
```

### 部分恢复
```bash
# 1. 清理旧PID文件
rm -f *.pid

# 2. 重启服务
./start_backend_daemon.sh

# 3. 重新预热模型
./warmup_model.sh

# 4. 重新注册webhook
./register_webhook.sh
```

## 📊 镜像环境监控

### 监控脚本
```bash
# 创建镜像环境监控脚本
cat > /root/PhotoEnhanceAI/mirror_monitor.sh <<'EOF'
#!/bin/bash
# 镜像环境监控脚本

while true; do
    echo "📊 镜像环境监控 - $(date)"
    echo "========================"
    
    # 系统运行时间
    UPTIME=$(uptime -p)
    echo "系统运行时间: $UPTIME"
    
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
    
    # GPU状态
    if command -v nvidia-smi &> /dev/null; then
        GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
        echo "GPU使用率: ${GPU_UTIL}%"
    fi
    
    echo ""
    sleep 60
done
EOF

chmod +x /root/PhotoEnhanceAI/mirror_monitor.sh
```

## 🎯 最佳实践

### 1. 镜像部署前准备
```bash
# 清理旧状态
rm -f *.pid
rm -rf logs/*

# 备份重要配置
cp -r models/ models_backup/
cp -r config/ config_backup/
```

### 2. 镜像部署后验证
```bash
# 运行诊断脚本
./mirror_diagnostics.sh

# 检查服务状态
./status_service.sh

# 测试API功能
curl http://localhost:8000/health
```

### 3. 监控和维护
```bash
# 启动监控
nohup ./mirror_monitor.sh > /var/log/mirror_monitor.log 2>&1 &

# 定期检查日志
tail -f logs/mirror_autostart.log
```

## 🔗 相关链接

- [自动启动配置](AUTOSTART.md)
- [故障排除](TROUBLESHOOTING.md)
- [部署指南](DEPLOYMENT.md)
- [镜像自动启动解决方案](../MIRROR_AUTOSTART_SOLUTION.md)
