#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
显示控制器模块
负责控制12864 OLED显示屏的显示内容
"""

import time
import logging
from luma.core.interface.serial import i2c
from luma.core.render import canvas
from luma.oled.device import ssd1306
from PIL import Image, ImageDraw, ImageFont
from config import DISPLAY_CONFIG, FONT_CONFIG

class DisplayController:
    def __init__(self):
        """初始化显示控制器"""
        self.device = None
        self.font_small = None
        self.font_medium = None
        self.font_large = None
        self.init_display()
        self.init_fonts()
        
    def init_display(self):
        """初始化显示设备"""
        try:
            # 创建i2c接口
            serial = i2c(port=DISPLAY_CONFIG['port'], 
                        address=DISPLAY_CONFIG['address'])
            
            # 创建SSD1306设备实例
            self.device = ssd1306(serial, 
                                width=DISPLAY_CONFIG['width'],
                                height=DISPLAY_CONFIG['height'],
                                rotate=DISPLAY_CONFIG['rotate'])
            
            # 清空显示屏
            self.clear()
            logging.info("显示设备初始化成功")
            
        except Exception as e:
            logging.error(f"显示设备初始化失败: {e}")
            raise
            
    def init_fonts(self):
        """初始化字体"""
        try:
            # 尝试加载默认字体
            self.font_small = ImageFont.load_default()
            self.font_medium = ImageFont.load_default()
            self.font_large = ImageFont.load_default()
            
            # 如果有TrueType字体文件，可以使用以下代码
            # self.font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", FONT_CONFIG['small_font_size'])
            # self.font_medium = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", FONT_CONFIG['medium_font_size'])
            # self.font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", FONT_CONFIG['large_font_size'])
            
        except Exception as e:
            logging.warning(f"字体加载失败，使用默认字体: {e}")
            
    def clear(self):
        """清空显示屏"""
        if self.device:
            with canvas(self.device) as draw:
                draw.rectangle(self.device.bounding_box, outline=0, fill=0)
                
    def display_text(self, lines, title=None):
        """显示文本内容
        Args:
            lines: 文本行列表
            title: 标题（可选）
        """
        if not self.device:
            return
            
        with canvas(self.device) as draw:
            y_offset = 0
            
            # 显示标题
            if title:
                draw.text((0, y_offset), title, font=self.font_medium, fill=255)
                draw.line((0, 12, 128, 12), fill=255)  # 标题下划线
                y_offset = 16
                
            # 显示内容行
            line_height = 10
            for i, line in enumerate(lines):
                if y_offset + line_height > 64:  # 超出显示范围
                    break
                draw.text((0, y_offset), line, font=self.font_small, fill=255)
                y_offset += line_height
                
    def display_network_info(self, wan_ip, upload_speed, download_speed, connections):
        """显示网络信息页面"""
        lines = [
            f"WAN IP: {wan_ip}",
            f"Upload: {upload_speed}",
            f"Download: {download_speed}",
            f"Connections: {connections}"
        ]
        self.display_text(lines, "Network Info")
        
    def display_system_status(self, cpu_usage, memory_usage, temperature):
        """显示系统状态页面"""
        lines = [
            f"CPU: {cpu_usage:.1f}%",
            f"Memory: {memory_usage:.1f}%",
            f"Temp: {temperature:.1f}°C",
            f"Uptime: {self.get_uptime()}"
        ]
        self.display_text(lines, "System Status")
        
    def display_device_count(self, lan_devices, wifi_devices, total_devices):
        """显示设备统计页面"""
        lines = [
            f"LAN Devices: {lan_devices}",
            f"WiFi Devices: {wifi_devices}",
            f"Total: {total_devices}",
            f"Time: {time.strftime('%H:%M:%S')}"
        ]
        self.display_text(lines, "Device Count")
        
    def display_storage_info(self, root_usage, tmp_usage, available_space):
        """显示存储信息页面"""
        lines = [
            f"Root: {root_usage:.1f}%",
            f"Tmp: {tmp_usage:.1f}%",
            f"Free: {available_space}",
            f"Date: {time.strftime('%m/%d')}"
        ]
        self.display_text(lines, "Storage Info")
        
    def display_startup_message(self):
        """显示启动消息"""
        lines = [
            "Pi3B Display",
            "Starting...",
            "",
            time.strftime("%Y-%m-%d"),
            time.strftime("%H:%M:%S")
        ]
        self.display_text(lines, "System")
        
    def display_error(self, error_msg):
        """显示错误信息"""
        lines = [
            "ERROR:",
            error_msg[:20],  # 限制错误消息长度
            "",
            "Check logs"
        ]
        self.display_text(lines, "Error")
        
    def get_uptime(self):
        """获取系统运行时间"""
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
                hours = int(uptime_seconds // 3600)
                minutes = int((uptime_seconds % 3600) // 60)
                return f"{hours:02d}:{minutes:02d}"
        except:
            return "N/A"
