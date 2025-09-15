#!/bin/bash
# PhotoEnhanceAI - Deployment Verification Script
# 验证部署是否成功

echo "🔍 PhotoEnhanceAI - Deployment Verification"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Initialize counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to check and report
check_item() {
    local description="$1"
    local check_command="$2"
    local expected_result="$3"
    
    if eval "$check_command" >/dev/null 2>&1; then
        print_status "$description"
        ((PASS_COUNT++))
        return 0
    else
        if [ "$expected_result" = "optional" ]; then
            print_warning "$description (optional)"
            ((WARN_COUNT++))
        else
            print_error "$description"
            ((FAIL_COUNT++))
        fi
        return 1
    fi
}

# Step 1: Check system requirements
print_step "1. Checking system requirements..."

check_item "Python 3.8+ installed" "python3 --version"
check_item "pip available" "command -v pip3"
check_item "git available" "command -v git"
check_item "wget or curl available" "command -v wget || command -v curl"

# Check GPU (optional)
if command -v nvidia-smi &> /dev/null; then
    check_item "NVIDIA GPU detected" "nvidia-smi --query-gpu=name --format=csv,noheader" "optional"
    check_item "CUDA available" "command -v nvcc" "optional"
else
    print_warning "NVIDIA GPU not detected (CPU mode will be used)"
    ((WARN_COUNT++))
fi

# Step 2: Check project structure
print_step "2. Checking project structure..."

check_item "Project root directory exists" "[ -d '.' ]"
check_item "GFPGAN directory exists" "[ -d 'gfpgan' ]"
check_item "Models directory exists" "[ -d 'models' ]"
check_item "Input directory exists" "[ -d 'input' ]"
check_item "Output directory exists" "[ -d 'output' ]"
check_item "Scripts directory exists" "[ -d 'scripts' ]"
check_item "Deploy directory exists" "[ -d 'deploy' ]"

# Step 3: Check virtual environment
print_step "3. Checking virtual environment..."

check_item "GFPGAN environment exists" "[ -d '/root/PhotoEnhanceAI/gfpgan_env' ]"

# Step 4: Check Python packages
print_step "4. Checking Python packages..."

if [ -d "/root/PhotoEnhanceAI/gfpgan_env" ]; then
    source /root/PhotoEnhanceAI/gfpgan_env/bin/activate
    
    check_item "PyTorch installed" "python -c 'import torch'"
    check_item "GFPGAN installed" "python -c 'import gfpgan'"
    check_item "OpenCV installed" "python -c 'import cv2'"
    check_item "PIL installed" "python -c 'import PIL'"
    check_item "NumPy installed" "python -c 'import numpy'"
    
    deactivate
else
    print_error "GFPGAN environment not found"
    ((FAIL_COUNT++))
fi

# Step 5: Check model files
print_step "5. Checking model files..."

check_item "GFPGAN model exists" "[ -f 'models/gfpgan/GFPGANv1.4.pth' ]"

# Step 6: Check scripts
print_step "6. Checking scripts..."

check_item "GFPGAN CLI script exists" "[ -f 'gfpgan_cli.py' ]"
check_item "Test script exists" "[ -f 'test_gfpgan.py' ]"
check_item "Install script exists" "[ -f 'install.sh' ]"

# Step 7: Test functionality
print_step "7. Testing functionality..."

# Check if we can import the main modules
if [ -d "/root/PhotoEnhanceAI/gfpgan_env" ]; then
    source /root/PhotoEnhanceAI/gfpgan_env/bin/activate
    
    check_item "GFPGAN CLI help works" "python gfpgan_cli.py --help"
    
    deactivate
else
    print_error "Cannot test functionality - environment not found"
    ((FAIL_COUNT++))
fi

# Step 8: Check sample files
print_step "8. Checking sample files..."

check_item "Sample input exists" "[ -f 'input/test001.jpg' ]" "optional"

# Final summary
echo ""
echo "📊 Verification Summary"
echo "======================"
echo "✅ Passed: $PASS_COUNT"
echo "⚠️  Warnings: $WARN_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "🎉 Deployment verification PASSED!"
    echo ""
    print_status "PhotoEnhanceAI is ready to use!"
    echo ""
    print_status "Quick start:"
    echo "1. Place your image in input/ directory"
    echo "2. Run: python gfpgan_cli.py --input input/your_image.jpg --output output/enhanced.jpg --scale 4"
    echo "3. Or use: ./quick_start.sh"
    echo ""
    exit 0
else
    echo "❌ Deployment verification FAILED!"
    echo ""
    print_error "Please fix the failed items before using PhotoEnhanceAI."
    echo ""
    print_status "Common fixes:"
    echo "• Run: ./install.sh (for complete installation)"
    echo "• Run: ./deploy/setup_gfpgan_env.sh (for environment setup)"
    echo "• Run: ./deploy/download_gfpgan_model.sh (for model download)"
    echo ""
    exit 1
fi