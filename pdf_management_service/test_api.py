import requests
import json

# Test the download_info endpoint
try:
    response = requests.get('http://localhost:5001/api/chapter/9/real_numbers/download_info')
    print(f"Download Info Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("✅ Download Info Response:")
        print(json.dumps(data, indent=2))
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"❌ Test failed: {e}")

# Test available chapters
try:
    response = requests.get('http://localhost:5001/api/chapters/available/9')
    print(f"\nAvailable Chapters Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("✅ Available Chapters Response:")
        chapters = data.get('chapters', [])[:2]  # Show first 2
        for chapter in chapters:
            print(f"  - {chapter.get('chapter_id')}: {chapter.get('displayTitle')} - Available: {chapter.get('is_available')}")
    else:
        print(f"❌ Error: {response.status_code}")
        
except Exception as e:
    print(f"❌ Test failed: {e}")
