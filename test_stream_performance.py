#!/usr/bin/env python3
"""
PhotoEnhanceAI 流式处理性能测试脚本
测试流式处理方案相比批量处理方案的性能提升
"""

import asyncio
import aiohttp
import time
import json
from pathlib import Path
import sys
from typing import List, Dict, Any

# 添加项目根目录到路径
PROJECT_ROOT = Path(__file__).parent
sys.path.append(str(PROJECT_ROOT))

class StreamPerformanceTester:
    """流式处理性能测试器"""
    
    def __init__(self, api_base: str = "http://localhost:8001"):
        self.api_base = api_base
        self.test_images = []
        self.results = {
            'batch_processing': {},
            'stream_processing': {}
        }
    
    def setup_test_images(self, image_dir: str = "input"):
        """设置测试图片"""
        image_path = PROJECT_ROOT / image_dir
        if not image_path.exists():
            print(f"❌ 测试图片目录不存在: {image_path}")
            return False
        
        # 查找所有图片文件
        image_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
        for ext in image_extensions:
            self.test_images.extend(list(image_path.glob(f"*{ext}")))
            self.test_images.extend(list(image_path.glob(f"*{ext.upper()}")))
        
        if not self.test_images:
            print(f"❌ 在 {image_path} 中未找到测试图片")
            return False
        
        print(f"✅ 找到 {len(self.test_images)} 张测试图片")
        return True
    
    async def test_batch_processing(self, max_images: int = 3) -> Dict[str, Any]:
        """测试批量处理方案"""
        print(f"\n🔄 测试批量处理方案 ({max_images} 张图片)...")
        
        # 准备测试图片
        test_files = self.test_images[:max_images]
        
        # 准备FormData
        form_data = aiohttp.FormData()
        for i, image_path in enumerate(test_files):
            form_data.add_field('files', open(image_path, 'rb'), filename=image_path.name)
        form_data.add_field('tile_size', '400')
        form_data.add_field('quality_level', 'high')
        
        start_time = time.time()
        first_image_time = None
        
        try:
            async with aiohttp.ClientSession() as session:
                # 上传并开始批量处理
                async with session.post(f"{self.api_base}/api/v1/enhance/batch", data=form_data) as response:
                    if response.status != 200:
                        raise Exception(f"批量上传失败: {response.status}")
                    
                    result = await response.json()
                    batch_task_id = result['batch_task_id']
                    print(f"📤 批量任务已创建: {batch_task_id}")
                
                # 监控批量处理进度
                while True:
                    async with session.get(f"{self.api_base}/api/v1/batch/status/{batch_task_id}") as response:
                        if response.status != 200:
                            raise Exception(f"状态检查失败: {response.status}")
                        
                        status = await response.json()
                        
                        # 记录第一张图片完成时间
                        if first_image_time is None and status['completed_files'] > 0:
                            first_image_time = time.time() - start_time
                            print(f"⚡ 第一张图片完成时间: {first_image_time:.2f}秒")
                        
                        print(f"📊 批量进度: {status['completed_files']}/{status['total_files']} ({status['message']})")
                        
                        if status['status'] in ['completed', 'partial_completed', 'failed']:
                            total_time = time.time() - start_time
                            break
                    
                    await asyncio.sleep(2)
                
                return {
                    'total_time': total_time,
                    'first_image_time': first_image_time,
                    'completed_files': status['completed_files'],
                    'failed_files': status['failed_files'],
                    'total_files': status['total_files'],
                    'batch_task_id': batch_task_id
                }
                
        except Exception as e:
            print(f"❌ 批量处理测试失败: {str(e)}")
            return {'error': str(e)}
    
    async def test_stream_processing(self, max_images: int = 3, max_concurrent: int = 3) -> Dict[str, Any]:
        """测试流式处理方案"""
        print(f"\n🚀 测试流式处理方案 ({max_images} 张图片, 并发数: {max_concurrent})...")
        
        # 准备测试图片
        test_files = self.test_images[:max_images]
        
        start_time = time.time()
        first_image_time = None
        completed_count = 0
        failed_count = 0
        task_results = []
        
        # 创建信号量控制并发
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def process_single_image(image_path: Path, index: int):
            """处理单张图片"""
            async with semaphore:
                nonlocal first_image_time, completed_count, failed_count
                
                try:
                    # 准备FormData
                    form_data = aiohttp.FormData()
                    form_data.add_field('file', open(image_path, 'rb'), filename=image_path.name)
                    form_data.add_field('tile_size', '400')
                    form_data.add_field('quality_level', 'high')
                    
                    async with aiohttp.ClientSession() as session:
                        # 上传并开始处理
                        async with session.post(f"{self.api_base}/api/v1/enhance", data=form_data) as response:
                            if response.status != 200:
                                raise Exception(f"上传失败: {response.status}")
                            
                            result = await response.json()
                            task_id = result['task_id']
                            print(f"📤 图片 {index + 1} 任务已创建: {task_id}")
                        
                        # 监控处理进度
                        while True:
                            async with session.get(f"{self.api_base}/api/v1/status/{task_id}") as response:
                                if response.status != 200:
                                    raise Exception(f"状态检查失败: {response.status}")
                                
                                status = await response.json()
                                
                                # 记录第一张图片完成时间
                                if first_image_time is None and status['status'] == 'completed':
                                    first_image_time = time.time() - start_time
                                    print(f"⚡ 第一张图片完成时间: {first_image_time:.2f}秒")
                                
                                if status['status'] == 'completed':
                                    completed_count += 1
                                    print(f"✅ 图片 {index + 1} 处理完成")
                                    break
                                elif status['status'] == 'failed':
                                    failed_count += 1
                                    print(f"❌ 图片 {index + 1} 处理失败: {status.get('error', '未知错误')}")
                                    break
                            
                            await asyncio.sleep(1)
                
                except Exception as e:
                    failed_count += 1
                    print(f"❌ 图片 {index + 1} 处理异常: {str(e)}")
        
        # 并发处理所有图片
        tasks = [process_single_image(image_path, i) for i, image_path in enumerate(test_files)]
        await asyncio.gather(*tasks)
        
        total_time = time.time() - start_time
        
        return {
            'total_time': total_time,
            'first_image_time': first_image_time,
            'completed_files': completed_count,
            'failed_files': failed_count,
            'total_files': len(test_files),
            'max_concurrent': max_concurrent
        }
    
    def print_performance_comparison(self):
        """打印性能对比结果"""
        print("\n" + "="*60)
        print("📊 性能对比结果")
        print("="*60)
        
        batch_result = self.results['batch_processing']
        stream_result = self.results['stream_processing']
        
        if 'error' in batch_result or 'error' in stream_result:
            print("❌ 测试过程中出现错误，无法进行对比")
            return
        
        print(f"\n🔄 批量处理方案:")
        print(f"   总时间: {batch_result['total_time']:.2f}秒")
        print(f"   第一张图片时间: {batch_result['first_image_time']:.2f}秒")
        print(f"   成功处理: {batch_result['completed_files']}/{batch_result['total_files']}")
        
        print(f"\n🚀 流式处理方案:")
        print(f"   总时间: {stream_result['total_time']:.2f}秒")
        print(f"   第一张图片时间: {stream_result['first_image_time']:.2f}秒")
        print(f"   成功处理: {stream_result['completed_files']}/{stream_result['total_files']}")
        print(f"   并发数: {stream_result['max_concurrent']}")
        
        # 计算性能提升
        if batch_result['first_image_time'] and stream_result['first_image_time']:
            first_image_improvement = ((batch_result['first_image_time'] - stream_result['first_image_time']) / batch_result['first_image_time']) * 100
            print(f"\n⚡ 第一张图片时间提升: {first_image_improvement:.1f}%")
        
        if batch_result['total_time'] and stream_result['total_time']:
            total_time_improvement = ((batch_result['total_time'] - stream_result['total_time']) / batch_result['total_time']) * 100
            print(f"⏱️ 总时间提升: {total_time_improvement:.1f}%")
        
        print(f"\n🎯 结论:")
        if stream_result['first_image_time'] < batch_result['first_image_time']:
            print(f"   ✅ 流式处理方案在第一张图片时间上表现更优")
        else:
            print(f"   ❌ 批量处理方案在第一张图片时间上表现更优")
    
    async def run_performance_test(self, max_images: int = 3):
        """运行完整的性能测试"""
        print("🧪 PhotoEnhanceAI 流式处理性能测试")
        print("="*60)
        
        # 设置测试图片
        if not self.setup_test_images():
            return
        
        # 测试批量处理方案
        self.results['batch_processing'] = await self.test_batch_processing(max_images)
        
        # 等待一段时间，避免服务器压力
        print("\n⏳ 等待5秒后开始流式处理测试...")
        await asyncio.sleep(5)
        
        # 测试流式处理方案
        self.results['stream_processing'] = await self.test_stream_processing(max_images)
        
        # 打印对比结果
        self.print_performance_comparison()

async def main():
    """主函数"""
    tester = StreamPerformanceTester()
    await tester.run_performance_test(max_images=3)

if __name__ == "__main__":
    asyncio.run(main())
