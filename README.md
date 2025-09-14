# PhotoEnhanceAI 🎨

AI驱动的人像图像增强服务，结合SwinIR超分辨率和GFPGAN人脸修复技术，让手机照片达到单反级别的效果。

## ✨ 特性

- 🚀 **反向流水线**: SwinIR专业处理 + GFPGAN人脸修复
- 🎯 **智能优化**: 自动瓦片处理，适应不同GPU显存
- 🌐 **Web API**: RESTful接口，支持异步处理
- 📱 **跨平台**: 支持各种前端框架集成
- ⚡ **高性能**: GPU加速，批量处理支持

## 🚀 快速开始

### 一键部署

```bash
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI
chmod +x deploy/setup_environment.sh
./deploy/setup_environment.sh
chmod +x models/download_models.sh
./models/download_models.sh
python api/start_server.py
```

### 手动安装

1. **创建虚拟环境**
```bash
# SwinIR环境
python3 -m venv swinir_env
source swinir_env/bin/activate
pip install -r requirements/swinir_requirements.txt
deactivate

# GFPGAN环境  
python3 -m venv gfpgan_env
source gfpgan_env/bin/activate
pip install -r requirements/gfpgan_requirements.txt
deactivate

# API环境
python3 -m venv api_env
source api_env/bin/activate
pip install -r requirements/api_requirements.txt
deactivate
```

2. **下载模型文件**
```bash
mkdir -p models/swinir models/gfpgan

# SwinIR模型 (约200MB)
wget -O models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth \
  https://github.com/JingyunLiang/SwinIR/releases/download/v0.0/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth

# GFPGAN模型 (约350MB)  
wget -O models/gfpgan/GFPGANv1.4.pth \
  https://github.com/TencentARC/GFPGAN/releases/download/v1.3.8/GFPGANv1.4.pth
```

3. **启动API服务**
```bash
python api/start_server.py
```

## 🌐 API使用

### 基础调用

```javascript
// 上传图像
const formData = new FormData();
formData.append('file', imageFile);
formData.append('tile_size', 400);
formData.append('quality_level', 'high');

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
| `/` | GET | 服务信息 |
| `/health` | GET | 健康检查 |
| `/docs` | GET | API文档 |
| `/api/v1/enhance` | POST | 图像增强 |
| `/api/v1/status/{task_id}` | GET | 任务状态 |
| `/api/v1/download/{task_id}` | GET | 下载结果 |
| `/api/v1/tasks/{task_id}` | DELETE | 删除任务 |

## ⚙️ 配置参数

### 处理参数
- **tile_size**: 瓦片大小 (256-512)
  - 256: 省显存模式
  - 400: 推荐模式 (默认)
  - 512: 高质量模式

- **quality_level**: 质量等级
  - fast: 快速处理
  - medium: 平衡模式
  - high: 高质量 (默认)

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
├── scripts/               # 核心处理脚本
│   ├── reverse_portrait_pipeline.py  # 反向流水线
│   ├── social_media_upscale.py      # SwinIR处理
│   └── inference_gfpgan.py          # GFPGAN推理
├── deploy/                # 部署脚本
│   ├── setup_environment.sh        # 环境安装
│   └── production_setup.sh         # 生产部署
├── models/                # AI模型文件
│   ├── download_models.sh # 模型下载脚本
│   ├── swinir/           # SwinIR模型
│   └── gfpgan/           # GFPGAN模型
├── requirements/          # 依赖文件
│   ├── swinir_requirements.txt
│   ├── gfpgan_requirements.txt
│   └── api_requirements.txt
├── docs/                  # 文档
│   ├── deployment.md      # 部署指南
│   ├── frontend-integration.md  # 前端集成
│   └── api.md            # API文档
└── examples/             # 示例代码
    ├── sample_input.jpg  # 测试图片
    └── test_api.html     # Web测试页面
```

## 🔧 环境要求

- **操作系统**: Ubuntu 18.04+ / CentOS 7+
- **Python**: 3.8+
- **GPU**: NVIDIA GPU (14GB+ VRAM推荐)
- **存储**: 10GB+ (包含模型文件)
- **内存**: 8GB+

## 📊 性能指标

| 图片尺寸 | 处理时间 | 显存占用 | 推荐配置 |
|----------|----------|----------|----------|
| 512×512 | 5-10秒 | 2-4GB | tile_size=512 |
| 1024×1024 | 15-30秒 | 6-10GB | tile_size=400 |
| 2048×2048 | 45-90秒 | 12-16GB | tile_size=256 |

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