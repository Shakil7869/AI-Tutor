#!/usr/bin/env python3
"""
Firebase Storage bucket verification and setup script
"""

import firebase_admin
from firebase_admin import credentials, storage
import os

def check_firebase_setup():
    """Check Firebase Storage setup and bucket existence"""
    
    try:
        # Initialize Firebase if not already done
        config_path = os.path.join(os.path.dirname(__file__), 'config', 'firebase_config.json')
        
        if not firebase_admin._apps:
            cred = credentials.Certificate(config_path)
            app = firebase_admin.initialize_app(cred, {
                'storageBucket': 'ai-tutor-oshan.firebasestorage.app'
            })
        
        # Try to access the bucket
        bucket = storage.bucket()
        print(f"✅ Successfully connected to Firebase Storage bucket: {bucket.name}")
        
        # Test bucket operations
        print("🔍 Testing bucket operations...")
        
        # List some objects (if any)
        blobs = list(bucket.list_blobs(max_results=5))
        print(f"📁 Found {len(blobs)} existing objects in bucket")
        
        for blob in blobs:
            print(f"  📄 {blob.name} ({blob.size} bytes)")
        
        # Test creating a test file
        print("\n🧪 Testing file upload...")
        test_blob = bucket.blob("test/connection_test.txt")
        test_content = "Firebase Storage connection test - " + str(datetime.now())
        test_blob.upload_from_string(test_content, content_type='text/plain')
        print("✅ Test file uploaded successfully")
        
        # Make it publicly readable
        test_blob.make_public()
        public_url = test_blob.public_url
        print(f"🔗 Public URL: {public_url}")
        
        # Delete test file
        test_blob.delete()
        print("🗑️ Test file cleaned up")
        
        return True
        
    except Exception as e:
        print(f"❌ Firebase Storage error: {e}")
        
        # Check if it's a bucket not found error
        if "bucket does not exist" in str(e) or "404" in str(e):
            print("\n💡 The Storage bucket doesn't exist yet.")
            print("🔧 To fix this:")
            print("1. Go to Firebase Console: https://console.firebase.google.com/")
            print("2. Select your project: ai-tutor-oshan")
            print("3. Go to Storage section")
            print("4. Click 'Get started' to initialize Storage")
            print("5. Choose your storage location (e.g., us-central1)")
            print("6. The bucket 'ai-tutor-oshan.appspot.com' will be created")
            return False
        
        # Check if it's a permissions error
        elif "403" in str(e) or "permission" in str(e).lower():
            print("\n💡 Permission error detected.")
            print("🔧 To fix this:")
            print("1. Go to Firebase Console > Project Settings > Service Accounts")
            print("2. Generate a new private key")
            print("3. Make sure the service account has 'Storage Admin' role")
            print("4. Update your firebase_config.json with the new credentials")
            return False
        
        else:
            print(f"\n💡 Unexpected error: {e}")
            return False

def create_storage_rules():
    """Create basic Storage security rules"""
    rules = """
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to read chapters
    match /chapters/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    
    // Allow public read access to chapters for students
    match /chapters/{classLevel}/{chapterId}.pdf {
      allow read: if true;  // Public read for PDFs
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
"""
    print("\n📋 Recommended Firebase Storage Rules:")
    print(rules)
    print("🔧 Apply these rules in Firebase Console > Storage > Rules")

if __name__ == '__main__':
    from datetime import datetime
    print("🔍 Checking Firebase Storage setup...")
    print("=" * 50)
    
    success = check_firebase_setup()
    
    if success:
        print("\n✅ Firebase Storage is properly configured!")
        print("🚀 You can now upload PDFs and store URLs in Firestore")
    else:
        print("\n❌ Firebase Storage needs configuration")
        create_storage_rules()
    
    print("\n" + "=" * 50)
