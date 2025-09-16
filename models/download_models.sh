#!/bin/bash
# PhotoEnhanceAI Model Download Script
# Downloads required model files for SwinIR and GFPGAN

set -e  # Exit on any error

echo "📦 PhotoEnhanceAI Model Download Started"
echo "======================================="

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

# Create model directories
mkdir -p models/swinir
mkdir -p models/gfpgan

# Step 1: Download SwinIR model
print_step "1. Downloading SwinIR model..."

SWINIR_MODEL_URL="https://github.com/JingyunLiang/SwinIR/releases/download/v0.0/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth"
SWINIR_MODEL_PATH="models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth"

if [ -f "$SWINIR_MODEL_PATH" ] && verify_file "$SWINIR_MODEL_PATH" 50 "SwinIR model"; then
    print_status "SwinIR model already exists and is valid."
else
    print_status "Downloading SwinIR model (001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth)..."
    download_file "$SWINIR_MODEL_URL" "$SWINIR_MODEL_PATH" "SwinIR 4x Classical SR Model"
    
    if verify_file "$SWINIR_MODEL_PATH" 50 "SwinIR model"; then
        print_status "✅ SwinIR model downloaded successfully!"
    else
        print_error "❌ SwinIR model download failed or file is corrupted."
        exit 1
    fi
fi

# Step 2: Download GFPGAN model
print_step "2. Downloading GFPGAN model..."

GFPGAN_MODEL_URL="https://github.com/TencentARC/GFPGAN/releases/download/v1.3.0/GFPGANv1.4.pth"
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

# Step 3: Create model info file
print_step "3. Creating model information file..."

cat > models/MODEL_INFO.md << EOF
# PhotoEnhanceAI Model Information

## Downloaded Models

### SwinIR Model
- **File**: \`001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth\`
- **Size**: ~57MB
- **Purpose**: 4x Classical Image Super-Resolution
- **Architecture**: SwinIR-M (Medium)
- **Training Dataset**: DIV2K
- **Window Size**: 8
- **Patch Size**: 48

### GFPGAN Model
- **File**: \`GFPGANv1.4.pth\`
- **Size**: ~333MB
- **Purpose**: Generative Facial Prior-Guided Face Restoration
- **Version**: 1.4
- **Architecture**: GFPGAN with facial component dictionaries

## Model Usage

### SwinIR
- Input: Low-resolution images
- Output: 4x super-resolved images
- Best for: General image enhancement, backgrounds, textures

### GFPGAN
- Input: Images with faces (any resolution)
- Output: Face-restored images
- Best for: Portrait photos, selfies, face enhancement

## File Verification

Run the following commands to verify model integrity:

\`\`\`bash
# Check SwinIR model
ls -lh models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth

# Check GFPGAN model  
ls -lh models/gfpgan/GFPGANv1.4.pth
\`\`\`

Expected sizes:
- SwinIR: ~57MB
- GFPGAN: ~333MB

## Troubleshooting

If models fail to download:
1. Check internet connection
2. Try running the download script again
3. Manually download from the URLs in download_models.sh
4. Verify file sizes match expected values

EOF

print_status "Model information file created."

# Step 4: Final verification
print_step "4. Final verification..."

echo ""
print_status "📊 Model Download Summary:"
echo "----------------------------------------"

if [ -f "$SWINIR_MODEL_PATH" ]; then
    SWINIR_SIZE=$(du -h "$SWINIR_MODEL_PATH" | cut -f1)
    echo "✅ SwinIR Model: $SWINIR_SIZE"
else
    echo "❌ SwinIR Model: Missing"
fi

if [ -f "$GFPGAN_MODEL_PATH" ]; then
    GFPGAN_SIZE=$(du -h "$GFPGAN_MODEL_PATH" | cut -f1)
    echo "✅ GFPGAN Model: $GFPGAN_SIZE"
else
    echo "❌ GFPGAN Model: Missing"
fi

echo "----------------------------------------"

# Calculate total size
if [ -f "$SWINIR_MODEL_PATH" ] && [ -f "$GFPGAN_MODEL_PATH" ]; then
    TOTAL_SIZE=$(du -h models/ | tail -1 | cut -f1)
    print_status "Total model size: $TOTAL_SIZE"
    echo ""
    echo "🎉 All models downloaded successfully!"
    echo ""
    print_status "You can now run PhotoEnhanceAI:"
    echo "python gfpgan_core.py --input your_image.jpg --output enhanced_image.jpg"
    echo ""
else
    echo ""
    print_error "❌ Some models are missing. Please check the download process."
    exit 1
fi
