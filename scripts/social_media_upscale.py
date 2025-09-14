#!/usr/bin/env python3
"""
社交媒体照片超分辨率处理工具
专门用于提升社交媒体照片的分辨率和清晰度

使用方法:
python social_media_upscale.py --input 低分辨率图片.jpg --output 高分辨率图片.jpg

特点:
- 4倍超分辨率放大
- 专门优化社交媒体照片处理
- 支持GPU加速
- 内存不足时自动使用tile模式
"""

import argparse
import cv2
import numpy as np
import os
import torch
from models.network_swinir import SwinIR as net
import time
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description='社交媒体照片超分辨率处理工具')
    parser.add_argument('--input', type=str, required=True, help='输入图片路径')
    parser.add_argument('--output', type=str, help='输出图片路径（默认在输入文件同目录）')
    parser.add_argument('--model_path', type=str, 
                       default='model_zoo/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth', 
                       help='模型路径')
    parser.add_argument('--tile', type=int, default=400, 
                       help='tile大小，显存不足时减小此值')
    parser.add_argument('--gpu', action='store_true', default=True, 
                       help='使用GPU加速（默认开启）')
    args = parser.parse_args()

    # 检查输入文件
    if not os.path.exists(args.input):
        print(f'❌ 输入文件不存在: {args.input}')
        return

    # 设置输出路径
    if args.output is None:
        input_path = Path(args.input)
        args.output = str(input_path.parent / f"{input_path.stem}_4x{input_path.suffix}")

    # 设备配置
    if args.gpu and torch.cuda.is_available():
        device = torch.device('cuda')
        print(f'🚀 使用GPU加速: {torch.cuda.get_device_name(0)}')
        print(f'📊 显存: {torch.cuda.get_device_properties(0).total_memory // 1024**3}GB')
    else:
        device = torch.device('cpu')
        print('💻 使用CPU处理')

    # 检查模型文件
    if not os.path.exists(args.model_path):
        print(f'❌ 模型文件不存在: {args.model_path}')
        print('请确保已下载模型文件')
        return

    print('🔄 加载模型...')
    start_time = time.time()

    # 定义模型（经典超分辨率配置）
    model = net(upscale=4, in_chans=3, img_size=48, window_size=8,
                img_range=1., depths=[6, 6, 6, 6, 6, 6], embed_dim=180,
                num_heads=[6, 6, 6, 6, 6, 6], mlp_ratio=2, 
                upsampler='pixelshuffle', resi_connection='1conv')
    
    # 加载预训练权重
    pretrained_model = torch.load(args.model_path, map_location=device, weights_only=False)
    param_key_g = 'params_ema' if 'params_ema' in pretrained_model.keys() else 'params'
    model.load_state_dict(pretrained_model[param_key_g] if param_key_g in pretrained_model.keys() else pretrained_model, strict=True)
    model.eval()
    model = model.to(device)
    
    load_time = time.time() - start_time
    print(f'✅ 模型加载完成 ({load_time:.2f}秒)')

    # 读取输入图片
    print(f'📖 读取图片: {args.input}')
    img_lq = cv2.imread(args.input, cv2.IMREAD_COLOR)
    if img_lq is None:
        print('❌ 无法读取图片，请检查文件格式')
        return

    original_h, original_w = img_lq.shape[:2]
    print(f'📏 原始尺寸: {original_w}x{original_h}')

    # 预处理
    img_lq = img_lq.astype(np.float32) / 255.
    img_lq = np.transpose(img_lq[:, :, [2, 1, 0]], (2, 0, 1))  # BGR to RGB, HWC to CHW
    img_lq = torch.from_numpy(img_lq).float().unsqueeze(0).to(device)  # NCHW

    # 推理
    print('🎯 开始超分辨率处理...')
    inference_start = time.time()
    
    with torch.no_grad():
        # 填充到8的倍数（窗口大小要求）
        _, _, h_old, w_old = img_lq.size()
        h_pad = (h_old // 8 + 1) * 8 - h_old
        w_pad = (w_old // 8 + 1) * 8 - w_old
        img_lq = torch.cat([img_lq, torch.flip(img_lq, [2])], 2)[:, :, :h_old + h_pad, :]
        img_lq = torch.cat([img_lq, torch.flip(img_lq, [3])], 3)[:, :, :, :w_old + w_pad]
        
        # 选择推理模式
        if args.tile and (h_old > args.tile or w_old > args.tile):
            print(f'🔧 使用Tile模式处理 (tile_size={args.tile})')
            output = tile_inference(img_lq, model, args.tile)
        else:
            print('⚡ 直接推理模式')
            try:
                output = model(img_lq)
            except RuntimeError as e:
                if 'out of memory' in str(e):
                    print('⚠️  显存不足，切换到Tile模式')
                    torch.cuda.empty_cache()
                    output = tile_inference(img_lq, model, args.tile)
                else:
                    raise e
        
        # 裁剪到原始尺寸的4倍
        output = output[..., :h_old * 4, :w_old * 4]

    inference_time = time.time() - inference_start
    print(f'✅ 处理完成 ({inference_time:.2f}秒)')

    # 后处理和保存
    print('💾 保存结果...')
    output = output.data.squeeze().float().cpu().clamp_(0, 1).numpy()
    if output.ndim == 3:
        output = np.transpose(output[[2, 1, 0], :, :], (1, 2, 0))  # CHW-RGB to HWC-BGR
    output = (output * 255.0).round().astype(np.uint8)

    # 保存图片
    success = cv2.imwrite(args.output, output)
    if success:
        output_h, output_w = output.shape[:2]
        print(f'🎉 处理成功！')
        print(f'📁 输出文件: {args.output}')
        print(f'📏 输出尺寸: {output_w}x{output_h}')
        print(f'📈 放大倍数: {output_w//original_w}x')
        print(f'⏱️  总耗时: {time.time() - start_time:.2f}秒')
        
        # 文件大小信息
        input_size = os.path.getsize(args.input) / 1024
        output_size = os.path.getsize(args.output) / 1024
        print(f'📦 文件大小: {input_size:.1f}KB → {output_size:.1f}KB')
    else:
        print('❌ 保存失败')

def tile_inference(img_lq, model, tile_size=400):
    """
    Tile模式推理，将大图分块处理以节省显存
    """
    b, c, h, w = img_lq.size()
    tile = min(tile_size, h, w)
    assert tile % 8 == 0, "tile size should be multiple of 8"
    
    tile_overlap = 32
    stride = tile - tile_overlap
    h_idx_list = list(range(0, h-tile, stride)) + [h-tile]
    w_idx_list = list(range(0, w-tile, stride)) + [w-tile]
    E = torch.zeros(b, c, h * 4, w * 4, dtype=img_lq.dtype, device=img_lq.device)
    W = torch.zeros_like(E)

    total_tiles = len(h_idx_list) * len(w_idx_list)
    current_tile = 0

    for h_idx in h_idx_list:
        for w_idx in w_idx_list:
            current_tile += 1
            print(f'  处理块 {current_tile}/{total_tiles}', end='\r')
            
            in_patch = img_lq[..., h_idx:h_idx+tile, w_idx:w_idx+tile]
            out_patch = model(in_patch)
            out_patch_mask = torch.ones_like(out_patch)

            E[..., h_idx*4:(h_idx+tile)*4, w_idx*4:(w_idx+tile)*4].add_(out_patch)
            W[..., h_idx*4:(h_idx+tile)*4, w_idx*4:(w_idx+tile)*4].add_(out_patch_mask)
    
    print()  # 换行
    output = E.div_(W)
    return output

if __name__ == '__main__':
    print("🌟 社交媒体照片超分辨率处理工具")
    print("=" * 50)
    main()
