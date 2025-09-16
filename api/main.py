#!/usr/bin/env python3
"""
PhotoEnhanceAI Web API
FastAPI-based web service for AI-powered portrait enhancement
"""

import os
import sys
import uuid
import asyncio
import tempfile
import shutil
from pathlib import Path
from typing import Optional, Dict, Any, List
import time
import zipfile
import io

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Query
from fastapi.responses import FileResponse, JSONResponse, Response
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pydantic import BaseModel
import aiofiles

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

# Import configuration
from config.settings import APISettings

# Import model manager
from model_manager import model_manager

# Initialize FastAPI app
app = FastAPI(
    title="PhotoEnhanceAI API",
    description="AI-powered portrait enhancement service using GFPGAN integrated solution (Face Restoration + Super Resolution)",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for web frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global settings
settings = APISettings()

# In-memory task storage (use Redis in production)
tasks_storage: Dict[str, Dict[str, Any]] = {}
batch_tasks_storage: Dict[str, Dict[str, Any]] = {}

class TaskResponse(BaseModel):
    """Task response model"""
    task_id: str
    status: str
    message: str
    created_at: float
    
class TaskStatus(BaseModel):
    """Task status model"""
    task_id: str
    status: str
    message: str
    progress: Optional[float] = None
    result_url: Optional[str] = None
    error: Optional[str] = None
    created_at: float
    updated_at: float
    processing_time: Optional[float] = None

class EnhanceRequest(BaseModel):
    """Enhancement request parameters"""
    tile_size: int = 400
    quality_level: str = "high"  # high, medium, fast

class BatchTaskResponse(BaseModel):
    """批量任务响应模型"""
    batch_task_id: str
    total_files: int
    status: str
    message: str
    created_at: float
    sub_tasks: List[str]  # 子任务ID列表

class BatchTaskStatus(BaseModel):
    """批量任务状态模型"""
    batch_task_id: str
    status: str  # queued, processing, completed, failed, partial_completed
    total_files: int
    completed_files: int
    failed_files: int
    progress: float
    sub_tasks: List[Dict[str, Any]]
    created_at: float
    updated_at: float
    message: str

def validate_image_file(file: UploadFile) -> None:
    """Validate uploaded image file"""
    # Check file size (max 50MB)
    if hasattr(file, 'size') and file.size and file.size > settings.MAX_FILE_SIZE_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Maximum size: {settings.MAX_FILE_SIZE_MB}MB"
        )
    
    # Check file format
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400,
            detail="Invalid file type. Only image files are allowed."
        )
    
    # Check file extension
    if file.filename:
        ext = Path(file.filename).suffix.lower()
        if ext not in settings.SUPPORTED_FORMATS:
            raise HTTPException(
                status_code=400,
                detail=f"Unsupported file format. Supported: {', '.join(settings.SUPPORTED_FORMATS)}"
            )

async def process_image_task(task_id: str, input_path: str, output_path: str, tile_size: int):
    """Background task for image processing using resident model"""
    try:
        # Update task status
        tasks_storage[task_id].update({
            'status': 'processing',
            'message': '使用常驻模型处理中...',
            'updated_at': time.time(),
            'progress': 0.1
        })
        
        # Update progress
        tasks_storage[task_id].update({
            'progress': 0.3,
            'message': 'GFPGAN常驻模型处理中 (人脸修复 + 超分辨率)...',
            'updated_at': time.time()
        })
        
        # Execute processing using resident model
        start_time = time.time()
        await model_manager.enhance_image(input_path, output_path, tile_size)
        processing_time = time.time() - start_time
        
        # Success
        tasks_storage[task_id].update({
            'status': 'completed',
            'message': 'GFPGAN图像增强完成 (人脸修复 + 4倍超分辨率)',
            'progress': 1.0,
            'result_url': f"/api/v1/download/{task_id}",
            'updated_at': time.time(),
            'processing_time': processing_time
        })
            
    except Exception as e:
        # Unexpected error
        tasks_storage[task_id].update({
            'status': 'failed',
            'message': 'GFPGAN处理异常',
            'error': str(e),
            'updated_at': time.time()
        })

