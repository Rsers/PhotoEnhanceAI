#!/bin/bash

# PhotoEnhanceAI - 容器环境开机自启动设置脚本
# 适用于 Docker 容器或非 systemd 环境

echo "=========================================="
echo "🐳 PhotoEnhanceAI 容器环境自启动设置"
echo "=========================================="

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 权限运行此脚本"
    echo "使用方法: sudo ./setup_container_autostart.sh"
    exit 1
fi

PROJECT_DIR="/root/PhotoEnhanceAI"

# 检查项目目录
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

# 检查虚拟环境
if [ ! -f "$PROJECT_DIR/gfpgan_env/bin/python" ]; then
    echo "❌ 虚拟环境不存在: $PROJECT_DIR/gfpgan_env/bin/python"
    echo "请先运行环境安装脚本"
    exit 1
fi

echo "🔍 检测系统环境..."

# 检测是否为容器环境
if [ -f /.dockerenv ] || [ "$(cat /proc/1/comm 2>/dev/null)" = "dumb-init" ]; then
    echo "🐳 检测到容器环境"
    IS_CONTAINER=true
else
    echo "🖥️  检测到物理机环境"
    IS_CONTAINER=false
fi

# 检测是否支持 systemd
if systemctl --version >/dev/null 2>&1; then
    echo "✅ 支持 systemd"
    HAS_SYSTEMD=true
else
    echo "❌ 不支持 systemd"
    HAS_SYSTEMD=false
fi

echo ""
echo "📋 配置开机自启动..."

if [ "$HAS_SYSTEMD" = true ]; then
    echo "🔧 使用 systemd 服务方式..."
    
    # 安装 systemd 服务
    if [ -f "$PROJECT_DIR/install_systemd_service.sh" ]; then
        "$PROJECT_DIR/install_systemd_service.sh"
    else
        echo "❌ systemd 安装脚本不存在"
        exit 1
    fi
    
elif [ "$IS_CONTAINER" = true ]; then
    echo "🐳 使用容器环境启动方式..."
    
    # 创建 rc.local
    cat > /etc/rc.local << 'EOF'
#!/bin/bash
# PhotoEnhanceAI 容器环境开机自启动脚本

# 等待网络就绪
sleep 10

# 启动 PhotoEnhanceAI 服务
/root/PhotoEnhanceAI/container_autostart.sh

exit 0
EOF
    
    chmod +x /etc/rc.local
    echo "✅ rc.local 配置完成"
    
    # 创建启动脚本别名
    cat > /usr/local/bin/photoenhanceai << EOF
#!/bin/bash
# PhotoEnhanceAI 快速启动脚本

cd /root/PhotoEnhanceAI
exec ./container_autostart.sh
EOF
    
    chmod +x /usr/local/bin/photoenhanceai
    echo "✅ 创建快速启动脚本: /usr/local/bin/photoenhanceai"
    
else
    echo "🖥️  使用传统启动方式..."
    
    # 创建 rc.local
    cat > /etc/rc.local << 'EOF'
#!/bin/bash
# PhotoEnhanceAI 开机自启动脚本

# 等待网络就绪
sleep 15

# 启动 PhotoEnhanceAI 服务
/root/PhotoEnhanceAI/container_autostart.sh

exit 0
EOF
    
    chmod +x /etc/rc.local
    echo "✅ rc.local 配置完成"
fi

echo ""
echo "=========================================="
echo "✅ 开机自启动设置完成！"
echo ""
echo "环境信息:"
echo "  系统类型: $(if [ "$IS_CONTAINER" = true ]; then echo "容器环境"; else echo "物理机"; fi)"
echo "  systemd: $(if [ "$HAS_SYSTEMD" = true ]; then echo "支持"; else echo "不支持"; fi)"
echo "  启动方式: $(if [ "$HAS_SYSTEMD" = true ]; then echo "systemd服务"; else echo "rc.local"; fi)"
echo ""
echo "管理命令:"
if [ "$HAS_SYSTEMD" = true ]; then
    echo "  启动服务:   sudo systemctl start photoenhanceai"
    echo "  停止服务:   sudo systemctl stop photoenhanceai"
    echo "  查看状态:   sudo systemctl status photoenhanceai"
    echo "  查看日志:   sudo journalctl -u photoenhanceai -f"
else
    echo "  手动启动:   /root/PhotoEnhanceAI/container_autostart.sh"
    echo "  快速启动:   photoenhanceai"
    echo "  查看日志:   tail -f /root/PhotoEnhanceAI/logs/photoenhanceai.log"
fi
echo ""
echo "测试开机自启动:"
echo "  重启系统后，服务将自动启动"
echo "  查看日志确认启动状态"
echo "=========================================="

# 询问是否立即启动服务
echo ""
read -p "是否立即启动服务进行测试？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 启动服务进行测试..."
    if [ "$HAS_SYSTEMD" = true ]; then
        systemctl start photoenhanceai.service
        sleep 3
        systemctl status photoenhanceai.service --no-pager
    else
        "$PROJECT_DIR/container_autostart.sh" &
        sleep 3
        echo "✅ 服务已在后台启动"
        echo "📝 查看日志: tail -f $PROJECT_DIR/logs/photoenhanceai.log"
    fi
fi
