# 📘 API参考文档

PhotoEnhanceAI的完整API接口说明和使用示例。

## 🌐 API概览

PhotoEnhanceAI提供RESTful API接口，支持图像增强、任务管理、批量处理等功能。

### 基础信息
- **Base URL**: `http://localhost:8000`
- **API版本**: v1
- **数据格式**: JSON
- **文件上传**: multipart/form-data

## 📋 API端点

| 端点 | 方法 | 描述 | 参数 |
|------|------|------|------|
| `/` | GET | 服务信息和GFPGAN功能介绍 | - |
| `/health` | GET | 健康检查 | - |
| `/docs` | GET | API文档（Swagger UI） | - |
| `/api/v1/enhance` | POST | GFPGAN图像增强 | file, tile_size, quality_level |
| `/api/v1/enhance/batch` | POST | 批量处理多张图片 | files[], tile_size, quality_level |
| `/api/v1/status/{task_id}` | GET | 任务状态查询 | task_id |
| `/api/v1/batch/status/{batch_task_id}` | GET | 批量任务状态 | batch_task_id |
| `/api/v1/download/{task_id}` | GET | 下载处理结果 | task_id |
| `/api/v1/batch/download/{batch_task_id}` | GET | 下载批量结果(ZIP) | batch_task_id |
| `/api/v1/tasks/{task_id}` | DELETE | 删除任务 | task_id |

## 🔧 请求参数

### 图像增强参数

#### tile_size
- **类型**: integer
- **范围**: 256-512
- **默认**: 400
- **描述**: 瓦片大小，影响GPU显存使用
- **建议**:
  - 256: 省显存模式，适合低显存GPU
  - 400: 推荐模式，平衡性能和质量
  - 512: 高质量模式，需要更多显存

#### quality_level
- **类型**: string
- **选项**: fast, medium, high
- **默认**: high
- **描述**: 处理质量等级
- **说明**:
  - fast: 快速处理，自动优化瓦片大小
  - medium: 平衡模式，推荐日常使用
  - high: 高质量处理，最佳效果

### 文件限制
- **支持格式**: JPG, JPEG, PNG, BMP, TIFF
- **最大文件**: 50MB
- **推荐尺寸**: 1000×1000以下

## 📝 请求示例

### 单图增强

#### cURL
```bash
curl -X POST "http://localhost:8000/api/v1/enhance" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@input.jpg" \
  -F "tile_size=400" \
  -F "quality_level=high"
```

#### JavaScript
```javascript
const formData = new FormData();
formData.append('file', imageFile);
formData.append('tile_size', 400);
formData.append('quality_level', 'high');

const response = await fetch('http://localhost:8000/api/v1/enhance', {
    method: 'POST',
    body: formData
});

const result = await response.json();
console.log('Task ID:', result.task_id);
```

#### Python
```python
import requests

url = "http://localhost:8000/api/v1/enhance"
files = {"file": open("input.jpg", "rb")}
data = {"tile_size": 400, "quality_level": "high"}

response = requests.post(url, files=files, data=data)
result = response.json()
print(f"Task ID: {result['task_id']}")
```

### 批量处理

#### JavaScript
```javascript
const formData = new FormData();
files.forEach(file => {
    formData.append('files', file);
});
formData.append('tile_size', 400);
formData.append('quality_level', 'high');

const response = await fetch('http://localhost:8000/api/v1/enhance/batch', {
    method: 'POST',
    body: formData
});

const result = await response.json();
console.log('Batch Task ID:', result.batch_task_id);
```

## 📊 响应格式

### 成功响应

#### 单图增强
```json
{
    "task_id": "uuid-string",
    "status": "processing",
    "message": "Task created successfully"
}
```

#### 批量处理
```json
{
    "batch_task_id": "uuid-string",
    "task_count": 5,
    "status": "processing",
    "message": "Batch task created successfully"
}
```

### 任务状态响应
```json
{
    "task_id": "uuid-string",
    "status": "completed",
    "progress": 100,
    "created_at": "2024-01-01T12:00:00Z",
    "completed_at": "2024-01-01T12:00:05Z",
    "processing_time": 5.2,
    "file_size": 2048000,
    "output_size": 8192000
}
```

