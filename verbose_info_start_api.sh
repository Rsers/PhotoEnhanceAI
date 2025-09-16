#!/bin/bash

# PhotoEnhanceAI API 快速启动脚本
# 一键启动API服务

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否在正确的目录
check_directory() {
    if [ ! -d "api" ] || [ ! -d "gfpgan_env" ]; then
        print_error "请在PhotoEnhanceAI项目根目录下运行此脚本"
        print_info "当前目录: $(pwd)"
        print_info "请切换到: cd /root/PhotoEnhanceAI"
        exit 1
    fi
    print_success "目录检查通过"
}

# 检查虚拟环境
check_venv() {
    if [ ! -f "gfpgan_env/bin/activate" ]; then
        print_error "虚拟环境不存在: gfpgan_env"
        print_info "请先运行环境设置脚本"
        exit 1
    fi
    print_success "虚拟环境检查通过"
}

# 检查API依赖
check_dependencies() {
    print_info "检查API依赖..."
    
    # 激活虚拟环境
    source gfpgan_env/bin/activate
    
    # 检查关键依赖
    python -c "import fastapi, uvicorn, aiofiles" 2>/dev/null
    if [ $? -ne 0 ]; then
        print_warning "API依赖未安装，正在安装..."
        pip install -r requirements/api_requirements.txt
        print_success "API依赖安装完成"
    else
        print_success "API依赖检查通过"
    fi
}

# 检查模型文件
check_models() {
    print_info "检查模型文件..."
    
    if [ ! -f "models/gfpgan/GFPGANv1.4.pth" ]; then
        print_warning "GFPGAN模型文件不存在"
        print_info "正在下载模型文件..."
        if [ -f "models/download_models.sh" ]; then
            chmod +x models/download_models.sh
            ./models/download_models.sh
            print_success "模型文件下载完成"
        else
            print_error "模型下载脚本不存在"
            exit 1
        fi
    else
        print_success "模型文件检查通过"
    fi
}

# 检查端口占用
check_port() {
    local port=${1:-8000}
    print_info "检查端口 $port 是否被占用..."
    
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "端口 $port 已被占用"
        print_info "尝试使用端口 8001..."
        check_port 8001
        export API_PORT=8001
    else
        print_success "端口 $port 可用"
        export API_PORT=$port
    fi
}

# 显示启动信息
show_startup_info() {
    local port=${API_PORT:-8000}
    
    echo ""
    echo "=========================================="
    echo "🚀 PhotoEnhanceAI API 服务启动中..."
    echo "=========================================="
    echo ""
    print_info "服务地址: http://localhost:$port"
    print_info "API文档: http://localhost:$port/docs"
    print_info "健康检查: http://localhost:$port/health"
    echo ""
    print_info "按 Ctrl+C 停止服务"
    echo ""
}

# 启动API服务
start_api() {
    local port=${API_PORT:-8000}
    
    # 激活虚拟环境
    source gfpgan_env/bin/activate
    
    # 设置环境变量
    export API_HOST=0.0.0.0
    export API_PORT=$port
    export LOG_LEVEL=INFO
    
    # 启动服务
    print_info "启动API服务..."
    python api/start_server.py
}

# 主函数
main() {
    echo "=========================================="
    echo "🎯 PhotoEnhanceAI API 快速启动脚本"
    echo "=========================================="
    echo ""
    
    # 执行检查步骤
    check_directory
    check_venv
    check_dependencies
    check_models
    check_port
    
    # 显示启动信息
    show_startup_info
    
    # 启动API服务
    start_api
}

# 捕获中断信号
trap 'echo ""; print_info "正在停止API服务..."; exit 0' INT

# 运行主函数
main "$@"
