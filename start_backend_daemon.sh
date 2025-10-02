#!/bin/bash

# PhotoEnhanceAI - 后台常驻服务启动脚本（生产环境推荐）
# ✅ 后台模式特点：
#   - 不占用终端窗口，立即返回命令行
#   - 关闭终端后服务继续运行
#   - 日志写入文件，通过 tail -f 查看
#   - 适合生产环境长期运行
# 💡 开发调试请使用: start_frontend_only.sh

echo "=========================================="
echo "🚀 后台模式启动 PhotoEnhanceAI 常驻服务"
echo "✅ 不占用终端，服务将在后台持续运行"
echo "✅ 关闭终端后服务不会停止"
echo "💡 前台调试请使用: ./start_frontend_only.sh"
echo "=========================================="
echo ""

# 进入项目目录
cd /root/PhotoEnhanceAI

# 激活虚拟环境
source gfpgan_env/bin/activate

# 创建日志目录
mkdir -p logs

# 使用 nohup 在后台运行，输出重定向到日志文件
nohup python api/start_server.py > logs/photoenhanceai.log 2>&1 &

# 保存进程ID
echo $! > photoenhanceai.pid

echo "✅ 服务已在后台启动，PID: $(cat photoenhanceai.pid)"
echo "📝 日志文件: /root/PhotoEnhanceAI/logs/photoenhanceai.log"
echo "🔍 查看日志: tail -f logs/photoenhanceai.log"
echo "🛑 停止服务: kill \$(cat photoenhanceai.pid)"
echo ""

# 启动模型预热（后台运行）
echo "🔥 启动AI模型预热进程..."
nohup ./warmup_model.sh > logs/model_warmup.log 2>&1 &
echo $! > model_warmup.pid

echo "✅ AI模型预热进程已启动，PID: $(cat model_warmup.pid)"
echo "📝 模型预热日志: /root/PhotoEnhanceAI/logs/model_warmup.log"
echo "🔍 查看预热日志: tail -f logs/model_warmup.log"

# 启动webhook注册（后台运行）
echo "🌐 启动webhook注册进程..."
nohup ./register_webhook.sh > logs/webhook_register.log 2>&1 &
echo $! > webhook_register.pid

echo "✅ Webhook注册进程已启动，PID: $(cat webhook_register.pid)"
echo "📝 Webhook日志: /root/PhotoEnhanceAI/logs/webhook_register.log"
echo "🔍 查看注册日志: tail -f logs/webhook_register.log"
echo ""
echo "=========================================="
echo "提示："
echo "  • 现在可以关闭终端，服务会继续运行"
echo "  • 日志不会显示在屏幕上，需要查看日志文件"
echo "  • AI模型预热将在后台自动进行"
echo "  • Webhook注册将在后台自动进行"
echo "=========================================="