async def process_batch_task(batch_task_id: str, sub_task_ids: List[str], tile_size: int):
    """批量处理任务"""
    try:
        batch_data = batch_tasks_storage[batch_task_id]
        batch_data.update({
            'status': 'processing',
            'message': '开始批量处理',
            'updated_at': time.time()
        })
        
        # 并发处理子任务（控制并发数）
        semaphore = asyncio.Semaphore(3)  # 最多3个并发
        
        async def process_single_task(task_id: str):
            async with semaphore:
                task_data = tasks_storage[task_id]
                try:
                    # 更新子任务状态
                    tasks_storage[task_id].update({
                        'status': 'processing',
                        'message': '使用常驻模型处理中...',
                        'progress': 0.1,
                        'updated_at': time.time()
                    })
                    
                    # 使用常驻模型处理
                    await model_manager.enhance_image(
                        task_data['input_path'],
                        task_data['output_path'],
                        task_data['tile_size']
                    )
                    
                    # 更新子任务状态
                    tasks_storage[task_id].update({
                        'status': 'completed',
                        'message': '处理完成',
                        'progress': 1.0,
                        'updated_at': time.time()
                    })
                    
                    return True
                except Exception as e:
                    tasks_storage[task_id].update({
                        'status': 'failed',
                        'message': '处理失败',
                        'error': str(e),
                        'updated_at': time.time()
                    })
                    return False
        
        # 并发处理所有子任务
        results = await asyncio.gather(*[process_single_task(task_id) for task_id in sub_task_ids])
        
        # 更新批量任务状态
        completed_count = sum(results)
        failed_count = len(results) - completed_count
        
        batch_tasks_storage[batch_task_id].update({
            'status': 'completed' if failed_count == 0 else 'partial_completed',
            'completed_files': completed_count,
            'failed_files': failed_count,
            'progress': 1.0,
            'message': f'批量处理完成：成功{completed_count}张，失败{failed_count}张',
            'updated_at': time.time()
        })
        
    except Exception as e:
        batch_tasks_storage[batch_task_id].update({
            'status': 'failed',
            'message': f'批量处理失败: {str(e)}',
            'updated_at': time.time()
        })

