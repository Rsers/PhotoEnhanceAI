# 📘 批量处理

PhotoEnhanceAI的批量处理优化方案和最佳实践。

## 🚀 批量处理方案对比

| 方案 | 第一张图片时间 | 用户体验 | 实现复杂度 | 网络效率 | 推荐度 |
|------|----------------|----------|------------|----------|--------|
| **批量上传** | 8秒 | 需要等待所有完成 | 中等 | 中等 | ⭐⭐⭐ |
| **ZIP包上传** | 6秒 | 需要等待解压 | 高 | 低（JPG压缩效果差） | ⭐⭐ |
| **流式处理** | **5秒** | **渐进式显示** | **低** | **高** | **⭐⭐⭐⭐⭐** |

## 🎯 流式处理方案（推荐）

### 核心优势
- ⚡ **性能最佳**: 第一张图片显示时间最短（4.91秒）
- 🎯 **用户体验最佳**: 渐进式显示，无需等待所有图片完成
- 🔧 **实现最简单**: 利用现有API，无需额外开发
- 💾 **资源利用最合理**: 避免AI模型资源竞争，确保稳定处理

### 技术实现
```javascript
class StreamUploader {
    constructor(maxConcurrent = 1) {  // 基于实际测试结果推荐1个并发
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
        // 控制并发数，避免AI模型资源竞争
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
            await this.monitorTask(task.task_id, file);
            
        } finally {
            this.active--;
        }
    }
}
```

## 📊 性能测试结果

### 并发数性能测试
基于实际服务器环境的并发数测试（使用test001.jpg，测试5张图片）：

| 并发数 | 总时间(秒) | 第一张图片(秒) | 成功率(%) | 推荐度 |
|--------|------------|----------------|-----------|--------|
| 1      | 24.44      | **4.91**       | 100.0     | 🥇 最佳 |
| 2      | 24.62      | 9.85           | 100.0     | ⚠️ 一般 |
| 3      | 24.72      | 11.57          | 100.0     | ⚠️ 一般 |
| 4      | 24.78      | 18.19          | 100.0     | ⚠️ 一般 |
| 5      | 24.80      | 18.20          | 100.0     | ⚠️ 一般 |

**测试结论**：
- 🎯 **最优并发数**: 1个并发
- ⚡ **第一张图片时间**: 4.91秒（最快）
- 📊 **成功率**: 100%（所有并发数都达到100%成功率）
- 💡 **服务器特性**: 当前服务器配置下，单并发处理效率最高

## ⚠️ AI模型并发处理能力

### 关键结论
GFPGAN模型**不支持真正的并发处理**

#### 技术分析
1. **模型架构限制**：
   - GFPGAN使用单例模式，全局只有一个模型实例
   - 所有请求共享同一个 `restorer` 模型对象
   - 模型内部没有并发处理机制

2. **实际处理模式**：
   ```
   请求1 → 模型处理(4.91秒) → 完成
   请求2 → 等待 → 模型处理(4.91秒) → 完成
   请求3 → 等待 → 模型处理(4.91秒) → 完成
   ```

3. **测试结果验证**：
   - 1个并发：串行处理，每张图片间隔约4.9秒
   - 2个并发：第一张图片时间翻倍（9.85秒）
   - 高并发：第一张图片时间进一步增加

## 🔧 批量处理实现

### 基础批量处理
```javascript
async function batchProcess(files) {
    const results = [];
    
    for (let file of files) {
        try {
            // 处理单张图片
            const result = await processSingleImage(file);
            results.push({ file: file.name, success: true, result });
        } catch (error) {
            results.push({ file: file.name, success: false, error: error.message });
        }
    }
    
    return results;
}

async function processSingleImage(file) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('tile_size', 400);
    formData.append('quality_level', 'high');

    const response = await fetch('/api/v1/enhance', {
        method: 'POST',
        body: formData
    });

    const { task_id } = await response.json();

    // 等待处理完成
    while (true) {
        const statusResponse = await fetch(`/api/v1/status/${task_id}`);
        const status = await statusResponse.json();
        
        if (status.status === 'completed') {
            const downloadResponse = await fetch(`/api/v1/download/${task_id}`);
            return await downloadResponse.blob();
        } else if (status.status === 'failed') {
            throw new Error(status.error);
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
}
```

