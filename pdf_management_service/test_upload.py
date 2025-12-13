#!/usr/bin/env python3
"""
Simple test to upload a PDF to Firebase Storage and save URL to Firestore
"""

import requests
import tempfile
import os
from datetime import datetime

def create_simple_test_pdf():
    """Create a simple text-based PDF for testing"""
    
    # Create a simple text file first
    temp_dir = tempfile.gettempdir()
    text_file = os.path.join(temp_dir, "test_chapter.txt")
    
    with open(text_file, 'w', encoding='utf-8') as f:
        f.write("""
Class 9 Mathematics - Real Numbers
বাস্তব সংখ্যা - নবম শ্রেণি

Chapter 1: Introduction to Real Numbers

Real numbers are all the numbers on the number line. This includes:

1. Natural Numbers (N): 1, 2, 3, 4, 5, ...
2. Whole Numbers (W): 0, 1, 2, 3, 4, 5, ...
3. Integers (Z): ..., -3, -2, -1, 0, 1, 2, 3, ...
4. Rational Numbers (Q): Numbers that can be expressed as p/q where p and q are integers and q ≠ 0
5. Irrational Numbers: Numbers that cannot be expressed as p/q (like √2, π, e)

Properties of Real Numbers:
- Closure Property
- Commutative Property  
- Associative Property
- Distributive Property

Examples and Practice Problems:

1. Identify whether the following are rational or irrational:
   a) 1/3
   b) √5
   c) 0.75
   d) π

2. Simplify: √18 + √32 - √50

3. Find the decimal expansion of 7/11

This chapter covers the fundamental concepts of real numbers that students will use throughout their mathematics education.

Sample problems and solutions would continue here in a real textbook...
""")
    
    # For testing, we'll just rename it as PDF (since our system extracts text anyway)
    pdf_file = os.path.join(temp_dir, "test_real_numbers.pdf")
    os.rename(text_file, pdf_file)
    
    return pdf_file

def test_upload_to_firebase():
    """Test uploading PDF to Firebase Storage via our API"""
    
    print("🧪 Testing PDF Upload to Firebase Storage")
    print("=" * 50)
    
    try:
        # Create test PDF
        print("📄 Creating test PDF file...")
        pdf_path = create_simple_test_pdf()
        print(f"✅ Created: {pdf_path}")
        
        # Upload via API
        print("\n⬆️  Uploading to Firebase Storage...")
        
        with open(pdf_path, 'rb') as f:
            files = {'pdf_file': ('test_real_numbers.pdf', f, 'application/pdf')}
            data = {
                'class_level': '9',
                'chapter_id': 'real_numbers',
                'force_reupload': 'true'
            }
            
            response = requests.post('http://localhost:5001/upload', files=files, data=data)
        
        print(f"📊 HTTP Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Upload Response: {result.get('success')}")
            
            if result.get('success'):
                print("\n🎉 SUCCESS! PDF uploaded to Firebase Storage!")
                print(f"🔥 Firebase Status: {result.get('firebase_status')}")
                print(f"📱 Student Download Ready: {result.get('student_download_ready')}")
                print(f"💾 Firestore Saved: {result.get('firestore_saved')}")
                
                if result.get('firebase_url'):
                    firebase_url = result.get('firebase_url')
                    print(f"🔗 Firebase Download URL: {firebase_url}")
                    
                    # Test the download URL
                    print("\n🔍 Testing download URL...")
                    download_response = requests.head(firebase_url)
                    print(f"📊 Download URL Status: {download_response.status_code}")
                    if download_response.status_code == 200:
                        print("✅ Download URL is accessible!")
                    else:
                        print("❌ Download URL not accessible")
                
                print(f"🧠 Text Chunks Created: {result.get('chunks_created')}")
                print(f"📋 Message: {result.get('message')}")
                
                # Test getting chapter info
                print("\n🔍 Testing chapter download info API...")
                info_response = requests.get('http://localhost:5001/api/chapter/9/real_numbers/download_info')
                if info_response.status_code == 200:
                    info_data = info_response.json()
                    if info_data.get('success'):
                        print("✅ Chapter info retrieved successfully!")
                        print(f"📱 Download Ready: {info_data.get('download_ready')}")
                        print(f"🔗 Download URL: {info_data.get('download_url')}")
                    else:
                        print(f"❌ Chapter info error: {info_data.get('error')}")
                else:
                    print(f"❌ Chapter info API failed: {info_response.status_code}")
                
            else:
                print(f"❌ Upload failed: {result.get('error')}")
                print(f"📋 Full response: {result}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"📋 Response: {response.text}")
        
        # Clean up
        os.remove(pdf_path)
        print(f"\n🗑️ Cleaned up test file")
        
    except Exception as e:
        print(f"❌ Error during test: {e}")

def test_flutter_api_compatibility():
    """Test the APIs that Flutter app will use"""
    
    print("\n📱 Testing Flutter App Compatibility")
    print("=" * 40)
    
    # Test available chapters API
    print("🔍 Testing available chapters API...")
    response = requests.get('http://localhost:5001/api/chapters/available/9')
    
    if response.status_code == 200:
        data = response.json()
        if data.get('success'):
            chapters = data.get('chapters', [])
            print(f"✅ Found {len(chapters)} chapters for Class 9")
            
            # Find our uploaded chapter
            real_numbers = next((ch for ch in chapters if ch.get('chapter_id') == 'real_numbers'), None)
            if real_numbers:
                print("✅ Real Numbers chapter found!")
                print(f"   📖 Display Title: {real_numbers.get('displayTitle')}")
                print(f"   📖 Display Subtitle: {real_numbers.get('displaySubtitle')}")
                print(f"   📱 Available: {real_numbers.get('is_available')}")
                print(f"   🔗 Download URL: {real_numbers.get('download_url')}")
            else:
                print("❌ Real Numbers chapter not found in API")
        else:
            print(f"❌ API Error: {data.get('error')}")
    else:
        print(f"❌ API Failed: {response.status_code}")

if __name__ == '__main__':
    # Run the tests
    test_upload_to_firebase()
    test_flutter_api_compatibility()
    
    print("\n" + "=" * 50)
    print("🎯 Test Summary:")
    print("✅ If successful, your Firebase Storage integration is working!")
    print("📱 Students can now download PDFs in the Flutter app")
    print("💾 URLs are automatically saved to Firestore database")
    print("🔗 Visit http://localhost:5001 for the web interface")