@app.get("/")
async def root():
    """API root endpoint"""
    return {
        "service": "PhotoEnhanceAI API",
        "version": "2.0.0",
        "status": "running",
        "description": "AI-powered portrait enhancement service using GFPGAN (Face Restoration + Super Resolution)",
        "features": {
            "face_restoration": "AI智能人脸修复和美化",
            "super_resolution": "RealESRGAN背景超分辨率",
            "integrated_processing": "一体化处理，速度提升7倍",
            "scale_options": "支持1-16倍分辨率放大"
        },
        "endpoints": {
            "docs": "/docs",
            "health": "/health", 
            "enhance": "/api/v1/enhance",
            "enhance_batch": "/api/v1/enhance/batch",
            "status": "/api/v1/status/{task_id}",
            "batch_status": "/api/v1/batch/status/{batch_task_id}",
            "download": "/api/v1/download/{task_id}",
            "batch_download": "/api/v1/batch/download/{batch_task_id}"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    model_info = model_manager.get_model_info()
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "active_tasks": len([t for t in tasks_storage.values() if t['status'] == 'processing']),
        "model_status": {
            "initialized": model_info["initialized"],
            "cuda_available": model_info["cuda_available"],
            "device": model_info["device"]
        }
    }

@app.post("/api/v1/enhance", response_model=TaskResponse)
async def enhance_portrait(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    tile_size: int = Query(400, ge=256, le=512, description="Tile size for processing (256-512)"),
    quality_level: str = Query("high", pattern="^(fast|medium|high)$", description="Quality level")
):
    """
    使用GFPGAN增强图像 (人脸修复 + 超分辨率)
    
    - **file**: 图像文件 (JPG, PNG, 等)
    - **tile_size**: 瓦片大小，影响显存使用 (256-512, 默认: 400)
    - **quality_level**: 处理质量 (fast/medium/high, 默认: high)
    
    GFPGAN功能:
    - ✅ AI人脸修复和美化
    - ✅ RealESRGAN背景超分辨率  
    - ✅ 4倍分辨率提升
    - ✅ 一体化处理，比传统流水线快7倍
    
    返回任务ID用于状态跟踪
    """
    # Validate input
    validate_image_file(file)
    
    # Generate task ID
    task_id = str(uuid.uuid4())
    
    # Create temporary directories
    temp_dir = Path(tempfile.mkdtemp(prefix="photoenhanceai_"))
    input_path = temp_dir / f"input_{file.filename}"
    output_path = temp_dir / f"output_{task_id}.jpg"
    
    try:
        # Save uploaded file
        async with aiofiles.open(input_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # Adjust tile size based on quality level
        if quality_level == "fast":
            tile_size = min(tile_size, 256)
        elif quality_level == "medium":
            tile_size = min(tile_size, 400)
        # high quality uses the provided tile_size
        
        # Initialize task
        current_time = time.time()
        tasks_storage[task_id] = {
            'task_id': task_id,
            'status': 'queued',
            'message': 'GFPGAN任务排队中 (使用常驻模型)',
            'progress': 0.0,
            'created_at': current_time,
            'updated_at': current_time,
            'input_path': str(input_path),
            'output_path': str(output_path),
            'temp_dir': str(temp_dir),
            'original_filename': file.filename,
            'quality_level': quality_level,
            'tile_size': tile_size
        }
        
        # Start background processing
        background_tasks.add_task(
            process_image_task,
            task_id,
            str(input_path),
            str(output_path),
            tile_size
        )
        
        return TaskResponse(
            task_id=task_id,
            status="queued",
            message="GFPGAN任务排队中 (使用常驻模型)",
            created_at=current_time
        )
        
    except Exception as e:
        # Cleanup on error
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        raise HTTPException(status_code=500, detail=f"Failed to process request: {str(e)}")

@app.get("/api/v1/status/{task_id}", response_model=TaskStatus)
async def get_task_status(task_id: str):
    """Get task processing status"""
    if task_id not in tasks_storage:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task_data = tasks_storage[task_id]
    return TaskStatus(**task_data)

@app.get("/api/v1/download/{task_id}")
async def download_result(task_id: str):
    """Download processed image"""
    if task_id not in tasks_storage:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task_data = tasks_storage[task_id]
    
    if task_data['status'] != 'completed':
        raise HTTPException(
            status_code=400, 
            detail=f"Task not completed. Current status: {task_data['status']}"
        )
    
    output_path = Path(task_data['output_path'])
    if not output_path.exists():
        raise HTTPException(status_code=404, detail="Result file not found")
    
    # Get original filename for response
    original_name = task_data.get('original_filename', 'image.jpg')
    name_parts = Path(original_name).stem, Path(original_name).suffix
    enhanced_filename = f"{name_parts[0]}_enhanced{name_parts[1]}"
    
    return FileResponse(
        path=output_path,
        filename=enhanced_filename,
        media_type='image/jpeg'
    )

@app.delete("/api/v1/tasks/{task_id}")
async def delete_task(task_id: str):
    """Delete task and cleanup files"""
    if task_id not in tasks_storage:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task_data = tasks_storage[task_id]
    
    # Cleanup files
    temp_dir = Path(task_data.get('temp_dir', ''))
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
    
    # Remove from storage
    del tasks_storage[task_id]
    
    return {"message": "Task deleted successfully"}

@app.get("/api/v1/tasks")
async def list_tasks():
    """List all tasks (for debugging)"""
    return {
        "total_tasks": len(tasks_storage),
        "tasks": [
            {
                "task_id": task_id,
                "status": task_data["status"],
                "created_at": task_data["created_at"],
                "updated_at": task_data["updated_at"]
            }
            for task_id, task_data in tasks_storage.items()
        ]
    }

@app.post("/api/v1/enhance/batch", response_model=BatchTaskResponse)
async def enhance_batch_portraits(
    background_tasks: BackgroundTasks,
    files: List[UploadFile] = File(...),
    tile_size: int = Query(400, ge=256, le=512),
    quality_level: str = Query("high", pattern="^(fast|medium|high)$")
):
    """
    批量处理多张图片
    
    - **files**: 多张图像文件（最多20张）
    - **tile_size**: 瓦片大小 (256-512, 默认: 400)
    - **quality_level**: 处理质量 (fast/medium/high, 默认: high)
    """
    # 验证文件数量
    if len(files) > 20:  # 限制最大20张
        raise HTTPException(status_code=400, detail="最多支持20张图片")
    
    # 验证所有文件
    for file in files:
        validate_image_file(file)
    
    # 创建批量任务
    batch_task_id = str(uuid.uuid4())
    current_time = time.time()
    
    # 创建临时目录
    temp_dir = Path(tempfile.mkdtemp(prefix="batch_photoenhanceai_"))
    temp_input_dir = temp_dir / "input"
    temp_output_dir = temp_dir / "output"
    temp_input_dir.mkdir()
    temp_output_dir.mkdir()
    
    # 保存所有文件并创建子任务
    sub_task_ids = []
    for i, file in enumerate(files):
        # 保存文件
        input_path = temp_input_dir / f"img_{i:03d}_{file.filename}"
        async with aiofiles.open(input_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # 创建子任务
        sub_task_id = str(uuid.uuid4())
        sub_task_ids.append(sub_task_id)
        
        output_path = temp_output_dir / f"enhanced_{i:03d}_{file.filename}"
        
        # 初始化子任务
        tasks_storage[sub_task_id] = {
            'task_id': sub_task_id,
            'batch_task_id': batch_task_id,
            'status': 'queued',
            'message': '等待处理',
            'progress': 0.0,
            'created_at': current_time,
            'updated_at': current_time,
            'input_path': str(input_path),
            'output_path': str(output_path),
            'original_filename': file.filename,
            'file_index': i,
            'quality_level': quality_level,
            'tile_size': tile_size
        }
    
    # 初始化批量任务
    batch_tasks_storage[batch_task_id] = {
        'batch_task_id': batch_task_id,
        'status': 'queued',
        'total_files': len(files),
        'completed_files': 0,
        'failed_files': 0,
        'progress': 0.0,
        'sub_tasks': sub_task_ids,
        'created_at': current_time,
        'updated_at': current_time,
        'temp_dir': str(temp_dir),
        'message': f'批量任务已创建，共{len(files)}张图片'
    }
    
    # 启动批量处理
    background_tasks.add_task(
        process_batch_task,
        batch_task_id,
        sub_task_ids,
        tile_size
    )
    
    return BatchTaskResponse(
        batch_task_id=batch_task_id,
        total_files=len(files),
        status="queued",
        message=f"批量任务已创建，共{len(files)}张图片",
        created_at=current_time,
        sub_tasks=sub_task_ids
    )

@app.get("/api/v1/batch/status/{batch_task_id}", response_model=BatchTaskStatus)
async def get_batch_task_status(batch_task_id: str):
    """获取批量任务状态"""
    if batch_task_id not in batch_tasks_storage:
        raise HTTPException(status_code=404, detail="批量任务不存在")
    
    batch_data = batch_tasks_storage[batch_task_id]
    
    # 获取子任务状态
    sub_tasks_status = []
    for task_id in batch_data['sub_tasks']:
        if task_id in tasks_storage:
            task_data = tasks_storage[task_id]
            sub_tasks_status.append({
                'task_id': task_id,
                'status': task_data['status'],
                'filename': task_data['original_filename'],
                'progress': task_data.get('progress', 0),
                'error': task_data.get('error')
            })
    
    return BatchTaskStatus(
        batch_task_id=batch_task_id,
        status=batch_data['status'],
        total_files=batch_data['total_files'],
        completed_files=batch_data['completed_files'],
        failed_files=batch_data['failed_files'],
        progress=batch_data['progress'],
        sub_tasks=sub_tasks_status,
        created_at=batch_data['created_at'],
        updated_at=batch_data['updated_at'],
        message=batch_data['message']
    )

@app.get("/api/v1/batch/download/{batch_task_id}")
async def download_batch_results(batch_task_id: str):
    """下载批量处理结果（ZIP格式）"""
    if batch_task_id not in batch_tasks_storage:
        raise HTTPException(status_code=404, detail="批量任务不存在")
    
    batch_data = batch_tasks_storage[batch_task_id]
    if batch_data['status'] not in ['completed', 'partial_completed']:
        raise HTTPException(status_code=400, detail="批量任务未完成")
    
    # 创建ZIP文件
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        for task_id in batch_data['sub_tasks']:
            if task_id in tasks_storage:
                task_data = tasks_storage[task_id]
                if task_data['status'] == 'completed':
                    output_path = Path(task_data['output_path'])
                    if output_path.exists():
                        zip_file.write(output_path, task_data['original_filename'])
    
    zip_buffer.seek(0)
    
    return Response(
        content=zip_buffer.getvalue(),
        media_type='application/zip',
        headers={'Content-Disposition': f'attachment; filename="batch_results_{batch_task_id}.zip"'}
    )

if __name__ == "__main__":
    # Development server
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        log_level="info"
    )
