# 📘 故障排除

PhotoEnhanceAI的常见问题和解决方案。

## 🔍 常见问题

### 1. 服务启动失败

#### 问题现象
- 服务无法启动
- 端口被占用
- 进程启动后立即退出

#### 解决方案
```bash
# 检查端口占用
netstat -tulpn | grep :8000
lsof -i :8000

# 杀死占用端口的进程
sudo kill -9 $(lsof -t -i:8000)

# 检查服务状态
./status_service.sh

# 查看详细日志
tail -f logs/photoenhanceai.log

# 重新启动服务
./start_backend_daemon.sh
```

### 2. CUDA内存不足

#### 问题现象
```
RuntimeError: CUDA out of memory. Tried to allocate 2.00 GiB (GPU 0; 8.00 GiB total capacity; 6.50 GiB already allocated; 1.20 GiB free; 6.50 GiB reserved in total by PyTorch)
```

#### 解决方案
```bash
# 降低tile_size参数
curl -X POST "http://localhost:8000/api/v1/enhance" \
  -F "file=@input.jpg" \
  -F "tile_size=256" \
  -F "quality_level=fast"

# 使用资源限制启动
./start_limited.sh

# 释放GPU内存
sudo fuser -v /dev/nvidia*
sudo kill -9 <PID>

# 重启服务
./stop_service.sh
./start_backend_daemon.sh
```

### 3. 模型加载失败

#### 问题现象
- 模型文件不存在
- 模型文件损坏
- 模型加载超时

#### 解决方案
```bash
# 检查模型文件
ls -la models/gfpgan/
file models/gfpgan/GFPGANv1.3.pth

# 重新下载模型
chmod +x deploy/download_gfpgan_model.sh
./deploy/download_gfpgan_model.sh

# 验证模型文件
./local_gfpgan_test.py

# 检查文件权限
chmod 644 models/gfpgan/GFPGANv1.3.pth
```

### 4. API连接超时

#### 问题现象
- 请求超时
- 连接被拒绝
- 响应时间过长

#### 解决方案
```bash
# 检查服务状态
curl -v http://localhost:8000/health

# 增加请求超时时间
curl --max-time 300 http://localhost:8000/api/v1/status/task_id

# 检查网络连接
ping localhost
telnet localhost 8000

# 检查防火墙
sudo ufw status
sudo iptables -L
```

### 5. 自动启动失败

#### 问题现象
- 开机后服务未自动启动
- 自动启动脚本执行失败
- 服务启动后立即停止

#### 解决方案
```bash
# 检查自动启动配置
./check_autostart.sh

# 重新配置自动启动
sudo ./setup_autostart.sh

# 检查bashrc配置
grep -n "PhotoEnhanceAI" ~/.bashrc

# 手动测试启动脚本
./start_backend_daemon.sh

# 检查系统日志
journalctl -u photoenhanceai -f
```

### 6. 容器环境问题

#### 问题现象
- 容器启动失败
- 服务在容器中无法访问
- GPU在容器中不可用

#### 解决方案
```bash
# 检查容器状态
docker ps -a
docker logs photoenhanceai

# 重新构建镜像
docker build -t photoenhanceai .

# 检查GPU支持
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi

# 重新运行容器
docker run -d --name photoenhanceai --gpus all -p 8000:8000 photoenhanceai
```

## 🛠️ 诊断工具

### 系统状态检查
```bash
# 运行系统状态检查
./monitor_system.sh

# 检查资源使用
./monitor_resources.sh

# 检查服务状态
./status_service.sh

# 检查自动启动状态
./check_autostart.sh
```

### 性能诊断
```bash
# 运行性能测试
python test_stream_performance.py

# 检查GPU状态
nvidia-smi

# 检查系统负载
uptime
top
htop

# 检查内存使用
free -h
cat /proc/meminfo
```

### 网络诊断
```bash
# 检查端口状态
netstat -tulpn | grep :8000
ss -tulpn | grep :8000

# 检查网络连接
curl -v http://localhost:8000/health
telnet localhost 8000

# 检查防火墙
sudo ufw status
sudo iptables -L
```

## 🔧 修复脚本

