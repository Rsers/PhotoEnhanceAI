# 📘 配置说明

PhotoEnhanceAI的参数配置和优化建议。

## ⚙️ 处理参数

### tile_size（瓦片大小）
- **类型**: integer
- **范围**: 256-512
- **默认**: 400
- **描述**: 瓦片大小，影响GPU显存使用
- **建议配置**:
  - `256`: 省显存模式，适合低显存GPU（4-6GB）
  - `400`: 推荐模式，平衡性能和质量（8GB+显存）
  - `512`: 高质量模式，需要更多显存（12GB+显存）

### quality_level（质量等级）
- **类型**: string
- **选项**: fast, medium, high
- **默认**: high
- **描述**: 处理质量等级
- **配置说明**:
  - `fast`: 快速处理，自动优化瓦片大小
  - `medium`: 平衡模式，推荐日常使用
  - `high`: 高质量处理，最佳效果

## 🔧 环境变量配置

### GPU配置
```bash
# CUDA设备选择
export CUDA_VISIBLE_DEVICES=0

# OpenMP线程数
export OMP_NUM_THREADS=4

# PyTorch CUDA内存分配配置
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

### 服务配置
```bash
# API服务配置
export API_HOST=0.0.0.0
export API_PORT=8000
export API_WORKERS=1

# 日志配置
export LOG_LEVEL=INFO
export LOG_FILE=/var/log/photoenhanceai.log
```

## 📊 性能配置

### 内存配置
```bash
# 系统内存限制
export MEMORY_LIMIT=8GB

# 进程内存限制
ulimit -v 8388608  # 8GB in KB
```

### CPU配置
```bash
# CPU核心限制
export CPU_LIMIT=400%

# 进程优先级
nice -n 10 python api/start_server.py
```

## 🎯 优化建议

### 根据硬件配置优化

#### 低配置（4-6GB显存）
```bash
# 配置参数
tile_size=256
quality_level=fast
OMP_NUM_THREADS=2
```

#### 中等配置（8-12GB显存）
```bash
# 配置参数
tile_size=400
quality_level=medium
OMP_NUM_THREADS=4
```

#### 高配置（12GB+显存）
```bash
# 配置参数
tile_size=512
quality_level=high
OMP_NUM_THREADS=8
```

### 根据使用场景优化

#### 开发调试
```bash
# 快速启动，详细日志
./start_frontend_only.sh
export LOG_LEVEL=DEBUG
```

#### 生产环境
```bash
# 后台运行，资源限制
./start_backend_daemon.sh
export MEMORY_LIMIT=8GB
export CPU_LIMIT=400%
```

#### 批量处理
```bash
# 优化并发处理
export MAX_CONCURRENT_TASKS=1
export TASK_QUEUE_SIZE=100
```

## 🔗 相关链接

- [安装指南](INSTALLATION.md)
- [API文档](API_REFERENCE.md)
- [性能优化](PERFORMANCE.md)
- [部署指南](DEPLOYMENT.md)
