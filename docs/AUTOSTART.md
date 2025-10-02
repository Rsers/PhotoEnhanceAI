# 📘 自动启动配置

PhotoEnhanceAI的开机自启动配置方案，支持多种环境和启动方式。

## 🔧 支持的启动方式

| 系统类型 | 启动方式 | 特点 | 适用场景 |
|----------|----------|------|----------|
| **supervisor** | supervisor 服务管理 | 专业、稳定、资源控制 | 容器环境、生产环境 |
| **systemd** | systemd 服务 | 现代、稳定、功能完整 | Ubuntu 16.04+, CentOS 7+ |
| **rc.local** | 传统启动脚本 | 兼容性好、简单 | 老版本系统 |
| **cron** | @reboot 任务 | 轻量级、跨平台 | 容器环境、云服务器 |
| **container** | 容器启动脚本 | 专门优化 | Docker 容器 |
| **mirror** | 镜像环境启动 | 智能检测、环境适配 | 镜像文件部署 |

## 🚀 一键设置开机自启动

```bash
# 自动检测系统类型并设置开机自启动
sudo ./setup_autostart.sh
```

## 🆕 Supervisor自动启动（推荐）

### 适用场景
容器环境、生产环境，需要专业服务管理和资源控制

### 重要说明
> ⚠️ **supervisor环境必须使用`start_supervisor.sh`脚本，不能使用`start_backend_daemon.sh`。**
> 原因：`start_backend_daemon.sh`使用`nohup`和后台运行，与supervisor的进程管理机制不兼容，会导致服务启动失败。

### 配置步骤

#### 1. 修改supervisor主配置
```bash
echo -e "[include]\nfiles = /etc/supervisor/conf.d/*.conf" >> /etc/supervisord.conf
```

#### 2. 创建PhotoEnhanceAI配置文件
在 `/etc/supervisor/conf.d/` 路径下创建 `photoenhanceai.conf`：
```ini
[program:photoenhanceai]
command=/root/PhotoEnhanceAI/start_supervisor.sh
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
memory_limit=8GB
cpu_limit=400%
numprocs=1
startsecs=5
startretries=3
stopsignal=TERM
stopwaitsecs=30
killasgroup=true
stopasgroup=true
```

#### 3. 重启应用验证
```bash
supervisorctl reread && supervisorctl update
supervisorctl restart photoenhanceai
supervisorctl status
```

### 核心特性
- 🚀 **专业服务管理**: supervisor提供完整的进程管理功能
- 💾 **资源限制**: 自动限制内存使用（8GB）和CPU使用（4核心）
- 🔄 **自动重启**: 服务异常时自动重启，确保服务稳定
- 📊 **日志管理**: 完整的日志记录和轮转
- ⚙️ **兼容性优化**: 使用`start_supervisor.sh`脚本，专为supervisor环境设计
- 🛡️ **安全控制**: 优雅停止和进程组管理
- ⚡ **快速启动**: 容器启动时自动运行PhotoEnhanceAI

### 服务管理命令
```bash
# 查看状态
supervisorctl status

# 重启服务
supervisorctl restart photoenhanceai

# 查看日志
supervisorctl tail photoenhanceai

# 停止服务
supervisorctl stop photoenhanceai

# 启动服务
supervisorctl start photoenhanceai
```

### 验证配置
```bash
# 运行自动启动验证脚本
./verify_supervisor_autostart.sh

# 检查supervisor状态
supervisorctl status photoenhanceai

# 测试API健康状态
curl http://localhost:8000/health
```

### 故障排除
```bash
# 检查配置
supervisorctl reread

# 重新加载配置
supervisorctl update

# 查看详细日志
tail -f /var/log/supervisor/photoenhanceai.log

# 检查资源使用
free -h && ps aux --sort=-%mem | head -5

# 如果启动失败，检查启动脚本
./start_supervisor.sh
```

## 🆕 镜像环境自动启动

### 适用场景
使用镜像文件在新服务器上开机部署

### 问题背景
镜像环境与原始环境存在差异，导致自动启动机制失效

### 解决方案
智能检测镜像环境，自动适配新服务器环境

```bash
# 一键配置镜像环境自动启动
./setup_mirror_autostart.sh
```

### 核心特性
- 🧠 **智能检测**: 根据系统运行时间判断环境类型
- 🧹 **环境清理**: 自动清理旧PID文件和进程状态
- 🌐 **网络适配**: 延长网络初始化等待时间
- 🎮 **硬件检测**: 检查GPU和CUDA环境状态
- 🔄 **多重保障**: 配置多种自动启动机制
- 📝 **详细日志**: 记录启动过程和问题诊断

### 启动流程
```
1. 系统开机 → 2. 智能检测环境 → 3. 清理旧状态 → 4. 等待网络就绪
   ↓
5. 检查硬件环境 → 6. 启动主服务 → 7. 模型预热 → 8. Webhook注册
```

