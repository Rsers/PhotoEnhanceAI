# PhotoEnhanceAI 开机自启动指南

## 🎯 概述

PhotoEnhanceAI 提供了完整的开机自启动解决方案，支持多种系统类型和部署环境。本指南将帮助您选择最适合的自启动方式。

## 🚀 快速开始

### 一键设置（推荐）

```bash
# 自动检测系统类型并设置开机自启动
sudo ./setup_autostart.sh
```

这个脚本会：
1. 自动检测您的系统类型（systemd、rc.local、cron、container）
2. 选择最适合的启动方式
3. 配置相应的自启动机制
4. 提供管理命令说明

## 📋 支持的启动方式

| 系统类型 | 启动方式 | 特点 | 适用场景 |
|----------|----------|------|----------|
| **systemd** | systemd 服务 | 现代、稳定、功能完整 | Ubuntu 16.04+, CentOS 7+ |
| **rc.local** | 传统启动脚本 | 兼容性好、简单 | 老版本系统 |
| **cron** | @reboot 任务 | 轻量级、跨平台 | 容器环境、云服务器 |
| **container** | 容器启动脚本 | 专门优化 | Docker 容器 |

## 🔧 详细配置

### 1. systemd 服务方式（推荐）

**适用系统**：Ubuntu 16.04+, CentOS 7+, Debian 8+

**安装步骤**：
```bash
# 1. 安装 systemd 服务
sudo ./install_systemd_service.sh

# 2. 启用开机自启动
sudo systemctl enable photoenhanceai

# 3. 启动服务
sudo systemctl start photoenhanceai
```

**服务管理**：
```bash
# 启动服务
sudo systemctl start photoenhanceai

# 停止服务
sudo systemctl stop photoenhanceai

# 重启服务
sudo systemctl restart photoenhanceai

# 查看状态
sudo systemctl status photoenhanceai

# 启用开机自启
sudo systemctl enable photoenhanceai

# 禁用开机自启
sudo systemctl disable photoenhanceai

# 查看日志
sudo journalctl -u photoenhanceai -f
```

**服务特性**：
- ✅ 自动重启（服务异常时自动恢复）
- ✅ 完整的日志管理
- ✅ 安全配置和权限控制
- ✅ 依赖关系管理（等待网络就绪）
- ✅ 标准化的服务控制

### 2. 容器环境自启动

**适用场景**：Docker 容器、非 systemd 环境

**使用方法**：
```bash
# 直接运行容器启动脚本
./container_autostart.sh
```

**特点**：
- ✅ 自动等待网络就绪
- ✅ 启动主服务、模型预热、webhook注册
- ✅ 服务监控和自动重启
- ✅ 适合容器环境

**在容器中使用**：
```dockerfile
# Dockerfile 示例
FROM ubuntu:20.04
# ... 其他配置 ...
CMD ["/root/PhotoEnhanceAI/container_autostart.sh"]
```

### 3. rc.local 方式

**适用系统**：老版本 Linux 系统

**配置步骤**：
```bash
# 1. 编辑 rc.local 文件
sudo nano /etc/rc.local

# 2. 在 exit 0 之前添加：
/root/PhotoEnhanceAI/container_autostart.sh

# 3. 设置执行权限
sudo chmod +x /etc/rc.local
```

### 4. cron @reboot 方式

**适用场景**：轻量级部署、云服务器

**配置步骤**：
```bash
# 1. 编辑 crontab
crontab -e

# 2. 添加以下行：
@reboot sleep 30 && /root/PhotoEnhanceAI/container_autostart.sh
```

## 🛠️ 服务管理脚本

PhotoEnhanceAI 提供了便捷的服务管理脚本：

```bash
# 使用管理脚本
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

## 📊 日志管理

### systemd 服务日志
```bash
# 实时查看日志
sudo journalctl -u photoenhanceai -f

# 查看历史日志
sudo journalctl -u photoenhanceai

# 查看最近的日志
sudo journalctl -u photoenhanceai -n 100
```

### 应用日志
```bash
# 主服务日志
tail -f logs/photoenhanceai.log

# 模型预热日志
tail -f logs/model_warmup.log

# Webhook注册日志
tail -f logs/webhook_register.log

# systemd 日志
tail -f logs/systemd.log

# 错误日志
tail -f logs/systemd_error.log
```

## 🔍 故障排除

### 常见问题

1. **服务启动失败**
   ```bash
   # 检查服务状态
   sudo systemctl status photoenhanceai
   
   # 查看详细日志
   sudo journalctl -u photoenhanceai -n 50
   ```

2. **开机自启动不生效**
   ```bash
   # 检查服务是否启用
   sudo systemctl is-enabled photoenhanceai
   
   # 重新启用
   sudo systemctl enable photoenhanceai
   ```

3. **容器环境问题**
   ```bash
   # 检查虚拟环境
   ls -la gfpgan_env/bin/python
   
   # 测试启动脚本
   ./container_autostart.sh
   ```

### 调试步骤

1. **检查系统类型**
   ```bash
   # 检查是否支持 systemd
   systemctl --version
   
   # 检查系统版本
   cat /etc/os-release
   ```

2. **验证脚本权限**
   ```bash
   # 确保脚本有执行权限
   chmod +x setup_autostart.sh
   chmod +x install_systemd_service.sh
   chmod +x manage_service.sh
   chmod +x container_autostart.sh
   ```

3. **测试手动启动**
   ```bash
   # 测试容器启动脚本
   ./container_autostart.sh
   
   # 测试原始启动脚本
   ./start_backend_daemon.sh
   ```

## 🎯 最佳实践

### 生产环境推荐

1. **使用 systemd 服务**（如果系统支持）
   - 最稳定和功能完整
   - 自动重启和日志管理
   - 标准化的服务控制

2. **容器环境使用 container_autostart.sh**
   - 专门为容器优化
   - 包含监控和自动重启
   - 适合 Docker 部署

### 开发环境推荐

1. **使用前台启动**
   ```bash
   ./start_frontend_only.sh
   ```

2. **使用后台启动**
   ```bash
   ./start_backend_daemon.sh
   ```

### 安全建议

1. **权限控制**
   - 使用非 root 用户运行（如果可能）
   - 限制服务访问权限

2. **日志管理**
   - 定期清理日志文件
   - 监控日志大小

3. **服务监控**
   - 设置服务健康检查
   - 监控服务状态

## 📞 支持

如果您在设置开机自启动时遇到问题，请：

1. 查看本文档的故障排除部分
2. 检查系统日志和应用日志
3. 在 GitHub Issues 中提交问题

---

**注意**：不同的系统类型可能需要不同的配置方式。建议先使用 `setup_autostart.sh` 自动检测和配置，如果遇到问题再参考手动配置方法。
