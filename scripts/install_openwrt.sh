#!/bin/sh

# OpenWrt 专用安装脚本 - 使用虚拟环境部署
# 适用于没有systemd的OpenWrt系统

set -e

PROJECT_NAME="pi3b_display"
PROJECT_DIR="/opt"
VENV_DIR="$PROJECT_DIR/pi3b_venv"
SRC_DIR="$PROJECT_DIR/src"
SERVICE_NAME="pi3b_display"
LOG_FILE="/var/log/pi3b_display.log"

echo "========================================="
echo "Pi3B Display OpenWrt 安装脚本"
echo "========================================="

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 请使用root权限运行此脚本"
    exit 1
fi

# 检查系统
if ! grep -q "OpenWrt" /etc/os-release 2>/dev/null; then
    echo "警告: 此脚本专为OpenWrt系统设计"
    read -p "是否继续安装? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 更新软件包列表
echo "更新软件包列表..."
opkg update

# 安装必要的系统包
echo "安装系统依赖包..."
opkg install python3 python3-pip python3-venv i2c-tools kmod-i2c-core kmod-i2c-gpio

# 检查i2c模块
echo "检查i2c接口..."
if ! lsmod | grep -q i2c; then
    echo "加载i2c模块..."
    modprobe i2c-dev 2>/dev/null || true
    modprobe i2c-bcm2708 2>/dev/null || true
fi

# 创建项目目录
echo "创建项目目录..."
mkdir -p "$PROJECT_DIR"
mkdir -p "$SRC_DIR"

# 检查是否已有虚拟环境
if [ -d "$VENV_DIR" ]; then
    echo "发现现有虚拟环境，是否删除重建? (y/N): "
    read -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$VENV_DIR"
    fi
fi

# 创建虚拟环境
if [ ! -d "$VENV_DIR" ]; then
    echo "创建Python虚拟环境..."
    python3 -m venv "$VENV_DIR"
fi

# 复制项目文件
echo "复制项目文件..."
if [ -d "src" ]; then
    cp -r src/* "$SRC_DIR/"
else
    echo "错误: 找不到src目录，请在项目根目录运行此脚本"
    exit 1
fi

# 设置权限
chmod +x "$SRC_DIR/main.py" 2>/dev/null || true

# 激活虚拟环境并安装依赖
echo "安装Python依赖包..."
cd "$PROJECT_DIR"

# 升级pip
"$VENV_DIR/bin/pip" install --upgrade pip

# 安装依赖包
if [ -f "$SRC_DIR/../requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install -r "$SRC_DIR/../requirements.txt"
elif [ -f "requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install -r requirements.txt
else
    echo "手动安装Python包..."
    "$VENV_DIR/bin/pip" install luma.oled requests
fi

# 创建init.d启动脚本
echo "创建OpenWrt启动脚本..."
cat > "/etc/init.d/$SERVICE_NAME" << EOF
#!/bin/sh /etc/rc.common

# Pi3B Display Service for OpenWrt
# /etc/init.d/pi3b_display

START=99
STOP=10

USE_PROCD=1
PROG=$VENV_DIR/bin/python3
ARGS="$SRC_DIR/main.py"
PIDFILE=/var/run/pi3b_display.pid

start_service() {
    echo "Starting Pi3B Display Service..."
    
    # 检查虚拟环境
    if [ ! -f "\$PROG" ]; then
        echo "错误: 找不到Python虚拟环境"
        return 1
    fi
    
    # 检查主程序
    if [ ! -f "\$ARGS" ]; then
        echo "错误: 找不到主程序文件"
        return 1
    fi
    
    procd_open_instance
    procd_set_param command \$PROG \$ARGS
    procd_set_param pidfile \$PIDFILE
    procd_set_param respawn 3600 5 5
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param user root
    procd_close_instance
}

stop_service() {
    echo "Stopping Pi3B Display Service..."
    service_stop \$PROG
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f "\$PIDFILE" ]; then
        PID=\$(cat \$PIDFILE)
        if kill -0 "\$PID" 2>/dev/null; then
            echo "Pi3B Display Service is running (PID: \$PID)"
            return 0
        else
            echo "Pi3B Display Service is not running (stale PID file)"
            rm -f "\$PIDFILE"
            return 1
        fi
    else
        echo "Pi3B Display Service is not running"
        return 1
    fi
}
EOF

# 设置启动脚本权限
chmod +x "/etc/init.d/$SERVICE_NAME"

# 创建日志文件
echo "设置日志文件..."
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# 启用服务
echo "启用服务自启动..."
"/etc/init.d/$SERVICE_NAME" enable

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
"/etc/init.d/$SERVICE_NAME" start

# 检查服务状态
sleep 3
if "/etc/init.d/$SERVICE_NAME" status >/dev/null 2>&1; then
    echo "✓ 服务启动成功"
else
    echo "✗ 服务启动失败"
    echo "查看服务状态: /etc/init.d/$SERVICE_NAME status"
    echo "查看日志: tail -f $LOG_FILE"
fi

echo ""
echo "========================================="
echo "OpenWrt 安装完成!"
echo "========================================="
echo "项目目录: $SRC_DIR"
echo "虚拟环境: $VENV_DIR"
echo "服务名称: $SERVICE_NAME"
echo "日志文件: $LOG_FILE"
echo ""
echo "常用命令:"
echo "  查看服务状态: /etc/init.d/$SERVICE_NAME status"
echo "  启动服务:     /etc/init.d/$SERVICE_NAME start"
echo "  停止服务:     /etc/init.d/$SERVICE_NAME stop"
echo "  重启服务:     /etc/init.d/$SERVICE_NAME restart"
echo "  查看日志:     tail -f $LOG_FILE"
echo "  系统日志:     logread | grep pi3b_display"
echo ""
echo "LuCI界面配置："
echo "  1. 访问 http://路由器IP 登录LuCI"
echo "  2. 导航到 系统 -> 启动项"
echo "  3. 可在此处管理服务的启用/禁用状态"
echo ""
echo "如果显示屏没有显示内容，请检查:"
echo "1. i2c接口是否正确连接"
echo "2. i2c地址是否正确 (通常为0x3C或0x3D)"
echo "3. 查看日志文件获取详细错误信息"

# 清理安装过程中的临时文件
echo "清理临时文件..."
find "$PROJECT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find "$PROJECT_DIR" -name "*.pyc" -delete 2>/dev/null || true