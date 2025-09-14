#!/bin/bash
# PhotoEnhanceAI 生产环境部署脚本

set -e  # 遇到错误立即退出

echo "🚀 开始 PhotoEnhanceAI 生产环境部署..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查Python版本
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 未安装"
        exit 1
    fi
    
    python_version=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1-2)
    if [[ $(echo "$python_version >= 3.8" | bc -l) -ne 1 ]]; then
        log_error "Python版本需要3.8或更高，当前版本: $python_version"
        exit 1
    fi
    
    # 检查GPU
    if command -v nvidia-smi &> /dev/null; then
        log_info "检测到NVIDIA GPU"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits
    else
        log_warn "未检测到NVIDIA GPU，可能影响性能"
    fi
    
    # 检查磁盘空间
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 10 ]; then
        log_error "磁盘空间不足，需要至少10GB，当前可用: ${available_space}GB"
        exit 1
    fi
    
    log_info "系统要求检查通过 ✅"
}

# 创建系统用户和目录
setup_system() {
    log_info "设置系统环境..."
    
    # 创建应用用户
    if ! id "photoenhanceai" &>/dev/null; then
        sudo useradd -r -s /bin/false photoenhanceai
        log_info "创建系统用户: photoenhanceai"
    fi
    
    # 创建应用目录
    sudo mkdir -p /opt/photoenhanceai
    sudo mkdir -p /var/log/photoenhanceai
    sudo mkdir -p /var/run/photoenhanceai
    
    # 设置权限
    sudo chown -R photoenhanceai:photoenhanceai /opt/photoenhanceai
    sudo chown -R photoenhanceai:photoenhanceai /var/log/photoenhanceai
    sudo chown -R photoenhanceai:photoenhanceai /var/run/photoenhanceai
    
    log_info "系统环境设置完成 ✅"
}

# 安装系统依赖
install_system_deps() {
    log_info "安装系统依赖..."
    
    # 更新包管理器
    sudo apt-get update
    
    # 安装基础依赖
    sudo apt-get install -y \
        python3-venv \
        python3-pip \
        libgl1-mesa-glx \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender-dev \
        libgomp1 \
        wget \
        curl \
        nginx \
        supervisor
    
    log_info "系统依赖安装完成 ✅"
}

# 部署应用
deploy_app() {
    log_info "部署应用代码..."
    
    # 复制代码到生产目录
    sudo cp -r . /opt/photoenhanceai/
    sudo chown -R photoenhanceai:photoenhanceai /opt/photoenhanceai
    
    # 切换到应用目录
    cd /opt/photoenhanceai
    
    log_info "应用代码部署完成 ✅"
}

# 设置虚拟环境
setup_environments() {
    log_info "设置Python虚拟环境..."
    
    cd /opt/photoenhanceai
    
    # SwinIR环境
    sudo -u photoenhanceai python3 -m venv swinir_env
    sudo -u photoenhanceai swinir_env/bin/pip install --upgrade pip
    sudo -u photoenhanceai swinir_env/bin/pip install -r requirements/swinir_requirements.txt
    
    # GFPGAN环境
    sudo -u photoenhanceai python3 -m venv gfpgan_env
    sudo -u photoenhanceai gfpgan_env/bin/pip install --upgrade pip
    sudo -u photoenhanceai gfpgan_env/bin/pip install -r requirements/gfpgan_requirements.txt
    
    # API环境
    sudo -u photoenhanceai python3 -m venv api_env
    sudo -u photoenhanceai api_env/bin/pip install --upgrade pip
    sudo -u photoenhanceai api_env/bin/pip install -r requirements/api_requirements.txt
    sudo -u photoenhanceai api_env/bin/pip install gunicorn
    
    log_info "虚拟环境设置完成 ✅"
}