### 配置特点
- **运行时间<10分钟**: 使用镜像环境启动脚本
- **运行时间>10分钟**: 使用标准启动检查
- **自动清理**: 清理旧PID文件和进程状态
- **延长等待**: 网络等待20秒，硬件检测15秒
- **状态验证**: 检查服务、API、GPU状态

### 日志文件
- `logs/mirror_autostart.log` - 镜像启动日志
- `logs/mirror_warmup.log` - 模型预热日志
- `logs/mirror_webhook.log` - Webhook注册日志
- `logs/profile_autostart.log` - 配置启动日志

### 故障排除
```bash
# 检查服务状态
./status_service.sh

# 查看启动日志
tail -f logs/mirror_autostart.log

# 手动启动
./mirror_autostart.sh

# 重新配置
./setup_mirror_autostart.sh
```

## systemd 服务方式

```bash
# 1. 安装 systemd 服务
sudo ./install_systemd_service.sh

# 2. 服务管理命令
sudo systemctl start photoenhanceai      # 启动服务
sudo systemctl stop photoenhanceai       # 停止服务
sudo systemctl restart photoenhanceai    # 重启服务
sudo systemctl status photoenhanceai     # 查看状态
sudo systemctl enable photoenhanceai     # 启用开机自启
sudo systemctl disable photoenhanceai    # 禁用开机自启

# 3. 查看服务日志
sudo journalctl -u photoenhanceai -f     # 实时日志
sudo journalctl -u photoenhanceai        # 历史日志
```

## 容器环境自启动

### 腾讯云容器环境专用配置

```bash
# 1. 一键配置容器自动启动（推荐）
./setup_container_autostart.sh

# 2. 或手动使用容器启动脚本
./container_autostart.sh
```

### 特点
- 自动等待网络就绪
- 启动主服务、模型预热、webhook注册
- 服务监控和自动重启
- 适合腾讯云容器、Docker 容器或非 systemd 环境

### 腾讯云容器环境特殊性

⚠️ **重要说明**：腾讯云容器环境（非用户自建Docker）与传统Linux系统不同：

#### 系统特性
- 使用 `dumb-init` 作为PID 1进程
- 没有 systemd 服务管理
- rc.local 可能不会自动执行
- 需要多重启动保障机制

#### 配置的自动启动方式
```bash
# 已配置的启动机制：
✅ .bashrc 自动启动 - 每次shell启动时检查服务状态
✅ /etc/profile.d 自动启动 - 系统级启动检查  
✅ rc.local 自动启动 - 容器启动时执行（备用）
✅ 容器初始化脚本 - 专用容器启动脚本
```

### 故障排除
如果开机后服务未自动启动，请检查：
```bash
# 检查服务状态
./status_service.sh

# 手动启动服务
./start_backend_daemon.sh

# 重新配置自动启动
./setup_container_autostart.sh

# 测试自动启动机制
bash -c "source /etc/profile.d/photoenhanceai_autostart.sh"
```

### 可能的问题点
- 容器启动顺序问题：rc.local 可能在其他服务之前执行
- 网络就绪时间：需要等待网络完全就绪
- 权限问题：确保脚本有执行权限
- 环境变量：虚拟环境路径可能变化
- 进程监控：容器重启时PID文件可能残留

## 手动设置方式

### rc.local 方式
```bash
# 编辑 /etc/rc.local
sudo nano /etc/rc.local

# 在 exit 0 之前添加：
/root/PhotoEnhanceAI/container_autostart.sh

# 设置执行权限
sudo chmod +x /etc/rc.local
```

### cron @reboot 方式
```bash
# 编辑 crontab
crontab -e

# 添加以下行：
@reboot sleep 30 && /root/PhotoEnhanceAI/container_autostart.sh
```

## 服务管理脚本

```bash
# 使用便捷的管理脚本
./manage_service.sh start      # 启动服务
./manage_service.sh stop       # 停止服务
./manage_service.sh restart    # 重启服务
./manage_service.sh status     # 查看状态
./manage_service.sh logs       # 查看日志
./manage_service.sh enable     # 启用开机自启
./manage_service.sh disable    # 禁用开机自启
./manage_service.sh install    # 安装服务
./manage_service.sh uninstall  # 卸载服务
./manage_service.sh help       # 显示帮助
```

## 开机自启动特性

- ✅ **自动检测系统**: 智能识别 systemd、rc.local、cron 等启动方式
- ✅ **服务管理**: 完整的启动、停止、重启、状态检查功能
- ✅ **日志管理**: systemd 日志、应用日志、错误日志分离
- ✅ **安全设置**: systemd 服务包含安全配置和权限控制
- ✅ **错误处理**: 服务异常时自动重启，确保服务稳定
- ✅ **容器优化**: 专门为容器环境优化的启动脚本
- ✅ **监控功能**: 服务状态监控和自动恢复

## 🔗 相关链接

- [部署指南](DEPLOYMENT.md)
- [容器部署](CONTAINER_DEPLOYMENT.md)
- [故障排除](TROUBLESHOOTING.md)
- [Supervisor修复方案](../FIX_SUMMARY.md)
