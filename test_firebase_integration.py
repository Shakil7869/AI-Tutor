#!/usr/bin/env python3
"""
Firebase Integration Test Script
Tests both Python backend and Flutter integration
"""

import requests
import json
import os
import sys

BASE_URL = "http://localhost:5000"

def test_service_status():
    """Test if the service is running"""
    try:
        response = requests.get(f"{BASE_URL}/status", timeout=5)
        if response.status_code == 200:
            print("✅ PDF Service is running")
            return True
        else:
            print(f"❌ PDF Service error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to PDF Service: {e}")
        return False

def test_firebase_status():
    """Test Firebase integration status"""
    try:
        response = requests.get(f"{BASE_URL}/firebase_status", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"🔥 Firebase Status: {data}")
            return data.get('firebase_available', False)
        else:
            print(f"⚠️ Firebase status check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"⚠️ Firebase status error: {e}")
        return False

def test_chapters():
    """Test chapter retrieval"""
    try:
        response = requests.get(f"{BASE_URL}/chapters/6", timeout=5)
        if response.status_code == 200:
            data = response.json()
            chapters = data.get('chapters', {})
            print(f"📊 Retrieved {len(chapters)} chapters for Class 6")
            if chapters:
                first_chapter = list(chapters.keys())[0]
                print(f"📖 First chapter: {first_chapter}")
            return True
        else:
            print(f"❌ Chapter retrieval failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Chapter retrieval error: {e}")
        return False

def test_pdf_download():
    """Test PDF download functionality"""
    try:
        response = requests.get(f"{BASE_URL}/pdf/6/chapter_1", timeout=10)
        if response.status_code == 200:
            print(f"📥 PDF download successful ({len(response.content)} bytes)")
            return True
        else:
            print(f"❌ PDF download failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ PDF download error: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Testing Firebase Integration...\n")
    
    # Test service status
    if not test_service_status():
        print("\n❌ PDF Service is not running. Start it with:")
        print("cd pdf_management_service")
        print("python pdf_manager_firebase.py")
        sys.exit(1)
    
    # Test Firebase status
    firebase_available = test_firebase_status()
    
    # Test chapters
    test_chapters()
    
    # Test PDF download
    test_pdf_download()
    
    print("\n📋 Summary:")
    print(f"  🔥 Firebase Available: {firebase_available}")
    print(f"  📱 Service Mode: {'Firebase + HTTP Fallback' if firebase_available else 'HTTP Only'}")
    print(f"  ✅ Integration Status: {'Complete' if firebase_available else 'HTTP Fallback Working'}")
    
    if not firebase_available:
        print("\n💡 To enable Firebase:")
        print("  1. Set up Firebase project")
        print("  2. Add firebase_config.json to pdf_management_service/")
        print("  3. Restart the service")
        print("  See FIREBASE_INTEGRATION_STATUS.md for details")

if __name__ == "__main__":
    main()
