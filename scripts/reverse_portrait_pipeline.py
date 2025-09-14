#!/usr/bin/env python3
"""
反向人像处理流水线
流程: SwinIR专业处理 → GFPGAN人脸精修
策略: 先获得整体高质量效果，再专门优化人脸细节
"""

import argparse
import cv2
import numpy as np
import os
import sys
import subprocess
import shutil
from pathlib import Path
import time

def apply_swinir_professional_processing(input_path, temp_dir, tile_size=400):
    """第1步: 使用AAA_professional_portrait.jpg的处理方式"""
    print("🚀 第1步: SwinIR专业处理中...")
    print("  📋 包含: 人像预处理增强 → SwinIR 4倍超分辨率 → 智能后处理")
    
    # 生成中间文件路径
    swinir_output = os.path.join(temp_dir, "swinir_processed.jpg")
    
    # 使用social_media_upscale.py进行专业处理
    # 这个脚本包含了AAA_professional_portrait.jpg使用的完整处理流程
    swinir_cmd = f"""
    source /root/SwinIR/swinir_env/bin/activate && \
    cd /root/SwinIR && \
    python social_media_upscale.py --input {input_path} --output {swinir_output} --tile {tile_size}
    """
    
    result = subprocess.run(swinir_cmd, shell=True, capture_output=True, text=True, executable='/bin/bash')
    
    if result.returncode != 0:
        print(f"❌ SwinIR专业处理失败: {result.stderr}")
        return None
    
    if os.path.exists(swinir_output):
        print(f"✅ SwinIR专业处理完成: {swinir_output}")
        return swinir_output
    else:
        print("❌ SwinIR专业处理输出文件不存在")
        return None

def apply_gfpgan_face_refinement(input_path, output_path, temp_dir):
    """第2步: GFPGAN人脸精修"""
    print("🎨 第2步: GFPGAN人脸精修中...")
    print("  📋 专门针对已放大的高质量图像进行人脸细节优化")
    
    # 激活gfpgan环境并运行
    gfpgan_cmd = f"""
    source /root/gfpgan_env/bin/activate && \
    cd /root/GFPGAN && \
    python inference_gfpgan.py -i {input_path} -o {temp_dir}/gfpgan_final -v 1.4 -s 1
    """
    
    result = subprocess.run(gfpgan_cmd, shell=True, capture_output=True, text=True, executable='/bin/bash')
    
    if result.returncode != 0:
        print(f"❌ GFPGAN人脸精修失败: {result.stderr}")
        return False
    
    # 查找输出文件
    restored_dir = f"{temp_dir}/gfpgan_final/restored_imgs"
    if os.path.exists(restored_dir):
        files = os.listdir(restored_dir)
        if files:
            restored_path = os.path.join(restored_dir, files[0])
            # 复制到最终输出位置
            shutil.copy2(restored_path, output_path)
            print(f"✅ GFPGAN人脸精修完成: {output_path}")
            return True
    
    print("❌ 未找到GFPGAN人脸精修输出文件")
    return False

def main():
    parser = argparse.ArgumentParser(description='反向人像处理流水线: SwinIR专业处理 → GFPGAN人脸精修')
    parser.add_argument('--input', '-i', type=str, required=True, help='输入图片路径')
    parser.add_argument('--output', '-o', type=str, required=True, help='输出图片路径')
    parser.add_argument('--tile', type=int, default=400, help='SwinIR tile大小 (默认400)')
    parser.add_argument('--keep-temp', action='store_true', help='保留中间文件')
    
    args = parser.parse_args()
    
    # 检查输入文件
    if not os.path.exists(args.input):
        print(f"❌ 输入文件不存在: {args.input}")
        return
    
    # 创建临时目录
    temp_dir = "/tmp/reverse_portrait_pipeline"
    os.makedirs(temp_dir, exist_ok=True)
    
    try:
        print(f"""
🎯 开始反向人像处理: {args.input}
📋 反向处理流程:
  1️⃣ SwinIR专业处理 (预处理+4倍超分辨率+后处理)
  2️⃣ GFPGAN人脸精修 (针对高分辨率图像的人脸优化)
🎨 处理策略: 先整体质量 → 再人脸细节
💡 预期效果: 背景优秀 + 人脸精细 = 完美结合
        """)
        
        start_time = time.time()
        
        # 第1步: SwinIR专业处理
        swinir_output = apply_swinir_professional_processing(args.input, temp_dir, args.tile)
        if not swinir_output:
            print("❌ SwinIR专业处理失败，流水线终止")
            return
        
        # 第2步: GFPGAN人脸精修
        success = apply_gfpgan_face_refinement(swinir_output, args.output, temp_dir)
        if not success:
            print("❌ GFPGAN人脸精修失败，流水线终止")
            return
        
        # 处理完成
        end_time = time.time()
        processing_time = end_time - start_time
        
        # 获取文件信息
        input_size = os.path.getsize(args.input) / (1024*1024)
        output_size = os.path.getsize(args.output) / (1024*1024)
        
        print(f"""
🎉 **反向人像处理完成！**

📊 处理结果:
├─ 输入文件: {args.input} ({input_size:.1f}MB)
├─ 输出文件: {args.output} ({output_size:.1f}MB)
├─ 处理时间: {processing_time:.1f}秒
├─ 文件增长: {output_size/input_size:.1f}x
└─ 质量提升: SwinIR专业处理 + GFPGAN人脸精修

✨ 反向流程优势:
🎯 第1步-SwinIR专业处理:
  ├─ 人像预处理增强 (对比度+锐化)
  ├─ 4倍AI超分辨率放大
  ├─ 智能后处理优化 (降噪+细节保护)
  └─ 获得整体高质量的大尺寸图像

🎨 第2步-GFPGAN人脸精修:
  ├─ 基于高分辨率图像进行人脸检测
  ├─ AI修复人脸细节和纹理
  ├─ 保持整体图像的优秀效果
  └─ 专门优化面部清晰度

🏆 最终效果特点:
✅ 背景处理: 继承SwinIR的优秀整体效果
✅ 人脸细节: GFPGAN在高分辨率下的精细修复
✅ 综合质量: 两种AI技术的最佳结合
✅ 处理策略: 先建立基础质量，再精雕细琢
        """)
        
    finally:
        # 清理临时文件
        if not args.keep_temp and os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
            print("🧹 已清理临时文件")

if __name__ == '__main__':
    main()
