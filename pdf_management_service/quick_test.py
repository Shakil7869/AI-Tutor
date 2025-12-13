import requests
import json

try:
    # Test server status
    response = requests.get('http://localhost:5001/status')
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print("✅ Server is running!")
        print(f"Firebase: {'✅' if data.get('firebase_initialized') else '❌'}")
        print(f"Firestore: {'✅' if data.get('firestore_available') else '❌'}")
        print(f"Pinecone: {'✅' if data.get('pinecone_initialized') else '❌'}")
    else:
        print(f"❌ Server error: {response.status_code}")
except Exception as e:
    print(f"❌ Connection failed: {e}")

# Test getting available chapters
try:
    response = requests.get('http://localhost:5001/api/chapters/available/9')
    print(f"\nChapters API Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Chapters API working! Found {len(data.get('chapters', []))} chapters")
    else:
        print(f"❌ Chapters API error: {response.status_code}")
except Exception as e:
    print(f"❌ Chapters API failed: {e}")
