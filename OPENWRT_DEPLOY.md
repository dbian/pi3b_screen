# OpenWrt 部署指南

## 概述

由于 OpenWrt 系统不使用 systemd，本指南提供专门针对 OpenWrt 系统的部署方法。推荐使用 Python 虚拟环境进行部署，并通过 LuCI 界面配置启动脚本。

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
# 安装i2c工具
opkg update
opkg install i2c-tools kmod-i2c-core kmod-i2c-gpio

# 加载i2c模块
modprobe i2c-dev
modprobe i2c-bcm2708

# 检查设备
ls /dev/i2c*

# 扫描i2c设备
i2cdetect -y 1
```

## 部署方法

### 方法1: 虚拟环境部署（推荐）

这种方法使用 Python 虚拟环境，避免污染系统 Python 环境，更适合 OpenWrt 系统。

#### 步骤1: 在开发机上准备虚拟环境

```bash
# 在开发机上创建虚拟环境
python3 -m venv pi3b_venv
source pi3b_venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 打包虚拟环境和项目文件
tar -czf pi3b_screen_venv.tar.gz \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.git' \
    --exclude='test_*' \
    --exclude='deploy.sh' \
    pi3b_venv/ src/ scripts/
```

#### 步骤2: 传输到OpenWrt设备

```bash
# 传输文件包到OpenWrt设备
scp pi3b_screen_venv.tar.gz root@192.168.1.1:/tmp/

# SSH登录OpenWrt设备
ssh root@192.168.1.1

# 解压到目标目录
cd /opt
tar -xzf /tmp/pi3b_screen_venv.tar.gz
```

#### 步骤3: 配置OpenWrt启动脚本

在OpenWrt设备上创建init.d启动脚本：

```bash
# 创建启动脚本
cat > /etc/init.d/pi3b_display << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

USE_PROCD=1
PROG=/opt/pi3b_venv/bin/python3
ARGS="/opt/src/main.py"
PIDFILE=/var/run/pi3b_display.pid

start_service() {
    procd_open_instance
    procd_set_param command $PROG $ARGS
    procd_set_param pidfile $PIDFILE
    procd_set_param respawn ${respawn_threshold:-3600} ${respawn_timeout:-5} ${respawn_retry:-5}
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}

stop_service() {
    service_stop $PROG
}
EOF

# 设置执行权限
chmod +x /etc/init.d/pi3b_display

# 启用服务
/etc/init.d/pi3b_display enable

# 启动服务
/etc/init.d/pi3b_display start
```

### 方法2: 使用LuCI界面配置

#### 步骤1: 通过LuCI添加启动脚本

1. 在浏览器中访问OpenWrt管理界面（通常是 http://192.168.1.1）
2. 登录LuCI界面
3. 导航到 **系统** -> **启动项**
4. 在 **本地启动脚本** 部分，添加以下内容到 `/etc/rc.local`：

```bash
# Pi3B Display Service
/opt/pi3b_venv/bin/python3 /opt/src/main.py > /var/log/pi3b_display.log 2>&1 &
```

#### 步骤2: 配置计划任务（可选）

如果需要定期重启服务，可以在LuCI中配置计划任务：

1. 导航到 **系统** -> **计划任务**
2. 添加以下cron任务：

```bash
# 每天凌晨2点重启显示服务
0 2 * * * /etc/init.d/pi3b_display restart
```

## 服务管理

### 使用init.d脚本管理

```bash
# 启动服务
/etc/init.d/pi3b_display start

# 停止服务
/etc/init.d/pi3b_display stop

# 重启服务
/etc/init.d/pi3b_display restart

# 查看服务状态
/etc/init.d/pi3b_display status

# 启用开机自启
/etc/init.d/pi3b_display enable

# 禁用开机自启
/etc/init.d/pi3b_display disable
```

### 查看日志

```bash
# 查看日志文件
tail -f /var/log/pi3b_display.log

# 查看系统日志
logread | grep pi3b_display
```

## 故障排除

### 1. 虚拟环境问题

```bash
# 检查虚拟环境Python路径
/opt/pi3b_venv/bin/python3 --version

# 检查依赖包
/opt/pi3b_venv/bin/pip list

# 手动测试程序
cd /opt/src
/opt/pi3b_venv/bin/python3 main.py
```

### 2. i2c设备问题

```bash
# 检查i2c设备
i2cdetect -y 1

# 检查i2c模块
lsmod | grep i2c

# 重新加载i2c模块
rmmod i2c-bcm2708
modprobe i2c-bcm2708
```

### 3. 权限问题

```bash
# 确保脚本有执行权限
chmod +x /etc/init.d/pi3b_display
chmod +x /opt/src/main.py

# 检查文件所有者
ls -la /opt/src/main.py
```

## 卸载

### 停止并删除服务

```bash
# 停止服务
/etc/init.d/pi3b_display stop

# 禁用服务
/etc/init.d/pi3b_display disable

# 删除启动脚本
rm /etc/init.d/pi3b_display

# 删除项目文件
rm -rf /opt/pi3b_venv /opt/src

# 清理日志
rm -f /var/log/pi3b_display.log
```

## 优化建议

### 1. 减少存储占用

```bash
# 清理Python缓存
find /opt -name "__pycache__" -type d -exec rm -rf {} +
find /opt -name "*.pyc" -delete

# 清理pip缓存
/opt/pi3b_venv/bin/pip cache purge
```

### 2. 内存优化

如果设备内存有限，可以考虑：
- 使用更轻量的Python包版本
- 调整程序刷新间隔
- 减少显示页面数量

### 3. 网络优化

对于通过网络部署的场景：
- 压缩传输文件
- 只传输必要的文件
- 使用rsync进行增量更新

## 注意事项

1. **系统兼容性**: 此方法适用于OpenWrt 19.07+版本
2. **存储空间**: 虚拟环境大约需要50-100MB存储空间
3. **内存使用**: Python虚拟环境会占用更多内存
4. **备份配置**: 升级OpenWrt系统前请备份配置和项目文件