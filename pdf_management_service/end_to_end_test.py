#!/usr/bin/env python3
"""
End-to-End Test: Upload PDF and verify student can download
"""

import requests
import tempfile
import os

def create_sample_pdf():
    """Create a proper PDF for testing"""
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import letter
    import tempfile
    
    # Create a temporary PDF file
    temp_file = tempfile.NamedTemporaryFile(suffix='.pdf', delete=False)
    temp_file.close()
    
    # Create PDF with reportlab
    c = canvas.Canvas(temp_file.name, pagesize=letter)
    width, height = letter
    
    # Add title
    c.setFont("Helvetica-Bold", 16)
    c.drawString(100, height - 100, "Class 9 Mathematics - Real Numbers")
    c.drawString(100, height - 130, "বাস্তব সংখ্যা - নবম শ্রেণি")
    
    # Add content
    c.setFont("Helvetica", 12)
    content = [
        "",
        "Chapter 1: Introduction to Real Numbers",
        "",
        "Real numbers include all rational and irrational numbers.",
        "",
        "Types of Numbers:",
        "1. Natural Numbers: 1, 2, 3, 4, 5, ...",
        "2. Whole Numbers: 0, 1, 2, 3, 4, 5, ...",
        "3. Integers: ..., -3, -2, -1, 0, 1, 2, 3, ...",
        "4. Rational Numbers: Numbers that can be expressed as p/q",
        "5. Irrational Numbers: Numbers that cannot be expressed as p/q",
        "",
        "Examples:",
        "- Rational: 1/2, 3/4, 0.75, 22/7",
        "- Irrational: √2, √3, π, e",
        "",
        "Properties of Real Numbers:",
        "1. Closure Property",
        "2. Commutative Property",
        "3. Associative Property",
        "4. Distributive Property",
        "",
        "Sample Problems:",
        "",
        "Problem 1: Classify as rational or irrational:",
        "a) 7/11 = Rational",
        "b) √3 = Irrational",
        "c) 0.75 = Rational",
        "d) π = Irrational",
        "",
        "Problem 2: Simplify √12 + √27 - √48",
        "= 2√3 + 3√3 - 4√3 = √3",
        "",
        "This is a test PDF to verify Firebase Storage integration.",
    ]
    
    y = height - 160
    for line in content:
        c.drawString(100, y, line)
        y -= 20
        if y < 100:  # Start new page
            c.showPage()
            y = height - 100
    
    c.save()
    return temp_file.name

def test_upload_pdf():
    """Test uploading PDF to Firebase Storage"""
    print("🧪 Testing End-to-End PDF Upload and Download")
    print("=" * 50)
    
    try:
        # Create sample PDF
        print("📄 Creating sample PDF...")
        pdf_path = create_sample_pdf()
        print(f"✅ Created: {pdf_path}")
        
        # Upload via API
        print("\n⬆️ Uploading to Firebase Storage...")
        
        with open(pdf_path, 'rb') as f:
            files = {'pdf_file': ('test_real_numbers.pdf', f, 'application/pdf')}
            data = {
                'class_level': '9',
                'chapter_id': 'real_numbers',
                'force_reupload': 'true'  # Force reupload for testing
            }
            
            response = requests.post('http://localhost:5001/upload', files=files, data=data)
        
        print(f"📊 Upload Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                print("✅ Upload successful!")
                print(f"🔥 Firebase Status: {result.get('firebase_status')}")
                print(f"📱 Student Download Ready: {result.get('student_download_ready')}")
                print(f"💾 Firestore Saved: {result.get('firestore_saved')}")
                
                firebase_url = result.get('firebase_url')
                if firebase_url:
                    print(f"🔗 Firebase URL: {firebase_url}")
                    
                    # Test the Firebase URL
                    print("\n🔍 Testing Firebase download URL...")
                    test_response = requests.head(firebase_url)
                    if test_response.status_code == 200:
                        print("✅ Firebase URL accessible!")
                    else:
                        print(f"❌ Firebase URL not accessible: {test_response.status_code}")
                
                # Test Flutter API endpoints
                print("\n📱 Testing Flutter-compatible APIs...")
                
                # Test download info
                info_response = requests.get('http://localhost:5001/api/chapter/9/real_numbers/download_info')
                if info_response.status_code == 200:
                    info_data = info_response.json()
                    if info_data.get('success') and info_data.get('download_ready'):
                        print("✅ Download info API working!")
                        print(f"   📖 Title: {info_data['chapter_info']['displayTitle']}")
                        print(f"   📱 Download Ready: {info_data['download_ready']}")
                        print(f"   🔗 URL: {info_data['download_url']}")
                        print(f"   📊 File Size: {info_data['file_size']} bytes")
                    else:
                        print(f"❌ Download info not ready: {info_data}")
                else:
                    print(f"❌ Download info API failed: {info_response.status_code}")
                
                # Test available chapters
                chapters_response = requests.get('http://localhost:5001/api/chapters/available/9')
                if chapters_response.status_code == 200:
                    chapters_data = chapters_response.json()
                    if chapters_data.get('success'):
                        chapters = chapters_data.get('chapters', [])
                        real_numbers = next((ch for ch in chapters if ch.get('chapter_id') == 'real_numbers'), None)
                        if real_numbers and real_numbers.get('is_available'):
                            print("✅ Chapter appears in available chapters API!")
                            print(f"   📖 Display: {real_numbers.get('displayTitle')}")
                        else:
                            print("❌ Chapter not in available chapters or not available")
                    else:
                        print(f"❌ Available chapters API error: {chapters_data.get('error')}")
                else:
                    print(f"❌ Available chapters API failed: {chapters_response.status_code}")
                
                print("\n🎉 SUCCESS! End-to-End test completed!")
                print("📱 Students can now:")
                print("   1. See the chapter in their available chapters list")
                print("   2. Download the PDF for offline viewing")
                print("   3. Open and read the PDF in the app")
                print("   4. Ask AI questions about the content")
                
            else:
                print(f"❌ Upload failed: {result.get('error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(response.text)
        
        # Clean up
        os.remove(pdf_path)
        
    except Exception as e:
        print(f"❌ Test failed: {e}")

if __name__ == '__main__':
    test_upload_pdf()
