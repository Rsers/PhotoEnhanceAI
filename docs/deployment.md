# PhotoEnhanceAI 部署指南

## 🎯 系统要求

### 硬件要求

- **GPU**: NVIDIA GPU with CUDA support (推荐8GB+ VRAM)
- **内存**: 16GB+ RAM
- **存储**: 10GB+ 可用空间
- **CPU**: 多核处理器 (GPU加速时CPU要求不高)

### 软件要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Windows 10+ (WSL2)
- **Python**: 3.8 - 3.10
- **CUDA**: 11.6+ (推荐11.8)
- **Git**: 最新版本

## 🚀 快速部署

### 方法一：一键自动部署

```bash
# 1. 克隆仓库
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI

# 2. 运行自动部署脚本
chmod +x deploy/setup_environment.sh
./deploy/setup_environment.sh

# 3. 下载模型文件
chmod +x models/download_models.sh
./models/download_models.sh

# 4. 测试安装
./test_installation.sh
```

### 方法二：手动部署

#### 步骤1：环境准备

```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装系统依赖
sudo apt install -y python3-venv python3-dev libgl1-mesa-glx \
    libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 \
    git wget curl

# 检查CUDA安装
nvidia-smi
nvcc --version
```

#### 步骤2：创建虚拟环境

```bash
# 创建SwinIR环境
python3 -m venv swinir_env
source swinir_env/bin/activate

# 安装SwinIR依赖
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install opencv-python Pillow numpy scikit-image tqdm pyyaml scipy matplotlib

deactivate

# 创建GFPGAN环境
python3 -m venv gfpgan_env
source gfpgan_env/bin/activate

# 安装GFPGAN依赖
pip install torch==1.12.1+cu116 torchvision==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
pip install basicsr facexlib gfpgan realesrgan
pip install opencv-python Pillow numpy scikit-image tqdm pyyaml lmdb yapf addict
pip install scipy numba tb-nightly future filterpy matplotlib

deactivate
```

#### 步骤3：下载模型文件

```bash
# 创建模型目录
mkdir -p models/swinir models/gfpgan

# 下载SwinIR模型
wget -O models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth \
    https://github.com/JingyunLiang/SwinIR/releases/download/v0.0/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth

# 下载GFPGAN模型
wget -O models/gfpgan/GFPGANv1.4.pth \
    https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth
```

## 🧪 验证安装

### 基础测试

```bash
# 测试环境
./test_installation.sh

# 测试处理单张图片
python gfpgan_cli.py \
    --input input/sample_input.jpg \
    --output output/sample_output.jpg \
    --tile 400
```

### 性能测试

```bash
# 小图片测试 (快速)
python gfpgan_cli.py \
    --input input/sample_input.jpg \
    --output output/test_small.jpg \
    --tile 256

# 大图片测试 (质量)
python gfpgan_cli.py \
    --input input/sample_input.jpg \
    --output output/test_large.jpg \
    --tile 512
```

## ⚙️ 配置优化

### GPU优化

```bash
# 检查GPU状态
nvidia-smi

# 监控GPU使用
watch -n 1 nvidia-smi
```

### 内存优化

根据你的GPU显存调整tile大小：

- **4GB VRAM**: `--tile 256`
- **8GB VRAM**: `--tile 400` (推荐)
- **12GB+ VRAM**: `--tile 512`

### 批量处理

```bash
# 处理目录中的所有图片
for file in input_dir/*.jpg; do
    python gfpgan_cli.py \
        --input "$file" \
        --output "output_dir/$(basename "$file" .jpg)_enhanced.jpg" \
        --tile 400
done
```

## 🐳 Docker部署 (可选)

### 构建Docker镜像

```dockerfile
# Dockerfile
FROM nvidia/cuda:11.8-devel-ubuntu20.04

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    libgl1-mesa-glx libglib2.0-0 \
    git wget curl

# 复制项目文件
COPY . /app
WORKDIR /app

# 运行安装脚本
RUN ./deploy/setup_environment.sh
RUN ./models/download_models.sh

# 设置入口点
ENTRYPOINT ["python", "gfpgan_cli.py"]
```

### 运行Docker容器

```bash
# 构建镜像
docker build -t photoenhanceai .

# 运行容器
docker run --gpus all -v $(pwd)/input:/app/input -v $(pwd)/output:/app/output \
    photoenhanceai --input /app/input/image.jpg --output /app/output/enhanced.jpg
```

## 🔧 故障排除

### 常见问题

#### 1. CUDA版本不匹配

```bash
# 检查CUDA版本
nvcc --version

# 重新安装对应版本的PyTorch
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

#### 2. 显存不足

```bash
# 减小tile大小
python gfpgan_cli.py --tile 256

# 或者使用CPU模式 (很慢)
CUDA_VISIBLE_DEVICES="" python gfpgan_cli.py
```

#### 3. 模型文件损坏

```bash
# 重新下载模型
rm models/swinir/*.pth models/gfpgan/*.pth
./models/download_models.sh
```

#### 4. 依赖冲突

```bash
# 清理环境重新安装
rm -rf swinir_env gfpgan_env
./deploy/setup_environment.sh
```

### 日志和调试

```bash
# 启用详细日志
python gfpgan_cli.py --input image.jpg --output output.jpg --verbose

# 检查GPU使用情况
nvidia-smi -l 1
```

## 📊 性能基准

### 处理时间参考

| 输入大小 | GPU型号 | Tile大小 | 处理时间 | 显存使用 |
|----------|---------|----------|----------|----------|
| 0.5MB    | RTX 3080 | 400     | ~60秒    | ~10GB   |
| 0.5MB    | RTX 4090 | 512     | ~40秒    | ~12GB   |
| 1.0MB    | RTX 3080 | 400     | ~120秒   | ~12GB   |

### 优化建议

1. **使用SSD存储**：提高I/O性能
2. **充足内存**：避免虚拟内存使用
3. **最新驱动**：使用最新的NVIDIA驱动
4. **合适tile大小**：平衡速度和质量

## 🔄 更新升级

### 更新项目

```bash
# 拉取最新代码
git pull origin main

# 更新依赖 (如果需要)
source swinir_env/bin/activate
pip install -r requirements/swinir_requirements.txt --upgrade
deactivate

source gfpgan_env/bin/activate
pip install -r requirements/gfpgan_requirements.txt --upgrade
deactivate
```

### 版本管理

```bash
# 查看当前版本
git log --oneline -5

# 切换到特定版本
git checkout v1.0.0
```

## 📞 获取帮助

如果遇到问题：

1. 查看 [故障排除文档](troubleshooting.md)
2. 检查 [GitHub Issues](https://github.com/Rsers/PhotoEnhanceAI/issues)
3. 提交新的Issue描述问题
4. 参与 [GitHub Discussions](https://github.com/Rsers/PhotoEnhanceAI/discussions)

---

**部署成功后，你就可以开始使用PhotoEnhanceAI进行专业级的人像照片增强了！** ✨
