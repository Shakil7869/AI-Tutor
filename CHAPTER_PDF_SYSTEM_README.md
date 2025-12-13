# Chapter PDF Management System

## Overview

This system has been completely redesigned to handle individual chapter PDFs instead of full textbooks with page ranges. The new architecture includes:

### 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Chapter PDF System                       │
├─────────────────────────────────────────────────────────────┤
│  Flutter App                                               │
│  ├── ChapterPdfService (Downloads individual chapters)     │
│  ├── AIService (Uses Pinecone for context)                 │
│  └── PDFViewerWidget (Displays chapter PDFs)               │
├─────────────────────────────────────────────────────────────┤
│  Python Flask Service                                      │
│  ├── ChapterPDFManager (Uploads & processes PDFs)          │
│  ├── Pinecone Integration (Vector search)                  │
│  ├── OpenAI Embeddings (Text chunking)                     │
│  └── Firebase Storage (Chapter PDF storage)                │
├─────────────────────────────────────────────────────────────┤
│  Storage & AI                                              │
│  ├── Firebase Storage (Individual chapter PDFs)            │
│  ├── Pinecone Vector DB (Text chunks for AI context)       │
│  └── OpenAI API (Embeddings & Chat completions)            │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **Python 3.8+** with pip
2. **Flutter SDK** (latest stable)
3. **Firebase Project** with Storage enabled
4. **Pinecone Account** with an index
5. **OpenAI API Key**

### 1. Setup Python Service

#### Windows:
```bash
# Run the startup script
start_chapter_service.bat
```

#### Linux/macOS:
```bash
# Make script executable and run
chmod +x start_chapter_service.sh
./start_chapter_service.sh
```

#### Manual Setup:
```bash
cd pdf_management_service

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables (see Configuration section)
# Start the service
python chapter_pdf_manager.py
```

### 2. Configure Environment Variables

Create a `.env` file in the `pdf_management_service` directory:

```env
# Pinecone Configuration
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_ENVIRONMENT=us-west1-gcp-free  # or your environment
PINECONE_INDEX_NAME=chapter-pdfs

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_PATH=path/to/your/firebase-service-account.json
FIREBASE_STORAGE_BUCKET=your-project-id.appspot.com

# Flask Configuration
FLASK_PORT=5000
FLASK_DEBUG=False
```

### 3. Setup Flutter App

```bash
# Get dependencies
flutter pub get

# Update AppConfig with your service URL
# In lib/src/core/config/app_config.dart:
# static const String chapterPdfServiceUrl = 'http://your-server:5000';

# Run the app
flutter run
```

## 📁 System Components

### 🐍 Python Flask Service

**Location**: `pdf_management_service/chapter_pdf_manager.py`

**Features**:
- Upload individual chapter PDFs
- Extract text and create chunks
- Generate embeddings using OpenAI
- Store vectors in Pinecone
- Upload PDFs to Firebase Storage
- Search functionality for AI context

**API Endpoints**:

```python
POST /upload_chapter_pdf
# Upload a chapter PDF with metadata
{
    "class_level": 9,
    "chapter_id": "algebra_basics",
    "chapter_name": "Algebra Basics",
    "subject": "Mathematics"
}

GET /search_chapter_content
# Search for relevant content
{
    "query": "quadratic equations",
    "class_level": 9,
    "chapter_id": "algebra_basics",
    "top_k": 3
}

GET /check_chapter_availability
# Check if chapter PDF is available
```

### 📱 Flutter Services

#### ChapterPdfService
**Location**: `lib/src/shared/services/chapter_pdf_service.dart`

**Functions**:
- `downloadChapterPDF()` - Download individual chapters
- `isChapterAvailable()` - Check availability
- `searchChapterContent()` - Search for AI context

#### Updated AIService
**Location**: `lib/src/shared/services/ai_service.dart`

**Features**:
- Uses Pinecone vector search for context
- Enhanced with chapter-specific knowledge
- Supports Bengali and English mixed responses

### 🖼️ Flutter Widgets

#### ChapterPDFViewerWidget
**Location**: `lib/src/features/learn/presentation/widgets/chapter_pdf_viewer_widget.dart`

**Features**:
- Displays individual chapter PDFs
- Text selection for AI queries
- Simplified interface (no page ranges)

## 🔄 Migration from Old System

### ✅ Completed Changes

1. **Removed Page Range System**:
   - ❌ Old: `pdf_service.dart`, `pdf_service_firebase.dart`
   - ✅ New: `chapter_pdf_service.dart`

2. **New Python Service**:
   - ❌ Old: Page extraction from full textbooks
   - ✅ New: Individual chapter PDF processing with Pinecone

3. **Updated AI Integration**:
   - ❌ Old: Basic text context
   - ✅ New: Vector search with chunked content

4. **Simplified PDF Viewer**:
   - ❌ Old: Complex page range navigation
   - ✅ New: Direct chapter viewing

