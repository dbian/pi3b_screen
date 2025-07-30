#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
测试system_monitor模块（不依赖psutil版本）
"""

import sys
import os

# 添加src目录到Python路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from system_monitor import SystemMonitor

def test_system_monitor():
    """测试系统监控功能"""
    print("=== 测试SystemMonitor（无psutil版本） ===")
    
    monitor = SystemMonitor()
    
    print("\n1. 测试WAN IP获取:")
    wan_ip = monitor.get_wan_ip()
    print(f"   WAN IP: {wan_ip}")
    
    print("\n2. 测试内存使用率:")
    memory_usage = monitor.get_memory_usage()
    print(f"   内存使用率: {memory_usage:.1f}%")
    
    print("\n3. 测试CPU使用率:")
    cpu_usage = monitor.get_cpu_usage()
    print(f"   CPU使用率: {cpu_usage:.1f}%")
    
    print("\n4. 测试温度获取:")
    temperature = monitor.get_temperature()
    print(f"   CPU温度: {temperature:.1f}°C")
    
    print("\n5. 测试磁盘使用情况:")
    root_usage, tmp_usage, available_space = monitor.get_disk_usage()
    print(f"   根分区使用率: {root_usage:.1f}%")
    print(f"   临时分区使用率: {tmp_usage:.1f}%")
    print(f"   可用空间: {available_space}")
    
    print("\n6. 测试网络连接数:")
    connections = monitor.get_connection_count()
    print(f"   已建立连接数: {connections}")
    
    print("\n7. 测试网络速度:")
    upload, download = monitor.get_network_speed()
    print(f"   上传速度: {upload}")
    print(f"   下载速度: {download}")
    
    print("\n8. 测试设备统计:")
    lan_devices, wifi_devices, total_devices = monitor.get_device_count()
    print(f"   LAN设备: {lan_devices}")
    print(f"   WiFi设备: {wifi_devices}")
    print(f"   总设备数: {total_devices}")
    
    print("\n9. 测试完整系统信息:")
    info = monitor.get_all_system_info()
    print("   完整信息:")
    for key, value in info.items():
        print(f"     {key}: {value}")

if __name__ == "__main__":
    test_system_monitor()
