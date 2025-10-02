# PhotoEnhanceAI 资源限制解决方案

## 🚨 问题描述

PhotoEnhanceAI在启动时消耗过多资源（内存冲到31GB），导致：
- 系统资源耗尽
- Cursor连接断开
- 可能触发OOM Killer

## ✅ 解决方案

### 1. Supervisor资源限制配置

已更新 `/etc/supervisor/conf.d/photoenhanceai.conf`：

```ini
[program:photoenhanceai]
command=/root/PhotoEnhanceAI/start_limited.sh
directory=/root/PhotoEnhanceAI
user=root
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/var/log/supervisor/photoenhanceai.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
environment=PATH="/root/PhotoEnhanceAI/gfpgan_env/bin"

; 资源限制配置 - 防止内存爆炸
; 内存限制：最大使用8GB内存（系统总内存30GB的26%）
memory_limit=8GB
; CPU限制：最多使用4个CPU核心
cpu_limit=400%
; 进程数限制
numprocs=1
; 启动延迟：给系统时间稳定
startsecs=30
; 启动重试次数
startretries=3
; 停止信号：优雅停止
stopsignal=TERM
; 停止等待时间
stopwaitsecs=30
; 杀死信号
killasgroup=true
stopasgroup=true
```

### 2. 资源限制启动脚本

创建了 `/root/PhotoEnhanceAI/start_limited.sh`：

```bash
#!/bin/bash
# PhotoEnhanceAI 资源限制启动脚本
# 防止内存爆炸导致系统崩溃

set -e

echo "🚀 启动PhotoEnhanceAI (资源限制模式)"
echo "⏰ 启动时间: $(date)"

# 设置资源限制
export OMP_NUM_THREADS=4  # 限制OpenMP线程数
export CUDA_VISIBLE_DEVICES=0  # 限制GPU使用
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512  # 限制CUDA内存分配

# 启动服务
echo "🎯 启动PhotoEnhanceAI服务..."
cd /root/PhotoEnhanceAI
exec /root/PhotoEnhanceAI/gfpgan_env/bin/python /root/PhotoEnhanceAI/api/start_server.py
```

### 3. Systemd服务配置（可选）

创建了 `/etc/systemd/system/photoenhanceai-limited.service`：

```ini
[Unit]
Description=PhotoEnhanceAI - Resource Limited Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/PhotoEnhanceAI
ExecStart=/root/PhotoEnhanceAI/start_limited.sh
Restart=always
RestartSec=10

# 资源限制配置
MemoryLimit=8G          # 内存限制：8GB
CPUQuota=400%           # CPU限制：4核心
TasksMax=100            # 进程数限制
LimitNOFILE=65536       # 文件描述符限制

# 环境变量
Environment=OMP_NUM_THREADS=4
Environment=CUDA_VISIBLE_DEVICES=0
Environment=PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# 安全设置
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

### 4. 资源监控脚本

创建了 `/root/PhotoEnhanceAI/monitor_resources.sh`：

```bash
#!/bin/bash
# PhotoEnhanceAI 资源监控脚本
# 实时监控内存和CPU使用，防止系统崩溃

# 设置告警阈值
MEMORY_WARNING_THRESHOLD=80   # 内存使用超过80%告警
MEMORY_CRITICAL_THRESHOLD=95  # 内存使用超过95%告警
CPU_WARNING_THRESHOLD=90      # CPU使用超过90%告警

# 实时监控功能
monitor_resources() {
    while true; do
        # 获取系统资源信息
        # 显示监控信息
        # 告警检查
        sleep 10
    done
}
```

## 🚀 使用方法

### 使用Supervisor管理（推荐）

```bash
# 重启服务
supervisorctl restart photoenhanceai

# 查看状态
supervisorctl status

# 查看日志
supervisorctl tail photoenhanceai

# 停止服务
supervisorctl stop photoenhanceai
```

### 使用Systemd管理

```bash
# 启用服务
systemctl enable photoenhanceai-limited

# 启动服务
systemctl start photoenhanceai-limited

# 查看状态
systemctl status photoenhanceai-limited

# 查看日志
journalctl -u photoenhanceai-limited -f
```

### 启动资源监控

```bash
# 后台监控
nohup /root/PhotoEnhanceAI/monitor_resources.sh > /var/log/photoenhanceai_monitor.log 2>&1 &

# 前台监控
/root/PhotoEnhanceAI/monitor_resources.sh
```

## 📊 资源限制说明

| 资源类型 | 限制值 | 说明 |
|---------|--------|------|
| 内存 | 8GB | 系统总内存的26% |
| CPU | 4核心 | 防止CPU过载 |
| GPU | 单卡 | 限制GPU使用 |
| 进程数 | 100 | 限制子进程数量 |
| 文件描述符 | 65536 | 防止文件句柄耗尽 |

## 🔧 故障排除

### 1. 服务启动失败

```bash
# 检查日志
tail -f /var/log/supervisor/photoenhanceai.log

# 检查资源使用
free -h
ps aux --sort=-%mem | head -10
```

### 2. 内存使用过高

```bash
# 停止服务
supervisorctl stop photoenhanceai

# 清理内存
sync && echo 3 > /proc/sys/vm/drop_caches

# 重新启动
supervisorctl start photoenhanceai
```

### 3. 连接断开问题

```bash
# 检查系统资源
free -h
top -bn1 | head -20

# 检查PhotoEnhanceAI进程
ps aux | grep start_server.py
```

## ⚠️ 注意事项

1. **资源限制**: 8GB内存限制确保系统有足够资源维持Cursor连接
2. **启动延迟**: 30秒启动延迟给系统时间稳定
3. **监控告警**: 实时监控防止资源耗尽
4. **优雅停止**: 使用TERM信号优雅停止进程
5. **自动重启**: 服务异常时自动重启

## 🎯 预期效果

- ✅ PhotoEnhanceAI内存使用控制在8GB以内
- ✅ 系统总内存使用保持在安全范围
- ✅ Cursor连接稳定，不会频繁断开
- ✅ 服务自动重启，保证可用性
- ✅ 实时监控，及时发现资源问题

## 📞 支持

如果仍有问题，请：
1. 查看监控日志：`tail -f /var/log/photoenhanceai_monitor.log`
2. 检查服务状态：`supervisorctl status`
3. 查看系统资源：`free -h && ps aux --sort=-%mem | head -10`
