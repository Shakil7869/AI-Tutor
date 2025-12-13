#!/usr/bin/env python3
"""
Batch Chapter PDF Upload Script
Upload multiple chapter PDFs at once
"""

import os
import requests
import time
from pathlib import Path

# Configuration
API_BASE_URL = "http://localhost:5001"
UPLOAD_ENDPOINT = f"{API_BASE_URL}/upload_chapter_pdf"

# Chapter mapping - modify these according to your PDF files
CHAPTER_MAPPING = {
    # Format: "your_pdf_filename.pdf": ("chapter_id", "chapter_name")
    "chapter1_real_numbers.pdf": ("real_numbers", "বাস্তব সংখ্যা (Real Numbers)"),
    "chapter2_sets_functions.pdf": ("sets_functions", "সেট ও ফাংশন (Sets and Functions)"),
    "chapter3_algebraic_expressions.pdf": ("algebraic_expressions", "বীজগাণিতিক রাশি (Algebraic Expressions)"),
    "chapter4_indices_logarithms.pdf": ("indices_logarithms", "সূচক ও লগারিদম (Indices and Logarithms)"),
    "chapter5_linear_equations.pdf": ("linear_equations", "এক চলকবিশিষ্ট সমীকরণ (Linear Equations)"),
    # Add more chapters as needed...
}

def upload_chapter_pdf(pdf_file_path, class_level, chapter_id, chapter_name, subject="Mathematics"):
    """Upload a single chapter PDF"""
    
    if not os.path.exists(pdf_file_path):
        return {"error": f"File not found: {pdf_file_path}"}
    
    files = {
        'pdf_file': ('chapter.pdf', open(pdf_file_path, 'rb'), 'application/pdf')
    }
    
    data = {
        'class_level': class_level,
        'chapter_id': chapter_id,
        'chapter_name': chapter_name,
        'subject': subject
    }
    
    try:
        print(f"📤 Uploading {chapter_name}...")
        response = requests.post(UPLOAD_ENDPOINT, files=files, data=data, timeout=300)  # 5 minute timeout
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print(f"✅ SUCCESS: {chapter_name}")
                print(f"   📄 Chunks: {result.get('chunks_created', 'N/A')}")
                print(f"   🧠 Pinecone: {result.get('pinecone_stored', 'N/A')}")
                print(f"   ☁️  Firebase: {'Yes' if result.get('firebase_url') else 'No'}")
            else:
                print(f"❌ FAILED: {chapter_name} - {result.get('error', 'Unknown error')}")
            return result
        else:
            print(f"❌ HTTP Error {response.status_code}: {response.text}")
            return {"error": f"HTTP {response.status_code}"}
            
    except Exception as e:
        print(f"❌ Error uploading {chapter_name}: {e}")
        return {"error": str(e)}
    finally:
        files['pdf_file'][1].close()

def batch_upload_chapters(pdf_folder, class_level, subject="Mathematics"):
    """Upload all chapter PDFs from a folder"""
    
    if not os.path.exists(pdf_folder):
        print(f"❌ Folder not found: {pdf_folder}")
        return
    
    print(f"🚀 Starting batch upload from: {pdf_folder}")
    print(f"📚 Class: {class_level}, Subject: {subject}")
    print("=" * 60)
    
    uploaded_count = 0
    failed_count = 0
    
    # Find PDF files in the folder
    pdf_files = [f for f in os.listdir(pdf_folder) if f.lower().endswith('.pdf')]
    
    if not pdf_files:
        print("❌ No PDF files found in the folder")
        return
    
    print(f"📁 Found {len(pdf_files)} PDF files")
    print()
    
    for pdf_file in pdf_files:
        pdf_path = os.path.join(pdf_folder, pdf_file)
        
        # Check if we have mapping for this file
        if pdf_file in CHAPTER_MAPPING:
            chapter_id, chapter_name = CHAPTER_MAPPING[pdf_file]
            
            # Upload the chapter
            result = upload_chapter_pdf(pdf_path, class_level, chapter_id, chapter_name, subject)
            
            if result.get('success'):
                uploaded_count += 1
            else:
                failed_count += 1
                
        else:
            print(f"⚠️  SKIPPING {pdf_file} - No mapping found")
            print(f"   Add it to CHAPTER_MAPPING in this script")
            failed_count += 1
        
        print()  # Empty line for readability
        time.sleep(2)  # Small delay between uploads
    
    print("=" * 60)
    print(f"📊 Upload Summary:")
    print(f"   ✅ Successful: {uploaded_count}")
    print(f"   ❌ Failed: {failed_count}")
    print(f"   📁 Total files: {len(pdf_files)}")