# 下载模型文件
download_models() {
    log_info "下载AI模型文件..."
    
    cd /opt/photoenhanceai
    
    # 创建模型目录
    sudo -u photoenhanceai mkdir -p models/swinir models/gfpgan
    
    # 下载SwinIR模型
    if [ ! -f "models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth" ]; then
        log_info "下载SwinIR模型 (约200MB)..."
        sudo -u photoenhanceai wget -O models/swinir/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth \
            https://github.com/JingyunLiang/SwinIR/releases/download/v0.0/001_classicalSR_DIV2K_s48w8_SwinIR-M_x4.pth
    fi
    
    # 下载GFPGAN模型
    if [ ! -f "models/gfpgan/GFPGANv1.4.pth" ]; then
        log_info "下载GFPGAN模型 (约350MB)..."
        sudo -u photoenhanceai wget -O models/gfpgan/GFPGANv1.4.pth \
            https://github.com/TencentARC/GFPGAN/releases/download/v1.3.8/GFPGANv1.4.pth
    fi
    
    log_info "模型文件下载完成 ✅"
}

# 配置Nginx
setup_nginx() {
    log_info "配置Nginx反向代理..."
    
    # 创建Nginx配置
    cat > /tmp/photoenhanceai.conf << 'EOF'
server {
    listen 80;
    server_name _;
    client_max_body_size 100M;
    
    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # 文档页面
    location /docs {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }
    
    # 静态文件服务
    location /static/ {
        alias /opt/photoenhanceai/static/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
    
    # 根路径
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF
    
    sudo mv /tmp/photoenhanceai.conf /etc/nginx/sites-available/
    sudo ln -sf /etc/nginx/sites-available/photoenhanceai.conf /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # 测试Nginx配置
    sudo nginx -t
    
    log_info "Nginx配置完成 ✅"
}

# 配置Supervisor
setup_supervisor() {
    log_info "配置Supervisor进程管理..."
    
    # 创建Supervisor配置
    cat > /tmp/photoenhanceai.conf << 'EOF'
[program:photoenhanceai]
command=/opt/photoenhanceai/api_env/bin/gunicorn -w 4 -k uvicorn.workers.UvicornWorker -b 127.0.0.1:8000 api.main:app
directory=/opt/photoenhanceai
user=photoenhanceai
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/photoenhanceai/app.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=5
environment=PYTHONPATH="/opt/photoenhanceai"
EOF
    
    sudo mv /tmp/photoenhanceai.conf /etc/supervisor/conf.d/
    
    log_info "Supervisor配置完成 ✅"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 重新加载Supervisor配置
    sudo supervisorctl reread
    sudo supervisorctl update
    
    # 启动应用
    sudo supervisorctl start photoenhanceai
    
    # 重启Nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    # 检查服务状态
    sleep 5
    
    if sudo supervisorctl status photoenhanceai | grep -q "RUNNING"; then
        log_info "应用服务启动成功 ✅"
    else
        log_error "应用服务启动失败 ❌"
        sudo supervisorctl status photoenhanceai
        exit 1
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        log_info "Nginx服务启动成功 ✅"
    else
        log_error "Nginx服务启动失败 ❌"
        exit 1
    fi
}

# 健康检查
health_check() {
    log_info "执行健康检查..."
    
    # 等待服务完全启动
    sleep 10
    
    # 检查API健康状态
    if curl -f -s http://localhost/health > /dev/null; then
        log_info "API健康检查通过 ✅"
    else
        log_error "API健康检查失败 ❌"
        exit 1
    fi
    
    # 显示服务信息
    echo
    log_info "🎉 PhotoEnhanceAI 部署成功！"
    echo
    echo "服务信息:"
    echo "  - API地址: http://$(hostname -I | awk '{print $1}')"
    echo "  - API文档: http://$(hostname -I | awk '{print $1}')/docs"
    echo "  - 健康检查: http://$(hostname -I | awk '{print $1}')/health"
    echo
    echo "管理命令:"
    echo "  - 查看状态: sudo supervisorctl status photoenhanceai"
    echo "  - 重启服务: sudo supervisorctl restart photoenhanceai"
    echo "  - 查看日志: sudo tail -f /var/log/photoenhanceai/app.log"
    echo "  - Nginx状态: sudo systemctl status nginx"
}

# 主函数
main() {
    check_requirements
    setup_system
    install_system_deps
    deploy_app
    setup_environments
    download_models
    setup_nginx
    setup_supervisor
    start_services
    health_check
}

# 运行主函数
main "$@"
