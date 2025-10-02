# 📘 前端集成指南

PhotoEnhanceAI的Web前端集成指南和示例代码。

## 🌐 基础集成

### HTML + JavaScript
```html
<!DOCTYPE html>
<html>
<head>
    <title>PhotoEnhanceAI 前端集成</title>
</head>
<body>
    <input type="file" id="imageInput" accept="image/*">
    <button onclick="enhanceImage()">增强图片</button>
    <div id="result"></div>

    <script>
        async function enhanceImage() {
            const fileInput = document.getElementById('imageInput');
            const file = fileInput.files[0];
            
            if (!file) {
                alert('请选择图片文件');
                return;
            }

            const formData = new FormData();
            formData.append('file', file);
            formData.append('tile_size', 400);
            formData.append('quality_level', 'high');

            try {
                // 上传并处理图片
                const response = await fetch('http://localhost:8000/api/v1/enhance', {
                    method: 'POST',
                    body: formData
                });

                const result = await response.json();
                const taskId = result.task_id;

                // 轮询任务状态
                await waitForCompletion(taskId);
                
                // 下载结果
                await downloadResult(taskId);

            } catch (error) {
                console.error('处理失败:', error);
            }
        }

        async function waitForCompletion(taskId) {
            while (true) {
                const response = await fetch(`http://localhost:8000/api/v1/status/${taskId}`);
                const status = await response.json();
                
                console.log(`进度: ${status.progress}%`);
                
                if (status.status === 'completed') {
                    return status;
                } else if (status.status === 'failed') {
                    throw new Error(`处理失败: ${status.error}`);
                }
                
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }

        async function downloadResult(taskId) {
            const response = await fetch(`http://localhost:8000/api/v1/download/${taskId}`);
            const blob = await response.blob();
            
            const url = window.URL.createObjectURL(blob);
            const img = document.createElement('img');
            img.src = url;
            img.style.maxWidth = '100%';
            
            document.getElementById('result').appendChild(img);
            
            window.URL.revokeObjectURL(url);
        }
    </script>
</body>
</html>
```

## ⚛️ React集成

### React Hook
```javascript
import { useState, useCallback } from 'react';

export function useImageEnhancement() {
    const [loading, setLoading] = useState(false);
    const [progress, setProgress] = useState(0);
    const [error, setError] = useState(null);
    const [result, setResult] = useState(null);

    const enhanceImage = useCallback(async (file, options = {}) => {
        setLoading(true);
        setError(null);
        setProgress(0);
        setResult(null);

        try {
            // 上传图片
            const formData = new FormData();
            formData.append('file', file);
            formData.append('tile_size', options.tile_size || 400);
            formData.append('quality_level', options.quality_level || 'high');

            const response = await fetch('http://localhost:8000/api/v1/enhance', {
                method: 'POST',
                body: formData
            });

            if (!response.ok) {
                throw new Error('上传失败');
            }

            const { task_id } = await response.json();

            // 轮询状态
            while (true) {
                const statusResponse = await fetch(`http://localhost:8000/api/v1/status/${task_id}`);
                const status = await statusResponse.json();
                
                setProgress(status.progress || 0);
                
                if (status.status === 'completed') {
                    // 下载结果
                    const downloadResponse = await fetch(`http://localhost:8000/api/v1/download/${task_id}`);
                    const blob = await downloadResponse.blob();
                    
                    setResult(blob);
                    return blob;
                } else if (status.status === 'failed') {
                    throw new Error(status.error || '处理失败');
                }
                
                await new Promise(resolve => setTimeout(resolve, 1000));
            }

        } catch (err) {
            setError(err.message);
            throw err;
        } finally {
            setLoading(false);
            setProgress(0);
        }
    }, []);

    return { enhanceImage, loading, progress, error, result };
}
```

### React组件示例
```javascript
import React, { useState } from 'react';
import { useImageEnhancement } from './useImageEnhancement';

