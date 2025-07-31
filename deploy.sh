#!/bin/bash

# 远程部署脚本 - 通过SSH部署到树莓派3B
# 使用方法: ./deploy.sh [树莓派IP地址] [用户名] [部署模式]
# 部署模式: systemd (默认) 或 openwrt

set -e

# 显示帮助信息
show_help() {
    echo "Pi3B Display 远程部署脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [IP地址] [用户名] [部署模式]"
    echo ""
    echo "参数:"
    echo "  IP地址      目标设备IP地址 (默认: 192.168.1.1)"
    echo "  用户名      SSH用户名 (默认: root)"
    echo "  部署模式    systemd|openwrt (默认: systemd)"
    echo ""
    echo "示例:"
    echo "  $0 192.168.1.100 root systemd    # 标准Linux系统"
    echo "  $0 192.168.1.100 root openwrt    # OpenWrt系统"
    echo "  $0 192.168.1.100                 # 使用默认用户名和部署模式"
    echo ""
    echo "说明:"
    echo "  systemd模式: 适用于Ubuntu/Debian等标准Linux发行版"
    echo "  openwrt模式: 适用于OpenWrt系统，使用虚拟环境和init.d服务"
}

# 检查帮助参数
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

# 默认配置
DEFAULT_PI_HOST="192.168.1.1"
DEFAULT_PI_USER="root"
PROJECT_NAME="pi3b_screen"
REMOTE_DIR="/tmp/$PROJECT_NAME"

# 解析命令行参数
PI_HOST="${1:-$DEFAULT_PI_HOST}"
PI_USER="${2:-$DEFAULT_PI_USER}"
DEPLOY_MODE="${3:-systemd}"

# 验证部署模式
if [[ "$DEPLOY_MODE" != "systemd" && "$DEPLOY_MODE" != "openwrt" ]]; then
    echo "错误: 无效的部署模式 '$DEPLOY_MODE'"
    echo "支持的模式: systemd, openwrt"
    echo ""
    show_help
    exit 1
fi

echo "========================================="
echo "Pi3B Display 远程部署脚本"
echo "========================================="
echo "目标主机: $PI_USER@$PI_HOST"
echo "远程目录: $REMOTE_DIR"
echo "部署模式: $DEPLOY_MODE"
echo ""

if [ "$DEPLOY_MODE" = "openwrt" ]; then
    echo "注意: OpenWrt模式将使用虚拟环境部署，不依赖systemd"
    echo "建议使用LuCI界面管理服务启动项"
    echo ""
fi

# 检查必要文件
if [ ! -f "src/main.py" ]; then
    echo "错误: 找不到 src/main.py，请在项目根目录运行此脚本"
    exit 1
fi

if [ ! -f "scripts/install.sh" ]; then
    echo "错误: 找不到 scripts/install.sh"
    exit 1
fi

# 测试SSH连接
echo "测试SSH连接..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$PI_USER@$PI_HOST" "echo 'SSH连接成功'" 2>/dev/null; then
    echo "错误: 无法连接到 $PI_USER@$PI_HOST"
    echo "请检查:"
    echo "1. IP地址是否正确"
    echo "2. SSH服务是否运行"
    echo "3. 用户名和密钥是否正确"
    exit 1
fi

# 创建项目压缩包
echo "创建项目压缩包..."
TEMP_TAR="/tmp/${PROJECT_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz"

# 根据部署模式选择要包含的文件
if [ "$DEPLOY_MODE" = "openwrt" ]; then
    echo "正在为OpenWrt模式打包（排除冗余文件）..."
    tar -czf "$TEMP_TAR" \
        --exclude='.git' \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        --exclude='.DS_Store' \
        --exclude='test_*.py' \
        --exclude='deploy.sh' \
        --exclude='scripts/pi3b_display.service' \
        src/ scripts/install_openwrt.sh requirements.txt README.md OPENWRT_DEPLOY.md 2>/dev/null || true
else
    echo "正在为标准Linux/systemd模式打包..."
    tar -czf "$TEMP_TAR" \
        --exclude='.git' \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        --exclude='.DS_Store' \
        --exclude='test_*.py' \
        --exclude='deploy.sh' \
        src/ scripts/ requirements.txt README.md DEPLOY.md 2>/dev/null || true
