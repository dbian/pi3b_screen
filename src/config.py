#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
配置文件
"""

# 显示屏配置
DISPLAY_CONFIG = {
    'interface': 'i2c',
    'port': 1,  # i2c端口号，通常为1
    'address': 0x3C,  # 12864 OLED的i2c地址，通常为0x3C或0x3D
    'width': 128,
    'height': 64,
    'rotate': 0  # 旋转角度：0, 1, 2, 3
}

# 刷新间隔配置（秒）
REFRESH_INTERVALS = {
    'network_speed': 2,  # 网络速度更新间隔
    'system_info': 5,    # 系统信息更新间隔
    'page_switch': 8     # 页面切换间隔
}

# 网络接口配置
NETWORK_CONFIG = {
    'wan_interface': 'eth0',  # WAN接口名称，根据实际情况调整
    'lan_interface': 'br-lan',  # LAN接口名称
    'wifi_interface': 'wlan0'   # WiFi接口名称
}

# 显示页面配置
DISPLAY_PAGES = [
    'network_info',     # 网络信息页面
    'system_status',    # 系统状态页面
    'device_count',     # 设备统计页面
    'storage_info'      # 存储信息页面
]

# 字体配置
FONT_CONFIG = {
    'small_font_size': 10,
    'medium_font_size': 12,
    'large_font_size': 14
}

# 日志配置
LOG_CONFIG = {
    'level': 'INFO',
    'file': '/var/log/pi3b_display.log',
    'max_size': 1024 * 1024,  # 1MB
    'backup_count': 3
}
