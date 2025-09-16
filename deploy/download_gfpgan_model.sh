#!/bin/bash
# PhotoEnhanceAI - GFPGAN Model Download Script
# 下载 GFPGAN 模型文件

set -e  # Exit on any error

echo "📦 PhotoEnhanceAI - GFPGAN Model Download"
echo "========================================="

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

# Function to download file with progress
download_file() {
    local url=$1
    local output_path=$2
    local description=$3
    
    print_status "Downloading $description..."
    
    if command -v wget &> /dev/null; then
        wget --progress=bar:force:noscroll -O "$output_path" "$url"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$output_path" "$url"
    else
        print_error "Neither wget nor curl is available. Please install one of them."
        exit 1
    fi
}

# Function to verify file size
verify_file() {
    local file_path=$1
    local min_size_mb=$2
    local description=$3
    
    if [ -f "$file_path" ]; then
        local file_size=$(du -m "$file_path" | cut -f1)
        if [ "$file_size" -ge "$min_size_mb" ]; then
            print_status "$description verified (${file_size}MB)"
            return 0
        else
            print_warning "$description seems incomplete (${file_size}MB < ${min_size_mb}MB expected)"
            return 1
        fi
    else
        print_error "$description not found at $file_path"
        return 1
    fi
}

# Create model directory
mkdir -p models/gfpgan

# Download GFPGAN model
print_step "1. Downloading GFPGAN model..."

GFPGAN_MODEL_URL="https://github.com/TencentARC/GFPGAN/releases/download/v1.3.8/GFPGANv1.4.pth"
GFPGAN_MODEL_PATH="models/gfpgan/GFPGANv1.4.pth"

if [ -f "$GFPGAN_MODEL_PATH" ] && verify_file "$GFPGAN_MODEL_PATH" 300 "GFPGAN model"; then
    print_status "GFPGAN model already exists and is valid."
else
    print_status "Downloading GFPGAN model (GFPGANv1.4.pth)..."
    download_file "$GFPGAN_MODEL_URL" "$GFPGAN_MODEL_PATH" "GFPGAN v1.4 Model"
    
    if verify_file "$GFPGAN_MODEL_PATH" 300 "GFPGAN model"; then
        print_status "✅ GFPGAN model downloaded successfully!"
    else
        print_error "❌ GFPGAN model download failed or file is corrupted."
        exit 1
    fi
fi

# Create model info file
print_step "2. Creating model information file..."

cat > models/MODEL_INFO.md << EOF
# PhotoEnhanceAI Model Information

## Downloaded Models

### GFPGAN Model
- **File**: \`GFPGANv1.4.pth\`
- **Size**: ~333MB
- **Purpose**: Generative Facial Prior-Guided Face Restoration
- **Version**: 1.4
- **Architecture**: GFPGAN with facial component dictionaries
- **Features**: 
  - AI人脸修复和美化
  - RealESRGAN背景超分辨率
  - 1-16倍分辨率放大
  - 一体化处理

## Model Usage

### GFPGAN
- Input: Images with faces (any resolution)
- Output: Face-restored images with super-resolution
- Best for: Portrait photos, selfies, face enhancement
- Processing: One-step face restoration + background upscaling

## File Verification

Run the following commands to verify model integrity:

\`\`\`bash
# Check GFPGAN model  
ls -lh models/gfpgan/GFPGANv1.4.pth
\`\`\`

Expected size:
- GFPGAN: ~333MB

## Troubleshooting

If model fails to download:
1. Check internet connection
2. Try running the download script again
3. Manually download from: https://github.com/TencentARC/GFPGAN/releases/download/v1.3.8/GFPGANv1.4.pth
4. Verify file size matches expected value (~333MB)

EOF

print_status "Model information file created."

# Final verification
print_step "3. Final verification..."

echo ""
print_status "📊 Model Download Summary:"
echo "----------------------------------------"

if [ -f "$GFPGAN_MODEL_PATH" ]; then
    GFPGAN_SIZE=$(du -h "$GFPGAN_MODEL_PATH" | cut -f1)
    echo "✅ GFPGAN Model: $GFPGAN_SIZE"
else
    echo "❌ GFPGAN Model: Missing"
fi

echo "----------------------------------------"

# Calculate total size
if [ -f "$GFPGAN_MODEL_PATH" ]; then
    TOTAL_SIZE=$(du -h models/ | tail -1 | cut -f1)
    print_status "Total model size: $TOTAL_SIZE"
    echo ""
    echo "🎉 GFPGAN model downloaded successfully!"
    echo ""
    print_status "You can now run PhotoEnhanceAI:"
    echo "python gfpgan_core.py --input input/your_image.jpg --output output/enhanced.jpg --scale 4"
    echo ""
    print_status "Or use the quick start script:"
    echo "./quick_start.sh"
    echo ""
else
    echo ""
    print_error "❌ GFPGAN model is missing. Please check the download process."
    exit 1
fi
