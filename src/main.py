#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
树莓派3B 12864显示屏主程序
显示系统状态信息，支持多页面轮换显示
"""

import time
import logging
import signal
import sys
from logging.handlers import RotatingFileHandler
from display_controller import DisplayController
from system_monitor import SystemMonitor
from config import REFRESH_INTERVALS, DISPLAY_PAGES, LOG_CONFIG

class Pi3BDisplay:
    def __init__(self):
        """初始化主程序"""
        self.setup_logging()
        self.display = None
        self.monitor = None
        self.current_page = 0
        self.last_page_switch = time.time()
        self.running = True
        
        # 设置信号处理
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=getattr(logging, LOG_CONFIG['level']),
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                RotatingFileHandler(
                    LOG_CONFIG['file'],
                    maxBytes=LOG_CONFIG['max_size'],
                    backupCount=LOG_CONFIG['backup_count']
                ),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
    def signal_handler(self, signum, frame):
        """信号处理器"""
        logging.info(f"接收到信号 {signum}，准备退出...")
        self.running = False
        
    def initialize(self):
        """初始化显示器和监控器"""
        try:
            logging.info("初始化显示控制器...")
            self.display = DisplayController()
            self.display.display_startup_message()
            
            logging.info("初始化系统监控器...")
            self.monitor = SystemMonitor()
            
            logging.info("初始化完成")
            time.sleep(2)  # 显示启动消息2秒
            
        except Exception as e:
            logging.error(f"初始化失败: {e}")
            if self.display:
                self.display.display_error(str(e))
            raise
            
    def update_display(self):
        """更新显示内容"""
        try:
            # 获取系统信息
            system_info = self.monitor.get_all_system_info()
            
            # 根据当前页面显示不同内容
            page_name = DISPLAY_PAGES[self.current_page]
            
            if page_name == 'network_info':
                self.display.display_network_info(
                    system_info['wan_ip'],
                    system_info['upload_speed'],
                    system_info['download_speed'],
                    system_info['connections']
                )
                
            elif page_name == 'system_status':
                self.display.display_system_status(
                    system_info['cpu_usage'],
                    system_info['memory_usage'],
                    system_info['temperature']
                )
                
            elif page_name == 'device_count':
                self.display.display_device_count(
                    system_info['lan_devices'],
                    system_info['wifi_devices'],
                    system_info['total_devices']
                )
                
            elif page_name == 'storage_info':
                self.display.display_storage_info(
                    system_info['root_usage'],
                    system_info['tmp_usage'],
                    system_info['available_space']
                )
                
            logging.debug(f"显示页面: {page_name}")
            
        except Exception as e:
            logging.error(f"更新显示失败: {e}")
            if self.display:
                self.display.display_error("Update Error")
                
    def should_switch_page(self):
        """检查是否应该切换页面"""
        current_time = time.time()
        return (current_time - self.last_page_switch) >= REFRESH_INTERVALS['page_switch']
        
    def switch_page(self):
        """切换到下一页"""
        self.current_page = (self.current_page + 1) % len(DISPLAY_PAGES)
        self.last_page_switch = time.time()
        logging.debug(f"切换到页面: {DISPLAY_PAGES[self.current_page]}")
        
    def run(self):
        """主运行循环"""
        logging.info("Pi3B Display 启动")
        
        try:
            self.initialize()
            
            while self.running:
                # 检查是否需要切换页面
                if self.should_switch_page():
                    self.switch_page()
                    
                # 更新显示
                self.update_display()
                
                # 等待刷新间隔
                time.sleep(REFRESH_INTERVALS['system_info'])
                
        except KeyboardInterrupt:
            logging.info("接收到键盘中断信号")
            
        except Exception as e:
            logging.error(f"程序运行出错: {e}")
            if self.display:
                self.display.display_error("Fatal Error")
                time.sleep(5)
                
        finally:
            self.cleanup()
            
    def cleanup(self):
        """清理资源"""
        logging.info("清理资源...")
        if self.display:
            try:
                self.display.clear()
            except:
                pass
        logging.info("程序退出")

def main():
    """主函数"""
    try:
        app = Pi3BDisplay()
        app.run()
    except Exception as e:
        logging.error(f"程序启动失败: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
