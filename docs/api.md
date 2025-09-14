# PhotoEnhanceAI API 文档

## 🌐 API 概览

PhotoEnhanceAI 提供基于 FastAPI 的 RESTful Web API，支持通过 HTTP 请求进行 AI 人像增强处理。

### 基本信息

- **基础URL**: `http://your-server:8000`
- **API版本**: v1
- **文档地址**: `http://your-server:8000/docs`
- **技术栈**: FastAPI + Uvicorn + 异步处理

## 🚀 快速开始

### 启动API服务

```bash
# 方法1: 使用启动脚本
python api/start_server.py

# 方法2: 直接使用uvicorn
uvicorn api.main:app --host 0.0.0.0 --port 8000

# 方法3: 开发模式 (自动重载)
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

### 安装API依赖

```bash
# 安装API专用依赖
pip install -r requirements/api_requirements.txt
```

## 📋 API 端点

### 1. 系统状态

#### GET `/`
获取API基本信息

**响应示例**:
```json
{
  "service": "PhotoEnhanceAI API",
  "version": "1.0.0",
  "status": "running",
  "description": "AI-powered portrait enhancement service",
  "endpoints": {
    "docs": "/docs",
    "health": "/health",
    "enhance": "/api/v1/enhance",
    "status": "/api/v1/status/{task_id}",
    "download": "/api/v1/download/{task_id}"
  }
}
```

#### GET `/health`
健康检查端点

**响应示例**:
```json
{
  "status": "healthy",
  "timestamp": 1703123456.789,
  "active_tasks": 2
}
```

### 2. 图像增强

#### POST `/api/v1/enhance`
提交图像增强任务

**请求参数**:
- `file`: 图像文件 (multipart/form-data)
- `tile_size`: 处理tile大小 (256-512, 默认: 400)
- `quality_level`: 质量级别 ("fast"/"medium"/"high", 默认: "high")

**cURL示例**:
```bash
curl -X POST "http://localhost:8000/api/v1/enhance" \
  -F "file=@your_image.jpg" \
  -F "tile_size=400" \
  -F "quality_level=high"
```

**响应示例**:
```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "queued",
  "message": "Task queued for processing",
  "created_at": 1703123456.789
}
```

### 3. 任务状态

#### GET `/api/v1/status/{task_id}`
查询任务处理状态

**响应示例**:
```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing",
  "message": "Processing with AI models...",
  "progress": 0.6,
  "result_url": null,
  "error": null,
  "created_at": 1703123456.789,
  "updated_at": 1703123466.789,
  "processing_time": null
}
```

**状态说明**:
- `queued`: 任务已排队
- `processing`: 正在处理
- `completed`: 处理完成
- `failed`: 处理失败

### 4. 结果下载

#### GET `/api/v1/download/{task_id}`
下载处理后的图像

**响应**: 二进制图像文件

**cURL示例**:
```bash
curl -O -J "http://localhost:8000/api/v1/download/550e8400-e29b-41d4-a716-446655440000"
```

### 5. 任务管理

#### DELETE `/api/v1/tasks/{task_id}`
删除任务并清理文件

**响应示例**:
```json
{
  "message": "Task deleted successfully"
}
```

#### GET `/api/v1/tasks`
列出所有任务 (调试用)

**响应示例**:
```json
{
  "total_tasks": 3,
  "tasks": [
    {
      "task_id": "task-1",
      "status": "completed",
      "created_at": 1703123456.789,
      "updated_at": 1703123466.789
    }
  ]
}
```

## 🔧 使用示例

### Python客户端示例

```python
import httpx
import asyncio
import time

async def enhance_image(image_path: str, output_path: str):
    async with httpx.AsyncClient(timeout=300.0) as client:
        # 1. 上传图像
        with open(image_path, "rb") as f:
            files = {"file": ("image.jpg", f, "image/jpeg")}
            params = {"tile_size": 400, "quality_level": "high"}
            
            response = await client.post(
                "http://localhost:8000/api/v1/enhance",
                files=files,
                params=params
            )
        
        if response.status_code != 200:
            print(f"Upload failed: {response.status_code}")
            return
        
        task_data = response.json()
        task_id = task_data["task_id"]
        print(f"Task ID: {task_id}")
        
        # 2. 轮询状态
        while True:
            status_response = await client.get(
                f"http://localhost:8000/api/v1/status/{task_id}"
            )
            
            if status_response.status_code != 200:
                print("Status check failed")
                return
            
            status_data = status_response.json()
            status = status_data["status"]
            progress = status_data.get("progress", 0)
            
            print(f"Status: {status} ({progress*100:.1f}%)")
            
            if status == "completed":
                # 3. 下载结果
                download_response = await client.get(
                    f"http://localhost:8000/api/v1/download/{task_id}"
                )
                
                if download_response.status_code == 200:
                    with open(output_path, "wb") as f:
                        f.write(download_response.content)
                    print(f"Result saved to: {output_path}")
                break
            elif status == "failed":
                print(f"Processing failed: {status_data.get('error')}")
                break
            
            await asyncio.sleep(5)

