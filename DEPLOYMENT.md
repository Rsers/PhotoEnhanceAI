# PhotoEnhanceAI 部署指南

## 🎯 概述

PhotoEnhanceAI 是一个独立的 AI 图像增强项目，集成了 GFPGAN 人脸修复和超分辨率功能。本指南将帮助您在新服务器上从零开始部署。

## 🚀 一键部署（推荐）

### 新服务器快速部署

```bash
# 1. 克隆项目
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI

# 2. 一键安装
chmod +x install.sh
./install.sh

# 3. 验证部署
./verify_deployment.sh
```

## 📋 系统要求

### 最低要求
- **操作系统**: Ubuntu 18.04+ / CentOS 7+ / Windows 10+ (WSL2)
- **Python**: 3.8 - 3.10
- **存储**: 2GB+ (包含模型文件)
- **内存**: 4GB+ RAM

### 推荐配置
- **操作系统**: Ubuntu 20.04+ / CentOS 8+
- **Python**: 3.9
- **GPU**: NVIDIA GPU (8GB+ VRAM)
- **CUDA**: 11.6+ (推荐11.8)
- **存储**: 5GB+ (SSD推荐)
- **内存**: 16GB+ RAM

## 🔧 手动部署

### 步骤 1: 安装系统依赖

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y python3-venv python3-dev python3-pip \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev \
    libgomp1 git wget curl build-essential cmake
```

#### CentOS/RHEL
```bash
sudo yum install -y python3-devel python3-pip mesa-libGL gcc git wget curl cmake
```

#### Fedora
```bash
sudo dnf install -y python3-devel python3-pip mesa-libGL gcc git wget curl cmake
```

### 步骤 2: 设置环境

```bash
# 运行环境安装脚本
chmod +x deploy/setup_gfpgan_env.sh
./deploy/setup_gfpgan_env.sh
```

### 步骤 3: 下载模型

```bash
# 下载 GFPGAN 模型文件
chmod +x deploy/download_gfpgan_model.sh
./deploy/download_gfpgan_model.sh
```

### 步骤 4: 验证安装

```bash
# 测试环境
./test_installation.sh

# 验证部署
./verify_deployment.sh
```

## 🎨 使用方法

### 命令行使用

```bash
# 基本用法
python gfpgan_core.py --input input/your_image.jpg --output output/enhanced.jpg --scale 4

# 查看所有选项
python gfpgan_core.py --help

# 快速开始（使用测试图片）
./quick_start.sh
```

### 参数说明

- `--input, -i`: 输入图像路径
- `--output, -o`: 输出图像路径
- `--scale, -s`: 分辨率放大倍数 (1, 2, 4, 8, 10, 16)
- `--quality`: 处理质量等级 (fast, balanced, high)
- `--tile-size`: 瓦片大小，影响显存使用 (256-512)

### 示例

```bash
# 4倍放大，高质量
python gfpgan_core.py --input input/photo.jpg --output output/enhanced.jpg --scale 4 --quality high

# 2倍放大，快速处理
python gfpgan_core.py --input input/photo.jpg --output output/enhanced.jpg --scale 2 --quality fast

# 自定义瓦片大小
python gfpgan_core.py --input input/photo.jpg --output output/enhanced.jpg --scale 4 --tile-size 512
```

## 📁 项目结构

```
PhotoEnhanceAI/
├── gfpgan/                    # GFPGAN核心模块
│   ├── inference_gfpgan.py  # GFPGAN推理脚本
│   ├── archs/               # 网络架构
│   ├── models/              # 模型定义
│   └── utils.py             # 工具函数
├── models/gfpgan/            # AI模型文件
│   └── GFPGANv1.4.pth       # GFPGAN模型文件
├── input/                    # 输入图片目录
├── output/                   # 输出结果目录
├── scripts/                  # 核心处理脚本
├── api/                      # Web API服务
├── deploy/                   # 部署脚本
├── docs/                     # 文档
├── gfpgan_core.py            # 独立命令行工具
├── test_gfpgan.py           # 测试脚本
├── install.sh               # 一键安装脚本
├── verify_deployment.sh     # 部署验证脚本
└── quick_start.sh           # 快速开始脚本
```

## 🔍 故障排除

### 常见问题

#### 1. Python 版本不兼容
```bash
# 检查 Python 版本
python3 --version

# 如果版本过低，安装 Python 3.8+
sudo apt-get install python3.8 python3.8-venv python3.8-dev
```

#### 2. GPU 不可用
```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 检查 CUDA
nvcc --version

# 如果没有 GPU，项目仍可在 CPU 上运行（较慢）
```

#### 3. 模型下载失败
```bash
# 手动下载模型
wget -O models/gfpgan/GFPGANv1.4.pth \
  https://github.com/TencentARC/GFPGAN/releases/download/v1.3.8/GFPGANv1.4.pth
```

#### 4. 内存不足
```bash
# 使用较小的瓦片大小
python gfpgan_core.py --input input/photo.jpg --output output/enhanced.jpg --scale 4 --tile-size 256

# 或使用快速模式
python gfpgan_core.py --input input/photo.jpg --output output/enhanced.jpg --scale 4 --quality fast
```

### 性能优化

#### GPU 优化
```bash
# 检查 GPU 使用情况
nvidia-smi

# 监控 GPU 使用
watch -n 1 nvidia-smi
```

#### 内存优化
- **4GB VRAM**: `--tile-size 256`
- **8GB VRAM**: `--tile-size 400` (推荐)
- **12GB+ VRAM**: `--tile-size 512`

## 📊 性能基准

| 图片尺寸 | 处理时间 | 输出分辨率 | 显存占用 | 推荐配置 |
|----------|----------|-----------|----------|----------|
| 512×512 | 8-12秒 | 2048×2048 | 2-4GB | tile_size=512 |
| 1080×1440 | 14-18秒 | 4320×5760 | 6-10GB | tile_size=400 |
| 2048×2048 | 35-50秒 | 8192×8192 | 12-16GB | tile_size=256 |

## 🔄 更新升级

### 更新项目
```bash
# 拉取最新代码
git pull origin main

# 重新安装环境（如果需要）
./install.sh
```

### 更新模型
```bash
# 重新下载模型
./deploy/download_gfpgan_model.sh
```

## 📞 获取帮助

如果遇到问题：

1. 查看 [故障排除文档](troubleshooting.md)
2. 检查 [GitHub Issues](https://github.com/Rsers/PhotoEnhanceAI/issues)
3. 提交新的 Issue 描述问题
4. 参与 [GitHub Discussions](https://github.com/Rsers/PhotoEnhanceAI/discussions)

## 🎉 部署成功

部署成功后，您就可以开始使用 PhotoEnhanceAI 进行专业级的人像照片增强了！

### 快速测试
```bash
# 使用测试图片
python gfpgan_core.py --input input/test001.jpg --output output/test001_enhanced.jpg --scale 4

# 查看结果
ls -la output/
```

---

**PhotoEnhanceAI** - 让手机照片达到单反级别的效果！ ✨
