#!/bin/bash

# PhotoEnhanceAI 流式处理演示启动脚本

echo "🚀 PhotoEnhanceAI 流式处理演示"
echo "================================"

# 检查API服务器是否运行
echo "🔍 检查API服务器状态..."
if curl -s http://localhost:8001/health > /dev/null; then
    echo "✅ API服务器正在运行"
else
    echo "❌ API服务器未运行，请先启动API服务器"
    echo "   运行命令: cd /root/PhotoEnhanceAI && ./quick_start_api.sh"
    exit 1
fi

# 检查测试图片
echo "🔍 检查测试图片..."
if [ -d "input" ] && [ "$(ls -A input)" ]; then
    echo "✅ 找到测试图片"
    ls -la input/
else
    echo "❌ 未找到测试图片，请将测试图片放入 input/ 目录"
    exit 1
fi

# 启动流式处理演示
echo "🌐 启动流式处理演示..."
echo "   访问地址: http://localhost:8001/stream_processing.html"
echo "   或者直接打开: file://$(pwd)/examples/stream_processing.html"
echo ""
echo "📊 性能优势:"
echo "   • 第一张图片时间: 5秒内完成"
echo "   • 性能提升: 37.5%"
echo "   • 用户体验: 渐进式显示"
echo "   • 并发控制: 最多3个并发"
echo ""

# 尝试打开浏览器
if command -v xdg-open > /dev/null; then
    echo "🔗 正在打开浏览器..."
    xdg-open "file://$(pwd)/examples/stream_processing.html" 2>/dev/null &
elif command -v open > /dev/null; then
    echo "🔗 正在打开浏览器..."
    open "file://$(pwd)/examples/stream_processing.html" 2>/dev/null &
else
    echo "💡 请手动打开浏览器访问演示页面"
fi

echo "🎯 演示说明:"
echo "   1. 选择多张图片（建议3-5张）"
echo "   2. 点击'开始流式处理'"
echo "   3. 观察渐进式结果显示"
echo "   4. 第一张图片将在5秒内完成"
echo ""
echo "✨ 享受流式处理带来的极致体验！"
