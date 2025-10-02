#!/bin/bash

# PhotoEnhanceAI - 容器环境开机自启动脚本
# 适用于 Docker 容器或非 systemd 环境

echo "=========================================="
echo "🐳 PhotoEnhanceAI 容器环境自启动"
echo "=========================================="

# 项目目录
PROJECT_DIR="/root/PhotoEnhanceAI"
LOG_DIR="$PROJECT_DIR/logs"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 等待网络就绪
echo "🌐 等待网络就绪..."
sleep 5

# 检查虚拟环境
if [ ! -f "$PROJECT_DIR/gfpgan_env/bin/python" ]; then
    echo "❌ 虚拟环境不存在: $PROJECT_DIR/gfpgan_env/bin/python"
    exit 1
fi

# 进入项目目录
cd "$PROJECT_DIR"

# 激活虚拟环境
source gfpgan_env/bin/activate

# 启动主服务
echo "🚀 启动 PhotoEnhanceAI API 服务..."
nohup python api/start_server.py > "$LOG_DIR/photoenhanceai.log" 2>&1 &
MAIN_PID=$!
echo $MAIN_PID > "$PROJECT_DIR/photoenhanceai.pid"

# 等待主服务启动
sleep 3

# 检查主服务是否启动成功
if ps -p $MAIN_PID > /dev/null; then
    echo "✅ 主服务启动成功 (PID: $MAIN_PID)"
else
    echo "❌ 主服务启动失败"
    exit 1
fi

# 启动模型预热
echo "🔥 启动AI模型预热..."
nohup ./warmup_model.sh > "$LOG_DIR/model_warmup.log" 2>&1 &
WARMUP_PID=$!
echo $WARMUP_PID > "$PROJECT_DIR/model_warmup.pid"

# 启动webhook注册
echo "🌐 启动webhook注册..."
nohup ./register_webhook.sh > "$LOG_DIR/webhook_register.log" 2>&1 &
WEBHOOK_PID=$!
echo $WEBHOOK_PID > "$PROJECT_DIR/webhook_register.pid"

echo "✅ 所有服务启动完成"
echo "📝 日志文件:"
echo "  主服务: $LOG_DIR/photoenhanceai.log"
echo "  模型预热: $LOG_DIR/model_warmup.log"
echo "  Webhook: $LOG_DIR/webhook_register.log"

# 保持脚本运行，监控主服务
echo "🔍 开始监控服务状态..."
while true; do
    if ! ps -p $MAIN_PID > /dev/null; then
        echo "⚠️  主服务异常退出，尝试重启..."
        nohup python api/start_server.py > "$LOG_DIR/photoenhanceai.log" 2>&1 &
        MAIN_PID=$!
        echo $MAIN_PID > "$PROJECT_DIR/photoenhanceai.pid"
        echo "✅ 主服务已重启 (PID: $MAIN_PID)"
    fi
    sleep 30
done
