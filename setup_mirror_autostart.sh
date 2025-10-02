#!/bin/bash

# PhotoEnhanceAI 镜像环境自动启动配置脚本
# 专门解决镜像文件在新服务器上开机时的自动启动问题

echo "🚀 PhotoEnhanceAI 镜像环境自动启动配置开始..."
echo "📅 配置时间: $(date)"
echo "🖥️  主机名: $(hostname)"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 进入项目目录
cd /root/PhotoEnhanceAI

# 1. 创建镜像环境专用启动脚本
echo "📝 创建镜像环境专用启动脚本..."
if [ ! -f "mirror_autostart.sh" ]; then
    echo "❌ mirror_autostart.sh 不存在，请先创建"
    exit 1
fi
chmod +x mirror_autostart.sh
echo "✅ mirror_autostart.sh 已设置执行权限"

# 2. 更新 /etc/profile.d 自动启动脚本
echo "📝 更新 /etc/profile.d 自动启动脚本..."
cat > /etc/profile.d/photoenhanceai_autostart.sh << 'EOF'
#!/bin/bash

# PhotoEnhanceAI 镜像环境自动启动脚本
# 专门解决镜像文件在新服务器上开机时的自动启动问题

# 只在交互式shell中执行
if [[ $- == *i* ]]; then
    echo "🔍 PhotoEnhanceAI 镜像环境自动启动检查..."
    
    # 检查系统运行时间，如果是新启动的系统（运行时间少于10分钟），使用镜像启动脚本
    UPTIME_MINUTES=$(awk '{print int($1/60)}' /proc/uptime)
    
    if [ "$UPTIME_MINUTES" -lt 10 ]; then
        echo "🆕 检测到新启动的系统（运行时间: ${UPTIME_MINUTES}分钟），使用镜像环境启动脚本"
        cd /root/PhotoEnhanceAI
        nohup ./mirror_autostart.sh > logs/profile_autostart.log 2>&1 &
        echo "✅ PhotoEnhanceAI 镜像环境自动启动已执行"
    else
        echo "🔄 系统运行时间较长（${UPTIME_MINUTES}分钟），使用标准启动检查"
        # 检查PhotoEnhanceAI服务状态
        if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
            PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
            if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
                echo "✅ PhotoEnhanceAI 服务已在运行 (PID: $PID)"
            else
                echo "🚀 PhotoEnhanceAI 服务未运行，正在自动启动..."
                cd /root/PhotoEnhanceAI
                nohup ./container_autostart.sh > logs/profile_autostart.log 2>&1 &
                echo "✅ PhotoEnhanceAI 自动启动已执行"
            fi
        else
            echo "🚀 PhotoEnhanceAI 服务未启动，正在自动启动..."
            cd /root/PhotoEnhanceAI
            nohup ./container_autostart.sh > logs/profile_autostart.log 2>&1 &
            echo "✅ PhotoEnhanceAI 自动启动已执行"
        fi
    fi
fi
EOF

chmod +x /etc/profile.d/photoenhanceai_autostart.sh
echo "✅ /etc/profile.d/photoenhanceai_autostart.sh 已更新"

# 3. 更新 .bashrc 自动启动配置
echo "📝 更新 .bashrc 自动启动配置..."
# 备份原始.bashrc
cp /root/.bashrc /root/.bashrc.backup.$(date +%Y%m%d_%H%M%S)

# 移除旧的PhotoEnhanceAI配置
sed -i '/# PhotoEnhanceAI 自动启动检查/,/^fi$/d' /root/.bashrc

# 添加新的镜像环境配置
cat >> /root/.bashrc << 'EOF'

# PhotoEnhanceAI 镜像环境自动启动检查
echo "🔍 PhotoEnhanceAI 镜像环境自动启动检查..."

# 检查系统运行时间，如果是新启动的系统（运行时间少于10分钟），使用镜像启动脚本
UPTIME_MINUTES=$(awk '{print int($1/60)}' /proc/uptime)

if [ "$UPTIME_MINUTES" -lt 10 ]; then
    echo "🆕 检测到新启动的系统（运行时间: ${UPTIME_MINUTES}分钟），使用镜像环境启动脚本"
    cd /root/PhotoEnhanceAI
    nohup ./mirror_autostart.sh > logs/bashrc_autostart.log 2>&1 &
    echo "✅ PhotoEnhanceAI 镜像环境自动启动已执行"
