#!/bin/bash

# 虚拟环境打包脚本 - 为OpenWrt部署准备虚拟环境
# 使用方法: ./prepare_venv.sh

set -e

PROJECT_NAME="pi3b_screen"
VENV_NAME="pi3b_venv"
PACKAGE_NAME="${PROJECT_NAME}_venv_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "========================================="
echo "Pi3B Display 虚拟环境打包脚本"
echo "========================================="
echo "此脚本将创建虚拟环境并打包用于OpenWrt部署"
echo ""

# 检查Python版本
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "检测到Python版本: $PYTHON_VERSION"

if [[ $(echo "$PYTHON_VERSION < 3.6" | bc -l) -eq 1 ]]; then
    echo "错误: 需要Python 3.6或更高版本"
    exit 1
fi

# 检查必要文件
if [ ! -f "requirements.txt" ]; then
    echo "错误: 找不到requirements.txt文件"
    exit 1
fi

if [ ! -d "src" ]; then
    echo "错误: 找不到src目录"
    exit 1
fi

# 清理旧的虚拟环境
if [ -d "$VENV_NAME" ]; then
    echo "清理现有虚拟环境..."
    rm -rf "$VENV_NAME"
fi

# 创建虚拟环境
echo "创建Python虚拟环境..."
python3 -m venv "$VENV_NAME"

# 激活虚拟环境
echo "激活虚拟环境..."
source "$VENV_NAME/bin/activate"

# 升级pip
echo "升级pip..."
pip install --upgrade pip

# 安装依赖
echo "安装项目依赖..."
pip install -r requirements.txt

# 验证安装
echo "验证依赖安装..."
pip list

# 清理缓存
echo "清理pip缓存..."
pip cache purge 2>/dev/null || true

# 退出虚拟环境
deactivate

# 清理Python缓存
echo "清理Python缓存..."
find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true

# 创建部署包
echo "创建部署包..."
tar -czf "$PACKAGE_NAME" \
    --exclude='.git' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    --exclude='test_*.py' \
    --exclude='deploy.sh' \
    --exclude='prepare_venv.sh' \
    --exclude='scripts/pi3b_display.service' \
    "$VENV_NAME/" src/ scripts/install_openwrt.sh requirements.txt OPENWRT_DEPLOY.md

echo ""
echo "========================================="
echo "虚拟环境打包完成!"
echo "========================================="
echo "包文件名: $PACKAGE_NAME"
echo "包大小: $(du -h "$PACKAGE_NAME" | cut -f1)"
echo ""
echo "部署步骤:"
echo "1. 传输到OpenWrt设备:"
echo "   scp $PACKAGE_NAME root@192.168.1.1:/tmp/"
echo ""
echo "2. 在OpenWrt设备上解压并安装:"
echo "   ssh root@192.168.1.1"
echo "   cd /opt"
echo "   tar -xzf /tmp/$PACKAGE_NAME"
echo "   ./scripts/install_openwrt.sh"
echo ""
echo "3. 或者使用远程部署脚本:"
echo "   ./deploy.sh 192.168.1.1 root openwrt"
echo ""

# 清理虚拟环境
echo "清理临时虚拟环境..."
rm -rf "$VENV_NAME"

echo "完成!"