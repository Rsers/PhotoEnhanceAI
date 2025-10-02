# 📘 快速开始指南

5分钟快速上手PhotoEnhanceAI，体验AI图像增强的强大功能。

## ⚡ 5分钟快速体验

### 1. 安装部署
```bash
# 克隆项目
git clone https://github.com/Rsers/PhotoEnhanceAI.git
cd PhotoEnhanceAI

# 一键安装
chmod +x install.sh
./install.sh
```

### 2. 启动服务
```bash
# 前台启动（开发调试，可看实时日志）
./start_frontend_only.sh
```

### 3. 验证服务
```bash
# 健康检查
curl http://localhost:8000/health

# 访问API文档
# 浏览器打开: http://localhost:8000/docs
```

### 4. 处理图片
```bash
# 命令行处理
python gfpgan_core.py --input input/test001.jpg --output output/enhanced.jpg --scale 4

# 或使用Web界面
# 浏览器打开: http://localhost:8000/examples/test_api.html
```

## 🎯 核心功能体验

### Web API调用
```javascript
// 上传图像进行GFPGAN增强
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

### 命令行处理
```bash
# 基础处理
python gfpgan_core.py --input input.jpg --output output.jpg

# 高质量处理
python gfpgan_core.py --input input.jpg --output output.jpg --scale 4 --tile_size 512

# 快速处理
python gfpgan_core.py --input input.jpg --output output.jpg --scale 2 --tile_size 256
```

## 🚀 流式处理体验

### 启动流式处理演示
```bash
# 启动流式处理演示
./start_stream_demo.sh

# 浏览器打开: http://localhost:8001/examples/stream_processing.html
```

### 流式处理优势
- ⚡ **第一张图片**: 5秒内完成
- 🎯 **渐进式显示**: 无需等待所有图片完成
- 🔄 **自动处理**: 上传即处理，实时显示结果
- 📊 **性能提升**: 比批量处理快37.5%

## 🔧 服务管理

### 启动方式
```bash
# 前台启动（开发调试）
./start_frontend_only.sh

# 后台启动（生产环境）
./start_backend_daemon.sh

# Supervisor启动（容器环境）
./start_supervisor.sh
```

### 服务控制
```bash
# 查看服务状态
./status_service.sh

# 停止服务（仅后台模式需要）
./stop_service.sh

# 查看服务日志
tail -f logs/photoenhanceai.log
```

## 📊 性能测试

### 运行性能测试
```bash
# 流式处理性能测试
python test_stream_performance.py

# 简单功能测试
python test_stream_simple.py
```

### 性能指标
| 图片尺寸 | 处理时间 | 输出分辨率 | 显存占用 |
|----------|----------|-----------|----------|
| 512×512 | 4-6秒 | 2048×2048 | 2-4GB |
| 1080×1440 | 8-12秒 | 4320×5760 | 6-10GB |
| 2048×2048 | 20-30秒 | 8192×8192 | 12-16GB |

## 🎮 交互式工具

### 快速图像增强
```bash
# 启动交互式增强工具
./quick_enhance.sh
```

### 功能特点
- 🖼️ **拖拽上传**: 支持拖拽图片上传
- ⚙️ **参数调整**: 实时调整处理参数
- 📊 **进度显示**: 实时显示处理进度
- 💾 **结果保存**: 自动保存处理结果

## 🔗 Webhook自动注册

启动服务时会自动注册到API网关：

```bash
# 后台启动（自动注册）
./start_backend_daemon.sh

# 查看注册日志
tail -f logs/webhook_register.log
```

### 注册信息
- 🌍 **自动IP查询**: 自动获取公网IP
- 📡 **自动注册**: 启动后自动注册到API网关
- 📝 **详细日志**: 记录注册过程和结果

## 🔥 AI模型预热

服务启动后会自动预热AI模型：

```bash
# 查看模型预热日志
tail -f logs/model_warmup.log

# 手动预热模型
./warmup_model.sh
```

### 预热效果
- ⚡ **首次请求**: 4-6秒（预热前需15-20秒）
- 💾 **模型常驻**: 预热后模型保持在内存中
- 🚀 **性能提升**: 首次请求速度提升约70%

## 🛠️ 故障排除

### 常见问题
```bash
# 检查服务状态
./status_service.sh

# 检查GPU状态
nvidia-smi

# 检查API健康
curl http://localhost:8000/health

# 查看详细日志
tail -f logs/photoenhanceai.log
```

### 快速修复
```bash
# 重启服务
./stop_service.sh
./start_backend_daemon.sh

# 重新预热模型
./warmup_model.sh

# 重新注册webhook
./register_webhook.sh
```

## 📚 下一步

完成快速开始后，您可以：

1. **深入了解API**: [API文档](API_REFERENCE.md)
2. **生产环境部署**: [部署指南](DEPLOYMENT.md)
3. **性能优化**: [性能优化](PERFORMANCE.md)
4. **前端集成**: [前端集成](FRONTEND_INTEGRATION.md)
5. **故障排除**: [故障排除](TROUBLESHOOTING.md)

## 🔗 相关链接

- [安装指南](INSTALLATION.md)
- [API文档](API_REFERENCE.md)
- [配置说明](CONFIGURATION.md)
- [部署指南](DEPLOYMENT.md)
