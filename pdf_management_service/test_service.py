#!/usr/bin/env python3
"""
Test Script for Chapter PDF Service
Verify all endpoints are working correctly
"""

import requests
import json

API_BASE_URL = "http://localhost:5001"

def test_service_status():
    """Test if the service is running"""
    print("🔍 Testing service status...")
    try:
        response = requests.get(f"{API_BASE_URL}/", timeout=5)
        if response.status_code == 200:
            print("✅ Service is running!")
            print(f"   Response: {response.text}")
            return True
        else:
            print(f"❌ Service returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to service: {e}")
        return False

def test_search_endpoint():
    """Test the search functionality"""
    print("\n🔍 Testing search endpoint...")
    
    test_queries = [
        "real numbers",
        "algebra",
        "mathematics basic concepts"
    ]
    
    for query in test_queries:
        try:
            response = requests.post(
                f"{API_BASE_URL}/search_chapter_content",
                json={
                    "query": query,
                    "class_level": 9,
                    "subject": "Mathematics",
                    "top_k": 3
                },
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Search '{query}': Found {len(result.get('results', []))} results")
            else:
                print(f"❌ Search '{query}': Status {response.status_code}")
                
        except Exception as e:
            print(f"❌ Search '{query}': Error {e}")

def test_chapter_availability():
    """Test chapter availability check"""
    print("\n🔍 Testing chapter availability...")
    
    test_chapters = [
        ("real_numbers", 9, "Mathematics"),
        ("sets_functions", 9, "Mathematics"),
        ("nonexistent_chapter", 9, "Mathematics")
    ]
    
    for chapter_id, class_level, subject in test_chapters:
        try:
            response = requests.get(
                f"{API_BASE_URL}/check_chapter_availability",
                params={
                    "chapter_id": chapter_id,
                    "class_level": class_level,
                    "subject": subject
                },
                timeout=5
            )
            
            if response.status_code == 200:
                result = response.json()
                available = result.get("available", False)
                status = "✅ Available" if available else "❌ Not available"
                print(f"   {chapter_id}: {status}")
            else:
                print(f"   {chapter_id}: HTTP {response.status_code}")
                
        except Exception as e:
            print(f"   {chapter_id}: Error {e}")

def test_pinecone_status():
    """Test Pinecone integration status"""
    print("\n🔍 Testing Pinecone integration...")
    try:
        response = requests.get(f"{API_BASE_URL}/pinecone_status", timeout=5)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Pinecone Status: {result}")
        else:
            print(f"❌ Pinecone status check failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Pinecone status error: {e}")

def test_openai_status():
    """Test OpenAI integration"""
    print("\n🔍 Testing OpenAI integration...")
    try:
        # Try a small embedding test
        response = requests.post(
            f"{API_BASE_URL}/test_openai",
            json={"text": "Hello world"},
            timeout=10
        )
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print("✅ OpenAI integration working")
            else:
                print(f"❌ OpenAI test failed: {result.get('error')}")
        else:
            print(f"❌ OpenAI test HTTP {response.status_code}")
    except Exception as e:
        print(f"❌ OpenAI test error: {e}")

def run_all_tests():
    """Run all tests"""
    print("🧪 Chapter PDF Service Test Suite")
    print("=" * 50)
    
    # Test service status first
    if not test_service_status():
        print("\n❌ Service is not running. Please start the service first:")
        print("   cd pdf_management_service")
        print("   python chapter_pdf_manager.py")
        return
    
    # Run other tests
    test_search_endpoint()
    test_chapter_availability()
    test_pinecone_status()
    test_openai_status()
    
    print("\n" + "=" * 50)
    print("🎉 Test suite completed!")
    print("\nNext steps:")
    print("1. Upload some chapter PDFs using upload_example.py or batch_upload.py")
    print("2. Test the search functionality with actual content")
    print("3. Integrate with your Flutter app")

if __name__ == "__main__":
    run_all_tests()
