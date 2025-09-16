#!/usr/bin/env python3
"""
PhotoEnhanceAI Model Manager
管理GFPGAN模型的常驻内存，避免重复加载
"""

import asyncio
import cv2
import torch
import logging
from pathlib import Path
from typing import Optional
import sys

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelManager:
    """GFPGAN模型管理器 - 单例模式"""
    
    def __init__(self):
        self.restorer = None
        self.bg_upsampler = None
        self._lock = asyncio.Lock()
        self._initialized = False
        self._initialization_started = False
        
    async def initialize(self):
        """初始化模型（只执行一次）"""
        async with self._lock:
            if self._initialized:
                logger.info("✅ 模型已初始化，直接返回")
                return
            
            if self._initialization_started:
                # 等待其他协程完成初始化
                while not self._initialized:
                    await asyncio.sleep(0.1)
                return
            
            self._initialization_started = True
            
            try:
                logger.info("🚀 开始加载GFPGAN模型...")
                
                # 延迟导入，避免启动时的问题
                from gfpgan import GFPGANer
                from basicsr.archs.rrdbnet_arch import RRDBNet
                from realesrgan import RealESRGANer
                
                # 初始化背景超分辨率模型
                if torch.cuda.is_available():
                    logger.info("🎮 检测到CUDA，初始化RealESRGAN背景超分辨率模型...")
                    model = RRDBNet(
                        num_in_ch=3, 
                        num_out_ch=3, 
                        num_feat=64, 
                        num_block=23, 
                        num_grow_ch=32, 
                        scale=2
                    )
                    self.bg_upsampler = RealESRGANer(
                        scale=2,
                        model_path='https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x2plus.pth',
                        model=model,
                        tile=400,
                        tile_pad=10,
                        pre_pad=0,
                        half=True
                    )
                    logger.info("✅ RealESRGAN背景超分辨率模型加载完成")
                else:
                    logger.info("💻 使用CPU模式，跳过RealESRGAN背景超分辨率")
                
                # 初始化GFPGAN模型
                logger.info("🎭 初始化GFPGAN人脸修复模型...")
                model_path = PROJECT_ROOT / "models" / "gfpgan" / "GFPGANv1.4.pth"
                
                if not model_path.exists():
                    raise FileNotFoundError(f"GFPGAN模型文件不存在: {model_path}")
                
                self.restorer = GFPGANer(
                    model_path=str(model_path),
                    upscale=4,
                    arch='clean',
                    channel_multiplier=2,
                    bg_upsampler=self.bg_upsampler
                )
                
                self._initialized = True
                logger.info("🎉 GFPGAN模型加载完成！模型已常驻内存")
                
            except Exception as e:
                logger.error(f"❌ 模型初始化失败: {str(e)}")
                self._initialization_started = False
                raise e
    
    async def get_restorer(self):
        """获取模型实例"""
        await self.initialize()
        return self.restorer
    
    async def enhance_image(self, input_path: str, output_path: str, tile_size: int = 400):
        """使用常驻模型处理图片"""
        try:
            restorer = await self.get_restorer()
            
            # 读取图片
            logger.info(f"📖 读取图片: {input_path}")
            input_img = cv2.imread(input_path)
            if input_img is None:
                raise ValueError(f"无法读取图片: {input_path}")
            
            logger.info(f"🖼️ 图片尺寸: {input_img.shape}")
            
            # 处理图片
            logger.info("🎨 开始GFPGAN处理...")
            cropped_faces, restored_faces, restored_img = restorer.enhance(
                input_img,
                has_aligned=False,
                only_center_face=False,
                paste_back=True,
                weight=0.5
            )
            
            # 保存结果
            if restored_img is not None:
                cv2.imwrite(output_path, restored_img)
                logger.info(f"💾 处理完成，保存到: {output_path}")
                return True
            else:
                raise ValueError("图片处理失败，未生成结果")
                
        except Exception as e:
            logger.error(f"❌ 图片处理失败: {str(e)}")
            raise e
    
    def get_model_info(self):
        """获取模型信息"""
        return {
            "initialized": self._initialized,
            "has_bg_upsampler": self.bg_upsampler is not None,
            "has_restorer": self.restorer is not None,
            "cuda_available": torch.cuda.is_available(),
            "device": str(torch.device('cuda' if torch.cuda.is_available() else 'cpu'))
        }

# 全局模型管理器实例
model_manager = ModelManager()
