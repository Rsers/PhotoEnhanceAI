#!/bin/bash

# PhotoEnhanceAI - Systemd 服务安装脚本
# 用于设置开机自启动

echo "=========================================="
echo "🔧 安装 PhotoEnhanceAI Systemd 服务"
echo "=========================================="

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请以 root 权限运行此脚本"
    echo "使用方法: sudo ./install_systemd_service.sh"
    exit 1
fi

# 检查项目目录
if [ ! -d "/root/PhotoEnhanceAI" ]; then
    echo "❌ 项目目录不存在: /root/PhotoEnhanceAI"
    exit 1
fi

# 检查虚拟环境
if [ ! -f "/root/PhotoEnhanceAI/gfpgan_env/bin/python" ]; then
    echo "❌ 虚拟环境不存在: /root/PhotoEnhanceAI/gfpgan_env/bin/python"
    echo "请先运行环境安装脚本"
    exit 1
fi

# 创建日志目录
echo "📁 创建日志目录..."
mkdir -p /root/PhotoEnhanceAI/logs

# 复制服务文件
echo "📋 安装 systemd 服务文件..."
cp /root/PhotoEnhanceAI/etc/systemd/system/photoenhanceai.service /etc/systemd/system/

# 重新加载 systemd 配置
echo "🔄 重新加载 systemd 配置..."
systemctl daemon-reload

# 启用开机自启动
echo "✅ 启用开机自启动..."
systemctl enable photoenhanceai.service

# 显示服务状态
echo "📊 服务状态:"
systemctl status photoenhanceai.service --no-pager

echo ""
echo "=========================================="
echo "✅ 安装完成！"
echo ""
echo "常用命令："
echo "  启动服务:   sudo systemctl start photoenhanceai"
echo "  停止服务:   sudo systemctl stop photoenhanceai"
echo "  重启服务:   sudo systemctl restart photoenhanceai"
echo "  查看状态:   sudo systemctl status photoenhanceai"
echo "  查看日志:   sudo journalctl -u photoenhanceai -f"
echo "  禁用自启:   sudo systemctl disable photoenhanceai"
echo "  启用自启:   sudo systemctl enable photoenhanceai"
echo ""
echo "日志文件位置："
echo "  系统日志:   /root/PhotoEnhanceAI/logs/systemd.log"
echo "  错误日志:   /root/PhotoEnhanceAI/logs/systemd_error.log"
echo "  应用日志:   /root/PhotoEnhanceAI/logs/photoenhanceai.log"
echo "=========================================="

# 询问是否立即启动服务
echo ""
read -p "是否立即启动服务？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 启动服务..."
    systemctl start photoenhanceai.service
    sleep 2
    systemctl status photoenhanceai.service --no-pager
fi
