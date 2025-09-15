#!/bin/bash
# PhotoEnhanceAI - 快速图像增强脚本
# 交互式GFPGAN图像增强工具

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$SCRIPT_DIR"

print_status "PhotoEnhanceAI - 快速图像增强工具"
echo "=================================="
echo ""

# Check if virtual environment exists
GFPGAN_ENV="/root/PhotoEnhanceAI/gfpgan_env"
if [ ! -d "$GFPGAN_ENV" ]; then
    print_error "GFPGAN虚拟环境不存在: $GFPGAN_ENV"
    print_error "请先运行 ./install.sh 安装环境"
    exit 1
fi

print_status "✅ 检测到GFPGAN虚拟环境: $GFPGAN_ENV"

# Default input file
DEFAULT_INPUT="PhotoEnhanceAI/input/test001.jpg"

# Prompt for input file
print_step "请输入要处理的图像文件路径:"
echo -e "${YELLOW}默认值: ${DEFAULT_INPUT}${NC}"
echo -e "${YELLOW}按回车使用默认值，或输入完整路径:${NC}"
read -r INPUT_FILE

# Use default if empty
if [ -z "$INPUT_FILE" ]; then
    INPUT_FILE="$DEFAULT_INPUT"
fi

# Convert to absolute path if it's a relative path
if [[ ! "$INPUT_FILE" = /* ]]; then
    # It's a relative path, make it absolute
    if [[ "$INPUT_FILE" == PhotoEnhanceAI/* ]]; then
        # Already has PhotoEnhanceAI prefix, just make it absolute
        INPUT_FILE="/root/$INPUT_FILE"
    else
        # Add PhotoEnhanceAI prefix
        INPUT_FILE="/root/PhotoEnhanceAI/$INPUT_FILE"
    fi
fi

print_status "输入文件: $INPUT_FILE"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    print_error "输入文件不存在: $INPUT_FILE"
    echo ""
    echo "请检查文件路径是否正确。"
    echo "支持的格式: JPG, JPEG, PNG, BMP, TIFF"
    exit 1
fi

# Extract filename without extension
FILENAME=$(basename "$INPUT_FILE")
NAME_NO_EXT="${FILENAME%.*}"

# Generate output filename
OUTPUT_DIR="/root/PhotoEnhanceAI/output"
OUTPUT_FILE="$OUTPUT_DIR/${NAME_NO_EXT}_enhanced.jpg"

print_status "输出文件: $OUTPUT_FILE"
echo ""

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Execute GFPGAN processing
print_step "开始GFPGAN图像增强处理..."
echo ""

# Progress bar function
show_progress() {
    local pid=$1
    local delay=1.0
    local counter=0
    local progress=0
    local bar_length=30
    local start_time=$(date +%s)
    local file_count=1
    
    echo ""
    print_status "🔄 正在处理图像，请稍候..."
    echo ""
    
    while kill -0 $pid 2>/dev/null; do
        counter=$((counter + 1))
        
        # Calculate progress (simulate based on time)
        progress=$((counter * 6))
        if [ $progress -gt 95 ]; then
            progress=95  # Keep at 95% until actually complete
        fi
        
        # Create progress bar
        local filled=$((progress * bar_length / 100))
        local empty=$((bar_length - filled))
        local bar=""
        
        # Build progress bar
        for i in $(seq 1 $filled); do
            bar="${bar}█"
        done
        for i in $(seq 1 $empty); do
            bar="${bar}░"
        done
        
        # Get current stage
        local stage=""
        case $((counter % 4)) in
            0) stage="⏳ 正在分析图像..." ;;
            1) stage="🔍 正在增强人脸..." ;;
            2) stage="🎨 正在优化背景..." ;;
            3) stage="✨ 正在生成结果..." ;;
        esac
        
        # Calculate elapsed time
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        
        # Format time display
        local time_display=""
        if [ $minutes -gt 0 ]; then
            time_display="${minutes}分${seconds}秒"
        else
            time_display="${seconds}秒"
        fi
        
        # Clear previous lines and show progress
        printf "\033[2K\r"  # Clear current line
        printf "   %s\n" "$stage"
        printf "\033[2K\r"  # Clear current line
        printf "   [%s] %d%%\n" "$bar" "$progress"
        printf "\033[2K\r"  # Clear current line
        printf "   ⏱️  运行时间: %s | 📁 处理文件: %d个\n" "$time_display" "$file_count"
        printf "\033[3A"    # Move cursor up 3 lines
        
        sleep $delay
    done
    
    # Final display
    local final_time=$(date +%s)
    local total_elapsed=$((final_time - start_time))
    local total_minutes=$((total_elapsed / 60))
    local total_seconds=$((total_elapsed % 60))
    
    local total_time_display=""
    if [ $total_minutes -gt 0 ]; then
        total_time_display="${total_minutes}分${total_seconds}秒"
    else
        total_time_display="${total_seconds}秒"
    fi
    
    printf "\033[3K\r"  # Clear 3 lines
    printf "   ✅ 处理完成! 图像增强成功!\n"
    printf "   [██████████████████████████████] 100%%\n"
    printf "   ⏱️  总用时: %s | 📁 处理文件: %d个\n" "$total_time_display" "$file_count"
    echo ""
}

# Create temporary log file
TEMP_LOG="/tmp/gfpgan_process.log"

# Run the GFPGAN CLI in background with output redirected
# Activate virtual environment before running
source "$GFPGAN_ENV/bin/activate" && \
python /root/PhotoEnhanceAI/gfpgan_cli.py \
    --input "$INPUT_FILE" \
    --output "$OUTPUT_FILE" \
    --scale 4 > "$TEMP_LOG" 2>&1 &

# Get the PID of the background process
GFPGAN_PID=$!

# Show progress bar while processing
show_progress $GFPGAN_PID

# Wait for the process to complete
wait $GFPGAN_PID

# Clean up log file
rm -f "$TEMP_LOG"

# Check if processing was successful
if [ $? -eq 0 ]; then
    echo ""
    print_success "🎉 图像增强完成！"
    echo ""
    
    # Show file size information first
    if [ -f "$OUTPUT_FILE" ]; then
        INPUT_SIZE=$(du -h "$INPUT_FILE" | cut -f1)
        OUTPUT_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
        print_success "📊 文件大小对比:"
        echo -e "   输入文件: ${INPUT_SIZE}"
        echo -e "   输出文件: ${OUTPUT_SIZE}"
        echo ""
    fi
    
    # Show final file location
    print_success "📁 最终文件位置:"
    echo -e "${CYAN}$OUTPUT_FILE${NC}"
    
else
    echo ""
    print_error "❌ 图像处理失败"
    echo "请检查错误信息并重试。"
    exit 1
fi