else
    echo "🔄 系统运行时间较长（${UPTIME_MINUTES}分钟），使用标准启动检查"
    # 检查PhotoEnhanceAI服务状态
    if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
        # 检查PID文件中的进程是否还在运行
        PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ PhotoEnhanceAI 服务已在运行 (PID: $PID)"
        else
            echo "🚀 PhotoEnhanceAI 服务未运行，正在自动启动..."
            cd /root/PhotoEnhanceAI
            nohup ./container_autostart.sh > logs/bashrc_autostart.log 2>&1 &
            echo "✅ PhotoEnhanceAI 自动启动已执行"
        fi
    else
        echo "🚀 PhotoEnhanceAI 服务未启动，正在自动启动..."
        cd /root/PhotoEnhanceAI
        nohup ./container_autostart.sh > logs/bashrc_autostart.log 2>&1 &
        echo "✅ PhotoEnhanceAI 自动启动已执行"
    fi
fi
EOF

echo "✅ .bashrc 已更新"

# 4. 更新 rc.local 开机启动脚本
echo "📝 更新 rc.local 开机启动脚本..."
cat > /etc/rc.local << 'EOF'
#!/bin/bash
# PhotoEnhanceAI 镜像环境开机自启动脚本
echo "🚀 PhotoEnhanceAI 镜像环境开机自启动开始..."
echo "📅 启动时间: $(date)"
echo "🖥️  主机名: $(hostname)"

# 等待网络就绪（镜像环境需要更长时间）
echo "🌐 等待网络就绪..."
sleep 20

# 进入项目目录
cd /root/PhotoEnhanceAI

# 清理可能存在的旧PID文件（镜像环境常见问题）
echo "🧹 清理旧的PID文件..."
rm -f *.pid

# 启动服务（使用镜像环境专用脚本）
echo "📱 启动 PhotoEnhanceAI 镜像环境服务..."
nohup ./mirror_autostart.sh > logs/rc_local_autostart.log 2>&1 &

echo "✅ PhotoEnhanceAI 镜像环境开机自启动完成"

exit 0
EOF

chmod +x /etc/rc.local
echo "✅ /etc/rc.local 已更新"

# 5. 创建日志目录
echo "📁 创建日志目录..."
mkdir -p logs
echo "✅ 日志目录已创建"

# 6. 清理旧的PID文件
echo "🧹 清理旧的PID文件..."
rm -f *.pid
echo "✅ 旧PID文件已清理"

# 7. 测试镜像启动脚本
echo "🧪 测试镜像启动脚本..."
if [ -x "mirror_autostart.sh" ]; then
    echo "✅ mirror_autostart.sh 可执行"
else
    echo "❌ mirror_autostart.sh 不可执行"
fi

echo ""
echo "🎉 PhotoEnhanceAI 镜像环境自动启动配置完成!"
echo ""
echo "📋 配置摘要:"
echo "   ✅ 镜像环境专用启动脚本: mirror_autostart.sh"
echo "   ✅ 系统级自动启动: /etc/profile.d/photoenhanceai_autostart.sh"
echo "   ✅ 用户级自动启动: /root/.bashrc"
echo "   ✅ 开机自启动: /etc/rc.local"
echo "   ✅ 日志目录: logs/"
echo ""
echo "🔧 配置特点:"
echo "   🆕 智能检测新启动系统（运行时间<10分钟）"
echo "   🧹 自动清理旧PID文件"
echo "   🌐 延长网络等待时间（20秒）"
echo "   📝 详细日志记录"
echo "   🔄 多重启动保障机制"
echo ""
echo "📊 下次开机时将自动:"
echo "   1. 检测系统运行时间"
echo "   2. 清理旧PID文件"
echo "   3. 等待网络就绪"
echo "   4. 检查GPU和CUDA环境"
echo "   5. 启动PhotoEnhanceAI服务"
echo "   6. 执行模型预热"
echo "   7. 注册Webhook"
echo ""
echo "🔍 查看日志:"
echo "   tail -f logs/mirror_autostart.log"
echo "   tail -f logs/profile_autostart.log"
echo "   tail -f logs/bashrc_autostart.log"
echo "   tail -f logs/rc_local_autostart.log"
echo ""
echo "✅ 配置完成，下次使用镜像文件开机时将自动启动PhotoEnhanceAI服务!"
