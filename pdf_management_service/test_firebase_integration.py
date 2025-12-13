#!/usr/bin/env python3
"""
Test script to demonstrate Firebase Storage upload and Firestore integration
"""
import requests
import json

def test_upload_chapter():
    """Test uploading a chapter via the API"""
    
    # First, check the system status
    print("🔍 Checking system status...")
    response = requests.get('http://localhost:5001/status')
    if response.status_code == 200:
        status = response.json()
        print(f"✅ Firebase: {'✅' if status.get('firebase_initialized') else '❌'}")
        print(f"✅ Firestore: {'✅' if status.get('firestore_available') else '❌'}")
        print(f"✅ Pinecone: {'✅' if status.get('pinecone_initialized') else '❌'}")
        print(f"📊 Total chapters: {status.get('total_chapters', 0)}")
    else:
        print("❌ Failed to get system status")
        return
    
    # Test getting available chapters for Class 9
    print("\n🔍 Checking available chapters for Class 9...")
    response = requests.get('http://localhost:5001/api/chapters/available/9')
    if response.status_code == 200:
        data = response.json()
        if data.get('success'):
            chapters = data.get('chapters', [])
            print(f"📚 Found {len(chapters)} chapters for Class 9")
            
            for chapter in chapters[:3]:  # Show first 3
                print(f"  📖 {chapter.get('displayTitle', '')} - {chapter.get('displaySubtitle', '')}")
                if chapter.get('is_available'):
                    print(f"      ✅ Available for download: {chapter.get('download_url')}")
                else:
                    print(f"      ❌ Not available for download")
        else:
            print(f"❌ Error: {data.get('error')}")
    else:
        print("❌ Failed to get chapters")
    
    # Test getting download info for a specific chapter
    print("\n🔍 Testing chapter download info for 'real_numbers'...")
    response = requests.get('http://localhost:5001/api/chapter/9/real_numbers/download_info')
    if response.status_code == 200:
        data = response.json()
        if data.get('success'):
            chapter_info = data.get('chapter_info', {})
            print(f"📖 Chapter: {chapter_info.get('chapter_name', 'Unknown')}")
            print(f"🔗 Download ready: {data.get('download_ready', False)}")
            if data.get('download_url'):
                print(f"📱 Download URL: {data.get('download_url')}")
            else:
                print("📁 No download URL available")
        else:
            print(f"❌ Error: {data.get('error')}")
    else:
        print("❌ Failed to get download info")

def create_sample_pdf():
    """Create a simple PDF for testing"""
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import letter
    import tempfile
    import os
    
    # Create a simple PDF
    temp_path = os.path.join(tempfile.gettempdir(), "sample_real_numbers.pdf")
    
    c = canvas.Canvas(temp_path, pagesize=letter)
    width, height = letter
    
    # Add content
    c.setFont("Helvetica-Bold", 16)
    c.drawString(100, height - 100, "Class 9 - Real Numbers")
    c.drawString(100, height - 130, "বাস্তব সংখ্যা")
    
    c.setFont("Helvetica", 12)
    content = [
        "",
        "Chapter 1: Real Numbers",
        "",
        "Real numbers include all rational and irrational numbers.",
        "Examples of real numbers:",
        "- Natural numbers: 1, 2, 3, ...",
        "- Integers: ..., -2, -1, 0, 1, 2, ...",
        "- Rational numbers: 1/2, 3/4, 0.5, etc.",
        "- Irrational numbers: √2, π, e, etc.",
        "",
        "Properties of real numbers:",
        "1. Closure property",
        "2. Commutative property", 
        "3. Associative property",
        "4. Distributive property",
        "",
        "This is a sample PDF for testing Firebase Storage upload",
        "and Firestore integration for the AI Tutor app."
    ]
    
    y = height - 160
    for line in content:
        c.drawString(100, y, line)
        y -= 20
        if y < 100:  # Start new page if needed
            c.showPage()
            y = height - 100
    
    c.save()
    return temp_path

def test_upload_sample_pdf():
    """Test uploading a sample PDF"""
    try:
        # Create sample PDF
        print("\n📄 Creating sample PDF...")
        pdf_path = create_sample_pdf()
        print(f"✅ Created sample PDF: {pdf_path}")
        
        # Upload via API
        print("\n⬆️  Uploading PDF to Firebase Storage...")
        
        with open(pdf_path, 'rb') as f:
            files = {'pdf_file': ('sample_real_numbers.pdf', f, 'application/pdf')}
            data = {
                'class_level': '9',
                'chapter_id': 'real_numbers',
                'force_reupload': 'true'  # Force upload for testing
            }
            
            response = requests.post('http://localhost:5001/upload', files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Upload successful!")
                print(f"🔥 Firebase status: {result.get('firebase_status')}")
                print(f"📱 Student download ready: {result.get('student_download_ready')}")
                print(f"💾 Firestore saved: {result.get('firestore_saved')}")
                if result.get('firebase_url'):
                    print(f"🔗 Firebase URL: {result.get('firebase_url')}")
                print(f"🧠 Chunks created: {result.get('chunks_created')}")
                print(f"📋 Message: {result.get('message')}")
            else:
                print(f"❌ Upload failed: {result.get('error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(response.text)
        
        # Clean up
        import os
        os.remove(pdf_path)
        
    except Exception as e:
        print(f"❌ Error in upload test: {e}")

if __name__ == '__main__':
    print("🧪 Testing Firebase Storage & Firestore Integration")
    print("=" * 50)
    
    # Basic API tests
    test_upload_chapter()
    
    # Try to install reportlab for PDF creation
    try:
        import reportlab
        print("\n🧪 Testing PDF upload...")
        test_upload_sample_pdf()
    except ImportError:
        print("\n⚠️  reportlab not installed - skipping PDF upload test")
        print("💡 To test PDF upload, install: pip install reportlab")
    
    print("\n✅ Test completed!")
    print("🌐 Visit http://localhost:5001 to use the web interface")
