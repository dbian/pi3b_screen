#!/bin/bash

# 树莓派3B OpenWrt 12864显示屏项目安装脚本

set -e

PROJECT_NAME="pi3b_display"
PROJECT_DIR="/opt/$PROJECT_NAME"
SERVICE_NAME="$PROJECT_NAME.service"
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/pi3b_display.log"

echo "========================================="
echo "Pi3B Display 安装脚本"
echo "========================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用root权限运行此脚本"
    echo "使用: sudo $0"
    exit 1
fi

# 检查系统架构
ARCH=$(uname -m)
echo "检测到系统架构: $ARCH"

# 更新软件包列表
echo "更新软件包列表..."
opkg update

# 安装必要的系统包
echo "安装系统依赖包..."
opkg install python3 python3-pip i2c-tools

# 检查i2c是否启用
echo "检查i2c接口..."
if ! lsmod | grep -q i2c; then
    echo "警告: i2c模块未加载，请确保i2c接口已启用"
fi

# 创建项目目录
echo "创建项目目录: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
mkdir -p $PROJECT_DIR/src
mkdir -p $PROJECT_DIR/scripts

# 复制项目文件
echo "复制项目文件..."
if [ -d "src" ]; then
    cp -r src/* $PROJECT_DIR/src/
else
    echo "错误: 找不到src目录，请在项目根目录运行此脚本"
    exit 1
fi

if [ -d "scripts" ]; then
    cp scripts/* $PROJECT_DIR/scripts/ 2>/dev/null || true
fi

# 复制requirements.txt
if [ -f "requirements.txt" ]; then
    cp requirements.txt $PROJECT_DIR/
fi

# 设置权限
chmod +x $PROJECT_DIR/src/main.py
chmod +x $PROJECT_DIR/scripts/*.sh 2>/dev/null || true

# 安装Python依赖
echo "安装Python依赖包..."
cd $PROJECT_DIR

# 升级pip
python3 -m pip install --upgrade pip

# 安装依赖包
if [ -f "requirements.txt" ]; then
    python3 -m pip install -r requirements.txt
else
    echo "手动安装Python包..."
    python3 -m pip install luma.oled psutil requests netifaces
fi

# 创建日志文件
echo "设置日志文件..."
touch $LOG_FILE
chmod 644 $LOG_FILE

# 创建systemd服务文件
echo "创建systemd服务..."
cat > /etc/systemd/system/$SERVICE_NAME << EOF
[Unit]
Description=Pi3B Display Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$PROJECT_DIR/src
ExecStart=/usr/bin/python3 $PROJECT_DIR/src/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd并启用服务
echo "配置服务自启动..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME

# 测试i2c设备
echo "检测i2c设备..."
if command -v i2cdetect >/dev/null 2>&1; then
    echo "i2c设备扫描结果:"
    i2cdetect -y 1 2>/dev/null || echo "无法扫描i2c设备，请检查硬件连接"
else
    echo "警告: i2cdetect命令不可用"
fi

# 启动服务
echo "启动服务..."
systemctl start $SERVICE_NAME

# 检查服务状态
sleep 3
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✓ 服务启动成功"
    echo "✓ 服务状态: $(systemctl is-active $SERVICE_NAME)"
else
    echo "✗ 服务启动失败"
    echo "查看服务状态: systemctl status $SERVICE_NAME"
    echo "查看日志: journalctl -u $SERVICE_NAME -f"
fi

echo ""
echo "========================================="
echo "安装完成!"
echo "========================================="
echo "项目目录: $PROJECT_DIR"
echo "服务名称: $SERVICE_NAME"
echo "日志文件: $LOG_FILE"
echo ""
echo "常用命令:"
echo "  查看服务状态: systemctl status $SERVICE_NAME"
echo "  启动服务:     systemctl start $SERVICE_NAME"
echo "  停止服务:     systemctl stop $SERVICE_NAME"
echo "  重启服务:     systemctl restart $SERVICE_NAME"
echo "  查看日志:     tail -f $LOG_FILE"
echo "  实时日志:     journalctl -u $SERVICE_NAME -f"
echo ""
echo "如果显示屏没有显示内容，请检查:"
echo "1. i2c接口是否正确连接"
echo "2. i2c地址是否正确 (通常为0x3C或0x3D)"
echo "3. 查看日志文件获取详细错误信息"
