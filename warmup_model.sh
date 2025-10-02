#!/bin/bash

# PhotoEnhanceAI - AI模型预热脚本
# 用于在服务启动后自动预热AI模型，让模型常驻内存

echo "=========================================="
echo "🔥 PhotoEnhanceAI AI模型预热"
echo "=========================================="

# 进入项目目录
cd /root/PhotoEnhanceAI

# 激活虚拟环境
source gfpgan_env/bin/activate

# 检查测试图片是否存在
TEST_IMAGE="/root/PhotoEnhanceAI/input/test001.jpg"
if [ ! -f "$TEST_IMAGE" ]; then
    echo "⚠️  测试图片不存在: $TEST_IMAGE"
    echo "🔧 尝试查找其他测试图片..."
    
    # 查找其他测试图片
    TEST_IMAGE=$(find /root/PhotoEnhanceAI/input -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | head -1)
    
    if [ -z "$TEST_IMAGE" ]; then
        echo "❌ 未找到任何测试图片"
        echo "📁 请在 /root/PhotoEnhanceAI/input/ 目录下放置测试图片"
        exit 1
    fi
fi

echo "✅ 使用测试图片: $TEST_IMAGE"

# 创建输出目录
OUTPUT_DIR="/root/PhotoEnhanceAI/output"
mkdir -p "$OUTPUT_DIR"

# 生成预热输出文件名
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="$OUTPUT_DIR/warmup_${TIMESTAMP}.jpg"

echo "📝 预热输出文件: $OUTPUT_FILE"
echo ""

# 执行模型预热
echo "🚀 开始AI模型预热..."
echo "⏳ 正在加载GFPGAN模型到内存..."

# 运行GFPGAN处理
python /root/PhotoEnhanceAI/gfpgan_core.py \
    --input "$TEST_IMAGE" \
    --output "$OUTPUT_FILE" \
    --scale 4

# 检查预热是否成功
if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo ""
    echo "✅ AI模型预热成功！"
    echo "🎯 GFPGAN模型已加载到内存"
    echo "⚡ 后续请求将获得更快的响应速度"
    echo "📁 预热输出文件: $OUTPUT_FILE"
    
    # 显示文件大小信息
    INPUT_SIZE=$(du -h "$TEST_IMAGE" | cut -f1)
    OUTPUT_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "📊 文件大小对比:"
    echo "   输入: $INPUT_SIZE"
    echo "   输出: $OUTPUT_SIZE"
    
    # 清理预热输出文件（可选）
    echo ""
    echo "🗑️  清理预热输出文件..."
    rm -f "$OUTPUT_FILE"
    echo "✅ 预热文件已清理"
    
else
    echo ""
    echo "❌ AI模型预热失败"
    echo "🔧 请检查模型文件和配置"
    exit 1
fi

echo ""
echo "=========================================="
echo "🎉 AI模型预热完成！"
echo "💾 模型已常驻内存，准备接受请求"
echo "=========================================="
