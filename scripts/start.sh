#!/bin/bash

# Pi3B Display 启动脚本

PROJECT_DIR="/opt/pi3b_display"
LOG_FILE="/var/log/pi3b_display.log"

echo "启动 Pi3B Display 服务..."

# 检查项目目录是否存在
if [ ! -d "$PROJECT_DIR" ]; then
    echo "错误: 项目目录不存在: $PROJECT_DIR"
    echo "请先运行安装脚本: ./install.sh"
    exit 1
fi

# 检查Python脚本是否存在
if [ ! -f "$PROJECT_DIR/src/main.py" ]; then
    echo "错误: 主程序不存在: $PROJECT_DIR/src/main.py"
    exit 1
fi

# 切换到项目目录
cd "$PROJECT_DIR/src"

# 启动程序
echo "正在启动程序..."
echo "日志文件: $LOG_FILE"
echo "按 Ctrl+C 停止程序"
echo ""

python3 main.py
