#!/usr/bin/env python3
"""
PhotoEnhanceAI 并发数性能测试脚本
测试不同并发数下的性能表现，确定最优并发配置
"""

import asyncio
import aiohttp
import time
import json
import shutil
from pathlib import Path
import sys
from typing import List, Dict, Any
import statistics

# 添加项目根目录到路径
PROJECT_ROOT = Path(__file__).parent
sys.path.append(str(PROJECT_ROOT))

class ConcurrentPerformanceTester:
    """并发数性能测试器"""
    
    def __init__(self, api_base: str = "http://localhost:8001"):
        self.api_base = api_base
        self.test_images = []
        self.results = {}
    
    def setup_test_images(self, source_image: str = "input/test001.jpg", count: int = 10):
        """设置测试图片 - 复制test001.jpg生成多张测试图片"""
        source_path = PROJECT_ROOT / source_image
        if not source_path.exists():
            print(f"❌ 源图片不存在: {source_path}")
            return False
        
        # 创建测试图片目录
        test_dir = PROJECT_ROOT / "input" / "concurrent_test"
        test_dir.mkdir(exist_ok=True)
        
        # 清空之前的测试图片
        for file in test_dir.glob("test_*.jpg"):
            file.unlink()
        
        # 复制源图片生成测试图片
        self.test_images = []
        for i in range(count):
            test_image_path = test_dir / f"test_{i+1:03d}.jpg"
            shutil.copy2(source_path, test_image_path)
            self.test_images.append(test_image_path)
        
        print(f"✅ 已生成 {len(self.test_images)} 张测试图片")
        return True
    
    async def test_concurrent_performance(self, max_concurrent: int, test_count: int = 5) -> Dict[str, Any]:
        """测试指定并发数下的性能表现"""
        print(f"\n🚀 测试并发数 {max_concurrent} (测试 {test_count} 张图片)...")
        
        # 准备测试图片
        test_files = self.test_images[:test_count]
        
        # 多次测试取平均值
        test_results = []
        
        for test_round in range(3):  # 进行3轮测试
            print(f"   📊 第 {test_round + 1} 轮测试...")
            
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
                            
                            # 监控处理进度
                            while True:
                                async with session.get(f"{self.api_base}/api/v1/status/{task_id}") as response:
                                    if response.status != 200:
                                        raise Exception(f"状态检查失败: {response.status}")
                                    
                                    status = await response.json()
                                    
                                    # 记录第一张图片完成时间
                                    if first_image_time is None and status['status'] == 'completed':
                                        first_image_time = time.time() - start_time
                                    
                                    if status['status'] == 'completed':
                                        completed_count += 1
                                        task_results.append({
                                            'task_id': task_id,
                                            'processing_time': time.time() - start_time,
                                            'status': 'completed'
                                        })
                                        break
                                    elif status['status'] == 'failed':
                                        failed_count += 1
                                        task_results.append({
                                            'task_id': task_id,
                                            'processing_time': time.time() - start_time,
                                            'status': 'failed',
                                            'error': status.get('error', '未知错误')
                                        })
                                        break
                                
                                await asyncio.sleep(1)
                    
                    except Exception as e:
                        failed_count += 1
                        task_results.append({
                            'task_id': f'error_{index}',
                            'processing_time': time.time() - start_time,
                            'status': 'failed',
                            'error': str(e)
                        })
            
            # 并发处理所有图片
            tasks = [process_single_image(image_path, i) for i, image_path in enumerate(test_files)]
            await asyncio.gather(*tasks)
            
            total_time = time.time() - start_time
            
            test_results.append({
                'total_time': total_time,
                'first_image_time': first_image_time,
                'completed_files': completed_count,
                'failed_files': failed_count,
                'total_files': len(test_files),
                'task_results': task_results
            })
            
            # 等待一段时间避免服务器压力
            await asyncio.sleep(2)
        
        # 计算平均值
        avg_total_time = statistics.mean([r['total_time'] for r in test_results])
        avg_first_image_time = statistics.mean([r['first_image_time'] for r in test_results if r['first_image_time']])
        avg_completed_files = statistics.mean([r['completed_files'] for r in test_results])
        avg_failed_files = statistics.mean([r['failed_files'] for r in test_results])
        
        return {
            'max_concurrent': max_concurrent,
            'test_count': test_count,
            'avg_total_time': avg_total_time,
            'avg_first_image_time': avg_first_image_time,
            'avg_completed_files': avg_completed_files,
            'avg_failed_files': avg_failed_files,
            'success_rate': (avg_completed_files / test_count) * 100,
            'test_results': test_results
        }
    
    async def run_comprehensive_test(self, max_concurrent_list: List[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]):
        """运行全面的并发数测试"""
        print("🧪 PhotoEnhanceAI 并发数性能测试")
        print("="*80)
        
        # 设置测试图片
        if not self.setup_test_images():
            return
        
        # 测试不同并发数
        for max_concurrent in max_concurrent_list:
            try:
                result = await self.test_concurrent_performance(max_concurrent, test_count=5)
                self.results[max_concurrent] = result
                
                print(f"✅ 并发数 {max_concurrent} 测试完成:")
                print(f"   平均总时间: {result['avg_total_time']:.2f}秒")
                print(f"   平均第一张图片时间: {result['avg_first_image_time']:.2f}秒")
                print(f"   成功率: {result['success_rate']:.1f}%")
                
            except Exception as e:
                print(f"❌ 并发数 {max_concurrent} 测试失败: {str(e)}")
                self.results[max_concurrent] = {'error': str(e)}
            
            # 等待一段时间避免服务器压力
            print("⏳ 等待5秒后继续下一个测试...")
            await asyncio.sleep(5)
        
        # 分析结果
        self.analyze_results()
    
    def analyze_results(self):
        """分析测试结果并推荐最优并发数"""
        print("\n" + "="*80)
        print("📊 并发数性能分析结果")
        print("="*80)
        
        # 过滤掉有错误的结果
        valid_results = {k: v for k, v in self.results.items() if 'error' not in v}
        
        if not valid_results:
            print("❌ 没有有效的测试结果")
            return
        
        # 创建结果表格
        print(f"\n{'并发数':<6} {'总时间(秒)':<12} {'第一张图片(秒)':<15} {'成功率(%)':<10} {'推荐度':<8}")
        print("-" * 60)
        
        best_first_image_time = float('inf')
        best_total_time = float('inf')
        best_success_rate = 0
        best_concurrent = 1
        
        for concurrent, result in sorted(valid_results.items()):
            total_time = result['avg_total_time']
            first_image_time = result['avg_first_image_time']
            success_rate = result['success_rate']
            
            # 计算推荐度 (综合考虑时间、成功率)
            if success_rate >= 95:  # 成功率必须>=95%
                recommendation_score = (1 / total_time) * (success_rate / 100)
            else:
                recommendation_score = 0
            
            # 更新最佳结果
            if success_rate >= 95:
                if first_image_time < best_first_image_time:
                    best_first_image_time = first_image_time
                    best_concurrent = concurrent
                
                if total_time < best_total_time:
                    best_total_time = total_time
            
            if success_rate > best_success_rate:
                best_success_rate = success_rate
            
            # 推荐度标记
            if recommendation_score > 0:
                if concurrent == best_concurrent:
                    recommendation = "🥇 最佳"
                elif recommendation_score > 0.8:
                    recommendation = "🥈 推荐"
                elif recommendation_score > 0.6:
                    recommendation = "🥉 可用"
                else:
                    recommendation = "⚠️ 一般"
            else:
                recommendation = "❌ 不推荐"
            
            print(f"{concurrent:<6} {total_time:<12.2f} {first_image_time:<15.2f} {success_rate:<10.1f} {recommendation:<8}")
        
        # 推荐最优并发数
        print(f"\n🎯 推荐结果:")
        print(f"   最优并发数: {best_concurrent}")
        print(f"   第一张图片时间: {best_first_image_time:.2f}秒")
        print(f"   总处理时间: {best_total_time:.2f}秒")
        print(f"   成功率: {best_success_rate:.1f}%")
        
        # 性能分析
        print(f"\n📈 性能分析:")
        if best_concurrent <= 3:
            print(f"   ✅ 低并发配置，适合资源有限的服务器")
        elif best_concurrent <= 6:
            print(f"   ✅ 中等并发配置，平衡性能和稳定性")
        else:
            print(f"   ✅ 高并发配置，适合高性能服务器")
        
        # 保存详细结果
        self.save_detailed_results()
    
    def save_detailed_results(self):
        """保存详细的测试结果"""
        results_file = PROJECT_ROOT / "concurrent_test_results.json"
        
        with open(results_file, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, indent=2, ensure_ascii=False)
        
        print(f"\n💾 详细结果已保存到: {results_file}")

async def main():
    """主函数"""
    tester = ConcurrentPerformanceTester()
    
    # 测试并发数 1-10
    await tester.run_comprehensive_test([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

if __name__ == "__main__":
    asyncio.run(main())
