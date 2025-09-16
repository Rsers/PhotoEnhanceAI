#!/usr/bin/env python3
"""
PhotoEnhanceAI - GFPGAN 测试脚本
简单的功能测试脚本
"""

import os
import sys
import subprocess
from pathlib import Path

def test_gfpgan():
    """测试GFPGAN功能"""
    print("🧪 PhotoEnhanceAI - GFPGAN 功能测试")
    print("=" * 50)
    
    # 检查环境
    gfpgan_env = "/root/PhotoEnhanceAI/gfpgan_env"
    if not os.path.exists(gfpgan_env):
        print("❌ GFPGAN环境不存在")
        return False
    
    # 检查测试文件
    test_input = "input/test001.jpg"
    if not os.path.exists(test_input):
        print("❌ 测试输入文件不存在")
        return False
    
    # 运行测试
    try:
        cmd = [
            "bash", "-c",
            f"source {gfpgan_env}/bin/activate && python gfpgan_core.py --input {test_input} --output output/test_output.jpg --scale 2 --quality fast"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        
        if result.returncode == 0:
            print("✅ GFPGAN功能测试通过")
            print("📁 输出文件: output/test_output.jpg")
            return True
        else:
            print("❌ GFPGAN功能测试失败")
            print(f"错误信息: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ 测试超时")
        return False
    except Exception as e:
        print(f"❌ 测试异常: {e}")
        return False

if __name__ == "__main__":
    success = test_gfpgan()
    sys.exit(0 if success else 1)
