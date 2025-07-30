# OpenWrt适配说明

## 主要变更

本项目已修改为适用于OpenWrt环境，主要变更如下：

### 移除psutil依赖

原版本依赖`psutil`库来获取系统信息，但在OpenWrt环境中安装psutil较为困难。现在改用Linux系统原生的方法：

1. **内存信息**: 从`/proc/meminfo`读取
2. **CPU使用率**: 从`/proc/stat`计算
3. **网络统计**: 从`/proc/net/dev`读取
4. **磁盘使用**: 使用`df`命令
5. **网络连接**: 使用`ss`、`netstat`或`/proc/net/tcp`

### 修改的文件

- `src/system_monitor.py`: 主要修改文件，移除psutil依赖
- `requirements.txt`: 移除psutil依赖

### 新增功能

- 自动降级备选方案：当首选方法失败时，会尝试备选方案
- 更好的OpenWrt兼容性：使用OpenWrt系统自带的工具

### 测试

运行测试脚本验证功能：

```bash
python3 test_system_monitor.py
```

### 依赖包

现在只需要以下Python包：
- luma.oled==3.12.0
- requests==2.31.0  
- netifaces==0.11.0

这些包在OpenWrt环境中更容易安装。

### 兼容性

- ✅ OpenWrt 19.07+
- ✅ 标准Linux发行版
- ✅ 树莓派
- ✅ 路由器硬件

### 注意事项

1. 某些功能可能需要root权限
2. WiFi设备统计需要`iw`工具
3. 如果系统缺少某些工具，相关功能会降级或返回默认值
