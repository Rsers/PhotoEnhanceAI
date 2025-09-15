#!/bin/bash

# PhotoEnhanceAI API 极简启动脚本
# 最简单的启动方式

echo "🚀 启动 PhotoEnhanceAI API 服务..."

# 进入项目目录
cd /root/PhotoEnhanceAI

# 激活虚拟环境
source gfpgan_env/bin/activate

# 启动API服务
python api/start_server.py
