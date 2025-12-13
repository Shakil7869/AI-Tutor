# 🔥 Firebase Integration Setup Guide

## Overview
Your AI Tutor app now supports Firebase for:
- **Firebase Storage**: PDF textbook storage
- **Firestore**: Chapter configuration and metadata
- **Automatic Fallback**: HTTP service when Firebase unavailable

## 🚀 Quick Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project: "ai-tutor-nctb"
3. Enable Google Analytics (optional)

### 2. Enable Firebase Services

#### **Firebase Storage**
1. Go to Storage in Firebase Console
2. Click "Get started"
3. Choose "Start in test mode" for now
4. Select your region

#### **Firestore Database**
1. Go to Firestore Database
2. Click "Create database"
3. Start in test mode
4. Choose your region

### 3. Configure Flutter App

#### **Download Configuration Files**
1. Go to Project Settings > General
2. Add Android app:
   - Package name: `com.example.student_ai_tutor`
   - Download `google-services.json`
   - Place in: `android/app/google-services.json`

3. Add iOS app (if needed):
   - Bundle ID: `com.example.studentAiTutor`
   - Download `GoogleService-Info.plist`
   - Place in: `ios/Runner/GoogleService-Info.plist`

#### **Download Service Account Key (for Python service)**
1. Go to Project Settings > Service Accounts
2. Click "Generate new private key"
3. Download JSON file
4. Rename to `firebase_config.json`
5. Place in: `pdf_management_service/config/firebase_config.json`

### 4. Update Configuration

#### **Update Storage Bucket Name**
In `pdf_management_service/pdf_manager_firebase.py`, line 53:
```python
'storageBucket': 'ai-tutor-nctb.appspot.com'  # Replace with your bucket
```

#### **Update Android Configuration**
Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

Add to `android/build.gradle`:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

## 🔧 Running with Firebase

### **Python Service (Firebase-enabled)**
```bash
# Start Firebase-enabled service
cd pdf_management_service
python pdf_manager_firebase.py
```

### **Flutter App (Firebase-enabled)**
```bash
# Run with Firebase
flutter run --dart-define=USE_FIREBASE=true

# Run without Firebase (HTTP only)
flutter run --dart-define=USE_FIREBASE=false
```

## 📊 Storage Architecture

### **PDF Files**
- **Firebase Storage**: `textbooks/nctb_class_9_math.pdf`
- **Local Cache**: `data/uploads/nctb_class_9_math.pdf`
- **Generated Chapters**: `chapters/chapter_9_real_numbers.pdf`

### **Configuration Data**
- **Firestore Collection**: `nctb_chapters`
  - Document: `class_9`
  - Fields: `chapters`, `updated_at`, `class_level`
- **Local Backup**: `data/chapter_ranges.json`

### **Metadata**
- **Firestore Collection**: `nctb_pdfs`
  - Document: `class_9`
  - Fields: `filename`, `total_pages`, `download_url`, `uploaded_at`

## 🔄 Migration from Local to Firebase

### **1. Upload Existing PDFs**
Your existing PDFs in `data/uploads/` will automatically be uploaded to Firebase Storage on first access.

### **2. Migrate Chapter Configuration**
Your `data/chapter_ranges.json` will be imported to Firestore automatically.

### **3. Hybrid Mode**
The system runs in hybrid mode:
- **Primary**: Firebase Storage + Firestore
- **Fallback**: Local files + HTTP service
- **Cache**: Local files for performance

## 🛡️ Security Rules

### **Firestore Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to NCTB chapters
    match /nctb_chapters/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow read access to PDF metadata
    match /nctb_pdfs/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### **Storage Rules**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read access to textbooks
    match /textbooks/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Allow read access to generated chapters
    match /chapters/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🔍 Troubleshooting

### **Firebase Connection Issues**
1. Check `google-services.json` is in correct location
2. Verify package name matches Firebase project
3. Ensure internet connection
4. Check Firebase Console for API quotas

### **Service Account Issues**
1. Verify `firebase_config.json` is valid JSON
2. Check service account has Storage Admin and Firestore User roles
3. Ensure project ID matches in configuration

### **Permission Errors**
1. Update Firestore and Storage security rules
2. Enable Authentication if needed
3. Check API keys are not restricted

## 📈 Benefits of Firebase Integration

### **Advantages**
- ✅ **Cloud Backup**: PDFs and configurations safe in cloud
- ✅ **Multi-Device**: Access from any device
- ✅ **Scalability**: Handles multiple users
- ✅ **Real-time**: Instant updates across devices
- ✅ **Offline Support**: Cached data works offline

### **Performance**
- 🚀 **Local Cache**: First access cached locally
- 🚀 **CDN**: Firebase Storage uses global CDN
- 🚀 **Compression**: Automatic image optimization
- 🚀 **Lazy Loading**: Download only needed content

---

**Status**: 🔥 Firebase integration ready
**Fallback**: 📁 Local storage always available
**Recommendation**: Use Firebase for production, local for development
