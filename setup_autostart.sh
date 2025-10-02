#!/bin/bash

# PhotoEnhanceAI - 开机自启动设置脚本
# 自动检测系统类型并选择最适合的自启动方案

echo "=========================================="
echo "🔧 PhotoEnhanceAI 开机自启动设置"
echo "=========================================="

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 权限运行此脚本"
    echo "使用方法: sudo ./setup_autostart.sh"
    exit 1
fi

# 检测系统类型
detect_system() {
    if systemctl --version >/dev/null 2>&1; then
        echo "systemd"
    elif [ -f /etc/init.d/rc.local ] || [ -f /etc/rc.local ]; then
        echo "rc.local"
    elif command -v crontab >/dev/null 2>&1; then
        echo "cron"
    else
        echo "container"
    fi
}

SYSTEM_TYPE=$(detect_system)
echo "🔍 检测到系统类型: $SYSTEM_TYPE"

case "$SYSTEM_TYPE" in
    "systemd")
        echo "📋 使用 systemd 服务方式..."
        if [ -f "/root/PhotoEnhanceAI/install_systemd_service.sh" ]; then
            /root/PhotoEnhanceAI/install_systemd_service.sh
        else
            echo "❌ systemd 安装脚本不存在"
            exit 1
        fi
        ;;
    "rc.local")
        echo "📋 使用 rc.local 方式..."
        
        # 确保 rc.local 存在
        if [ ! -f /etc/rc.local ]; then
            cat > /etc/rc.local << 'EOF'
#!/bin/bash
# rc.local - 开机自启动脚本

# 等待网络就绪
sleep 10

# 启动 PhotoEnhanceAI 服务
/root/PhotoEnhanceAI/container_autostart.sh

exit 0
EOF
        else
            # 检查是否已经添加了启动命令
            if ! grep -q "PhotoEnhanceAI" /etc/rc.local; then
                # 在 exit 0 之前添加启动命令
                sed -i '/^exit 0/i # 启动 PhotoEnhanceAI 服务\n/root/PhotoEnhanceAI/container_autostart.sh' /etc/rc.local
            fi
        fi
        
        chmod +x /etc/rc.local
        echo "✅ rc.local 配置完成"
        ;;
    "cron")
        echo "📋 使用 cron @reboot 方式..."
        
        # 添加 @reboot 任务
        (crontab -l 2>/dev/null; echo "@reboot sleep 30 && /root/PhotoEnhanceAI/container_autostart.sh") | crontab -
        echo "✅ cron @reboot 配置完成"
        ;;
    "container")
        echo "📋 容器环境，创建启动脚本..."
        echo "✅ 容器环境配置完成"
        echo "💡 在容器启动时运行: /root/PhotoEnhanceAI/container_autostart.sh"
        ;;
esac

echo ""
echo "=========================================="
echo "✅ 开机自启动设置完成！"
echo ""
echo "系统类型: $SYSTEM_TYPE"
echo "启动脚本: /root/PhotoEnhanceAI/container_autostart.sh"
echo ""
echo "管理命令:"
echo "  启动服务:   /root/PhotoEnhanceAI/manage_service.sh start"
echo "  停止服务:   /root/PhotoEnhanceAI/manage_service.sh stop"
echo "  查看状态:   /root/PhotoEnhanceAI/manage_service.sh status"
echo "  查看日志:   /root/PhotoEnhanceAI/manage_service.sh logs"
echo "=========================================="
