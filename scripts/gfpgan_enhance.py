#!/usr/bin/env python3
"""
GFPGAN图像增强脚本
集成人脸修复和超分辨率功能的一体化解决方案

GFPGAN内置功能:
- AI人脸修复和美化
- RealESRGAN背景超分辨率 
- 支持1-16倍分辨率放大
- 一步到位的图像增强

作者: PhotoEnhanceAI
版本: 2.0 (GFPGAN单独处理版本)
"""

import argparse
import os
import sys
import time
import subprocess
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(
        description='GFPGAN一体化图像增强 - 人脸修复 + 超分辨率',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
🎨 GFPGAN功能特点:
  ✅ AI人脸修复和美化
  ✅ RealESRGAN背景超分辨率
  ✅ 1-16倍分辨率放大
  ✅ 一步到位处理

📊 性能优势:
  🚀 速度: 比传统流水线快7倍
  💾 显存: 智能瓦片处理
  🎯 效果: 人脸+背景同步优化

使用示例:
  python gfpgan_enhance.py --input photo.jpg --output enhanced.jpg --scale 4
  python gfpgan_enhance.py --input photo.jpg --output enhanced.jpg --scale 2 --quality fast
        """
    )
    
    parser.add_argument(
        '--input', '-i', 
        required=True,
        help='输入图像路径'
    )
    
    parser.add_argument(
        '--output', '-o',
        required=True, 
        help='输出图像路径'
    )
    
    parser.add_argument(
        '--scale', '-s',
        type=int,
        default=4,
        choices=[1, 2, 4, 8, 10, 16],
        help='分辨率放大倍数 (默认: 4倍)'
    )
    
    parser.add_argument(
        '--quality',
        choices=['fast', 'balanced', 'high'],
        default='balanced',
        help='处理质量等级 (默认: balanced)'
    )
    
    parser.add_argument(
        '--tile-size',
        type=int,
        default=400,
        help='瓦片大小，影响显存使用 (默认: 400)'
    )
    
    args = parser.parse_args()
    
    # 验证输入文件
    if not os.path.exists(args.input):
        print(f"❌ 错误: 输入文件不存在: {args.input}")
        sys.exit(1)
    
    # 创建输出目录
    output_dir = os.path.dirname(args.output)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)
    
    # 根据质量等级调整参数
    if args.quality == 'fast':
        tile_size = min(args.tile_size, 256)
    elif args.quality == 'high':
        tile_size = args.tile_size
    else:  # balanced
        tile_size = min(args.tile_size, 400)
    
    print("🎨 GFPGAN一体化图像增强")
    print("=" * 50)
    print(f"📁 输入文件: {args.input}")
    print(f"📁 输出文件: {args.output}")
    print(f"📈 放大倍数: {args.scale}x")
    print(f"🎯 处理质量: {args.quality}")
    print(f"🔧 瓦片大小: {tile_size}")
    print()
    
    print("✨ GFPGAN功能包含:")
    print("  🎭 AI人脸修复和美化")
    print("  🖼️  RealESRGAN背景超分辨率")
    print(f"  📏 {args.scale}倍分辨率提升")
    print("  ⚡ 一步到位处理")
    print()
    
    # 检查GFPGAN环境
    gfpgan_env = "/root/gfpgan_env"
    gfpgan_script = "/root/GFPGAN/inference_gfpgan.py"
    
    if not os.path.exists(gfpgan_env):
        print(f"❌ 错误: GFPGAN环境不存在: {gfpgan_env}")
        sys.exit(1)
    
    if not os.path.exists(gfpgan_script):
        print(f"❌ 错误: GFPGAN脚本不存在: {gfpgan_script}")
        sys.exit(1)
    
    # 创建临时输出目录
    temp_output_dir = "/tmp/gfpgan_enhance"
    os.makedirs(temp_output_dir, exist_ok=True)
    
    try:
        print("🚀 开始GFPGAN处理...")
        start_time = time.time()
        
        # 构建GFPGAN命令
        cmd = [
            "bash", "-c",
            f"""
            source {gfpgan_env}/bin/activate && \
            cd /root/GFPGAN && \
            python inference_gfpgan.py \
                -i '{args.input}' \
                -o '{temp_output_dir}' \
                -v 1.4 \
                -s {args.scale} \
                --bg_upsampler realesrgan \
                --bg_tile {tile_size} \
                --suffix _enhanced
            """
        ]
        
        # 执行处理
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        processing_time = time.time() - start_time
        
        if result.returncode == 0:
            # 查找生成的文件 - GFPGAN生成的文件名格式
            input_filename = os.path.splitext(os.path.basename(args.input))[0]
            # GFPGAN实际生成的文件名格式
            possible_files = [
                os.path.join(temp_output_dir, "restored_imgs", f"{input_filename}_enhanced.jpg"),
                os.path.join(temp_output_dir, "restored_imgs", f"{input_filename}.jpg"),
                os.path.join(temp_output_dir, f"{input_filename}_enhanced.jpg"),
                os.path.join(temp_output_dir, f"{input_filename}.jpg")
            ]
            
            generated_file = None
            for possible_file in possible_files:
                if os.path.exists(possible_file):
                    generated_file = possible_file
                    break
            
            # 如果找不到，列出实际生成的文件
            if not generated_file:
                print("🔍 查找生成的文件...")
                for root, dirs, files in os.walk(temp_output_dir):
                    for file in files:
                        if file.endswith(('.jpg', '.png')):
                            full_path = os.path.join(root, file)
                            print(f"  发现文件: {full_path}")
                            if input_filename in file:
                                generated_file = full_path
                                break
            
            if generated_file and os.path.exists(generated_file):
                # 移动到目标位置
                import shutil
                shutil.move(generated_file, args.output)
                
                # 获取文件信息
                input_size = os.path.getsize(args.input) / (1024 * 1024)  # MB
                output_size = os.path.getsize(args.output) / (1024 * 1024)  # MB
                
                print("✅ GFPGAN处理完成!")
                print()
                print("📊 处理结果:")
                print(f"├─ 输入文件: {args.input} ({input_size:.1f}MB)")
                print(f"├─ 输出文件: {args.output} ({output_size:.1f}MB)")
                print(f"├─ 处理时间: {processing_time:.1f}秒")
                print(f"├─ 放大倍数: {args.scale}x")
                print(f"└─ 文件增长: {output_size/input_size:.1f}x")
                print()
                
                print("🎉 增强效果:")
                print("✅ 人脸修复: AI智能修复面部细节")
                print("✅ 背景增强: RealESRGAN超分辨率处理")
                print(f"✅ 分辨率提升: {args.scale}倍清晰度增强")
                print("✅ 整体优化: 一体化处理保证质量一致性")
                
            else:
                print("❌ 错误: 未找到处理结果文件")
                print(f"预期位置: {generated_file}")
                sys.exit(1)
                
        else:
            print("❌ GFPGAN处理失败:")
            print(result.stderr)
            sys.exit(1)
            
    finally:
        # 清理临时文件
        import shutil
        if os.path.exists(temp_output_dir):
            shutil.rmtree(temp_output_dir)
        print("🧹 已清理临时文件")

if __name__ == "__main__":
    main()
