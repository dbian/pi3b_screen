# OpenWrt适配说明

## 主要变更

本项目已修改为同时适用于标准Linux和OpenWrt环境，主要变更如下：

### 1. 移除psutil依赖

原版本依赖`psutil`库来获取系统信息，但在OpenWrt环境中安装psutil较为困难。现在改用Linux系统原生的方法：

1. **内存信息**: 从`/proc/meminfo`读取
2. **CPU使用率**: 从`/proc/stat`计算
3. **网络统计**: 从`/proc/net/dev`读取
4. **磁盘使用**: 使用`df`命令
5. **网络连接**: 使用`ss`、`netstat`或`/proc/net/tcp`

### 2. 新增OpenWrt部署支持

- **虚拟环境部署**: 使用`python3-venv`创建独立环境，避免污染系统Python
- **init.d服务脚本**: 替代systemd，使用OpenWrt原生的init.d管理服务
- **LuCI界面支持**: 可通过LuCI界面管理服务启动项
- **冗余文件清理**: 部署时自动排除不必要的文件（`__pycache__`、`.git`、测试文件等）

### 3. 修改的文件

- `src/system_monitor.py`: 主要修改文件，移除psutil依赖
- `requirements.txt`: 移除psutil依赖
- `scripts/install_openwrt.sh`: 新增OpenWrt专用安装脚本
- `OPENWRT_DEPLOY.md`: OpenWrt部署专用文档
- `deploy.sh`: 支持OpenWrt模式，自动排除冗余文件
- `prepare_venv.sh`: 虚拟环境预打包脚本

### 4. 部署方式比较

| 特性 | 标准Linux (systemd) | OpenWrt (init.d + venv) |
|------|-------------------|------------------------|
| 服务管理 | systemd | init.d + procd |
| Python环境 | 系统Python | 虚拟环境 |
| 依赖管理 | pip全局安装 | 虚拟环境隔离 |
| 启动配置 | systemctl | /etc/init.d/pi3b_display |
| LuCI支持 | 不适用 | 支持LuCI界面管理 |
| 存储占用 | 较小 | 较大（含虚拟环境） |
| 环境隔离 | 无 | 完全隔离 |

### 5. 新增功能

- **自动降级备选方案**: 当首选方法失败时，会尝试备选方案
- **更好的OpenWrt兼容性**: 使用OpenWrt系统自带的工具
- **文件清理**: 部署时自动排除冗余文件
- **虚拟环境打包**: 支持在开发机上预打包虚拟环境

### 6. 测试

运行测试脚本验证功能：

```bash
python3 test_system_monitor.py
```

### 7. 依赖包

现在只需要以下Python包：
- luma.oled==3.12.0
- requests==2.31.0  

这些包在OpenWrt环境中更容易安装，且通过虚拟环境避免版本冲突。

### 8. 兼容性

- ✅ OpenWrt 19.07+ (使用虚拟环境)
- ✅ 标准Linux发行版 (systemd)
- ✅ 树莓派
- ✅ 路由器硬件

### 9. 部署建议

#### OpenWrt系统
1. 使用虚拟环境部署方式
2. 通过LuCI界面管理服务
3. 定期清理Python缓存文件
4. 监控存储空间使用

#### 标准Linux系统
1. 使用systemd服务管理
2. 通过journalctl查看日志
3. 使用系统Python环境

### 10. 注意事项

1. **存储空间**: 虚拟环境会占用50-100MB存储空间
2. **内存使用**: 虚拟环境会使用更多内存
3. **权限要求**: 某些功能可能需要root权限
4. **工具依赖**: WiFi设备统计需要`iw`工具
5. **降级处理**: 如果系统缺少某些工具，相关功能会降级或返回默认值
6. **备份重要**: 升级OpenWrt系统前请备份配置文件
