# PhotoEnhanceAI 🎨

AI驱动的人像图像增强服务，使用GFPGAN一体化解决方案，集成人脸修复和超分辨率技术，让手机照片达到单反级别的效果。

## ✨ 特性

- 🎭 **GFPGAN一体化**: 人脸修复 + RealESRGAN超分辨率，一步到位
- ⚡ **7倍速度提升**: 比传统流水线快7倍，14秒完成4倍放大
- 🎯 **智能瓦片处理**: 自动适应GPU显存，支持1-16倍放大
- 🌐 **Web API**: RESTful接口，支持异步处理
- 📱 **跨平台**: 支持各种前端框架集成
- 🔥 **内置超分辨率**: GFPGAN集成RealESRGAN，无需额外模型

## 🚀 快速开始

### 📋 脚本说明

| 脚本 | 用途 | 适用场景 |
|------|------|----------|
| `install.sh` | 一键安装部署 | 新服务器从零部署 |
| `quick_start_api.sh` | 极简启动API | 开发环境快速启动 |
| `verbose_info_start_api.sh` | 详细信息启动API | 生产环境安全启动 |
| `local_gfpgan_test.py` | 本地功能测试 | 验证环境配置 |
| `quick_enhance.sh` | 快速图像增强 | 交互式图片处理 |
| `gfpgan_core.py` | 核心处理引擎 | 命令行图片增强 |

### 一键安装（推荐）

在新服务器上从零部署：

```bash
# 克隆项目
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI

# 一键安装
chmod +x install.sh
./install.sh
```

### 手动安装

1. **安装系统依赖**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y python3-venv python3-dev python3-pip \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev \
    libgomp1 git wget curl build-essential cmake

# CentOS/RHEL
sudo yum install -y python3-devel python3-pip mesa-libGL gcc git wget curl cmake
```

2. **设置环境**
```bash
# 运行环境安装脚本
chmod +x deploy/setup_gfpgan_env.sh
./deploy/setup_gfpgan_env.sh

# 下载模型文件
chmod +x deploy/download_gfpgan_model.sh
./deploy/download_gfpgan_model.sh
```

3. **测试安装**
```bash
# 测试环境
./local_gfpgan_test.py

# 处理测试图片
python gfpgan_core.py --input input/test001.jpg --output output/enhanced.jpg --scale 4
```

4. **启动API服务**
```bash
# 极简启动（开发环境）
./quick_start_api.sh

# 详细信息启动（生产环境）
./verbose_info_start_api.sh
```

5. **快速图像增强**
```bash
# 交互式增强工具
./quick_enhance.sh
```

## 🌐 API使用

### 基础调用

```javascript
// 上传图像进行GFPGAN增强 (人脸修复 + 4倍超分辨率)
const formData = new FormData();
formData.append('file', imageFile);
formData.append('tile_size', 400);  // 瓦片大小，影响显存使用
formData.append('quality_level', 'high');  // fast/medium/high

const response = await fetch('http://localhost:8000/api/v1/enhance', {
    method: 'POST',
    body: formData
});

const result = await response.json();
const taskId = result.task_id;

// 轮询状态
while (true) {
    const statusResponse = await fetch(`http://localhost:8000/api/v1/status/${taskId}`);
    const status = await statusResponse.json();
    
    if (status.status === 'completed') {
        // 下载结果
        const downloadResponse = await fetch(`http://localhost:8000/api/v1/download/${taskId}`);
        const blob = await downloadResponse.blob();
        break;
    }
    
    await new Promise(resolve => setTimeout(resolve, 2000));
}
```

### React Hook

```javascript
import { useState, useCallback } from 'react';

