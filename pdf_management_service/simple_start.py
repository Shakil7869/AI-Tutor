#!/usr/bin/env python3
"""
Simple PDF Service Launcher
No external dependencies required
"""

import platform
import os
import subprocess
import sys

def get_system_info():
    """Get basic system information"""
    try:
        import os
        
        # Get CPU count from environment
        cpu_count = os.cpu_count() or 2
        
        # Get platform info
        system = platform.system()
        machine = platform.machine()
        
        print("🖥️ System Information:")
        print(f"  OS: {system}")
        print(f"  Architecture: {machine}")
        print(f"  CPU Cores: {cpu_count}")
        
        return {
            'cpu_count': cpu_count,
            'system': system,
            'machine': machine
        }
    except Exception as e:
        print(f"⚠️ Could not get system info: {e}")
        return {'cpu_count': 2, 'system': 'Unknown', 'machine': 'Unknown'}

def recommend_server(system_info):
    """Simple recommendation based on CPU count"""
    cpu_count = system_info.get('cpu_count', 2)
    
    print("\n💡 Server Recommendation:")
    
    if cpu_count >= 8:
        print("✅ High Performance System Detected")
        print("   Recommended: Optimized Server (balanced features)")
        return "optimized"
    elif cpu_count >= 4:
        print("⚖️ Medium Performance System Detected") 
        print("   Recommended: Optimized Server (balanced features)")
        return "optimized"
    else:
        print("⚠️ Lower Performance System Detected")
        print("   Recommended: Lightweight Server (faster, simpler)")
        return "lightweight"

def start_server(server_type):
    """Start the selected server"""
    
    if server_type == "lightweight":
        script = "lightweight_server.py"
        port = 5002
        description = "Lightweight server - fast uploads, minimal processing"
    else:
        script = "chapter_pdf_manager.py"
        port = 5001
        description = "Optimized server - all features with performance tuning"
    
    if not os.path.exists(script):
        print(f"❌ Server script not found: {script}")
        return False
    
    print(f"\n🚀 Starting {server_type} server...")
    print(f"📄 Script: {script}")
    print(f"🔗 URL: http://localhost:{port}")
    print(f"📝 Description: {description}")
    
    try:
        print("\n⏳ Starting server... (Press Ctrl+C to stop)")
        subprocess.run([sys.executable, script])
        return True
    except KeyboardInterrupt:
        print("\n⚠️ Server stopped by user")
        return True
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        return False

def show_usage_tips():
    """Show usage tips"""
    print("\n🔧 Performance Tips:")
    print("  📱 For best performance on older laptops:")
    print("    - Use the lightweight server")
    print("    - Close other heavy applications")
    print("    - Upload smaller PDF files (< 50MB)")
    print("    - Upload one chapter at a time")
    print("")
    print("  🚀 For better features on newer systems:")
    print("    - Use the optimized server")
    print("    - Ensure stable internet connection")
    print("    - Keep API keys updated")
    print("")
    print("  🔍 To monitor performance:")
    print("    - Check Task Manager / Activity Monitor")
    print("    - Watch CPU and memory usage")
    print("    - Restart server if it becomes slow")

def main():
    """Main startup logic"""
    
    print("📚 PDF Service Launcher")
    print("=" * 30)
    
    # Get system info
    system_info = get_system_info()
    
    # Get recommendation
    recommended = recommend_server(system_info)
    
    # Show tips
    show_usage_tips()
    
    print("\n" + "=" * 30)
    print("Choose server type:")
    print(f"1. {recommended} server (recommended)")
    print("2. Lightweight server (fastest, simple uploads)")
    print("3. Optimized server (balanced features)")
    print("4. Show tips only")
    
    try:
        choice = input("\nEnter choice (1-4): ").strip()
        
        if choice == "1":
            start_server(recommended)
        elif choice == "2":
            start_server("lightweight")
        elif choice == "3":
            start_server("optimized")
        elif choice == "4":
            print("✅ Tips shown above!")
        else:
            print("❌ Invalid choice, starting recommended server...")
            start_server(recommended)
    
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("💡 Trying lightweight server...")
        start_server("lightweight")

if __name__ == "__main__":
    main()