function ImageEnhancer() {
    const [selectedFile, setSelectedFile] = useState(null);
    const { enhanceImage, loading, progress, error, result } = useImageEnhancement();

    const handleFileChange = (event) => {
        setSelectedFile(event.target.files[0]);
    };

    const handleEnhance = async () => {
        if (!selectedFile) return;
        
        try {
            await enhanceImage(selectedFile, {
                tile_size: 400,
                quality_level: 'high'
            });
        } catch (err) {
            console.error('增强失败:', err);
        }
    };

    return (
        <div>
            <input type="file" onChange={handleFileChange} accept="image/*" />
            <button onClick={handleEnhance} disabled={loading || !selectedFile}>
                {loading ? '处理中...' : '增强图片'}
            </button>
            
            {loading && (
                <div>
                    <p>处理进度: {progress}%</p>
                    <progress value={progress} max={100} />
                </div>
            )}
            
            {error && <p style={{color: 'red'}}>错误: {error}</p>}
            
            {result && (
                <div>
                    <h3>增强结果:</h3>
                    <img src={URL.createObjectURL(result)} alt="增强结果" style={{maxWidth: '100%'}} />
                </div>
            )}
        </div>
    );
}

export default ImageEnhancer;
```

## 🚀 流式处理集成

### 流式上传器
```javascript
class StreamUploader {
    constructor(maxConcurrent = 1) {
        this.maxConcurrent = maxConcurrent;
        this.active = 0;
        this.results = new Map();
    }
    
    async uploadFiles(files, onProgress, onComplete, onError) {
        // 为每个文件创建结果项
        files.forEach((file, index) => {
            this.createResultItem(file, index);
        });
        
        // 开始流式上传
        for (let file of files) {
            await this.uploadSingle(file, onProgress, onComplete, onError);
        }
    }
    
    async uploadSingle(file, onProgress, onComplete, onError) {
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
            await this.monitorTask(task.task_id, file, onProgress, onComplete, onError);
            
        } catch (error) {
            onError && onError(file, error);
        } finally {
            this.active--;
        }
    }
    
    async monitorTask(taskId, file, onProgress, onComplete, onError) {
        while (true) {
            try {
                const response = await fetch(`/api/v1/status/${taskId}`);
                const status = await response.json();
                
                onProgress && onProgress(file, status.progress);
                
                if (status.status === 'completed') {
                    const downloadResponse = await fetch(`/api/v1/download/${taskId}`);
                    const blob = await downloadResponse.blob();
                    onComplete && onComplete(file, blob);
                    break;
                } else if (status.status === 'failed') {
                    onError && onError(file, new Error(status.error));
                    break;
                }
                
                await new Promise(resolve => setTimeout(resolve, 1000));
            } catch (error) {
                onError && onError(file, error);
                break;
            }
        }
    }
    
    createFormData(file) {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('tile_size', 400);
        formData.append('quality_level', 'high');
        return formData;
    }
    
    createResultItem(file, index) {
        this.results.set(file, {
            index,
            progress: 0,
            status: 'pending',
            result: null,
            error: null
        });
    }
    
    waitForSlot() {
        return new Promise(resolve => setTimeout(resolve, 100));
    }
}
```

### 使用流式上传器
```javascript
const uploader = new StreamUploader(1); // 推荐1个并发

uploader.uploadFiles(
    files,
    // 进度回调
    (file, progress) => {
        console.log(`${file.name}: ${progress}%`);
        updateProgress(file, progress);
    },
    // 完成回调
    (file, result) => {
        console.log(`${file.name}: 处理完成`);
        displayResult(file, result);
    },
    // 错误回调
    (file, error) => {
        console.error(`${file.name}: ${error.message}`);
        displayError(file, error);
    }
);
```

## 🎨 UI组件示例

### 拖拽上传组件
```javascript
import React, { useCallback, useState } from 'react';

