#!/usr/bin/env python3
"""
Performance Monitor for PDF Service
Track CPU, memory, and disk usage
"""

import psutil
import time
import json
from datetime import datetime
import matplotlib.pyplot as plt
from collections import deque

class PerformanceMonitor:
    def __init__(self, max_points=100):
        self.max_points = max_points
        self.cpu_data = deque(maxlen=max_points)
        self.memory_data = deque(maxlen=max_points)
        self.timestamps = deque(maxlen=max_points)
        
    def collect_metrics(self):
        """Collect current system metrics"""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Memory usage
            memory = psutil.virtual_memory()
            memory_percent = memory.percent
            
            # Store data
            now = datetime.now()
            self.timestamps.append(now)
            self.cpu_data.append(cpu_percent)
            self.memory_data.append(memory_percent)
            
            return {
                'timestamp': now.isoformat(),
                'cpu_percent': cpu_percent,
                'memory_percent': memory_percent,
                'memory_available_gb': memory.available / (1024**3),
                'disk_usage': psutil.disk_usage('/').percent
            }
            
        except Exception as e:
            print(f"Error collecting metrics: {e}")
            return None
    
    def get_process_info(self, process_name="python"):
        """Get info about specific processes"""
        processes = []
        
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                if process_name.lower() in proc.info['name'].lower():
                    processes.append(proc.info)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        return processes
    
    def create_chart(self, save_path="performance_chart.png"):
        """Create performance chart"""
        if len(self.timestamps) < 2:
            print("Not enough data for chart")
            return
        
        try:
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 8))
            
            # CPU Chart
            ax1.plot(self.timestamps, self.cpu_data, 'b-', linewidth=2, label='CPU Usage')
            ax1.set_ylabel('CPU Usage (%)')
            ax1.set_title('System Performance Monitor')
            ax1.grid(True, alpha=0.3)
            ax1.legend()
            ax1.set_ylim(0, 100)
            
            # Memory Chart
            ax2.plot(self.timestamps, self.memory_data, 'r-', linewidth=2, label='Memory Usage')
            ax2.set_ylabel('Memory Usage (%)')
            ax2.set_xlabel('Time')
            ax2.grid(True, alpha=0.3)
            ax2.legend()
            ax2.set_ylim(0, 100)
            
            plt.tight_layout()
            plt.savefig(save_path, dpi=150, bbox_inches='tight')
            plt.close()
            
            print(f"📊 Chart saved to: {save_path}")
            
        except Exception as e:
            print(f"Error creating chart: {e}")
    
    def monitor_continuous(self, duration_minutes=10, interval_seconds=5):
        """Monitor system for a specific duration"""
        print(f"🔍 Monitoring system for {duration_minutes} minutes...")
        print(f"📊 Collecting data every {interval_seconds} seconds")
        print("-" * 50)
        
        start_time = time.time()
        end_time = start_time + (duration_minutes * 60)
        
        metrics_log = []
        
        try:
            while time.time() < end_time:
                metrics = self.collect_metrics()
                if metrics:
                    metrics_log.append(metrics)
                    
                    # Print current status
                    print(f"⏰ {metrics['timestamp'][:19]} | "
                          f"CPU: {metrics['cpu_percent']:5.1f}% | "
                          f"Memory: {metrics['memory_percent']:5.1f}% | "
                          f"Available: {metrics['memory_available_gb']:.1f}GB")
                
                time.sleep(interval_seconds)
                
        except KeyboardInterrupt:
            print("\n⚠️ Monitoring stopped by user")
        
        # Save log
        log_file = f"performance_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(log_file, 'w') as f:
            json.dump(metrics_log, f, indent=2)
        
        print(f"\n📄 Log saved to: {log_file}")
        
        # Create chart
        self.create_chart(f"performance_chart_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png")
        
        # Summary
        if metrics_log:
            cpu_values = [m['cpu_percent'] for m in metrics_log]
            memory_values = [m['memory_percent'] for m in metrics_log]
            
            print("\n📊 Summary:")
            print(f"   CPU - Avg: {sum(cpu_values)/len(cpu_values):.1f}%, Max: {max(cpu_values):.1f}%")
            print(f"   Memory - Avg: {sum(memory_values)/len(memory_values):.1f}%, Max: {max(memory_values):.1f}%")

def check_system_requirements():
    """Check if system meets minimum requirements"""
    print("🔍 System Requirements Check")
    print("-" * 30)
    
    # CPU cores
    cpu_cores = psutil.cpu_count()
    print(f"CPU Cores: {cpu_cores} {'✅' if cpu_cores >= 2 else '⚠️'}")
    
    # RAM
    memory = psutil.virtual_memory()
    ram_gb = memory.total / (1024**3)
    print(f"Total RAM: {ram_gb:.1f} GB {'✅' if ram_gb >= 4 else '⚠️'}")
    
    # Available RAM
    available_gb = memory.available / (1024**3)
    print(f"Available RAM: {available_gb:.1f} GB {'✅' if available_gb >= 2 else '⚠️'}")
    
    # Disk space
    disk = psutil.disk_usage('/')
    free_gb = disk.free / (1024**3)
    print(f"Free Disk Space: {free_gb:.1f} GB {'✅' if free_gb >= 5 else '⚠️'}")
    
    print("\n💡 Recommendations:")
    if ram_gb < 8:
        print("  - Consider upgrading RAM to 8GB+ for better performance")
    if available_gb < 3:
        print("  - Close other applications to free up memory")
    if cpu_cores < 4:
        print("  - Use the lightweight server for better performance")
    
    return {
        'cpu_cores': cpu_cores,
        'ram_gb': ram_gb,
        'available_gb': available_gb,
        'free_disk_gb': free_gb
    }

def monitor_pdf_service():
    """Monitor PDF service specifically"""
    print("🔍 Monitoring PDF Service Process...")
    
    monitor = PerformanceMonitor()
    
    # Find Python processes
    python_processes = monitor.get_process_info("python")
    
    if not python_processes:
        print("❌ No Python processes found")
        return
    
    print(f"📋 Found {len(python_processes)} Python processes:")
    for proc in python_processes:
        print(f"  PID: {proc['pid']} | CPU: {proc['cpu_percent']:.1f}% | Memory: {proc['memory_percent']:.1f}%")
    
    # Monitor for 5 minutes
    monitor.monitor_continuous(duration_minutes=5, interval_seconds=2)

if __name__ == "__main__":
    print("⚡ PDF Service Performance Monitor")
    print("=" * 40)
    
    # Check system requirements
    check_system_requirements()
    
    print("\nChoose monitoring option:")
    print("1. Check system requirements only")
    print("2. Monitor PDF service (5 minutes)")
    print("3. Custom monitoring duration")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    if choice == "2":
        monitor_pdf_service()
    elif choice == "3":
        duration = int(input("Enter duration in minutes: "))
        interval = int(input("Enter interval in seconds: "))
        
        monitor = PerformanceMonitor()
        monitor.monitor_continuous(duration, interval)
    else:
        print("✅ System check completed!")
