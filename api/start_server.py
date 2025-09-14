#!/usr/bin/env python3
"""
PhotoEnhanceAI API Server Startup Script
"""

import os
import sys
import uvicorn
from pathlib import Path

# Add project root to Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

from config.settings import APISettings

def main():
    """Start the API server"""
    settings = APISettings()
    
    print("🚀 Starting PhotoEnhanceAI API Server...")
    print(f"📁 Project Root: {PROJECT_ROOT}")
    print(f"🌐 Server: http://{settings.API_HOST}:{settings.API_PORT}")
    print(f"📖 API Docs: http://{settings.API_HOST}:{settings.API_PORT}/docs")
    print(f"🔧 Log Level: {settings.LOG_LEVEL}")
    
    # Check model files
    if not settings.validate_models():
        print("\n⚠️  Warning: Model files not found!")
        print("Please run: ./models/download_models.sh")
        model_info = settings.get_model_info()
        for model, info in model_info.items():
            status = "✅ Found" if info['exists'] else "❌ Missing"
            print(f"  {model.upper()}: {status}")
        print()
    
    # Start server
    uvicorn.run(
        "api.main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        workers=settings.API_WORKERS,
        log_level=settings.LOG_LEVEL.lower(),
        reload=False  # Set to True for development
    )

if __name__ == "__main__":
    main()
