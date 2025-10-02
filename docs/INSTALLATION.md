# 📘 安装指南

PhotoEnhanceAI的详细安装步骤和系统要求说明。

## 🔧 系统要求

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

### 硬件加速
- **GPU**: 支持CUDA的NVIDIA显卡
- **显存**: 8GB+ (推荐12GB+)
- **CPU**: 多核处理器 (GPU加速时CPU要求不高)

## 🚀 一键安装（推荐）

在新服务器上从零部署：

```bash
# 克隆项目
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI

# 一键安装
chmod +x install.sh
./install.sh
```

## 🔨 手动安装

### 1. 安装系统依赖

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

### 2. 设置环境
```bash
# 运行环境安装脚本
chmod +x deploy/setup_gfpgan_env.sh
./deploy/setup_gfpgan_env.sh

# 下载模型文件
chmod +x deploy/download_gfpgan_model.sh
./deploy/download_gfpgan_model.sh
```

### 3. 测试安装
```bash
# 测试环境
./local_gfpgan_test.py

# 处理测试图片
python gfpgan_core.py --input input/test001.jpg --output output/enhanced.jpg --scale 4
```

### 4. 启动API服务
```bash
# 前台启动（开发调试 - 占用终端，可看实时日志）
./start_frontend_only.sh

# 后台启动（生产环境推荐 - 不占用终端，关闭终端继续运行）
./start_backend_daemon.sh

# Supervisor启动（容器环境推荐 - 专业服务管理，自动重启）
./start_supervisor.sh

# 详细信息启动（诊断模式 - 显示完整环境信息）
./verbose_info_start_api.sh
```

## 🎮 GPU配置

### CUDA安装
```bash
# 检查CUDA版本
nvidia-smi

# 安装CUDA 11.8 (推荐)
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run
sudo sh cuda_11.8.0_520.61.05_linux.run
```

### PyTorch安装
```bash
# 激活虚拟环境
source gfpgan_env/bin/activate

# 安装PyTorch with CUDA 11.8
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

## 🐳 Docker安装

### 构建镜像
```bash
# 构建镜像
docker build -t photoenhanceai .
```

### 运行容器
```bash
# 运行容器
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  -v /data/models:/app/models \
  photoenhanceai
```

## 🔍 安装验证

### 环境检查
```bash
# 检查Python版本
python3 --version

# 检查CUDA
nvidia-smi

# 检查PyTorch
python3 -c "import torch; print(torch.cuda.is_available())"
```

### 功能测试
```bash
# 测试GFPGAN模型
./local_gfpgan_test.py

# 测试API服务
curl http://localhost:8000/health

# 测试图像处理
python gfpgan_core.py --input input/test001.jpg --output output/test.jpg
```

## 🛠️ 故障排除

### 常见安装问题

1. **CUDA内存不足**
   ```bash
   # 检查GPU状态
   nvidia-smi
   
   # 释放GPU内存
   sudo fuser -v /dev/nvidia*
   sudo kill -9 <PID>
   ```

2. **模型下载失败**
   ```bash
   # 手动下载模型
   wget https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.3.pth
   mv GFPGANv1.3.pth models/gfpgan/
   ```

3. **依赖安装失败**
   ```bash
   # 清理pip缓存
   pip cache purge
   
   # 重新安装
   pip install -r requirements/gfpgan_requirements.txt
   ```

### 系统兼容性

| 系统 | Python版本 | CUDA版本 | 状态 |
|------|------------|----------|------|
| Ubuntu 20.04 | 3.8-3.10 | 11.6+ | ✅ 完全支持 |
| Ubuntu 18.04 | 3.8-3.9 | 11.6+ | ✅ 支持 |
| CentOS 7 | 3.8-3.9 | 11.6+ | ✅ 支持 |
| CentOS 8 | 3.8-3.10 | 11.6+ | ✅ 完全支持 |
| Windows 10 (WSL2) | 3.8-3.10 | 11.6+ | ✅ 支持 |

## 📋 安装清单

安装完成后，请确认以下文件存在：

- [ ] `gfpgan_env/` - Python虚拟环境
- [ ] `models/gfpgan/GFPGANv1.3.pth` - GFPGAN模型文件
- [ ] `api/start_server.py` - API服务启动脚本
- [ ] `start_frontend_only.sh` - 前台启动脚本
- [ ] `start_backend_daemon.sh` - 后台启动脚本
- [ ] `install.sh` - 安装脚本

## 🔗 相关链接

- [快速开始指南](QUICK_START.md)
- [配置说明](CONFIGURATION.md)
- [部署指南](DEPLOYMENT.md)
- [故障排除](TROUBLESHOOTING.md)