export function useImageEnhancement() {
    const [loading, setLoading] = useState(false);
    const [progress, setProgress] = useState(0);
    const [error, setError] = useState(null);

    const enhanceImage = useCallback(async (file, options = {}) => {
        setLoading(true);
        setError(null);
        setProgress(0);

        try {
            // 上传、等待、下载逻辑...
            return blob;
        } catch (err) {
            setError(err.message);
            throw err;
        } finally {
            setLoading(false);
            setProgress(0);
        }
    }, []);

    return { enhanceImage, loading, progress, error };
}
```

## 🎯 API端点

| 端点 | 方法 | 描述 |
|------|------|------|
| `/` | GET | 服务信息和GFPGAN功能介绍 |
| `/health` | GET | 健康检查 |
| `/docs` | GET | API文档 |
| `/api/v1/enhance` | POST | GFPGAN图像增强 (人脸修复 + 超分辨率) |
| `/api/v1/status/{task_id}` | GET | 任务状态 |
| `/api/v1/download/{task_id}` | GET | 下载结果 |
| `/api/v1/tasks/{task_id}` | DELETE | 删除任务 |

## ⚙️ 配置参数

### 处理参数
- **tile_size**: 瓦片大小，影响GPU显存使用 (256-512)
  - 256: 省显存模式，适合低显存GPU
  - 400: 推荐模式，平衡性能和质量 (默认)
  - 512: 高质量模式，需要更多显存

- **quality_level**: 处理质量等级
  - fast: 快速处理，自动优化瓦片大小
  - medium: 平衡模式，推荐日常使用
  - high: 高质量处理，最佳效果 (默认)

### GFPGAN功能
- **人脸修复**: AI智能修复面部细节和纹理
- **背景超分辨率**: RealESRGAN处理背景区域
- **分辨率放大**: 默认4倍，支持1-16倍放大
- **一体化处理**: 无需多个模型，一步完成所有增强

### 文件限制
- **支持格式**: JPG, JPEG, PNG, BMP, TIFF
- **最大文件**: 50MB
- **推荐尺寸**: 1000×1000以下

## 🏗️ 项目结构

```
PhotoEnhanceAI/
├── api/                    # Web API服务
│   ├── main.py            # FastAPI应用
│   ├── start_server.py    # 服务启动脚本
│   └── test_client.py     # API测试客户端
├── config/                # 配置文件
│   └── settings.py        # API配置
├── gfpgan/                # GFPGAN核心模块
│   ├── inference_gfpgan.py # GFPGAN推理脚本
│   ├── archs/             # 网络架构
│   ├── models/            # 模型定义
│   └── utils.py           # 工具函数
├── deploy/                # 部署脚本
│   ├── setup_environment.sh        # 环境安装
│   └── production_setup.sh         # 生产部署
├── models/                # AI模型文件
│   ├── download_models.sh # 模型下载脚本
│   └── gfpgan/           # GFPGAN模型文件
├── requirements/          # 依赖文件
│   ├── gfpgan_requirements.txt
│   └── api_requirements.txt
├── docs/                  # 文档
│   ├── deployment.md      # 部署指南
│   ├── frontend-integration.md  # 前端集成
│   └── api.md            # API文档
├── input/                 # 输入图片目录
├── output/                # 输出结果目录
├── examples/             # 示例代码
│   └── test_api.html     # Web测试页面
├── gfpgan_core.py        # GFPGAN核心处理引擎
├── quick_start_api.sh    # 极简启动API服务
├── verbose_info_start_api.sh # 详细信息启动API服务
├── local_gfpgan_test.py  # 本地功能测试脚本
├── quick_enhance.sh      # 快速图像增强工具
└── install.sh            # 一键安装脚本
```

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

## 📊 性能指标 (GFPGAN一体化处理)

| 图片尺寸 | 处理时间 | 输出分辨率 | 显存占用 | 推荐配置 |
|----------|----------|-----------|----------|----------|
| 512×512 | 8-12秒 | 2048×2048 | 2-4GB | tile_size=512 |
| 1080×1440 | 14-18秒 | 4320×5760 | 6-10GB | tile_size=400 |
| 2048×2048 | 35-50秒 | 8192×8192 | 12-16GB | tile_size=256 |

**性能优势**:
- ⚡ 比传统SwinIR+GFPGAN流水线快7倍
- 🎯 一体化处理，无需模型切换
- 💾 内置智能瓦片处理，适应各种GPU

## 🚀 生产部署

### Docker部署 (推荐)

```bash
# 构建镜像
docker build -t photoenhanceai .

# 运行容器
docker run -d \
  --name photoenhanceai \
  --gpus all \
  -p 8000:8000 \
  -v /data/models:/app/models \
  photoenhanceai
```

### 系统服务部署

```bash
# 执行生产部署脚本
sudo chmod +x deploy/production_setup.sh
sudo ./deploy/production_setup.sh

# 服务管理
sudo supervisorctl status photoenhanceai
sudo supervisorctl restart photoenhanceai
```

## 🔍 故障排除

### 常见问题

1. **CUDA内存不足**
   - 降低tile_size参数
   - 使用quality_level="fast"
   - 关闭其他GPU程序

2. **模型加载失败**
   - 检查模型文件完整性
   - 重新下载模型文件
   - 验证文件路径正确

3. **API连接超时**
   - 增加请求超时时间
   - 检查网络连接
   - 验证服务端口开放

### 性能优化

1. **服务器端**
   - 使用SSD存储
   - 增加系统内存
   - 优化GPU驱动

2. **客户端**
   - 图片预压缩
   - 批量处理
   - 缓存结果

## 🤝 贡献指南

1. Fork项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 📄 许可证

本项目基于MIT许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [SwinIR](https://github.com/JingyunLiang/SwinIR) - 图像超分辨率
- [GFPGAN](https://github.com/TencentARC/GFPGAN) - 人脸修复技术
- [FastAPI](https://fastapi.tiangolo.com/) - 现代Web框架

## 📞 支持

- 📧 Email: support@photoenhanceai.com
- 💬 Issues: [GitHub Issues](https://github.com/Rsers/PhotoEnhanceAI/issues)
- 📖 文档: [项目Wiki](https://github.com/Rsers/PhotoEnhanceAI/wiki)

---

⭐ 如果这个项目对你有帮助，请给个Star支持一下！