### 健康检查响应
```json
{
    "status": "healthy",
    "timestamp": 1640995200.123456,
    "active_tasks": 3,
    "model_status": {
        "initialized": true,
        "cuda_available": true,
        "device": "cuda"
    }
}
```

## 🔄 任务状态

### 状态类型
- **pending**: 等待处理
- **processing**: 正在处理
- **completed**: 处理完成
- **failed**: 处理失败
- **cancelled**: 任务取消

### 状态轮询示例
```javascript
async function waitForCompletion(taskId) {
    while (true) {
        const response = await fetch(`http://localhost:8000/api/v1/status/${taskId}`);
        const status = await response.json();
        
        console.log(`Status: ${status.status}, Progress: ${status.progress}%`);
        
        if (status.status === 'completed') {
            return status;
        } else if (status.status === 'failed') {
            throw new Error(`Task failed: ${status.error}`);
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
}
```

## 📥 结果下载

### 单图下载
```javascript
async function downloadResult(taskId) {
    const response = await fetch(`http://localhost:8000/api/v1/download/${taskId}`);
    const blob = await response.blob();
    
    // 创建下载链接
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `enhanced_${taskId}.jpg`;
    a.click();
    
    window.URL.revokeObjectURL(url);
}
```

### 批量下载
```javascript
async function downloadBatchResult(batchTaskId) {
    const response = await fetch(`http://localhost:8000/api/v1/batch/download/${batchTaskId}`);
    const blob = await response.blob();
    
    // 下载ZIP文件
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `batch_result_${batchTaskId}.zip`;
    a.click();
    
    window.URL.revokeObjectURL(url);
}
```

## 🚀 流式处理

### 流式上传器实现
```javascript
class StreamUploader {
    constructor(maxConcurrent = 1) {
        this.maxConcurrent = maxConcurrent;
        this.active = 0;
        this.results = new Map();
    }
    
    async uploadFiles(files) {
        // 为每个文件创建结果项
        files.forEach((file, index) => {
            this.createResultItem(file, index);
        });
        
        // 开始流式上传
        for (let file of files) {
            await this.uploadSingle(file);
        }
    }
    
    async uploadSingle(file) {
        // 控制并发数
        while (this.active >= this.maxConcurrent) {
            await this.waitForSlot();
        }
        
        this.active++;
        
        try {
            // 立即上传并处理单张图片
            const response = await fetch('/api/v1/enhance', {
                method: 'POST',
                body: this.createFormData(file)
            });
            
            const task = await response.json();
            this.monitorTask(task.task_id, fileIndex, file);
            
        } finally {
            this.active--;
        }
    }
    
    async monitorTask(taskId, fileIndex, file) {
        while (true) {
            const response = await fetch(`/api/v1/status/${taskId}`);
            const status = await response.json();
            
            this.updateProgress(fileIndex, status.progress);
            
            if (status.status === 'completed') {
                this.downloadResult(taskId, fileIndex, file);
                break;
            } else if (status.status === 'failed') {
                this.handleError(fileIndex, status.error);
                break;
            }
            
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
}
```

## 🛡️ 错误处理

### 错误响应格式
```json
{
    "error": "error_type",
    "message": "Detailed error message",
    "task_id": "uuid-string",
    "timestamp": 1640995200.123456
}
```

### 常见错误类型
- **validation_error**: 参数验证失败
- **file_too_large**: 文件过大
- **unsupported_format**: 不支持的文件格式
- **processing_error**: 处理过程中出错
- **task_not_found**: 任务不存在
- **server_error**: 服务器内部错误

### 错误处理示例
```javascript
async function handleApiCall() {
    try {
        const response = await fetch('/api/v1/enhance', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(`${error.error}: ${error.message}`);
        }
        
        const result = await response.json();
        return result;
        
    } catch (error) {
        console.error('API调用失败:', error.message);
        // 处理错误
    }
}
```

## 🔗 相关链接

- [快速开始指南](QUICK_START.md)
- [配置说明](CONFIGURATION.md)
- [流式处理方案](STREAM_PROCESSING.md)
- [前端集成指南](FRONTEND_INTEGRATION.md)