### 流式批量处理
```javascript
class BatchProcessor {
    constructor(maxConcurrent = 1) {
        this.maxConcurrent = maxConcurrent;
        this.active = 0;
        this.queue = [];
        this.results = new Map();
    }
    
    async processBatch(files) {
        // 为每个文件创建结果项
        files.forEach((file, index) => {
            this.createResultItem(file, index);
        });
        
        // 开始流式处理
        for (let file of files) {
            await this.processSingle(file);
        }
        
        return this.getResults();
    }
    
    async processSingle(file) {
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
            await this.monitorTask(task.task_id, file);
            
        } catch (error) {
            this.setError(file, error);
        } finally {
            this.active--;
        }
    }
    
    async monitorTask(taskId, file) {
        while (true) {
            try {
                const response = await fetch(`/api/v1/status/${taskId}`);
                const status = await response.json();
                
                this.updateProgress(file, status.progress);
                
                if (status.status === 'completed') {
                    const downloadResponse = await fetch(`/api/v1/download/${taskId}`);
                    const blob = await downloadResponse.blob();
                    this.setResult(file, blob);
                    break;
                } else if (status.status === 'failed') {
                    this.setError(file, new Error(status.error));
                    break;
                }
                
                await new Promise(resolve => setTimeout(resolve, 1000));
            } catch (error) {
                this.setError(file, error);
                break;
            }
        }
    }
}
```

## 📈 性能优化建议

### 并发控制
```javascript
// 推荐配置：1个并发
const processor = new BatchProcessor(1);

// 避免高并发
// const processor = new BatchProcessor(5); // ❌ 不推荐
```

### 错误处理
```javascript
class RobustBatchProcessor extends BatchProcessor {
    async processSingle(file) {
        let retries = 3;
        
        while (retries > 0) {
            try {
                await super.processSingle(file);
                return;
            } catch (error) {
                retries--;
                if (retries === 0) {
                    this.setError(file, error);
                } else {
                    await new Promise(resolve => setTimeout(resolve, 2000));
                }
            }
        }
    }
}
```

### 进度回调
```javascript
class ProgressBatchProcessor extends BatchProcessor {
    constructor(maxConcurrent = 1, onProgress = null) {
        super(maxConcurrent);
        this.onProgress = onProgress;
    }
    
    updateProgress(file, progress) {
        super.updateProgress(file, progress);
        
        if (this.onProgress) {
            const totalProgress = this.calculateTotalProgress();
            this.onProgress(totalProgress, file, progress);
        }
    }
    
    calculateTotalProgress() {
        const totalFiles = this.results.size;
        const completedFiles = Array.from(this.results.values())
            .filter(result => result.status === 'completed').length;
        
        return Math.round((completedFiles / totalFiles) * 100);
    }
}
```

## 🎯 最佳实践

### 1. 使用流式处理
```javascript
// ✅ 推荐：流式处理
const uploader = new StreamUploader(1);
await uploader.uploadFiles(files);

// ❌ 避免：批量上传
const batchResponse = await fetch('/api/v1/enhance/batch', {
    method: 'POST',
    body: batchFormData
});
```

### 2. 控制并发数
```javascript
// ✅ 推荐：1个并发
const processor = new BatchProcessor(1);

// ❌ 避免：高并发
const processor = new BatchProcessor(10);
```

### 3. 实现进度显示
```javascript
const processor = new ProgressBatchProcessor(1, (totalProgress, file, fileProgress) => {
    console.log(`总体进度: ${totalProgress}%, 当前文件: ${file.name} (${fileProgress}%)`);
    updateUI(totalProgress, file, fileProgress);
});
```

### 4. 错误隔离
```javascript
// ✅ 推荐：单张失败不影响其他
files.forEach(async (file) => {
    try {
        await processSingleImage(file);
    } catch (error) {
        console.error(`处理 ${file.name} 失败:`, error);
        // 继续处理其他文件
    }
});
```

## 📊 时间线对比

```
批量方案：0-3秒上传 → 3-8秒处理 → 8秒看到第一张图片
流式方案：0-0.5秒上传 → 0.5-5秒处理 → 5秒看到第一张图片

性能提升：快3秒（37.5%）
```

## 🔗 相关链接

- [流式处理方案](STREAM_PROCESSING.md)
- [API文档](API_REFERENCE.md)
- [前端集成](FRONTEND_INTEGRATION.md)
- [性能优化](PERFORMANCE.md)
