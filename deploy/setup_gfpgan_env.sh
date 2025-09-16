#!/bin/bash
# PhotoEnhanceAI - GFPGAN Environment Setup Script
# 为独立项目设置 GFPGAN 环境

set -e  # Exit on any error

echo "🎨 PhotoEnhanceAI - GFPGAN Environment Setup"
echo "============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_status "Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Step 1: Check system requirements
print_step "1. Checking system requirements..."

# Check Python version
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_status "Python version: $PYTHON_VERSION"
    
    # Check if Python version is 3.8+
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
        print_error "Python 3.8 or higher is required. Current version: $PYTHON_VERSION"
        exit 1
    fi
else
    print_error "Python3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check if NVIDIA GPU is available
if command -v nvidia-smi &> /dev/null; then
    print_status "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | head -1
    GPU_AVAILABLE=true
else
    print_warning "NVIDIA GPU not detected. The system will use CPU (very slow)."
    GPU_AVAILABLE=false
fi

# Check CUDA version
if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
    print_status "CUDA version: $CUDA_VERSION"
else
    print_warning "CUDA not found. Please install CUDA 11.6 or higher for GPU acceleration."
fi

# Step 2: Install system dependencies
print_step "2. Installing system dependencies..."

if command -v apt-get &> /dev/null; then
    print_status "Installing system packages (Ubuntu/Debian)..."
    apt-get update -qq
    apt-get install -y -qq \
        python3-venv \
        python3-dev \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        git \
        wget \
        curl \
        build-essential
elif command -v yum &> /dev/null; then
    print_status "Installing system packages (CentOS/RHEL)..."
    yum install -y python3-devel mesa-libGL gcc git wget curl
else
    print_warning "Package manager not recognized. Please install system dependencies manually."
fi

# Step 3: Create GFPGAN virtual environment
print_step "3. Creating GFPGAN virtual environment..."

# Remove existing environment if it exists
if [ -d "gfpgan_env" ]; then
    print_warning "GFPGAN environment already exists. Removing..."
    rm -rf gfpgan_env
fi

print_status "Creating virtual environment..."
python3 -m venv gfpgan_env
source gfpgan_env/bin/activate

# Upgrade pip
print_status "Upgrading pip..."
pip install --upgrade pip

# Install GFPGAN requirements
print_status "Installing GFPGAN dependencies..."

# Install PyTorch with CUDA support if GPU is available
if [ "$GPU_AVAILABLE" = true ]; then
    print_status "Installing PyTorch with CUDA support..."
    pip install torch==1.12.1+cu116 torchvision==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
else
    print_status "Installing PyTorch CPU version..."
    pip install torch==1.12.1+cpu torchvision==0.13.1+cpu --extra-index-url https://download.pytorch.org/whl/cpu
fi

# Install GFPGAN and related packages
print_status "Installing GFPGAN packages..."
pip install basicsr facexlib gfpgan realesrgan
pip install opencv-python Pillow numpy scikit-image tqdm pyyaml lmdb yapf addict
pip install scipy numba tb-nightly future filterpy matplotlib

deactivate

print_status "✅ GFPGAN environment setup completed."

# Step 4: Create project directories
print_step "4. Creating project directories..."

mkdir -p input
mkdir -p output
mkdir -p models/gfpgan
mkdir -p logs

print_status "Project directories created."

# Step 5: Create convenience scripts
print_step "5. Creating convenience scripts..."

# Create activation script
cat > activate_gfpgan.sh << 'EOF'
#!/bin/bash
echo "🎭 Activating GFPGAN environment..."
source gfpgan_env/bin/activate
echo "✅ GFPGAN environment activated. Use 'deactivate' to exit."
EOF

chmod +x activate_gfpgan.sh

# Create test script
cat > test_installation.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing PhotoEnhanceAI installation..."

echo "Testing GFPGAN environment..."
source gfpgan_env/bin/activate
python -c "import torch; print(f'GFPGAN - PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
python -c "import gfpgan; print('GFPGAN module loaded successfully')"
deactivate

echo "✅ Installation test completed!"
EOF

chmod +x test_installation.sh

# Create quick start script
cat > quick_start.sh << 'EOF'
#!/bin/bash
echo "🚀 PhotoEnhanceAI Quick Start"
echo "============================="

# Check if input file exists
if [ ! -f "input/test001.jpg" ]; then
    echo "❌ No input file found. Please place your image in input/ directory."
    echo "   Example: cp your_image.jpg input/test001.jpg"
    exit 1
fi

# Run GFPGAN processing
echo "🎨 Processing image with GFPGAN..."
source gfpgan_env/bin/activate
python gfpgan_core.py --input input/test001.jpg --output output/test001_enhanced.jpg --scale 4
deactivate

echo "✅ Processing completed! Check output/ directory for results."
EOF

chmod +x quick_start.sh

print_status "Convenience scripts created."

# Step 6: Create configuration file
print_step "6. Creating configuration file..."

cat > config/settings.py << EOF
# PhotoEnhanceAI Configuration

import os

# Project paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GFPGAN_ENV_PATH = os.path.join(PROJECT_ROOT, 'gfpgan_env')

# Model paths
GFPGAN_MODEL_PATH = os.path.join(PROJECT_ROOT, 'models/gfpgan/GFPGANv1.4.pth')

# Processing settings
DEFAULT_TILE_SIZE = 400
MAX_FILE_SIZE_MB = 50
SUPPORTED_FORMATS = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']

# Output settings
OUTPUT_QUALITY = 95
TEMP_DIR = '/tmp/photoenhanceai'

# GPU settings
USE_GPU = True
EOF

print_status "Configuration file created."

# Final summary
echo ""
echo "🎉 PhotoEnhanceAI Environment Setup Completed!"
echo "=============================================="
echo ""
print_status "Next steps:"
echo "1. Download model file: ./models/download_models.sh"
echo "2. Test installation: ./test_installation.sh"
echo "3. Place your image in input/ directory"
echo "4. Run processing: ./quick_start.sh"
echo ""
print_status "Manual processing:"
echo "source gfpgan_env/bin/activate"
echo "python gfpgan_core.py --input input/your_image.jpg --output output/enhanced.jpg --scale 4"
echo ""
print_warning "Note: Make sure to download the GFPGAN model before processing images!"
echo ""
