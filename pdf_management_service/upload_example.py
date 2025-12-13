#!/usr/bin/env python3
"""
Chapter PDF Upload Example
This script demonstrates how to upload individual chapter PDFs to the Chapter PDF Manager
"""

import requests
import os

# Configuration
API_BASE_URL = "http://localhost:5001"
UPLOAD_ENDPOINT = f"{API_BASE_URL}/upload_chapter_pdf"

def upload_chapter_pdf(pdf_file_path, class_level, chapter_id, chapter_name, subject="Mathematics"):
    """
    Upload a chapter PDF to the Chapter PDF Manager
    
    Args:
        pdf_file_path (str): Path to the PDF file
        class_level (int): Class level (9 or 10)
        chapter_id (str): Chapter identifier (e.g., 'real_numbers')
        chapter_name (str): Display name of the chapter
        subject (str): Subject name
    
    Returns:
        dict: Response from the server
    """
    
    if not os.path.exists(pdf_file_path):
        return {"error": f"File not found: {pdf_file_path}"}
    
    # Prepare the files and data
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
        print(f"📤 Uploading {chapter_name} (Class {class_level})...")
        response = requests.post(UPLOAD_ENDPOINT, files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print(f"✅ Successfully uploaded: {chapter_name}")
                print(f"   - Text chunks created: {result.get('chunks_created', 'N/A')}")
                print(f"   - Stored in Pinecone: {result.get('pinecone_stored', 'N/A')}")
                print(f"   - Firebase URL: {result.get('firebase_url', 'N/A')}")
            else:
                print(f"❌ Upload failed: {result.get('error', 'Unknown error')}")
            return result
        else:
            print(f"❌ HTTP Error {response.status_code}: {response.text}")
            return {"error": f"HTTP {response.status_code}"}
            
    except Exception as e:
        print(f"❌ Error uploading: {e}")
        return {"error": str(e)}
    finally:
        files['pdf_file'][1].close()

def check_chapter_availability(class_level, chapter_id):
    """Check if a chapter is available"""
    try:
        response = requests.get(f"{API_BASE_URL}/check_chapter_availability", params={
            'class_level': class_level,
            'chapter_id': chapter_id
        })
        return response.json()
    except Exception as e:
        return {"error": str(e)}

def search_chapter_content(query, class_level=None, chapter_id=None, top_k=5):
    """Search chapter content using vector similarity"""
    try:
        params = {
            'query': query,
            'top_k': top_k
        }
        if class_level:
            params['class_level'] = class_level
        if chapter_id:
            params['chapter_id'] = chapter_id
            
        response = requests.get(f"{API_BASE_URL}/search_chapter_content", params=params)
        return response.json()
    except Exception as e:
        return {"error": str(e)}

# Example usage
if __name__ == "__main__":
    print("🚀 Chapter PDF Upload Example")
    print("=" * 50)
    
    # Example: Upload Chapter 1 - Real Numbers for Class 9
    # Make sure you have a PDF file ready
    
    # EXAMPLE UPLOAD (uncomment and modify path as needed)
    """
    result = upload_chapter_pdf(
        pdf_file_path="path/to/your/chapter1_real_numbers.pdf",
        class_level=9,
        chapter_id="real_numbers", 
        chapter_name="বাস্তব সংখ্যা (Real Numbers)",
        subject="Mathematics"
    )
    print("Upload result:", result)
    """
    
    # Example: Check if a chapter is available
    print("\n📊 Checking chapter availability...")
    availability = check_chapter_availability(9, "real_numbers")
    print("Availability:", availability)
    
    # Example: Search content
    print("\n🔍 Searching content...")
    search_results = search_chapter_content(
        query="rational numbers",
        class_level=9,
        chapter_id="real_numbers",
        top_k=3
    )
    print("Search results:", search_results)
    
    print("\n" + "=" * 50)
    print("💡 To upload your own PDFs:")
    print("1. Save your chapter PDFs in a folder")
    print("2. Modify the upload_chapter_pdf() call above")
    print("3. Use the correct chapter_id from NCTB_CHAPTERS")
    print("4. Run this script")
    
    print("\n📚 Available Chapter IDs for Class 9:")
    chapter_ids = [
        "real_numbers", "sets_functions", "algebraic_expressions",
        "indices_logarithms", "linear_equations", "lines_angles_triangles",
        "practical_geometry", "circles", "trigonometric_ratios",
        "distance_height", "algebraic_ratios", "simultaneous_equations",
        "finite_series", "ratio_similarity_symmetry", "area_theorems",
        "mensuration", "statistics"
    ]
    
    for chapter_id in chapter_ids:
        print(f"   - {chapter_id}")