# 使用示例
asyncio.run(enhance_image("input.jpg", "output.jpg"))
```

### JavaScript客户端示例

```javascript
async function enhanceImage(file, tileSize = 400, qualityLevel = 'high') {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('tile_size', tileSize);
    formData.append('quality_level', qualityLevel);
    
    // 1. 上传图像
    const uploadResponse = await fetch('/api/v1/enhance', {
        method: 'POST',
        body: formData
    });
    
    if (!uploadResponse.ok) {
        throw new Error('Upload failed');
    }
    
    const { task_id } = await uploadResponse.json();
    console.log('Task ID:', task_id);
    
    // 2. 轮询状态
    while (true) {
        const statusResponse = await fetch(`/api/v1/status/${task_id}`);
        const statusData = await statusResponse.json();
        
        console.log(`Status: ${statusData.status} (${(statusData.progress * 100).toFixed(1)}%)`);
        
        if (statusData.status === 'completed') {
            // 3. 下载结果
            const downloadUrl = `/api/v1/download/${task_id}`;
            window.open(downloadUrl, '_blank');
            break;
        } else if (statusData.status === 'failed') {
            throw new Error(`Processing failed: ${statusData.error}`);
        }
        
        await new Promise(resolve => setTimeout(resolve, 5000));
    }
}
```

## ⚙️ 配置选项

### 环境变量

```bash
# 服务器配置
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=1

# 安全配置
CORS_ORIGINS=*
MAX_CONCURRENT_TASKS=10

# 日志配置
LOG_LEVEL=INFO

# 任务清理
TASK_CLEANUP_HOURS=24
```

### 质量级别说明

| 级别 | Tile大小 | 处理时间 | 质量 | 适用场景 |
|------|----------|----------|------|----------|
| fast | ≤256 | 快 | 良好 | 快速预览 |
| medium | ≤400 | 中等 | 优秀 | 一般使用 |
| high | 用户指定 | 慢 | 最佳 | 专业输出 |

## 🔒 安全考虑

### 文件上传限制

- **最大文件大小**: 50MB
- **支持格式**: JPG, PNG, BMP, TIFF
- **文件类型验证**: MIME类型检查

### 资源保护

- **并发任务限制**: 最多10个同时处理
- **临时文件清理**: 24小时后自动删除
- **内存管理**: 自动垃圾回收

## 🧪 测试

### 运行测试客户端

```bash
# 启动API服务器 (终端1)
python api/start_server.py

# 运行测试客户端 (终端2)
python api/test_client.py
```

### 性能测试

```bash
# 使用Apache Bench测试
ab -n 10 -c 2 -p test_image.jpg -T 'multipart/form-data; boundary=1234567890' \
   http://localhost:8000/api/v1/enhance
```

## 🐛 故障排除

### 常见问题

1. **模型文件未找到**
   ```bash
   ./models/download_models.sh
   ```

2. **端口被占用**
   ```bash
   # 更改端口
   export API_PORT=8001
   python api/start_server.py
   ```

3. **处理超时**
   - 减小tile_size
   - 使用quality_level="fast"

4. **显存不足**
   - 降低MAX_CONCURRENT_TASKS
   - 使用更小的tile_size

### 日志查看

```bash
# 查看详细日志
LOG_LEVEL=DEBUG python api/start_server.py
```

## 📊 监控

### 健康检查

```bash
# 简单健康检查
curl http://localhost:8000/health

# 详细状态
curl http://localhost:8000/api/v1/tasks
```

### 性能监控

- 使用 `/health` 端点监控活跃任务数
- 监控临时目录磁盘使用
- 观察GPU显存使用情况

---

**API现已准备就绪，开始构建你的AI图像增强应用吧！** 🚀