def auto_detect_and_upload(pdf_folder, class_level, subject="Mathematics"):
    """Auto-detect chapter PDFs based on filename patterns"""
    
    if not os.path.exists(pdf_folder):
        print(f"❌ Folder not found: {pdf_folder}")
        return
    
    # Auto-detection patterns
    patterns = {
        'real': ('real_numbers', 'বাস্তব সংখ্যা (Real Numbers)'),
        'set': ('sets_functions', 'সেট ও ফাংশন (Sets and Functions)'),
        'algebra': ('algebraic_expressions', 'বীজগাণিতিক রাশি (Algebraic Expressions)'),
        'indic': ('indices_logarithms', 'সূচক ও লগারিদম (Indices and Logarithms)'),
        'linear': ('linear_equations', 'এক চলকবিশিষ্ট সমীকরণ (Linear Equations)'),
        'line': ('lines_angles_triangles', 'রেখা, কোণ ও ত্রিভুজ (Lines, Angles and Triangles)'),
        'geometry': ('practical_geometry', 'ব্যবহারিক জ্যামিতি (Practical Geometry)'),
        'circle': ('circles', 'বৃত্ত (Circles)'),
        'trigon': ('trigonometric_ratios', 'ত্রিকোণমিতিক অনুপাত (Trigonometric Ratios)'),
        'distance': ('distance_height', 'দূরত্ব ও উচ্চতা (Distance and Height)'),
        'ratio': ('algebraic_ratios', 'বীজগাণিতিক অনুপাত ও সমানুপাত (Algebraic Ratios)'),
        'simultaneous': ('simultaneous_equations', 'দুই চলকবিশিষ্ট সরল সহসমীকরণ (Simultaneous Linear Equations)'),
        'finite': ('finite_series', 'সসীম ধারা (Finite Series)'),
        'similarity': ('ratio_similarity_symmetry', 'অনুপাত, সদৃশতা ও প্রতিসমতা (Ratio, Similarity and Symmetry)'),
        'area': ('area_theorems', 'ক্ষেত্রফল সম্পর্কিত উপপাদ্য ও সম্পাদ্য (Area Related Theorems)'),
        'mensur': ('mensuration', 'পরিমিতি (Mensuration)'),
        'statistic': ('statistics', 'পরিসংখ্যান (Statistics)'),
    }
    
    print(f"🤖 Auto-detecting chapters in: {pdf_folder}")
    print(f"📚 Class: {class_level}, Subject: {subject}")
    print("=" * 60)
    
    pdf_files = [f for f in os.listdir(pdf_folder) if f.lower().endswith('.pdf')]
    uploaded_count = 0
    failed_count = 0
    
    for pdf_file in pdf_files:
        pdf_path = os.path.join(pdf_folder, pdf_file)
        filename_lower = pdf_file.lower()
        
        # Try to match patterns
        matched = False
        for pattern, (chapter_id, chapter_name) in patterns.items():
            if pattern in filename_lower:
                print(f"🎯 Detected: {pdf_file} → {chapter_name}")
                
                result = upload_chapter_pdf(pdf_path, class_level, chapter_id, chapter_name, subject)
                
                if result.get('success'):
                    uploaded_count += 1
                else:
                    failed_count += 1
                
                matched = True
                break
        
        if not matched:
            print(f"❓ Could not detect chapter type for: {pdf_file}")
            failed_count += 1
        
        print()
        time.sleep(2)
    
    print("=" * 60)
    print(f"📊 Auto-Upload Summary:")
    print(f"   ✅ Successful: {uploaded_count}")
    print(f"   ❌ Failed/Undetected: {failed_count}")
    print(f"   📁 Total files: {len(pdf_files)}")

if __name__ == "__main__":
    print("📚 Chapter PDF Batch Upload Tool")
    print("=" * 60)
    
    # Configuration - MODIFY THESE PATHS
    PDF_FOLDER = "chapters"  # Folder containing your chapter PDFs
    CLASS_LEVEL = 9          # Class 9 or 10
    SUBJECT = "Mathematics"  # Subject name
    
    print("Choose upload method:")
    print("1. Batch upload with filename mapping")
    print("2. Auto-detect chapters from filenames") 
    print("3. Manual single upload")
    
    choice = input("\nEnter choice (1-3): ").strip()
    
    if choice == "1":
        batch_upload_chapters(PDF_FOLDER, CLASS_LEVEL, SUBJECT)
        
    elif choice == "2":
        auto_detect_and_upload(PDF_FOLDER, CLASS_LEVEL, SUBJECT)
        
    elif choice == "3":
        pdf_path = input("Enter PDF file path: ").strip()
        chapter_id = input("Enter chapter ID (e.g., real_numbers): ").strip()
        chapter_name = input("Enter chapter name: ").strip()
        
        result = upload_chapter_pdf(pdf_path, CLASS_LEVEL, chapter_id, chapter_name, SUBJECT)
        print("Result:", result)
        
    else:
        print("❌ Invalid choice")
    
    print("\n🎉 Upload process completed!")
