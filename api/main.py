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
from typing import Optional, Dict, Any
import time

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks, Query
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from pydantic import BaseModel
import aiofiles

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

# Import configuration
from config.settings import APISettings

# Initialize FastAPI app
app = FastAPI(
    title="PhotoEnhanceAI API",
    description="AI-powered portrait enhancement service using SwinIR + GFPGAN reverse pipeline",
    version="1.0.0",
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
    """Background task for image processing"""
    try:
        # Update task status
        tasks_storage[task_id].update({
            'status': 'processing',
            'message': 'Starting image enhancement...',
            'updated_at': time.time(),
            'progress': 0.1
        })
        
        # Import processing module (lazy import to avoid startup issues)
        import subprocess
        
        # Prepare command
        script_path = PROJECT_ROOT / "scripts" / "reverse_portrait_pipeline.py"
        cmd = [
            "python", str(script_path),
            "--input", input_path,
            "--output", output_path,
            "--tile", str(tile_size)
        ]
        
        # Update progress
        tasks_storage[task_id].update({
            'progress': 0.3,
            'message': 'Processing with AI models...',
            'updated_at': time.time()
        })
        
        # Execute processing
        start_time = time.time()
        result = subprocess.run(cmd, capture_output=True, text=True, cwd=PROJECT_ROOT)
        processing_time = time.time() - start_time
        
        if result.returncode == 0:
            # Success
            tasks_storage[task_id].update({
                'status': 'completed',
                'message': 'Image enhancement completed successfully',
                'progress': 1.0,
                'result_url': f"/api/v1/download/{task_id}",
                'updated_at': time.time(),
                'processing_time': processing_time
            })
        else:
            # Error
            error_msg = result.stderr or "Unknown processing error"
            tasks_storage[task_id].update({
                'status': 'failed',
                'message': 'Image enhancement failed',
                'error': error_msg,
                'updated_at': time.time(),
                'processing_time': processing_time
            })
            
    except Exception as e:
        # Unexpected error
        tasks_storage[task_id].update({
            'status': 'failed',
            'message': 'Internal processing error',
            'error': str(e),
            'updated_at': time.time()
        })

@app.get("/")
async def root():
    """API root endpoint"""
    return {
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

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "active_tasks": len([t for t in tasks_storage.values() if t['status'] == 'processing'])
    }

@app.post("/api/v1/enhance", response_model=TaskResponse)
async def enhance_portrait(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    tile_size: int = Query(400, ge=256, le=512, description="Tile size for processing (256-512)"),
    quality_level: str = Query("high", regex="^(fast|medium|high)$", description="Quality level")
):
    """
    Enhance portrait image using AI
    
    - **file**: Image file to enhance (JPG, PNG, etc.)
    - **tile_size**: Processing tile size (256-512, default: 400)
    - **quality_level**: Processing quality (fast/medium/high, default: high)
    
    Returns task ID for status tracking
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
            'message': 'Task queued for processing',
            'progress': 0.0,
            'created_at': current_time,
            'updated_at': current_time,
            'input_path': str(input_path),
            'output_path': str(output_path),
            'temp_dir': str(temp_dir),
            'original_filename': file.filename
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
            message="Task queued for processing",
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

if __name__ == "__main__":
    # Development server
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