function DragDropUploader({ onFilesSelected, maxFiles = 10 }) {
    const [isDragOver, setIsDragOver] = useState(false);

    const handleDragOver = useCallback((e) => {
        e.preventDefault();
        setIsDragOver(true);
    }, []);

    const handleDragLeave = useCallback((e) => {
        e.preventDefault();
        setIsDragOver(false);
    }, []);

    const handleDrop = useCallback((e) => {
        e.preventDefault();
        setIsDragOver(false);
        
        const files = Array.from(e.dataTransfer.files)
            .filter(file => file.type.startsWith('image/'))
            .slice(0, maxFiles);
            
        onFilesSelected(files);
    }, [onFilesSelected, maxFiles]);

    return (
        <div
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleDrop}
            style={{
                border: isDragOver ? '2px dashed #007bff' : '2px dashed #ccc',
                borderRadius: '8px',
                padding: '40px',
                textAlign: 'center',
                backgroundColor: isDragOver ? '#f8f9fa' : '#fff',
                cursor: 'pointer'
            }}
        >
            {isDragOver ? (
                <p>释放文件以上传</p>
            ) : (
                <p>拖拽图片文件到这里，或点击选择文件</p>
            )}
        </div>
    );
}
```

### 进度显示组件
```javascript
import React from 'react';

function ProgressDisplay({ files, results }) {
    return (
        <div>
            {files.map((file, index) => {
                const result = results.get(file);
                return (
                    <div key={index} style={{ marginBottom: '16px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                            <span>{file.name}</span>
                            <span>{result?.status || 'pending'}</span>
                        </div>
                        
                        {result?.progress !== undefined && (
                            <div style={{ width: '100%', backgroundColor: '#f0f0f0', borderRadius: '4px' }}>
                                <div
                                    style={{
                                        width: `${result.progress}%`,
                                        backgroundColor: '#007bff',
                                        height: '8px',
                                        borderRadius: '4px',
                                        transition: 'width 0.3s ease'
                                    }}
                                />
                            </div>
                        )}
                        
                        {result?.error && (
                            <p style={{ color: 'red', fontSize: '14px' }}>
                                错误: {result.error.message}
                            </p>
                        )}
                        
                        {result?.result && (
                            <img
                                src={URL.createObjectURL(result.result)}
                                alt={`增强结果 - ${file.name}`}
                                style={{ maxWidth: '200px', marginTop: '8px' }}
                            />
                        )}
                    </div>
                );
            })}
        </div>
    );
}
```

## 📱 移动端适配

### 响应式设计
```css
.image-enhancer {
    max-width: 100%;
    padding: 16px;
}

.upload-area {
    min-height: 200px;
    display: flex;
    align-items: center;
    justify-content: center;
}

@media (max-width: 768px) {
    .upload-area {
        min-height: 150px;
        padding: 20px;
    }
    
    .progress-container {
        flex-direction: column;
    }
    
    .result-image {
        max-width: 100%;
        height: auto;
    }
}
```

### 移动端优化
```javascript
// 移动端文件选择优化
function handleFileInput(e) {
    const files = Array.from(e.target.files);
    
    // 移动端可能需要压缩图片
    if (isMobileDevice()) {
        files.forEach(file => {
            compressImage(file, 0.8).then(compressedFile => {
                processFile(compressedFile);
            });
        });
    } else {
        files.forEach(processFile);
    }
}

function isMobileDevice() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
}

function compressImage(file, quality) {
    return new Promise((resolve) => {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        const img = new Image();
        
        img.onload = () => {
            canvas.width = img.width;
            canvas.height = img.height;
            ctx.drawImage(img, 0, 0);
            
            canvas.toBlob(resolve, 'image/jpeg', quality);
        };
        
        img.src = URL.createObjectURL(file);
    });
}
```

## 🔗 相关链接

- [API文档](API_REFERENCE.md)
- [流式处理方案](STREAM_PROCESSING.md)
- [快速开始指南](QUICK_START.md)
- [性能优化](PERFORMANCE.md)
