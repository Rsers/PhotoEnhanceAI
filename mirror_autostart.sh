#!/bin/bash

# PhotoEnhanceAI 镜像环境自动启动脚本
# 专门解决镜像文件在新服务器上开机时的自动启动问题

echo "🚀 PhotoEnhanceAI 镜像环境自动启动开始..."
echo "📅 启动时间: $(date)"
echo "🖥️  主机名: $(hostname)"
echo "⏰ 系统运行时间: $(uptime)"

# 进入项目目录
cd /root/PhotoEnhanceAI

# 清理可能存在的旧PID文件（镜像环境常见问题）
echo "🧹 清理旧的PID文件..."
rm -f *.pid

# 等待网络完全就绪（镜像环境网络初始化较慢）
echo "🌐 等待网络就绪..."
sleep 15

# 检查GPU状态
echo "🎮 检查GPU状态..."
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits
else
    echo "⚠️  nvidia-smi 不可用"
fi

# 检查Python环境
echo "🐍 检查Python环境..."
if [ -d "venv" ]; then
    echo "✅ 虚拟环境存在"
    source venv/bin/activate
else
    echo "⚠️  虚拟环境不存在，使用系统Python"
fi

# 检查CUDA环境
echo "🔧 检查CUDA环境..."
python -c "
try:
    import torch
    print(f'✅ PyTorch版本: {torch.__version__}')
    print(f'✅ CUDA可用: {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'✅ GPU设备数: {torch.cuda.device_count()}')
        print(f'✅ 当前设备: {torch.cuda.get_device_name(0)}')
except ImportError:
    print('⚠️  PyTorch未安装')
except Exception as e:
    print(f'⚠️  CUDA检查失败: {e}')
"

# 启动主服务
echo "🚀 启动PhotoEnhanceAI主服务..."
nohup ./start_backend_daemon.sh > logs/mirror_autostart.log 2>&1 &
MAIN_PID=$!
echo "📝 主服务PID: $MAIN_PID"

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid)
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI服务启动成功 (PID: $PID)"
    else
        echo "❌ PhotoEnhanceAI服务启动失败"
    fi
else
    echo "❌ PID文件不存在"
fi

# 检查API健康状态
echo "🏥 检查API健康状态..."
sleep 5
if curl -s http://localhost:8000/health >/dev/null 2>&1; then
    echo "✅ API服务健康检查通过"
    curl -s http://localhost:8000/health | python -m json.tool
else
    echo "❌ API服务健康检查失败"
fi

# 启动模型预热
echo "🔥 启动模型预热..."
nohup ./warmup_model.sh > logs/mirror_warmup.log 2>&1 &
WARMUP_PID=$!
echo "📝 模型预热PID: $WARMUP_PID"

# 启动Webhook注册
echo "🔗 启动Webhook注册..."
nohup ./register_webhook.sh > logs/mirror_webhook.log 2>&1 &
WEBHOOK_PID=$!
echo "📝 Webhook注册PID: $WEBHOOK_PID"

echo "🎉 PhotoEnhanceAI镜像环境自动启动完成!"
echo "📊 启动的服务:"
echo "   - 主服务PID: $MAIN_PID"
echo "   - 模型预热PID: $WARMUP_PID" 
echo "   - Webhook注册PID: $WEBHOOK_PID"
echo "📝 日志文件:"
echo "   - 主启动日志: logs/mirror_autostart.log"
echo "   - 模型预热日志: logs/mirror_warmup.log"
echo "   - Webhook注册日志: logs/mirror_webhook.log"
echo "🌐 API地址: http://$(hostname -I | awk '{print $1}'):8000"
echo "📖 API文档: http://$(hostname -I | awk '{print $1}'):8000/docs"
