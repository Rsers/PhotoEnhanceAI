# 前端集成指南

## 🌐 API服务信息

### 服务地址
- **本地开发**: http://localhost:8000
- **生产环境**: http://your-server-ip:8000

### 可用端点
- **API文档**: `/docs` - Swagger交互式文档
- **健康检查**: `/health` - 服务状态检查
- **图像增强**: `/api/v1/enhance` - 上传图像进行处理
- **任务状态**: `/api/v1/status/{task_id}` - 查询处理状态
- **下载结果**: `/api/v1/download/{task_id}` - 下载处理结果
- **删除任务**: `/api/v1/tasks/{task_id}` - 清理任务文件

## 💻 前端调用示例

### JavaScript/TypeScript 基础函数

```javascript
/**
 * 上传图像并获取任务ID
 */
async function uploadImage(imageFile, options = {}) {
    const formData = new FormData();
    formData.append('file', imageFile);
    formData.append('tile_size', options.tileSize || 400);
    formData.append('quality_level', options.quality || 'high');

    try {
        const response = await fetch('http://localhost:8000/api/v1/enhance', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const result = await response.json();
        return result.task_id;
    } catch (error) {
        console.error('Upload failed:', error);
        throw error;
    }
}

/**
 * 轮询任务状态直到完成
 */
async function waitForCompletion(taskId, onProgress = null) {
    while (true) {
        try {
            const response = await fetch(`http://localhost:8000/api/v1/status/${taskId}`);
            const status = await response.json();
            
            if (onProgress) {
                onProgress(status);
            }
            
            if (status.status === 'completed') {
                return status;
            } else if (status.status === 'failed') {
                throw new Error(status.error || 'Processing failed');
            }
            
            // 等待2秒后再次检查
            await new Promise(resolve => setTimeout(resolve, 2000));
        } catch (error) {
            console.error('Status check failed:', error);
            throw error;
        }
    }
}

/**
 * 下载处理结果
 */
async function downloadResult(taskId, filename = 'enhanced_image.jpg') {
    try {
        const response = await fetch(`http://localhost:8000/api/v1/download/${taskId}`);
        
        if (!response.ok) {
            throw new Error(`Download failed! status: ${response.status}`);
        }
        
        const blob = await response.blob();
        
        // 创建下载链接
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
        
        return blob;
    } catch (error) {
        console.error('Download failed:', error);
        throw error;
    }
}

/**
 * 完整的图像增强流程
 */
async function enhanceImage(imageFile, options = {}) {
    try {
        console.log('🚀 开始上传图像...');
        
        // 1. 上传图像
        const taskId = await uploadImage(imageFile, options);
        console.log(`📋 任务ID: ${taskId}`);
        
        // 2. 等待处理完成
        console.log('⏳ 正在处理图像...');
        const result = await waitForCompletion(taskId, (status) => {
            console.log(`📊 处理进度: ${Math.round((status.progress || 0) * 100)}%`);
            console.log(`💬 状态: ${status.message}`);
        });
        
        // 3. 下载结果
        console.log('✅ 处理完成，开始下载...');
        const blob = await downloadResult(taskId);
        
        // 4. 清理任务
        await fetch(`http://localhost:8000/api/v1/tasks/${taskId}`, {
            method: 'DELETE'
        });
        
        console.log('🎉 图像增强完成！');
        return blob;
        
    } catch (error) {
        console.error('❌ 图像增强失败:', error);
        throw error;
    }
}
```

### React Hook 示例

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
            // 上传
            const taskId = await uploadImage(file, options);
            
            // 等待完成
            const result = await waitForCompletion(taskId, (status) => {
                setProgress(Math.round((status.progress || 0) * 100));
            });
            
            // 下载
            const blob = await downloadResult(taskId);
            
            // 清理
            await fetch(`http://localhost:8000/api/v1/tasks/${taskId}`, {
                method: 'DELETE'
            });
            
            return blob;
            
        } catch (err) {
            setError(err.message);
            throw err;
        } finally {
            setLoading(false);
            setProgress(0);
        }
    }, []);

    return {
        enhanceImage,
        loading,
        progress,
        error
    };
}

// 使用示例
function ImageEnhancer() {
    const { enhanceImage, loading, progress, error } = useImageEnhancement();
    const [result, setResult] = useState(null);

    const handleFileSelect = async (event) => {
        const file = event.target.files[0];
        if (!file) return;

        try {
            const blob = await enhanceImage(file, {
                quality: 'high',
                tileSize: 400
            });
            
            const url = URL.createObjectURL(blob);
            setResult(url);
        } catch (error) {
            console.error('Enhancement failed:', error);
        }
    };

    return (
        <div>
            <input type="file" accept="image/*" onChange={handleFileSelect} />
            
            {loading && (
                <div>
                    <p>处理中... {progress}%</p>
                    <div style={{width: '100%', background: '#f0f0f0'}}>
                        <div style={{
                            width: `${progress}%`, 
                            height: '10px', 
                            background: '#007bff'
                        }} />
                    </div>
                </div>
            )}
            
            {error && <p style={{color: 'red'}}>错误: {error}</p>}
            
            {result && <img src={result} alt="Enhanced" style={{maxWidth: '100%'}} />}
        </div>
    );
}
```

### Vue.js 示例

```javascript
// Vue 3 Composition API
import { ref } from 'vue';

export function useImageEnhancement() {
    const loading = ref(false);
    const progress = ref(0);
    const error = ref(null);

    const enhanceImage = async (file, options = {}) => {
        loading.value = true;
        error.value = null;
        progress.value = 0;

        try {
            const taskId = await uploadImage(file, options);
            
            const result = await waitForCompletion(taskId, (status) => {
                progress.value = Math.round((status.progress || 0) * 100);
            });
            
            const blob = await downloadResult(taskId);
            
            // 清理任务
            await fetch(`http://localhost:8000/api/v1/tasks/${taskId}`, {
                method: 'DELETE'
            });
            
            return blob;
            
        } catch (err) {
            error.value = err.message;
            throw err;
        } finally {
            loading.value = false;
            progress.value = 0;
        }
    };

    return {
        enhanceImage,
        loading,
        progress,
        error
    };
}
```

## 🔧 配置参数说明

### 处理参数
- **tile_size**: 瓦片大小 (256-512)
  - 256: 最省显存，速度快，质量稍低
  - 400: 推荐设置，平衡质量和性能
  - 512: 最高质量，需要更多显存

- **quality_level**: 质量等级
  - fast: 快速处理，适合预览
  - medium: 中等质量，平衡速度和效果
  - high: 高质量处理，效果最佳

### 文件限制
- **支持格式**: JPG, JPEG, PNG, BMP, TIFF
- **最大文件**: 50MB
- **推荐尺寸**: 1000x1000 以下

## 🚦 状态码说明

### 任务状态
- **queued**: 任务排队中
- **processing**: 正在处理
- **completed**: 处理完成
- **failed**: 处理失败

### HTTP状态码
- **200**: 成功
- **400**: 请求错误
- **404**: 任务不存在
- **413**: 文件过大
- **500**: 服务器错误

## 🔍 故障排除

### 常见问题
1. **上传失败**: 检查文件格式和大小
2. **处理超时**: 大图片需要更长时间，尝试降低tile_size
3. **下载失败**: 确认任务状态为completed

### 性能优化
1. 图片预压缩到合适尺寸
2. 使用适当的quality_level
3. 实现断点续传机制
