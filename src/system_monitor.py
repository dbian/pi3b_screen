#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
系统监控模块
负责获取系统状态信息
适用于OpenWrt环境，不依赖psutil
"""

import time
import subprocess
import requests
import logging
import re
import os
from config import NETWORK_CONFIG

class SystemMonitor:
    def __init__(self):
        """初始化系统监控器"""
        self.last_network_stats = None
        self.last_time = time.time()
        
    def get_network_stats(self):
        """获取网络统计信息"""
        try:
            # 从/proc/net/dev读取网络统计
            with open('/proc/net/dev', 'r') as f:
                lines = f.readlines()
            
            total_rx_bytes = 0
            total_tx_bytes = 0
            
            for line in lines[2:]:  # 跳过前两行标题
                parts = line.split()
                if len(parts) >= 10:
                    # 排除lo接口
                    interface = parts[0].rstrip(':')
                    if interface != 'lo':
                        total_rx_bytes += int(parts[1])
                        total_tx_bytes += int(parts[9])
            
            return total_rx_bytes, total_tx_bytes
        except Exception as e:
            logging.error(f"获取网络统计失败: {e}")
            return 0, 0
        
    def get_wan_ip(self):
        """获取WAN口IP地址"""
            
        try:
            # 尝试从路由表获取默认网关接口的IP
            result = subprocess.run(['ip', 'route', 'get', '8.8.8.8'], 
                                  capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                # 解析输出获取源IP
                match = re.search(r'src (\d+\.\d+\.\d+\.\d+)', result.stdout)
                if match:
                    return match.group(1)
        except:
            pass
            
        try:
            # 尝试从网络接口获取IP
            for interface in [NETWORK_CONFIG['wan_interface'], 'eth0', 'pppoe-wan', 'br-lan']:
                try:
                    # 使用ip命令获取接口IP地址
                    result = subprocess.run(['ip', 'addr', 'show', interface], 
                                          capture_output=True, text=True, timeout=5)
                    if result.returncode == 0:
                        # 解析IP地址
                        for line in result.stdout.split('\n'):
                            if 'inet ' in line and not '127.0.0.1' in line:
                                match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', line)
                                if match:
                                    return match.group(1)
                except:
                    continue
        except:
            pass
            
        return "N/A"
        
    def get_network_speed(self):
        """获取网络上下行速度"""
        try:
            current_time = time.time()
            current_rx, current_tx = self.get_network_stats()
            
            if self.last_network_stats is None:
                self.last_network_stats = (current_rx, current_tx)
                self.last_time = current_time
                return "0 KB/s", "0 KB/s"
                
            time_delta = current_time - self.last_time
            if time_delta <= 0:
                return "0 KB/s", "0 KB/s"
                
            # 计算上传速度
            upload_bytes = current_tx - self.last_network_stats[1]
            upload_speed = upload_bytes / time_delta
            
            # 计算下载速度
            download_bytes = current_rx - self.last_network_stats[0]
            download_speed = download_bytes / time_delta
            
            # 更新记录
            self.last_network_stats = (current_rx, current_tx)
            self.last_time = current_time
            
            # 格式化速度显示
            upload_str = self.format_speed(upload_speed)
            download_str = self.format_speed(download_speed)
            
            return upload_str, download_str
            
        except Exception as e:
            logging.error(f"获取网络速度失败: {e}")
            return "Error", "Error"
            
    def format_speed(self, speed_bytes):
        """格式化速度显示"""
        if speed_bytes < 1024:
            return f"{speed_bytes:.0f} B/s"
        elif speed_bytes < 1024 * 1024:
            return f"{speed_bytes/1024:.1f} KB/s"
        else:
            return f"{speed_bytes/(1024*1024):.1f} MB/s"
            
    def get_memory_usage(self):
        """获取内存使用率"""
        try:
            # 从/proc/meminfo读取内存信息
            with open('/proc/meminfo', 'r') as f:
                lines = f.readlines()
            
            mem_info = {}
            for line in lines:
                if ':' in line:
                    key, value = line.split(':', 1)
                    # 提取数字部分（KB）
                    value = int(value.strip().split()[0])
                    mem_info[key] = value
            
            total = mem_info.get('MemTotal', 0)
            available = mem_info.get('MemAvailable', 0)
            if available == 0:
                # 如果没有MemAvailable，使用MemFree + Buffers + Cached
                free = mem_info.get('MemFree', 0)
                buffers = mem_info.get('Buffers', 0)
                cached = mem_info.get('Cached', 0)
                available = free + buffers + cached
            
            if total > 0:
                used_percent = ((total - available) / total) * 100
                return used_percent
            return 0.0
            
        except Exception as e:
            logging.error(f"获取内存使用率失败: {e}")
            return 0.0
            
    def get_cpu_usage(self):
        """获取CPU使用率"""
        try:
            # 读取两次/proc/stat来计算CPU使用率
            def get_cpu_times():
                with open('/proc/stat', 'r') as f:
                    line = f.readline()
                times = [int(x) for x in line.split()[1:]]
                return times
            
            # 第一次读取
            times1 = get_cpu_times()
            time.sleep(0.1)  # 短暂等待
            # 第二次读取
            times2 = get_cpu_times()
            
            # 计算时间差
            deltas = [t2 - t1 for t1, t2 in zip(times1, times2)]
            total_delta = sum(deltas)
            
            if total_delta == 0:
                return 0.0
                
            # idle时间是第4个值
            idle_delta = deltas[3] if len(deltas) > 3 else 0
            cpu_usage = 100.0 * (1.0 - idle_delta / total_delta)
            
            return max(0.0, min(100.0, cpu_usage))
            
        except Exception as e:
            logging.error(f"获取CPU使用率失败: {e}")
            return 0.0
            
    def get_temperature(self):
        """获取CPU温度"""
        try:
            # 树莓派CPU温度读取
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = int(f.read().strip()) / 1000.0
                return temp
        except:
            try:
                # 备选方法
                result = subprocess.run(['vcgencmd', 'measure_temp'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    temp_str = result.stdout.strip()
                    temp = float(temp_str.split('=')[1].replace('\'C', ''))
                    return temp
            except:
                pass
        return 0.0
        
    def get_disk_usage(self):
        """获取磁盘使用情况"""
        try:
            # 使用df命令获取磁盘使用情况
            result = subprocess.run(['df', '/'], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                if len(lines) >= 2:
                    parts = lines[1].split()
                    if len(parts) >= 5:
                        # df输出格式: 文件系统 1K-块 已用 可用 已用% 挂载点
                        used_percent = int(parts[4].rstrip('%'))
                        available_kb = int(parts[3])
                        available_gb = available_kb / (1024 * 1024)
                        root_usage = float(used_percent)
                    else:
                        root_usage = 0.0
                        available_gb = 0.0
                else:
                    root_usage = 0.0
                    available_gb = 0.0
            else:
                root_usage = 0.0
                available_gb = 0.0
            
            # 尝试获取/tmp使用情况
            tmp_usage = 0.0
            try:
                result = subprocess.run(['df', '/tmp'], capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    if len(lines) >= 2:
                        parts = lines[1].split()
                        if len(parts) >= 5:
                            tmp_usage = float(parts[4].rstrip('%'))
            except:
                pass
                
            available_space = f"{available_gb:.1f}GB"
            return root_usage, tmp_usage, available_space
            
        except Exception as e:
            logging.error(f"获取磁盘使用情况失败: {e}")
            return 0.0, 0.0, "Error"
            
    def get_connection_count(self):
        """获取网络连接数量"""
        try:
            # 使用netstat或ss命令获取连接数
            try:
                # 优先使用ss命令（更现代）
                result = subprocess.run(['ss', '-t', '-n', 'state', 'established'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    # 去掉标题行
                    connections = [line for line in lines if line.strip() and not line.startswith('State')]
                    return len(connections)
            except:
                pass
                
            # 备选方案：使用netstat
            try:
                result = subprocess.run(['netstat', '-tn'], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    lines = result.stdout.strip().split('\n')
                    established_count = 0
                    for line in lines:
                        if 'ESTABLISHED' in line:
                            established_count += 1
                    return established_count
            except:
                pass
                
            # 最后备选：读取/proc/net/tcp
            try:
                with open('/proc/net/tcp', 'r') as f:
                    lines = f.readlines()
                # 状态01表示ESTABLISHED
                established_count = 0
                for line in lines[1:]:  # 跳过标题行
                    parts = line.split()
                    if len(parts) >= 4 and parts[3] == '01':
                        established_count += 1
                return established_count
            except:
                pass
                
            return 0
        except Exception as e:
            logging.error(f"获取连接数量失败: {e}")
            return 0
            
    def get_device_count(self):
        """获取连接设备数量"""
        lan_devices = 0
        wifi_devices = 0
        
        try:
            # 通过ARP表获取LAN设备数量
            result = subprocess.run(['arp', '-a'], capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                arp_lines = result.stdout.strip().split('\n')
                lan_devices = len([line for line in arp_lines if line.strip()])
        except:
            pass
            
        try:
            # 尝试获取WiFi设备数量（如果有WiFi接口）
            result = subprocess.run(['iw', 'dev', NETWORK_CONFIG['wifi_interface'], 'station', 'dump'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                stations = result.stdout.count('Station ')
                wifi_devices = stations
        except:
            pass
            
        # 如果ARP表方法失败，尝试其他方法
        if lan_devices == 0:
            try:
                # 通过DHCP租约文件获取设备数量
                with open('/var/lib/dhcp/dhcpd.leases', 'r') as f:
                    content = f.read()
                    # 简单计算活跃租约数量
                    lan_devices = content.count('lease ') // 2  # 粗略估计
            except:
                pass
                
        total_devices = lan_devices + wifi_devices
        return lan_devices, wifi_devices, total_devices
        
    def get_all_system_info(self):
        """获取所有系统信息"""
        info = {}
        
        # 网络信息
        info['wan_ip'] = self.get_wan_ip()
        upload, download = self.get_network_speed()
        info['upload_speed'] = upload
        info['download_speed'] = download
        info['connections'] = self.get_connection_count()
        
        # 系统状态
        info['cpu_usage'] = self.get_cpu_usage()
        info['memory_usage'] = self.get_memory_usage()
        info['temperature'] = self.get_temperature()
        
        # 设备统计
        lan_devices, wifi_devices, total_devices = self.get_device_count()
        info['lan_devices'] = lan_devices
        info['wifi_devices'] = wifi_devices
        info['total_devices'] = total_devices
        
        # 存储信息
        root_usage, tmp_usage, available_space = self.get_disk_usage()
        info['root_usage'] = root_usage
        info['tmp_usage'] = tmp_usage
        info['available_space'] = available_space
        
        return info
