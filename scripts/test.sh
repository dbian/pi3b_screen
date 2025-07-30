#!/bin/bash

# 测试脚本 - 验证项目功能

set -e

PROJECT_DIR="/opt/pi3b_display"

echo "========================================="
echo "Pi3B Display 功能测试"
echo "========================================="

# 检查项目文件
echo "1. 检查项目文件..."
files_to_check=(
    "$PROJECT_DIR/src/main.py"
    "$PROJECT_DIR/src/config.py"
    "$PROJECT_DIR/src/display_controller.py"
    "$PROJECT_DIR/src/system_monitor.py"
    "/etc/systemd/system/pi3b_display.service"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file (缺失)"
    fi
done

# 检查Python依赖
echo ""
echo "2. 检查Python依赖..."
cd "$PROJECT_DIR/src"

dependencies=("luma.oled" "psutil" "requests" "netifaces")
for dep in "${dependencies[@]}"; do
    if python3 -c "import $dep" 2>/dev/null; then
        echo "✓ $dep"
    else
        echo "✗ $dep (未安装)"
    fi
done

# 检查i2c设备
echo ""
echo "3. 检查i2c设备..."
if command -v i2cdetect >/dev/null 2>&1; then
    echo "i2c设备扫描:"
    i2cdetect -y 1 2>/dev/null || echo "无法扫描i2c设备"
else
    echo "✗ i2cdetect 命令不可用"
fi

# 检查服务状态
echo ""
echo "4. 检查服务状态..."
if systemctl is-active --quiet pi3b_display; then
    echo "✓ 服务正在运行"
    echo "  状态: $(systemctl is-active pi3b_display)"
    echo "  启用: $(systemctl is-enabled pi3b_display)"
else
    echo "✗ 服务未运行"
    echo "  状态: $(systemctl is-active pi3b_display)"
fi

# 测试系统监控功能
echo ""
echo "5. 测试系统监控功能..."
python3 << 'EOF'
import sys
import os
sys.path.append('/opt/pi3b_display/src')

try:
    from system_monitor import SystemMonitor
    monitor = SystemMonitor()
    
    print("✓ SystemMonitor 初始化成功")
    
    # 测试各个功能
    info = monitor.get_all_system_info()
    
    print(f"  WAN IP: {info['wan_ip']}")
    print(f"  CPU使用率: {info['cpu_usage']:.1f}%")
    print(f"  内存使用率: {info['memory_usage']:.1f}%")
    print(f"  连接数: {info['connections']}")
    print(f"  设备总数: {info['total_devices']}")
    
    print("✓ 系统监控功能正常")
    
except Exception as e:
    print(f"✗ 系统监控功能异常: {e}")
EOF

# 测试显示功能（需要显示屏连接）
echo ""
echo "6. 测试显示功能..."
timeout 10s python3 << 'EOF' || echo "显示测试超时或失败"
import sys
sys.path.append('/opt/pi3b_display/src')

try:
    from display_controller import DisplayController
    display = DisplayController()
    
    print("✓ DisplayController 初始化成功")
    
    # 显示测试消息
    display.display_text([
        "Test Message",
        "Display Working",
        "Connection OK"
    ], "Test")
    
    print("✓ 显示功能正常")
    
    # 清空显示
    import time
    time.sleep(2)
    display.clear()
    
except Exception as e:
    print(f"✗ 显示功能异常: {e}")
    print("  请检查i2c连接和显示屏硬件")
EOF

# 检查日志
echo ""
echo "7. 检查日志文件..."
LOG_FILE="/var/log/pi3b_display.log"
if [ -f "$LOG_FILE" ]; then
    echo "✓ 日志文件存在: $LOG_FILE"
    echo "最近的日志:"
    tail -5 "$LOG_FILE" | while read line; do
        echo "  $line"
    done
else
    echo "✗ 日志文件不存在"
fi

echo ""
echo "========================================="
echo "测试完成"
echo "========================================="
echo ""
echo "如果发现问题，请查看详细日志:"
echo "  journalctl -u pi3b_display -n 20"
echo "  tail -f /var/log/pi3b_display.log"
