#!/bin/bash

# PhotoEnhanceAI 常驻服务启动脚本
# 使用 nohup 在后台运行

echo "🚀 启动 PhotoEnhanceAI 常驻服务..."

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

echo "✅ 服务已启动，PID: $(cat photoenhanceai.pid)"
echo "📝 日志文件: /root/PhotoEnhanceAI/logs/photoenhanceai.log"
echo "🔍 查看日志: tail -f logs/photoenhanceai.log"
echo "🛑 停止服务: kill \$(cat photoenhanceai.pid)"
