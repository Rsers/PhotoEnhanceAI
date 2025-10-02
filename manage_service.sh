#!/bin/bash

# PhotoEnhanceAI - 服务管理脚本
# 提供便捷的服务控制命令

SERVICE_NAME="photoenhanceai"
PROJECT_DIR="/root/PhotoEnhanceAI"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${BLUE}PhotoEnhanceAI 服务管理脚本${NC}"
    echo ""
    echo "使用方法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看服务状态"
    echo "  logs      查看服务日志"
    echo "  enable    启用开机自启动"
    echo "  disable   禁用开机自启动"
    echo "  install   安装 systemd 服务"
    echo "  uninstall 卸载 systemd 服务"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 logs"
}

# 检查服务是否存在
check_service() {
    if ! systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        echo -e "${RED}❌ 服务未安装，请先运行: $0 install${NC}"
        exit 1
    fi
}

# 启动服务
start_service() {
    check_service
    echo -e "${BLUE}🚀 启动 PhotoEnhanceAI 服务...${NC}"
    sudo systemctl start $SERVICE_NAME
    sleep 2
    sudo systemctl status $SERVICE_NAME --no-pager
}

# 停止服务
stop_service() {
    check_service
    echo -e "${YELLOW}🛑 停止 PhotoEnhanceAI 服务...${NC}"
    sudo systemctl stop $SERVICE_NAME
    sleep 2
    sudo systemctl status $SERVICE_NAME --no-pager
}

# 重启服务
restart_service() {
    check_service
    echo -e "${BLUE}🔄 重启 PhotoEnhanceAI 服务...${NC}"
    sudo systemctl restart $SERVICE_NAME
    sleep 2
    sudo systemctl status $SERVICE_NAME --no-pager
}

# 查看服务状态
show_status() {
    check_service
    echo -e "${BLUE}📊 PhotoEnhanceAI 服务状态:${NC}"
    sudo systemctl status $SERVICE_NAME --no-pager
    echo ""
    echo -e "${BLUE}📈 进程信息:${NC}"
    ps aux | grep -E "(python.*start_server|photoenhanceai)" | grep -v grep
}

# 查看服务日志
show_logs() {
    check_service
    echo -e "${BLUE}📝 PhotoEnhanceAI 服务日志:${NC}"
    echo "按 Ctrl+C 退出日志查看"
    echo ""
    sudo journalctl -u $SERVICE_NAME -f
}

# 启用开机自启动
enable_service() {
    check_service
    echo -e "${GREEN}✅ 启用开机自启动...${NC}"
    sudo systemctl enable $SERVICE_NAME
    echo "服务已设置为开机自启动"
}

# 禁用开机自启动
disable_service() {
    check_service
    echo -e "${YELLOW}⚠️  禁用开机自启动...${NC}"
    sudo systemctl disable $SERVICE_NAME
    echo "服务已取消开机自启动"
}

# 安装服务
install_service() {
    echo -e "${BLUE}🔧 安装 PhotoEnhanceAI systemd 服务...${NC}"
    if [ -f "$PROJECT_DIR/install_systemd_service.sh" ]; then
        sudo "$PROJECT_DIR/install_systemd_service.sh"
    else
        echo -e "${RED}❌ 安装脚本不存在: $PROJECT_DIR/install_systemd_service.sh${NC}"
        exit 1
    fi
}

# 卸载服务
uninstall_service() {
    check_service
    echo -e "${RED}🗑️  卸载 PhotoEnhanceAI systemd 服务...${NC}"
    
    # 停止服务
    sudo systemctl stop $SERVICE_NAME 2>/dev/null
    sudo systemctl disable $SERVICE_NAME 2>/dev/null
    
    # 删除服务文件
    sudo rm -f /etc/systemd/system/$SERVICE_NAME.service
    
    # 重新加载 systemd
    sudo systemctl daemon-reload
    
    echo -e "${GREEN}✅ 服务已卸载${NC}"
}

# 主逻辑
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    enable)
        enable_service
        ;;
    disable)
        disable_service
        ;;
    install)
        install_service
        ;;
    uninstall)
        uninstall_service
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ 未知命令: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
