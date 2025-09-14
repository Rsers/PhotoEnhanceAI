# PhotoEnhanceAI 🎨

[![GitHub stars](https://img.shields.io/github/stars/Rsers/PhotoEnhanceAI?style=social)](https://github.com/Rsers/PhotoEnhanceAI)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![CUDA](https://img.shields.io/badge/CUDA-11.6+-green.svg)](https://developer.nvidia.com/cuda-downloads)

**AI驱动的人像照片专业增强工具** - 让手机自拍照达到单反相机的专业效果

## ✨ 核心特性

- 🎯 **反向流水线技术**: SwinIR专业处理 → GFPGAN人脸精修
- 🚀 **4倍超分辨率**: AI算法实现图像分辨率和质量的显著提升
- 👤 **智能人脸修复**: 专业级面部细节增强和修复
- ⚡ **GPU加速**: 支持CUDA加速，处理速度快
- 🎨 **专业级效果**: 手机照片 → 单反品质

## 🎬 效果展示

| 处理前 | 处理后 | 提升效果 |
|--------|--------|----------|
| 0.1-0.7MB | 1.6-10.4MB | 14-18倍文件增长 |
| 普通清晰度 | 专业级质量 | 4倍分辨率提升 |
| 手机自拍 | 单反效果 | 面部+整体双重优化 |

## 🚀 快速开始

### 环境要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+
- **Python**: 3.8+
- **GPU**: NVIDIA GPU with CUDA 11.6+
- **显存**: 建议8GB以上
- **存储**: 至少10GB可用空间

### 一键部署

```bash
# 克隆仓库
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI

# 运行自动部署脚本
chmod +x deploy/setup_environment.sh
./deploy/setup_environment.sh

# 下载模型文件
chmod +x models/download_models.sh
./models/download_models.sh
```

### 基础使用

```bash
# 激活环境并处理单张图片
python scripts/reverse_portrait_pipeline.py \
    --input examples/input.jpg \
    --output examples/output.jpg \
    --tile 400
```

## 📊 处理性能

### 性能基准测试

| 输入大小 | 处理时间 | 输出大小 | 增长倍数 | GPU显存占用 |
|----------|----------|----------|----------|--------------|
| 0.1MB    | ~48秒    | 1.6MB    | 14.2x    | ~8GB        |
| 0.3MB    | ~97秒    | 4.8MB    | 16.3x    | ~10GB       |
| 0.5MB    | ~97秒    | 7.7MB    | 14.4x    | ~12GB       |
| 0.7MB    | ~136秒   | 10.4MB   | 14.7x    | ~14GB       |

### 质量保证

- ✅ **100%成功率**: 经过8+张不同类型图片验证
- ✅ **稳定性**: 处理时间和质量提升可预测
- ✅ **兼容性**: 支持JPG、PNG等主流格式

## 🔧 技术架构

### 核心算法

1. **SwinIR**: 基于Swin Transformer的图像超分辨率网络
   - 预处理增强 (对比度+锐化)
   - 4倍AI超分辨率放大
   - 智能后处理优化 (降噪+细节保护)

2. **GFPGAN**: Generative Facial Prior-Guided Face Restoration
   - 基于高分辨率图像的人脸检测
   - AI修复人脸细节和纹理
   - 保持整体图像优秀效果

### 反向流水线优势

```
传统方案: 人脸修复 → 整体放大 (面部清晰，背景一般)
反向流水线: 整体优化 → 人脸精修 (背景优秀，面部精细)
```

**优势**:
- 🎯 先建立整体高质量基础
- 🎨 再进行人脸精细优化
- ⚖️ 平衡背景和人脸效果
- ⚡ 处理时间更优化

## 📁 项目结构

```
PhotoEnhanceAI/
├── README.md                   # 项目说明
├── requirements/              # 依赖管理
│   ├── swinir_requirements.txt
│   ├── gfpgan_requirements.txt
│   └── common_requirements.txt
├── scripts/                   # 核心脚本
│   ├── reverse_portrait_pipeline.py  # 主处理脚本
│   ├── social_media_upscale.py      # SwinIR处理
│   └── inference_gfpgan.py          # GFPGAN处理
├── models/                    # 模型管理
│   ├── download_models.sh     # 模型下载脚本
│   └── README.md             # 模型说明
├── config/                    # 配置文件
├── deploy/                    # 部署脚本
│   ├── setup_environment.sh  # 环境配置
│   └── install_dependencies.sh
├── api/                       # API接口 (开发中)
├── docs/                      # 详细文档
├── tests/                     # 测试用例
└── examples/                  # 示例文件
```

## 🌐 API接口 (开发中)

### 计划功能

- **RESTful API**: 支持HTTP请求调用
- **批量处理**: 支持多张图片同时处理
- **异步队列**: 长时间任务后台处理
- **Web界面**: 浏览器直接使用

```python
# 计划的API接口
POST /api/v1/enhance/portrait
GET  /api/v1/status
POST /api/v1/batch/enhance
```

## 📖 详细文档

- [部署指南](docs/deployment.md) - 详细的部署步骤和环境配置
- [使用教程](docs/usage.md) - 完整的使用说明和参数调优
- [API文档](docs/api.md) - API接口详细说明 (开发中)
- [性能分析](docs/performance.md) - 详细的性能测试和优化建议
- [故障排除](docs/troubleshooting.md) - 常见问题和解决方案

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出改进建议！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [SwinIR](https://github.com/JingyunLiang/SwinIR) - 优秀的图像超分辨率算法
- [GFPGAN](https://github.com/TencentARC/GFPGAN) - 强大的人脸修复技术
- 所有为开源AI社区做出贡献的开发者们

## 📞 联系方式

- **GitHub Issues**: [报告问题](https://github.com/Rsers/PhotoEnhanceAI/issues)
- **讨论**: [GitHub Discussions](https://github.com/Rsers/PhotoEnhanceAI/discussions)

---

**让每一张照片都达到专业级别的效果！** ✨

如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！