fi

echo "✓ 项目压缩包已创建: $TEMP_TAR"

# 传输文件到树莓派
echo "传输文件到树莓派..."
scp "$TEMP_TAR" "$PI_USER@$PI_HOST:/tmp/"
REMOTE_TAR="/tmp/$(basename $TEMP_TAR)"

echo "✓ 文件传输完成"

# 清理本地临时文件
rm -f "$TEMP_TAR"

# 远程执行部署
echo "在远程主机上执行部署..."
if [ "$DEPLOY_MODE" = "openwrt" ]; then
    ssh "$PI_USER@$PI_HOST" << EOF
set -e

echo "解压项目文件..."
cd /tmp
tar -xzf "$(basename $REMOTE_TAR)"
cd $PROJECT_NAME

echo "设置执行权限..."
chmod +x scripts/install_openwrt.sh

echo "执行OpenWrt安装脚本..."
./scripts/install_openwrt.sh

echo "清理临时文件..."
rm -f "$REMOTE_TAR"

echo ""
echo "========================================="
echo "OpenWrt 远程部署完成!"
echo "========================================="
echo ""
echo "服务管理命令："
echo "  查看状态: /etc/init.d/pi3b_display status"
echo "  启动服务: /etc/init.d/pi3b_display start"
echo "  停止服务: /etc/init.d/pi3b_display stop"
echo "  重启服务: /etc/init.d/pi3b_display restart"
echo ""
echo "LuCI界面管理："
echo "  访问 http://$PI_HOST 登录管理界面"
echo "  导航到 系统 -> 启动项 管理服务"
echo ""
echo "查看日志："
echo "  tail -f /var/log/pi3b_display.log"
echo "  logread | grep pi3b_display"
EOF
else
    ssh "$PI_USER@$PI_HOST" << EOF
set -e

echo "解压项目文件..."
cd /tmp
tar -xzf "$(basename $REMOTE_TAR)"
cd $PROJECT_NAME

echo "设置执行权限..."
chmod +x scripts/*.sh

echo "执行安装脚本..."
./scripts/install.sh

echo "清理临时文件..."
rm -f "$REMOTE_TAR"

echo ""
echo "========================================="
echo "远程部署完成!"
echo "========================================="
echo ""
echo "检查服务状态:"
systemctl status pi3b_display --no-pager || true
echo ""
echo "如需查看实时日志，请运行:"
echo "  ssh $PI_USER@$PI_HOST 'journalctl -u pi3b_display -f'"
EOF
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 部署成功完成!"
    echo ""
    if [ "$DEPLOY_MODE" = "openwrt" ]; then
        echo "OpenWrt 常用远程命令:"
        echo "  查看服务状态: ssh $PI_USER@$PI_HOST '/etc/init.d/pi3b_display status'"
        echo "  启动服务:     ssh $PI_USER@$PI_HOST '/etc/init.d/pi3b_display start'"
        echo "  停止服务:     ssh $PI_USER@$PI_HOST '/etc/init.d/pi3b_display stop'"
        echo "  重启服务:     ssh $PI_USER@$PI_HOST '/etc/init.d/pi3b_display restart'"
        echo "  查看日志:     ssh $PI_USER@$PI_HOST 'tail -f /var/log/pi3b_display.log'"
        echo ""
        echo "LuCI界面: http://$PI_HOST (系统 -> 启动项)"
    else
        echo "常用远程命令:"
        echo "  查看服务状态: ssh $PI_USER@$PI_HOST 'systemctl status pi3b_display'"
        echo "  查看实时日志: ssh $PI_USER@$PI_HOST 'journalctl -u pi3b_display -f'"
        echo "  重启服务:     ssh $PI_USER@$PI_HOST 'systemctl restart pi3b_display'"
        echo "  停止服务:     ssh $PI_USER@$PI_HOST 'systemctl stop pi3b_display'"
    fi
else
    echo ""
    echo "✗ 部署失败，请检查错误信息"
    exit 1
fi
