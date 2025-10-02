# PhotoEnhanceAI 🎨

AI驱动的人像图像增强服务，使用GFPGAN一体化解决方案，集成人脸修复和超分辨率技术，让手机照片达到单反级别的效果。

## ✨ 核心特性

- 🎭 **GFPGAN一体化**: 人脸修复 + RealESRGAN超分辨率，一步到位
- ⚡ **7倍速度提升**: 比传统流水线快7倍，14秒完成4倍放大
- 🚀 **流式处理方案**: 第一张图片5秒内完成，性能提升37.5%
- 🌐 **Web API**: RESTful接口，支持异步处理和批量处理
- 🔥 **模型常驻内存**: 避免重复加载，处理速度提升62%
- 🔗 **自动注册**: 启动后自动查询公网IP并注册到API网关

## 🚀 快速开始

### 一键安装
```bash
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI
chmod +x install.sh
./install.sh
```

### 启动服务
```bash
# 前台启动（开发调试）
./start_frontend_only.sh

# 后台启动（生产环境）
./start_backend_daemon.sh

# Supervisor启动（容器环境）
./start_supervisor.sh
```

### 验证服务
```bash
curl http://localhost:8000/health
```

## 📚 文档导航

### 📖 基础文档
| 文档 | 描述 | 链接 |
|------|------|------|
| **安装指南** | 详细安装步骤和系统要求 | [📘 INSTALLATION.md](docs/INSTALLATION.md) |
| **快速开始** | 5分钟快速上手指南 | [📘 QUICK_START.md](docs/QUICK_START.md) |
| **API文档** | 完整的API接口说明 | [📘 API_REFERENCE.md](docs/API_REFERENCE.md) |
| **配置说明** | 参数配置和优化建议 | [📘 CONFIGURATION.md](docs/CONFIGURATION.md) |

### 🔧 部署运维
| 文档 | 描述 | 链接 |
|------|------|------|
| **部署指南** | 生产环境部署方案 | [📘 DEPLOYMENT.md](docs/DEPLOYMENT.md) |
| **自动启动** | 开机自启动配置方案 | [📘 AUTOSTART.md](docs/AUTOSTART.md) |
| **容器部署** | Docker和容器环境部署 | [📘 CONTAINER_DEPLOYMENT.md](docs/CONTAINER_DEPLOYMENT.md) |
| **监控运维** | 服务监控和故障排除 | [📘 MONITORING.md](docs/MONITORING.md) |

### 🚀 高级功能
| 文档 | 描述 | 链接 |
|------|------|------|
| **流式处理** | 最优批量处理方案 | [📘 STREAM_PROCESSING.md](docs/STREAM_PROCESSING.md) |
| **性能优化** | 性能调优和硬件分析 | [📘 PERFORMANCE.md](docs/PERFORMANCE.md) |
| **前端集成** | Web前端集成指南 | [📘 FRONTEND_INTEGRATION.md](docs/FRONTEND_INTEGRATION.md) |
| **批量处理** | 批量处理优化方案 | [📘 BATCH_PROCESSING.md](docs/BATCH_PROCESSING.md) |

### 🛠️ 故障排除
| 文档 | 描述 | 链接 |
|------|------|------|
| **常见问题** | FAQ和常见问题解答 | [📘 TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| **容器问题** | 容器环境特殊问题 | [📘 CONTAINER_TROUBLESHOOTING.md](docs/CONTAINER_TROUBLESHOOTING.md) |
| **镜像部署** | 镜像文件部署问题 | [📘 MIRROR_DEPLOYMENT.md](docs/MIRROR_DEPLOYMENT.md) |

### 📋 解决方案记录
| 文档 | 描述 | 链接 |
|------|------|------|
| **Supervisor修复** | Supervisor自动启动修复方案 | [📘 FIX_SUMMARY.md](FIX_SUMMARY.md) |
| **容器自动启动** | 容器环境自动启动配置 | [📘 CONTAINER_AUTOSTART_CONFIG.md](CONTAINER_AUTOSTART_CONFIG.md) |
| **镜像自动启动** | 镜像环境自动启动解决方案 | [📘 MIRROR_AUTOSTART_SOLUTION.md](MIRROR_AUTOSTART_SOLUTION.md) |
| **资源限制** | 资源限制解决方案 | [📘 RESOURCE_LIMIT_SOLUTION.md](RESOURCE_LIMIT_SOLUTION.md) |
| **流式处理总结** | 流式处理实现总结 | [📘 STREAM_PROCESSING_SUMMARY.md](STREAM_PROCESSING_SUMMARY.md) |

## 🎯 核心功能

### Web API
- **健康检查**: `GET /health`
- **图像增强**: `POST /api/v1/enhance`
- **任务状态**: `GET /api/v1/status/{task_id}`
- **结果下载**: `GET /api/v1/download/{task_id}`

### 脚本工具
| 脚本 | 用途 | 详细说明 |
|------|------|----------|
| `install.sh` | 一键安装部署 | [安装指南](docs/INSTALLATION.md) |
| `start_frontend_only.sh` | 前台启动API | [部署指南](docs/DEPLOYMENT.md) |
| `start_backend_daemon.sh` | 后台常驻服务 | [部署指南](docs/DEPLOYMENT.md) |
| `start_supervisor.sh` | Supervisor启动 | [自动启动](docs/AUTOSTART.md) |
| `verify_supervisor_autostart.sh` | Supervisor验证 | [自动启动](docs/AUTOSTART.md) |

## 🏗️ 项目结构

```
PhotoEnhanceAI/
├── docs/                    # 📚 文档目录
│   ├── INSTALLATION.md      # 安装指南
│   ├── QUICK_START.md       # 快速开始
│   ├── API_REFERENCE.md     # API文档
│   ├── DEPLOYMENT.md        # 部署指南
│   ├── AUTOSTART.md         # 自动启动配置
│   ├── TROUBLESHOOTING.md   # 故障排除
│   └── ...                  # 其他文档
├── api/                     # 🌐 Web API服务
├── gfpgan/                  # 🎭 GFPGAN核心模块
├── examples/                # 💡 示例代码
├── *.sh                     # 🔧 启动和管理脚本
└── *.md                     # 📋 解决方案记录
```

## 🔗 相关链接

- **GitHub仓库**: [https://github.com/Rsers/PhotoEnhanceAI](https://github.com/Rsers/PhotoEnhanceAI)
- **问题反馈**: [GitHub Issues](https://github.com/Rsers/PhotoEnhanceAI/issues)
- **API文档**: 启动服务后访问 `http://localhost:8000/docs`

## 📞 支持

- 📧 Email: support@photoenhanceai.com
- 💬 Issues: [GitHub Issues](https://github.com/Rsers/PhotoEnhanceAI/issues)
- 📖 文档: [项目Wiki](https://github.com/Rsers/PhotoEnhanceAI/wiki)

## 📄 许可证

本项目基于MIT许可证开源 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

⭐ 如果这个项目对你有帮助，请给个Star支持一下！
