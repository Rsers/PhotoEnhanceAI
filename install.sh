#!/bin/bash
# PhotoEnhanceAI - One-Click Installation Script
# 一键安装脚本，适用于新服务器从零部署

set -e  # Exit on any error

echo "🚀 PhotoEnhanceAI - One-Click Installation"
echo "=========================================="
echo ""

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
PROJECT_DIR="$SCRIPT_DIR"

print_status "Project directory: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Some operations may require non-root user."
fi

# Step 1: System requirements check
print_step "1. Checking system requirements..."

# Check if we're on a supported system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    print_status "Operating System: $OS"
else
    print_warning "Cannot determine operating system."
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_status "Python version: $PYTHON_VERSION"
else
    print_error "Python3 is not installed. Please install Python 3.8 or higher first."
    exit 1
fi

# Check GPU
if command -v nvidia-smi &> /dev/null; then
    print_status "NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | head -1
    GPU_AVAILABLE=true
else
    print_warning "NVIDIA GPU not detected. Will use CPU (slower but functional)."
    GPU_AVAILABLE=false
fi

# Step 2: Install system dependencies
print_step "2. Installing system dependencies..."

if command -v apt-get &> /dev/null; then
    print_status "Installing packages for Ubuntu/Debian..."
    apt-get update -qq
    apt-get install -y -qq \
        python3-venv \
        python3-dev \
        python3-pip \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        git \
        wget \
        curl \
        build-essential \
        cmake
elif command -v yum &> /dev/null; then
    print_status "Installing packages for CentOS/RHEL..."
    yum install -y python3-devel python3-pip mesa-libGL gcc git wget curl cmake
elif command -v dnf &> /dev/null; then
    print_status "Installing packages for Fedora..."
    dnf install -y python3-devel python3-pip mesa-libGL gcc git wget curl cmake
else
    print_warning "Package manager not recognized. Please install dependencies manually:"
    echo "  - python3-venv python3-dev python3-pip"
    echo "  - libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1"
    echo "  - git wget curl build-essential cmake"
fi

# Step 3: Setup GFPGAN environment
print_step "3. Setting up GFPGAN environment..."

if [ -f "deploy/setup_gfpgan_env.sh" ]; then
    print_status "Running GFPGAN environment setup..."
    chmod +x deploy/setup_gfpgan_env.sh
    ./deploy/setup_gfpgan_env.sh
else
    print_error "GFPGAN environment setup script not found!"
    exit 1
fi

# Step 4: Download model
print_step "4. Downloading GFPGAN model..."

if [ -f "deploy/download_gfpgan_model.sh" ]; then
    print_status "Downloading GFPGAN model..."
    chmod +x deploy/download_gfpgan_model.sh
    ./deploy/download_gfpgan_model.sh
else
    print_error "Model download script not found!"
    exit 1
fi

# Step 5: Test installation
print_step "5. Testing installation..."

if [ -f "test_installation.sh" ]; then
    print_status "Running installation test..."
    chmod +x test_installation.sh
    ./test_installation.sh
else
    print_warning "Installation test script not found. Skipping test."
fi

# Step 6: Create sample input
print_step "6. Preparing sample files..."

# Create a sample input directory with instructions
mkdir -p input
if [ ! -f "input/README.md" ]; then
    cat > input/README.md << EOF
# Input Directory

Place your images here for processing.

## Supported formats:
- JPG, JPEG
- PNG
- BMP
- TIFF

## Example usage:
\`\`\`bash
# Copy your image to input directory
cp /path/to/your/image.jpg input/my_image.jpg

# Process the image
python PhotoEnhanceAI/gfpgan_cli.py --input PhotoEnhanceAI/input/my_image.jpg --output PhotoEnhanceAI/output/enhanced.jpg --scale 4

# Or use quick start (if you rename your image to test001.jpg)
./quick_start.sh
\`\`\`
EOF
    print_status "Created input directory with instructions."
fi

# Step 7: Final summary
echo ""
echo "🎉 PhotoEnhanceAI Installation Completed!"
echo "========================================"
echo ""
print_status "Installation Summary:"
echo "✅ System dependencies installed"
echo "✅ GFPGAN environment created"
echo "✅ Model files downloaded"
echo "✅ Project structure ready"
echo ""

print_status "Quick Start:"
echo "1. Place your image in input/ directory:"
echo "   cp /path/to/your/image.jpg input/my_image.jpg"
echo ""
echo "2. Process the image:"
echo "   python PhotoEnhanceAI/gfpgan_cli.py --input PhotoEnhanceAI/input/my_image.jpg --output PhotoEnhanceAI/output/enhanced.jpg --scale 4"
echo ""
echo "3. Or use the quick start script:"
echo "   cp /path/to/your/image.jpg input/test001.jpg"
echo "   ./quick_start.sh"
echo ""

print_status "Available commands:"
echo "• python PhotoEnhanceAI/gfpgan_cli.py --help          # Show command line options"
echo "• python PhotoEnhanceAI/gfpgan_cli.py --input PhotoEnhanceAI/input/test001.jpg --output PhotoEnhanceAI/output/test001_enhanced.jpg --scale 4  # Test with sample image"
echo "• source /root/gfpgan_env/bin/activate       # Activate environment manually"
echo ""

print_status "Project structure:"
echo "• input/     - Place your images here"
echo "• output/    - Enhanced images will appear here"
echo "• gfpgan/    - GFPGAN core modules"
echo "• models/    - AI model files"
echo "• scripts/   - Processing scripts"
echo "• api/       - Web API (if needed)"
echo ""

if [ "$GPU_AVAILABLE" = true ]; then
    print_status "🚀 GPU acceleration is available!"
else
    print_warning "⚠️  Running on CPU. Consider using a GPU for faster processing."
fi

echo ""
print_status "For more information, see README.md or docs/ directory."
echo ""
echo "Happy enhancing! 🎨✨"