### 一键修复脚本
```bash
# 创建一键修复脚本
cat > /root/PhotoEnhanceAI/fix_common_issues.sh <<'EOF'
#!/bin/bash
# 常见问题一键修复脚本

echo "🔧 PhotoEnhanceAI 常见问题修复"
echo "==============================="

# 1. 清理旧进程
echo "🧹 清理旧进程..."
pkill -f "python api/start_server.py"
rm -f *.pid

# 2. 检查端口占用
echo "🔍 检查端口占用..."
if lsof -i :8000 > /dev/null 2>&1; then
    echo "⚠️  端口8000被占用，正在清理..."
    sudo kill -9 $(lsof -t -i:8000)
    sleep 2
fi

# 3. 检查模型文件
echo "📁 检查模型文件..."
if [ ! -f "models/gfpgan/GFPGANv1.3.pth" ]; then
    echo "⚠️  模型文件缺失，正在下载..."
    chmod +x deploy/download_gfpgan_model.sh
    ./deploy/download_gfpgan_model.sh
fi

# 4. 检查虚拟环境
echo "🐍 检查虚拟环境..."
if [ ! -d "gfpgan_env" ]; then
    echo "⚠️  虚拟环境缺失，正在创建..."
    chmod +x deploy/setup_gfpgan_env.sh
    ./deploy/setup_gfpgan_env.sh
fi

# 5. 重新启动服务
echo "🚀 重新启动服务..."
./start_backend_daemon.sh

# 6. 验证服务状态
echo "✅ 验证服务状态..."
sleep 5
if curl -s http://localhost:8000/health | grep -q "healthy"; then
    echo "✅ 服务启动成功！"
else
    echo "❌ 服务启动失败，请查看日志"
    tail -n 20 logs/photoenhanceai.log
fi

echo "🎉 修复完成！"
EOF

chmod +x /root/PhotoEnhanceAI/fix_common_issues.sh
```

### 使用修复脚本
```bash
# 运行一键修复
./fix_common_issues.sh

# 查看修复日志
tail -f logs/photoenhanceai.log
```

## 📊 日志分析

### 日志文件位置
- **API服务日志**: `logs/photoenhanceai.log`
- **模型预热日志**: `logs/model_warmup.log`
- **Webhook注册日志**: `logs/webhook_register.log`
- **系统监控日志**: `/var/log/photoenhanceai_monitor.log`

### 日志分析工具
```bash
# 查看错误日志
grep -i error logs/photoenhanceai.log

# 查看警告日志
grep -i warning logs/photoenhanceai.log

# 查看最近的日志
tail -n 100 logs/photoenhanceai.log

# 实时查看日志
tail -f logs/photoenhanceai.log

# 按时间过滤日志
grep "$(date '+%Y-%m-%d')" logs/photoenhanceai.log
```

### 常见错误信息
| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `CUDA out of memory` | GPU显存不足 | 降低tile_size或使用fast模式 |
| `Port already in use` | 端口被占用 | 杀死占用进程或更换端口 |
| `Model file not found` | 模型文件缺失 | 重新下载模型文件 |
| `Permission denied` | 权限不足 | 检查文件权限或使用sudo |
| `Connection refused` | 服务未启动 | 启动PhotoEnhanceAI服务 |

## 🔄 恢复流程

### 完全重置
```bash
# 1. 停止所有服务
./stop_service.sh
pkill -f "python api/start_server.py"

# 2. 清理文件
rm -f *.pid
rm -rf logs/*

# 3. 重新安装
./install.sh

# 4. 重新启动
./start_backend_daemon.sh
```

### 部分恢复
```bash
# 1. 重启服务
./stop_service.sh
./start_backend_daemon.sh

# 2. 重新预热模型
./warmup_model.sh

# 3. 重新注册webhook
./register_webhook.sh
```

## 📞 获取帮助

### 收集诊断信息
```bash
# 创建诊断信息收集脚本
cat > /root/PhotoEnhanceAI/collect_diagnostics.sh <<'EOF'
#!/bin/bash
# 诊断信息收集脚本

echo "🔍 收集诊断信息..."
echo "=================="

# 系统信息
echo "📊 系统信息:"
uname -a
lsb_release -a
echo ""

# 硬件信息
echo "💻 硬件信息:"
lscpu | grep -E "Model name|CPU\(s\)"
free -h
df -h
echo ""

# GPU信息
echo "🎮 GPU信息:"
nvidia-smi
echo ""

# 服务状态
echo "🚀 服务状态:"
./status_service.sh
echo ""

# 网络状态
echo "🌐 网络状态:"
netstat -tulpn | grep :8000
echo ""

# 日志信息
echo "📝 最近日志:"
tail -n 20 logs/photoenhanceai.log
echo ""

echo "✅ 诊断信息收集完成"
EOF

chmod +x /root/PhotoEnhanceAI/collect_diagnostics.sh
```

### 联系方式
- **GitHub Issues**: [https://github.com/Rsers/PhotoEnhanceAI/issues](https://github.com/Rsers/PhotoEnhanceAI/issues)
- **Email**: support@photoenhanceai.com
- **文档**: [项目Wiki](https://github.com/Rsers/PhotoEnhanceAI/wiki)

## 🔗 相关链接

- [安装指南](INSTALLATION.md)
- [部署指南](DEPLOYMENT.md)
- [自动启动配置](AUTOSTART.md)
- [性能优化](PERFORMANCE.md)
- [容器部署](CONTAINER_DEPLOYMENT.md)
