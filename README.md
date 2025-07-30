# 树莓派3B OpenWrt 12864显示屏项目

这个项目用于在树莓派3B的OpenWrt系统上通过i2c控制12864 OLED显示屏，显示系统状态信息。

## 功能特性

- 🌐 显示WAN口IP地址
- 📊 显示网络上下行速度
- 💾 显示内存使用情况
- 💿 显示磁盘使用情况
- 🔗 显示网络连接数量
- 📱 显示LAN口设备数量
- 🔄 信息轮换显示（每8秒切换）
- 🚀 开机自启动
- 📝 详细日志记录

## 硬件要求

- 树莓派3B (运行OpenWrt系统)
- 12864 OLED显示屏 (SSD1306芯片)
- i2c接口连接 (SDA->GPIO2, SCL->GPIO3)

## 快速部署

### 方法1: 远程部署（推荐）
```bash
# 在本地运行，自动部署到树莓派
chmod +x deploy.sh
./deploy.sh [树莓派IP] [用户名]

# 示例
./deploy.sh 192.168.1.1 root
```

### 方法2: 手动部署
```bash
# 1. 传输文件到树莓派
scp -r pi3b_screen/ root@192.168.1.1:/tmp/

# 2. SSH登录树莓派
ssh root@192.168.1.1

# 3. 安装
cd /tmp/pi3b_screen
chmod +x scripts/install.sh
./scripts/install.sh
```

## 显示内容

显示屏会循环显示以下4个页面：

### 页面1: 网络信息
```
Network Info
────────────
WAN IP: 192.168.1.100
Upload: 120.5 KB/s
Download: 1.2 MB/s
Connections: 15
```

### 页面2: 系统状态
```
System Status
─────────────
CPU: 25.3%
Memory: 60.8%
Temp: 45.2°C
Uptime: 12:34
```

### 页面3: 设备统计
```
Device Count
────────────
LAN Devices: 8
WiFi Devices: 5
Total: 13
Time: 14:25:30
```

### 页面4: 存储信息
```
Storage Info
────────────
Root: 45.2%
Tmp: 12.5%
Free: 2.8GB
Date: 07/30
```

## 项目结构

```
pi3b_screen/
├── src/                      # 源代码目录
│   ├── main.py              # 主程序入口
│   ├── display_controller.py # OLED显示控制器
│   ├── system_monitor.py     # 系统信息监控
│   └── config.py            # 配置文件
├── scripts/                  # 脚本目录
│   ├── install.sh           # 安装脚本
│   ├── uninstall.sh         # 卸载脚本
│   ├── start.sh             # 手动启动脚本
│   ├── test.sh              # 功能测试脚本
│   └── pi3b_display.service # systemd服务文件
├── deploy.sh                # 远程部署脚本
├── requirements.txt         # Python依赖包
├── README.md               # 项目说明
└── DEPLOY.md               # 详细部署文档
```

## 常用命令

```bash
# 查看服务状态
systemctl status pi3b_display

# 启动/停止/重启服务
systemctl start pi3b_display
systemctl stop pi3b_display
systemctl restart pi3b_display

# 查看实时日志
journalctl -u pi3b_display -f

# 查看日志文件
tail -f /var/log/pi3b_display.log

# 运行功能测试
/opt/pi3b_display/scripts/test.sh

# 手动启动程序（调试用）
cd /opt/pi3b_display/src
python3 main.py
```

## 配置自定义

主要配置文件位于 `/opt/pi3b_display/src/config.py`：

```python
# 显示屏i2c配置
DISPLAY_CONFIG = {
    'port': 1,           # i2c端口号
    'address': 0x3C,     # i2c地址 (通常是0x3C或0x3D)
    'width': 128,
    'height': 64,
    'rotate': 0          # 旋转角度
}

# 刷新间隔（秒）
REFRESH_INTERVALS = {
    'network_speed': 2,  # 网络速度更新
    'system_info': 5,    # 系统信息更新
    'page_switch': 8     # 页面切换间隔
}

# 网络接口名称
NETWORK_CONFIG = {
    'wan_interface': 'eth0',
    'lan_interface': 'br-lan',
    'wifi_interface': 'wlan0'
}
```

修改配置后重启服务：
```bash
systemctl restart pi3b_display
```
