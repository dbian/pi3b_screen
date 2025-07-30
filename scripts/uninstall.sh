#!/bin/bash

# Pi3B Display 卸载脚本

set -e

PROJECT_NAME="pi3b_display"
PROJECT_DIR="/opt/$PROJECT_NAME"
SERVICE_NAME="$PROJECT_NAME.service"
LOG_FILE="/var/log/pi3b_display.log"

echo "========================================="
echo "Pi3B Display 卸载脚本"
echo "========================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用root权限运行此脚本"
    echo "使用: sudo $0"
    exit 1
fi

# 停止并禁用服务
echo "停止服务..."
if systemctl is-active --quiet $SERVICE_NAME; then
    systemctl stop $SERVICE_NAME
    echo "✓ 服务已停止"
fi

if systemctl is-enabled --quiet $SERVICE_NAME; then
    systemctl disable $SERVICE_NAME
    echo "✓ 服务自启动已禁用"
fi

# 删除服务文件
echo "删除服务文件..."
if [ -f "/etc/systemd/system/$SERVICE_NAME" ]; then
    rm -f "/etc/systemd/system/$SERVICE_NAME"
    systemctl daemon-reload
    echo "✓ 服务文件已删除"
fi

# 删除项目目录
echo "删除项目目录..."
if [ -d "$PROJECT_DIR" ]; then
    rm -rf "$PROJECT_DIR"
    echo "✓ 项目目录已删除: $PROJECT_DIR"
fi

# 删除日志文件（可选）
read -p "是否删除日志文件? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
        echo "✓ 日志文件已删除: $LOG_FILE"
    fi
fi

echo ""
echo "========================================="
echo "卸载完成!"
echo "========================================="
echo ""
echo "注意: Python依赖包未被删除，如需删除请手动执行:"
echo "  pip3 uninstall luma.oled psutil requests netifaces"
