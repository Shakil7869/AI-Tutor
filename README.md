# Student AI Tutor - Production MVP

A comprehensive AI-powered learning application for Class 9-10 Mathematics students with personalized tutoring and practice modes.

## 🚀 Features

### Core Functionality
- **AI Tutor Chat**: Real-time AI assistance using OpenAI GPT-3.5 Turbo
- **Practice Mode**: Adaptive quizzes with performance tracking  
- **Progress Analytics**: Detailed charts and insights using fl_chart
- **Multi-platform**: Android, iOS, Web support

### Technical Stack
- **Frontend**: Flutter 3.5.4+ with Material Design 3
- **State Management**: Riverpod with providers
- **Backend**: Firebase (Auth, Firestore, Cloud Functions, Storage)
- **AI Integration**: OpenAI API + Pinecone vector database
- **Navigation**: GoRouter for type-safe routing
- **Charts**: fl_chart for progress visualization

## 📱 App Architecture

```
lib/
├── src/
│   ├── core/                  # Core configuration
│   │   ├── config/           # App, theme, Firebase config
│   │   └── routing/          # Navigation setup
│   ├── features/             # Feature modules
│   │   ├── auth/            # Authentication
│   │   ├── dashboard/       # Main dashboard
│   │   ├── learn/           # AI tutor chat
│   │   ├── practice/        # Quiz system
│   │   ├── progress/        # Analytics
│   │   └── subjects/        # Subject navigation
│   └── shared/              # Shared components
│       ├── models/          # Data models
│       ├── services/        # Business logic
│       └── widgets/         # Reusable UI
└── main.dart               # App entry point
```

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK 3.5.4+
- Firebase CLI
- Android Studio / VS Code
- OpenAI API account
- Pinecone account

### 1. Clone & Install Dependencies
```bash
git clone <repository-url>
cd ai_tutor_mvp
flutter pub get
```

### 2. Firebase Setup
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase project
flutterfire configure --project=your-project-id
```

### 3. API Keys Configuration
Create a `.env` file in the project root with your API keys:
```env
# OpenAI Configuration
OPENAI_API_KEY=your-actual-openai-api-key-here

# Pinecone Configuration
PINECONE_API_KEY=your-actual-pinecone-api-key-here

# Firebase Configuration (from your Firebase service account)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY=your-private-key-here
FIREBASE_CLIENT_EMAIL=your-client-email@firebase.com
FIREBASE_CLIENT_ID=your-client-id
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=your-client-x509-cert-url
```

**Important:** Never commit the `.env` file to version control. It's listed in `.gitignore` for security.
Reference `.env.example` for the required variables format.

### 4. Firebase Collections Setup
Create the following Firestore collections:
- `users` - User profiles and preferences
- `progress` - User progress tracking
- `study_sessions` - Learning session logs
- `quiz_questions` - Question bank (optional, AI generates if empty)

### 5. Security Rules
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /progress/{progressId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    match /study_sessions/{sessionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    match /quiz_questions/{questionId} {
      allow read: if request.auth != null;
    }
  }
}
```

## 🚀 Deployment

### Android
```bash
# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS
flutter build ios --release
```

### Web
```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## 🔐 Environment Variables

All sensitive configuration is managed through environment variables in the `.env` file.

### Setup
1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Fill in your actual credentials:
   ```env
   OPENAI_API_KEY=sk-...
   FIREBASE_PROJECT_ID=your-project-id
   # ... (see .env.example for all required variables)
   ```

3. The application automatically loads these at runtime using `flutter_dotenv`

### Security Best Practices
- ✅ Never commit `.env` to version control
- ✅ Each developer/environment has their own `.env`
- ✅ Use different credentials for dev/staging/production
- ✅ Rotate API keys regularly
- ✅ Monitor API usage and costs

## 📊 Firebase Analytics Events

Track key user interactions:
```dart
// Example events to implement
- 'ai_chat_started'
- 'quiz_completed' 
- 'topic_progress_updated'
- 'study_session_ended'
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart
```

## 🔍 Performance Monitoring

1. Enable Firebase Performance Monitoring
2. Set up Crashlytics for error tracking
3. Monitor API usage and costs
4. Track user engagement metrics

## 📱 App Store Guidelines

### Android (Google Play)
- Target API level 34+
- 64-bit support enabled
- App signing configured
- Content rating: Educational

### iOS (App Store)
- iOS 12.0+ minimum deployment target
- App Store Review Guidelines compliance
- Educational app category
- Privacy policy required

## 🔧 Maintenance

### Regular Updates
- Update dependencies monthly
- Monitor OpenAI API changes
- Update Firebase SDKs
- Review and update content

### Cost Optimization
- Monitor OpenAI API usage
- Implement response caching
- Optimize Firestore queries
- Use Firebase Cloud Functions for heavy operations

## 📞 Support

### Technical Issues
- Check Firebase console for backend errors
- Monitor OpenAI API logs
- Review app logs via Firebase Crashlytics

### Content Updates
- Add new topics via Firestore
- Update AI prompts in ai_service.dart
- Expand question database

## 🚀 Scaling Considerations

### Performance
- Implement proper caching strategies
- Use Firebase Cloud Functions for backend logic
- Consider CDN for static assets
- Optimize image loading

### Features to Add
- Multiple subjects (Physics, Chemistry)
- Advanced analytics dashboard
- Offline mode support
- Parent/teacher portal
- Premium subscriptions

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Production Checklist:**
- ✅ Firebase project configured
- ✅ API keys secured
- ✅ Security rules implemented
- ✅ Performance monitoring enabled
- ✅ App store assets prepared
- ✅ Privacy policy created
- ✅ Terms of service written
- ✅ Beta testing completed
