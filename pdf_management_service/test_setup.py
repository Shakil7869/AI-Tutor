#!/usr/bin/env python3
"""
Test script for PDF Management Service
Tests basic functionality without dependencies
"""

import sys
import os

def test_python_version():
    """Test Python version compatibility"""
    print("🐍 Testing Python version...")
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        return False
    print(f"✅ Python {sys.version.split()[0]} detected")
    return True

def test_dependencies():
    """Test if required dependencies can be imported"""
    print("\n📦 Testing dependencies...")
    
    # Test Flask
    try:
        import flask
        print(f"✅ Flask {flask.__version__} imported successfully")
    except ImportError:
        print("❌ Flask not found. Run: pip install Flask")
        return False
    
    # Test PyMuPDF
    try:
        import fitz
        print(f"✅ PyMuPDF imported successfully")
    except ImportError:
        print("❌ PyMuPDF not found. Run: pip install PyMuPDF")
        return False
    
    # Test Pillow
    try:
        import PIL
        print(f"✅ Pillow imported successfully")
    except ImportError:
        print("❌ Pillow not found. Run: pip install Pillow")
        return False
    
    # Test Werkzeug
    try:
        import werkzeug
        print(f"✅ Werkzeug imported successfully")
    except ImportError:
        print("❌ Werkzeug not found. Run: pip install Werkzeug")
        return False
    
    return True

def test_directories():
    """Test if required directories exist"""
    print("\n📁 Testing directories...")
    
    required_dirs = ['data', 'data/uploads', 'config', 'templates']
    
    for dir_path in required_dirs:
        if os.path.exists(dir_path):
            print(f"✅ Directory '{dir_path}' exists")
        else:
            print(f"⚠️  Creating directory '{dir_path}'")
            os.makedirs(dir_path, exist_ok=True)
    
    return True

def test_flask_app():
    """Test if Flask app can be imported"""
    print("\n🌐 Testing Flask application...")
    
    try:
        # Simple import test
        from pdf_manager import app
        print("✅ Flask app imported successfully")
        return True
    except Exception as e:
        print(f"❌ Flask app import failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🔧 PDF Management Service - System Test")
    print("=" * 50)
    
    tests = [
        test_python_version,
        test_dependencies,
        test_directories,
        test_flask_app,
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
        print()
    
    print("=" * 50)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! PDF service is ready to run.")
        print("💡 Run 'python pdf_manager.py' to start the service")
    else:
        print("⚠️  Some tests failed. Please fix the issues above.")
        print("💡 Try running 'pip install Flask PyMuPDF Pillow Werkzeug'")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
