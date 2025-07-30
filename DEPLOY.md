# Pi3B 显示屏部署指南

## 准备工作

### 1. 硬件连接
确保12864 OLED显示屏已正确连接到树莓派的i2c接口：
- VCC -> 3.3V 或 5V
- GND -> GND  
- SDA -> GPIO 2 (PIN 3)
- SCL -> GPIO 3 (PIN 5)

### 2. 启用i2c接口
在OpenWrt中启用i2c：
```bash
# 加载i2c模块
modprobe i2c-dev
modprobe i2c-bcm2708

# 检查设备
ls /dev/i2c*

# 扫描i2c设备
i2cdetect -y 1
```

## 部署步骤

### 方法1: 直接在树莓派上部署

1. **传输项目文件**
```bash
# 使用scp传输整个项目目录
scp -r pi3b_screen/ root@192.168.1.1:/tmp/

# 或者使用wget下载（如果有在线版本）
wget -O pi3b_screen.tar.gz "项目下载链接"
tar -xzf pi3b_screen.tar.gz
```

2. **SSH连接到树莓派**
```bash
ssh root@192.168.1.1
```

3. **进入项目目录并安装**
```bash
cd /tmp/pi3b_screen
chmod +x scripts/install.sh
./scripts/install.sh
```

### 方法2: 使用SSH远程部署脚本

1. **创建远程部署脚本** (在本地运行)
```bash
#!/bin/bash
# deploy.sh - 远程部署脚本

PI_HOST="192.168.1.1"
PI_USER="root"
PROJECT_DIR="/tmp/pi3b_screen"

echo "正在部署到 $PI_USER@$PI_HOST..."

# 传输项目文件
echo "传输项目文件..."
scp -r ./ $PI_USER@$PI_HOST:$PROJECT_DIR

# 远程执行安装
echo "远程执行安装..."
ssh $PI_USER@$PI_HOST << 'EOF'
cd /tmp/pi3b_screen
chmod +x scripts/install.sh
./scripts/install.sh
EOF

echo "部署完成!"
```

2. **运行部署脚本**
```bash
chmod +x deploy.sh
./deploy.sh
```

## 验证安装

### 检查服务状态
```bash
# 查看服务状态
systemctl status pi3b_display

# 查看实时日志
journalctl -u pi3b_display -f

# 查看日志文件
tail -f /var/log/pi3b_display.log
```

### 检查显示屏
- 显示屏应该显示系统信息
- 每8秒自动切换页面
- 显示内容包括网络信息、系统状态、设备统计、存储信息

## 故障排除

### 1. 显示屏无显示
```bash
# 检查i2c设备
i2cdetect -y 1

# 检查服务日志
journalctl -u pi3b_display --no-pager

# 手动运行程序测试
cd /opt/pi3b_display/src
python3 main.py
```

### 2. i2c地址错误
编辑配置文件调整i2c地址：
```bash
vi /opt/pi3b_display/src/config.py
# 修改 DISPLAY_CONFIG['address'] 为正确地址 (0x3C 或 0x3D)
systemctl restart pi3b_display
```

### 3. 网络信息获取失败
检查网络接口配置：
```bash
# 查看网络接口
ip link show

# 编辑配置文件
vi /opt/pi3b_display/src/config.py
# 修改 NETWORK_CONFIG 中的接口名称
```

## 维护操作

### 重启服务
```bash
systemctl restart pi3b_display
```

### 停止服务
```bash
systemctl stop pi3b_display
```

### 禁用自启动
```bash
systemctl disable pi3b_display
```

### 卸载程序
```bash
cd /opt/pi3b_display/scripts
./uninstall.sh
```

### 更新程序
```bash
# 停止服务
systemctl stop pi3b_display

# 备份配置（如果有自定义）
cp /opt/pi3b_display/src/config.py /tmp/config.py.bak

# 重新部署
# ... 执行部署步骤 ...

# 恢复配置（如需要）
cp /tmp/config.py.bak /opt/pi3b_display/src/config.py

# 重启服务
systemctl start pi3b_display
```

## 配置自定义

### 修改显示内容
编辑 `/opt/pi3b_display/src/config.py`：
- `DISPLAY_PAGES`: 控制显示页面顺序
- `REFRESH_INTERVALS`: 控制刷新间隔
- `NETWORK_CONFIG`: 配置网络接口名称

### 修改i2c配置
```python
DISPLAY_CONFIG = {
    'interface': 'i2c',
    'port': 1,           # i2c端口号
    'address': 0x3C,     # i2c地址
    'width': 128,
    'height': 64,
    'rotate': 0          # 旋转角度
}
```

修改后重启服务：
```bash
systemctl restart pi3b_display
```
