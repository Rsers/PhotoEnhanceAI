#!/bin/bash
# PhotoEnhanceAI Environment Setup Script
# Automatically sets up the required environments for SwinIR and GFPGAN

set -e  # Exit on any error

echo "🚀 PhotoEnhanceAI Environment Setup Started"
echo "=========================================="

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

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Some operations may require non-root user."
fi

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_status "Project directory: $PROJECT_DIR"

# Step 1: Check system requirements
print_step "1. Checking system requirements..."

# Check Python version
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_status "Python version: $PYTHON_VERSION"
else
    print_error "Python3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

# Check if NVIDIA GPU is available
if command -v nvidia-smi &> /dev/null; then
    print_status "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | head -1
else
    print_warning "NVIDIA GPU not detected. The system will use CPU (very slow)."
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
        curl
elif command -v yum &> /dev/null; then
    print_status "Installing system packages (CentOS/RHEL)..."
    yum install -y python3-devel mesa-libGL gcc git wget curl
else
    print_warning "Package manager not recognized. Please install system dependencies manually."
fi

# Step 3: Create virtual environments
print_step "3. Creating virtual environments..."

cd "$PROJECT_DIR"

# Create SwinIR environment
print_status "Creating SwinIR environment..."
if [ -d "swinir_env" ]; then
    print_warning "SwinIR environment already exists. Removing..."
    rm -rf swinir_env
fi

python3 -m venv swinir_env
source swinir_env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install SwinIR requirements
print_status "Installing SwinIR dependencies..."
if [ -f "requirements/swinir_requirements.txt" ]; then
    # Install PyTorch with CUDA support
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    
    # Install other requirements
    pip install opencv-python Pillow numpy scikit-image tqdm pyyaml scipy matplotlib
    
    print_status "SwinIR environment setup completed."
else
    print_error "SwinIR requirements file not found!"
    exit 1
fi

deactivate

# Create GFPGAN environment
print_status "Creating GFPGAN environment..."
if [ -d "gfpgan_env" ]; then
    print_warning "GFPGAN environment already exists. Removing..."
    rm -rf gfpgan_env
fi

python3 -m venv gfpgan_env
source gfpgan_env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install GFPGAN requirements
print_status "Installing GFPGAN dependencies..."
if [ -f "requirements/gfpgan_requirements.txt" ]; then
    # Install compatible PyTorch version
    pip install torch==1.12.1+cu116 torchvision==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
    
    # Install other requirements
    pip install basicsr facexlib gfpgan realesrgan
    pip install opencv-python Pillow numpy scikit-image tqdm pyyaml lmdb yapf addict
    pip install scipy numba tb-nightly future filterpy matplotlib
    
    print_status "GFPGAN environment setup completed."
else
    print_error "GFPGAN requirements file not found!"
    exit 1
fi

deactivate

# Step 4: Create necessary directories
print_step "4. Creating project directories..."

mkdir -p models/swinir
mkdir -p models/gfpgan
mkdir -p examples
mkdir -p results
mkdir -p logs

print_status "Project directories created."

# Step 5: Set up configuration
print_step "5. Setting up configuration..."

# Create a simple config file
cat > config/settings.py << EOF
# PhotoEnhanceAI Configuration

import os

# Project paths
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWINIR_ENV_PATH = os.path.join(PROJECT_ROOT, 'swinir_env')
GFPGAN_ENV_PATH = os.path.join(PROJECT_ROOT, 'gfpgan_env')

# Model paths
SWINIR_MODEL_PATH = os.path.join(PROJECT_ROOT, 'models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth')
GFPGAN_MODEL_PATH = os.path.join(PROJECT_ROOT, 'models/gfpgan/GFPGANv1.4.pth')

# Processing settings
DEFAULT_TILE_SIZE = 400
MAX_FILE_SIZE_MB = 50
SUPPORTED_FORMATS = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']

# Output settings
OUTPUT_QUALITY = 95
TEMP_DIR = '/tmp/photoenhanceai'
EOF

print_status "Configuration file created."

# Step 6: Create activation script
print_step "6. Creating convenience scripts..."

# Create activation script for SwinIR
cat > activate_swinir.sh << 'EOF'
#!/bin/bash
echo "🎨 Activating SwinIR environment..."
source swinir_env/bin/activate
echo "✅ SwinIR environment activated. Use 'deactivate' to exit."
EOF

# Create activation script for GFPGAN
cat > activate_gfpgan.sh << 'EOF'
#!/bin/bash
echo "🎭 Activating GFPGAN environment..."
source gfpgan_env/bin/activate
echo "✅ GFPGAN environment activated. Use 'deactivate' to exit."
EOF

chmod +x activate_swinir.sh activate_gfpgan.sh

# Create quick test script
cat > test_installation.sh << 'EOF'
#!/bin/bash
echo "🧪 Testing PhotoEnhanceAI installation..."

echo "Testing SwinIR environment..."
source swinir_env/bin/activate
python -c "import torch; print(f'SwinIR - PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
deactivate

echo "Testing GFPGAN environment..."
source gfpgan_env/bin/activate
python -c "import torch; print(f'GFPGAN - PyTorch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
deactivate

echo "✅ Installation test completed!"
EOF

chmod +x test_installation.sh

print_status "Convenience scripts created."

# Final summary
echo ""
echo "🎉 PhotoEnhanceAI Environment Setup Completed!"
echo "=============================================="
echo ""
print_status "Next steps:"
echo "1. Download model files: ./models/download_models.sh"
echo "2. Test installation: ./test_installation.sh"
echo "3. Process your first image:"
echo "   python scripts/reverse_portrait_pipeline.py --input your_image.jpg --output enhanced_image.jpg"
echo ""
print_status "Environment activation:"
echo "- SwinIR: source swinir_env/bin/activate"
echo "- GFPGAN: source gfpgan_env/bin/activate"
echo ""
print_warning "Note: Make sure to download the model files before processing images!"
echo ""
