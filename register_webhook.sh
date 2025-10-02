#!/bin/bash

# PhotoEnhanceAI - Webhook注册脚本
# 用于在服务启动后自动注册到API网关

# 配置参数
WEBHOOK_URL="https://www.gongjuxiang.work/webhook/register"
SECRET="gpu-server-register-to-api-gateway-2024"
API_PORT=8000

echo "=========================================="
echo "🌐 正在注册 PhotoEnhanceAI 服务到API网关"
echo "=========================================="

# 等待服务启动（给服务一些启动时间）
echo "⏳ 等待服务启动..."
sleep 10

# 检查本地服务是否启动
echo "🔍 检查本地API服务状态..."
if curl -s http://localhost:${API_PORT}/health > /dev/null 2>&1; then
    echo "✅ 本地API服务运行正常"
else
    echo "⚠️  本地API服务可能未完全启动，继续尝试注册..."
fi

# 查询公网IP
echo "🌍 查询公网IP地址..."
PUBLIC_IP=$(curl -s --connect-timeout 10 https://api.ipify.org 2>/dev/null || curl -s --connect-timeout 10 https://ipv4.icanhazip.com 2>/dev/null || curl -s --connect-timeout 10 https://checkip.amazonaws.com 2>/dev/null)

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ 无法获取公网IP地址"
    echo "🔧 请检查网络连接或手动配置公网IP"
    exit 1
fi

echo "✅ 公网IP: $PUBLIC_IP"

# 构建注册数据
REGISTER_DATA=$(cat <<EOF
{
    "ip": "$PUBLIC_IP",
    "port": $API_PORT,
    "secret": "$SECRET"
}
EOF
)

echo "📡 正在注册到API网关..."
echo "🔗 注册URL: $WEBHOOK_URL"
echo "📊 注册数据: $REGISTER_DATA"

# 发送注册请求
RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$REGISTER_DATA" \
    --connect-timeout 30 \
    --max-time 60)

# 检查响应
if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    echo "✅ 注册请求发送成功"
    echo "📝 服务器响应: $RESPONSE"
    
    # 尝试解析响应中的success字段
    if echo "$RESPONSE" | grep -q '"success":\s*true'; then
        echo "🎉 服务注册成功！"
        echo "🌐 您的PhotoEnhanceAI服务已可通过以下地址访问："
        echo "   http://$PUBLIC_IP:$API_PORT"
        echo "   http://$PUBLIC_IP:$API_PORT/docs (API文档)"
    else
        echo "⚠️  注册可能失败，请检查服务器响应"
        echo "📝 响应内容: $RESPONSE"
    fi
else
    echo "❌ 注册请求失败"
    echo "🔧 请检查网络连接和API网关地址"
    echo "📝 错误信息: $RESPONSE"
fi

echo "=========================================="
