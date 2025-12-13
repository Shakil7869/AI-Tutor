#!/usr/bin/env python3
"""
Smart Startup Script for PDF Service
Automatically chooses the best server based on system resources
"""

import psutil
import subprocess
import sys
import os
from pathlib import Path

def check_system_performance():
    """Check system resources and recommend best server"""
    
    # Get system info
    cpu_cores = psutil.cpu_count()
    memory = psutil.virtual_memory()
    ram_gb = memory.total / (1024**3)
    available_gb = memory.available / (1024**3)
    cpu_percent = psutil.cpu_percent(interval=1)
    
    print("🔍 System Analysis:")
    print(f"  CPU Cores: {cpu_cores}")
    print(f"  Total RAM: {ram_gb:.1f} GB")
    print(f"  Available RAM: {available_gb:.1f} GB")
    print(f"  Current CPU Usage: {cpu_percent:.1f}%")
    
    # Scoring system
    score = 0
    
    # RAM scoring
    if ram_gb >= 16:
        score += 4
    elif ram_gb >= 8:
        score += 3
    elif ram_gb >= 4:
        score += 2
    else:
        score += 1
    
    # Available RAM scoring
    if available_gb >= 4:
        score += 3
    elif available_gb >= 2:
        score += 2
    else:
        score += 1
    
    # CPU scoring
    if cpu_cores >= 8:
        score += 3
    elif cpu_cores >= 4:
        score += 2
    else:
        score += 1
    
    # Current load scoring
    if cpu_percent < 30:
        score += 2
    elif cpu_percent < 60:
        score += 1
    
    return score, {
        'cpu_cores': cpu_cores,
        'ram_gb': ram_gb,
        'available_gb': available_gb,
        'cpu_percent': cpu_percent
    }

def recommend_server(score, system_info):
    """Recommend which server to use"""
    
    print("\n💡 Server Recommendation:")
    
    if score >= 10:
        print("✅ High Performance System")
        print("   Recommended: Full Featured Server")
        print("   - All AI features enabled")
        print("   - Real-time processing")
        print("   - Pinecone & OpenAI integration")
        return "full"
    
    elif score >= 7:
        print("⚖️ Medium Performance System")
        print("   Recommended: Optimized Server")
        print("   - AI features with optimizations")
        print("   - Batch processing")
        print("   - Limited chunks per PDF")
        return "optimized"
    
    else:
        print("⚠️ Low Performance System")
        print("   Recommended: Lightweight Server")
        print("   - File upload only")
        print("   - No AI processing during upload")
        print("   - Minimal memory usage")
        return "lightweight"

def start_server(server_type, auto_start=False):
    """Start the recommended server"""
    
    scripts = {
        "full": "chapter_pdf_manager.py",
        "optimized": "chapter_pdf_manager.py",  # Same file but with optimizations
        "lightweight": "lightweight_server.py"
    }
    
    script_path = scripts[server_type]
    
    if not os.path.exists(script_path):
        print(f"❌ Server script not found: {script_path}")
        return False
    
    print(f"\n🚀 Starting {server_type} server...")
    print(f"📄 Script: {script_path}")
    
    if auto_start:
        print("⏳ Starting automatically...")
    else:
        confirm = input("Start this server? (y/n): ").lower().strip()
        if confirm != 'y':
            print("❌ Server start cancelled")
            return False
    
    try:
        # Set environment variables for optimized mode
        env = os.environ.copy()
        if server_type == "optimized":
            env['PDF_SERVICE_MODE'] = 'optimized'
        elif server_type == "lightweight":
            env['PDF_SERVICE_MODE'] = 'lightweight'
        
        # Start the server
        if sys.platform == "win32":
            # Windows
            subprocess.run([sys.executable, script_path], env=env)
        else:
            # Unix/Linux/Mac
            subprocess.run([sys.executable, script_path], env=env)
        
        return True
        
    except KeyboardInterrupt:
        print("\n⚠️ Server stopped by user")
        return True
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        return False

def show_performance_tips(server_type, system_info):
    """Show performance optimization tips"""
    
    print(f"\n🔧 Performance Tips for {server_type} mode:")
    
    if server_type == "lightweight":
        print("  ✅ Close unnecessary applications")
        print("  ✅ Use smaller PDF files (< 20MB)")
        print("  ✅ Upload one chapter at a time")
        print("  ✅ Restart browser if it becomes slow")
    
    elif server_type == "optimized":
        print("  ✅ Close heavy applications (video editors, games)")
        print("  ✅ Keep PDF files under 50MB")
        print("  ✅ Wait for each upload to complete")
        print("  ✅ Monitor system temperature")
    
    else:  # full
        print("  ✅ Ensure stable internet connection")
        print("  ✅ Keep OpenAI API key active")
        print("  ✅ Monitor Pinecone usage limits")
        print("  ✅ Regular system maintenance")
    
    print("\n🔧 General Tips:")
    print("  📊 Monitor performance using performance_monitor.py")
    print("  🔄 Restart server if memory usage grows too high")
    print("  💾 Ensure sufficient disk space (5GB+)")
    print("  🌡️ Check laptop temperature and cooling")

def main():
    """Main startup logic"""
    
    print("🚀 Smart PDF Service Launcher")
    print("=" * 40)
    
    # Check system performance
    score, system_info = check_system_performance()
    
    # Get recommendation
    recommended = recommend_server(score, system_info)
    
    # Show performance tips
    show_performance_tips(recommended, system_info)
    
    print("\n" + "=" * 40)
    print("Choose startup option:")
    print(f"1. Start {recommended} server (recommended)")
    print("2. Start lightweight server (fastest)")
    print("3. Start optimized server (balanced)")
    print("4. Start full server (all features)")
    print("5. Run performance check only")
    print("6. Auto-start recommended server")
    
    choice = input("\nEnter choice (1-6): ").strip()
    
    if choice == "1":
        start_server(recommended)
    elif choice == "2":
        start_server("lightweight")
    elif choice == "3":
        start_server("optimized")
    elif choice == "4":
        start_server("full")
    elif choice == "5":
        print("✅ Performance check completed!")
        print("\n💡 Run this script again to start a server")
    elif choice == "6":
        start_server(recommended, auto_start=True)
    else:
        print("❌ Invalid choice")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("💡 Try running: python lightweight_server.py")
