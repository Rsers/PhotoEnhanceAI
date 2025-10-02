#!/bin/bash

# PhotoEnhanceAI 容器自动启动设置脚本
# 配置容器环境下的自动启动机制

echo "=========================================="
echo "🐳 PhotoEnhanceAI 容器自动启动设置"
echo "=========================================="

# 1. 设置 .bashrc 自动启动
echo "📝 配置 .bashrc 自动启动..."
if ! grep -q "PhotoEnhanceAI 自动启动检查" /root/.bashrc; then
    cat >> /root/.bashrc << 'EOF'

# PhotoEnhanceAI 自动启动检查
if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
    PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI 服务已在运行 (PID: $PID)"
    else
        echo "🚀 PhotoEnhanceAI 服务未运行，正在自动启动..."
        cd /root/PhotoEnhanceAI
        nohup ./container_autostart.sh > /dev/null 2>&1 &
        echo "✅ PhotoEnhanceAI 自动启动已执行"
    fi
else
    echo "🚀 PhotoEnhanceAI 服务未启动，正在自动启动..."
    cd /root/PhotoEnhanceAI
    nohup ./container_autostart.sh > /dev/null 2>&1 &
    echo "✅ PhotoEnhanceAI 自动启动已执行"
fi
EOF
    echo "✅ .bashrc 自动启动配置完成"
else
    echo "✅ .bashrc 自动启动已配置"
fi

# 2. 设置 /etc/profile.d 自动启动
echo "📝 配置 /etc/profile.d 自动启动..."
cat > /etc/profile.d/photoenhanceai_autostart.sh << 'EOF'
#!/bin/bash

# PhotoEnhanceAI 自动启动脚本
# 每次shell启动时检查服务状态并自动启动

# 只在交互式shell中执行
if [[ $- == *i* ]]; then
    # 检查PhotoEnhanceAI服务状态
    if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
        PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
        if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ PhotoEnhanceAI 服务已在运行 (PID: $PID)"
        else
            echo "🚀 PhotoEnhanceAI 服务未运行，正在自动启动..."
            cd /root/PhotoEnhanceAI
            nohup ./container_autostart.sh > /dev/null 2>&1 &
            echo "✅ PhotoEnhanceAI 自动启动已执行"
        fi
    else
        echo "🚀 PhotoEnhanceAI 服务未启动，正在自动启动..."
        cd /root/PhotoEnhanceAI
        nohup ./container_autostart.sh > /dev/null 2>&1 &
        echo "✅ PhotoEnhanceAI 自动启动已执行"
    fi
fi
EOF

chmod +x /etc/profile.d/photoenhanceai_autostart.sh
echo "✅ /etc/profile.d 自动启动配置完成"

# 3. 设置 rc.local 启动（备用方案）
echo "📝 配置 rc.local 启动..."
cat > /etc/rc.local << 'EOF'
#!/bin/bash
# PhotoEnhanceAI 容器环境开机自启动脚本
echo "🚀 PhotoEnhanceAI 容器自启动开始..."

# 等待网络就绪
sleep 10

# 进入项目目录
cd /root/PhotoEnhanceAI

# 启动服务
echo "📱 启动 PhotoEnhanceAI 服务..."
./container_autostart.sh

exit 0
EOF

chmod +x /etc/rc.local
echo "✅ rc.local 启动配置完成"

# 4. 创建容器初始化脚本
echo "📝 创建容器初始化脚本..."
cat > /root/PhotoEnhanceAI/container_init.sh << 'EOF'
#!/bin/bash

# PhotoEnhanceAI 容器初始化脚本
# 确保在容器启动时自动运行PhotoEnhanceAI服务

echo "=========================================="
echo "🐳 PhotoEnhanceAI 容器初始化启动"
echo "=========================================="

# 等待系统完全启动
echo "⏳ 等待系统启动完成..."
sleep 5

# 进入项目目录
cd /root/PhotoEnhanceAI

# 检查服务是否已经在运行
if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid 2>/dev/null)
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI 服务已在运行 (PID: $PID)"
        exit 0
    fi
fi

echo "🚀 启动 PhotoEnhanceAI 服务..."

# 启动服务
nohup ./container_autostart.sh > /dev/null 2>&1 &

# 等待启动
sleep 3

# 检查启动状态
if [ -f "photoenhanceai.pid" ]; then
    PID=$(cat photoenhanceai.pid 2>/dev/null)
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI 服务启动成功 (PID: $PID)"
    else
        echo "❌ PhotoEnhanceAI 服务启动失败"
        exit 1
    fi
else
    echo "❌ PhotoEnhanceAI 服务启动失败，未找到PID文件"
    exit 1
fi

echo "🎉 PhotoEnhanceAI 容器初始化完成"
EOF

chmod +x /root/PhotoEnhanceAI/container_init.sh
echo "✅ 容器初始化脚本创建完成"

# 5. 测试当前服务状态
echo "🔍 检查当前服务状态..."
if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
    PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ PhotoEnhanceAI 服务正在运行 (PID: $PID)"
    else
        echo "⚠️  PID文件存在但进程未运行，启动服务..."
        cd /root/PhotoEnhanceAI
        nohup ./container_autostart.sh > /dev/null 2>&1 &
        sleep 5
        if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
            PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
            echo "✅ PhotoEnhanceAI 服务启动成功 (PID: $PID)"
        fi
    fi
else
    echo "🚀 PhotoEnhanceAI 服务未启动，正在启动..."
    cd /root/PhotoEnhanceAI
    nohup ./container_autostart.sh > /dev/null 2>&1 &
    sleep 5
    if [ -f "/root/PhotoEnhanceAI/photoenhanceai.pid" ]; then
        PID=$(cat /root/PhotoEnhanceAI/photoenhanceai.pid 2>/dev/null)
        echo "✅ PhotoEnhanceAI 服务启动成功 (PID: $PID)"
    fi
fi

echo ""
echo "🎉 PhotoEnhanceAI 容器自动启动配置完成！"
echo ""
echo "📋 配置的自动启动方式："
echo "   1. ✅ .bashrc 自动启动 (每次shell启动时检查)"
echo "   2. ✅ /etc/profile.d 自动启动 (系统级启动检查)"
echo "   3. ✅ rc.local 自动启动 (容器启动时执行)"
echo "   4. ✅ 容器初始化脚本 (专用容器启动脚本)"
echo ""
echo "🔧 使用方法："
echo "   - 容器重启后会自动启动PhotoEnhanceAI服务"
echo "   - 每次打开新shell时会检查服务状态"
echo "   - 如果服务未运行会自动启动"
echo ""
echo "📊 当前服务状态："
./status_service.sh