### 🔧 Files Updated

- `lib/src/features/learn/presentation/screens/learn_mode_screen.dart` ✅
- `lib/src/features/learn/presentation/widgets/chapter_pdf_viewer_widget.dart` ✅
- `lib/src/shared/services/ai_service.dart` ✅
- `lib/src/shared/services/chapter_pdf_service.dart` ✅
- `pdf_management_service/chapter_pdf_manager.py` ✅
- `pdf_management_service/requirements.txt` ✅

### 🗑️ Files Removed

- `lib/src/shared/services/pdf_service.dart`
- `lib/src/shared/services/pdf_service_firebase.dart`
- `lib/src/shared/services/pdf_book_service.dart`
- `lib/src/shared/services/pdf_service_new.dart`
- `lib/src/features/learn/presentation/widgets/pdf_viewer_widget.dart`

### ⚠️ Files Needing Updates

The following files still reference old services and may need updates:

- `lib/src/features/settings/presentation/screens/pdf_settings_screen.dart`
- `lib/src/features/subjects/presentation/screens/subject_list_screen.dart`
- `lib/src/shared/managers/pdf_cache_manager.dart`

## 🎯 Usage Workflow

### For Teachers (PDF Upload):

1. **Start Python Service**: Run `start_chapter_service.bat` or `.sh`
2. **Upload Chapter**: Use API or web interface to upload individual chapter PDFs
3. **Automatic Processing**: System extracts text, creates chunks, generates embeddings
4. **Storage**: PDF stored in Firebase, vectors in Pinecone

### For Students (Learning):

1. **Open Learn Mode**: Navigate to a chapter in the Flutter app
2. **Access PDF**: Click PDF icon to view chapter content
3. **Interactive Learning**: Highlight text to ask AI questions
4. **Enhanced AI**: AI uses Pinecone to find relevant context from uploaded chapters

## 🔍 API Usage Examples

### Upload a Chapter PDF

```bash
curl -X POST http://localhost:5000/upload_chapter_pdf \
  -F "pdf_file=@chapter1_algebra.pdf" \
  -F "class_level=9" \
  -F "chapter_id=algebra_basics" \
  -F "chapter_name=Algebra Basics" \
  -F "subject=Mathematics"
```

### Search Chapter Content

```bash
curl -X GET "http://localhost:5000/search_chapter_content" \
  -G -d "query=quadratic equations" \
  -d "class_level=9" \
  -d "chapter_id=algebra_basics" \
  -d "top_k=3"
```

### Check Chapter Availability

```bash
curl -X GET "http://localhost:5000/check_chapter_availability" \
  -G -d "class_level=9" \
  -d "chapter_id=algebra_basics"
```

## 🐛 Troubleshooting

### Common Issues

1. **Pinecone Connection Error**:
   - Check API key and environment
   - Ensure index exists and has correct dimensions (1536 for OpenAI embeddings)

2. **Firebase Upload Error**:
   - Verify service account JSON file path
   - Check Firebase Storage rules
   - Ensure bucket name is correct

3. **OpenAI API Error**:
   - Verify API key is valid
   - Check quota limits
   - Ensure network connectivity

4. **Flutter Build Errors**:
   - Run `flutter clean && flutter pub get`
   - Check for missing dependencies
   - Update import paths if needed

### Debug Mode

Enable debug mode in `.env`:
```env
FLASK_DEBUG=True
```

This provides detailed error messages and auto-reload on code changes.

## 📊 System Benefits

### Advantages of New System:

1. **Better Organization**: Individual chapters instead of page ranges
2. **Enhanced AI**: Vector search provides better context
3. **Improved Performance**: No need to extract pages at runtime
4. **Easier Management**: Upload chapters independently
5. **Better UX**: Direct chapter access without complex navigation
6. **Scalable**: Can handle multiple subjects and classes
7. **AI-Powered**: Automatic text chunking and embedding generation

### Technical Improvements:

- **Microservice Architecture**: Python service handles PDF processing
- **Vector Search**: Pinecone enables semantic search for AI context
- **Cloud Storage**: Firebase for reliable PDF storage
- **Modern Stack**: Flask + Flutter + AI/ML integration
- **Error Handling**: Comprehensive error handling and validation
- **Documentation**: Auto-generated API docs at `/docs`

## 🔮 Future Enhancements

- **Web Upload Interface**: HTML form for easier chapter uploads
- **Batch Processing**: Upload multiple chapters at once
- **Progress Tracking**: Upload and processing progress indicators
- **Advanced Search**: Filter by difficulty, topic, etc.
- **Analytics**: Usage statistics and learning analytics
- **Multi-language**: Support for more regional languages

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review API documentation at `http://localhost:5000/docs`
3. Check console logs for detailed error messages
4. Ensure all environment variables are correctly set
