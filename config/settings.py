"""
PhotoEnhanceAI Configuration Settings
"""

import os
from pathlib import Path
from typing import List

class APISettings:
    """API configuration settings"""
    
    # Project paths
    PROJECT_ROOT = Path(__file__).parent.parent
    GFPGAN_ENV_PATH = PROJECT_ROOT / 'gfpgan_env'
    
    # Model paths
    GFPGAN_MODEL_PATH = PROJECT_ROOT / 'models/gfpgan/GFPGANv1.4.pth'
    
    # File handling settings
    MAX_FILE_SIZE_MB = 50
    MAX_FILE_SIZE_BYTES = MAX_FILE_SIZE_MB * 1024 * 1024
    SUPPORTED_FORMATS = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']
    
    # Processing settings
    DEFAULT_TILE_SIZE = 400
    MIN_TILE_SIZE = 256
    MAX_TILE_SIZE = 512
    
    # Output settings
    OUTPUT_QUALITY = 95
    TEMP_DIR = '/tmp/photoenhanceai'
    
    # API settings
    API_HOST = os.getenv('API_HOST', '0.0.0.0')
    API_PORT = int(os.getenv('API_PORT', 8000))
    API_WORKERS = int(os.getenv('API_WORKERS', 1))
    
    # Security settings
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*').split(',')
    MAX_CONCURRENT_TASKS = int(os.getenv('MAX_CONCURRENT_TASKS', 10))
    
    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    
    # Task cleanup settings
    TASK_CLEANUP_HOURS = int(os.getenv('TASK_CLEANUP_HOURS', 24))
    
    def __init__(self):
        # Ensure temp directory exists
        os.makedirs(self.TEMP_DIR, exist_ok=True)
    
    def validate_models(self) -> bool:
        """Check if required model files exist"""
        return self.GFPGAN_MODEL_PATH.exists()
    
    def get_model_info(self) -> dict:
        """Get model file information"""
        info = {}
        
        if self.GFPGAN_MODEL_PATH.exists():
            size = self.GFPGAN_MODEL_PATH.stat().st_size / (1024 * 1024)  # MB
            info['gfpgan'] = {
                'path': str(self.GFPGAN_MODEL_PATH),
                'size_mb': round(size, 1),
                'exists': True
            }
        else:
            info['gfpgan'] = {'exists': False}
            
        return info

# Global settings instance
settings = APISettings()
