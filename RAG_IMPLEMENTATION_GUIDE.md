# NCTB RAG Pipeline Implementation Guide

## Overview

This document describes the complete implementation of the RAG (Retrieval-Augmented Generation) pipeline for the NCTB AI Tutor app. The system provides textbook-powered AI responses for Classes 9-12 using advanced chunking, embeddings, and vector search.

## Features Implemented

### 1. PDF Processing & Chunking
- **Smart Text Extraction**: Clean text extraction from PDF files with automatic cleanup
- **Chapter Detection**: Automatic detection of chapter boundaries using Bengali and English patterns
- **Intelligent Chunking**: Split text into 300-800 word chunks without breaking sentences
- **Metadata Generation**: Rich metadata for each chunk including class, subject, chapter, page number

### 2. Embeddings & Vector Storage
- **OpenAI Embeddings**: Uses `text-embedding-3-large` for high-quality embeddings
- **Pinecone Integration**: Serverless vector database for fast similarity search
- **Firestore Metadata**: Detailed metadata storage for chunks and references

### 3. RAG-Powered AI Responses
- **Semantic Search**: Find relevant textbook content for student questions
- **Context-Aware Answers**: AI responses based on actual textbook content
- **Source Attribution**: Show which textbook sections were used for answers
- **Out-of-Syllabus Detection**: Graceful handling when content is not in textbooks

### 4. Enhanced Features
- **Chapter Summaries**: AI-generated comprehensive chapter summaries
- **Quiz Generation**: Automatic MCQ and short answer questions from textbook content
- **Content Search**: Direct search through processed textbook content

### 5. Flutter Integration
- **Enhanced Chat Interface**: RAG vs. General AI toggle with source attribution
- **Class/Subject Selection**: Intuitive selection interface for students
- **Summary & Quiz Screens**: Dedicated interfaces for learning features

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PDF Files     │    │   RAG Pipeline   │    │  Vector DB      │
│  (Textbooks)    │───▶│  - Extract Text  │───▶│  (Pinecone)     │
│                 │    │  - Chunk Text    │    │  - Embeddings   │
│                 │    │  - Generate      │    │  - Metadata     │
│                 │    │    Embeddings    │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Flutter App    │◀───│   RAG API        │◀───│  Firestore      │
│  - Chat UI      │    │  - Question      │    │  - Metadata     │
│  - Summaries    │    │    Answering     │    │  - Full Text    │
│  - Quizzes      │    │  - Content       │    │                 │
│                 │    │    Search        │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Installation & Setup

### Prerequisites
- Python 3.8+
- Node.js (for Flutter)
- OpenAI API Key
- Pinecone API Key
- Firebase Project (optional)

### Backend Setup

1. **Navigate to the RAG service directory:**
   ```bash
   cd pdf_management_service
   ```

2. **Run the setup script:**
   ```bash
   # Windows
   setup_rag.bat
   
   # Linux/Mac
   python setup_rag.py
   ```

3. **Configure environment variables:**
   Edit the `.env` file:
   ```env
   OPENAI_API_KEY=your_openai_api_key_here
   PINECONE_API_KEY=your_pinecone_api_key_here
   FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
   ```

4. **Start the RAG API server:**
   ```bash
   # Windows
   start_rag_server.bat
   
   # Linux/Mac
   venv/bin/python rag_api_server.py
   ```

### Flutter Integration

1. **Update dependencies** in `pubspec.yaml`:
   ```yaml
   dependencies:
     dio: ^5.3.0  # For HTTP requests
     # ... other dependencies
   ```

2. **Configure RAG service URL** in `rag_service.dart`:
   ```dart
   static const String _baseUrl = 'http://localhost:5000'; // Update as needed
   ```

## Usage Guide

### 1. Uploading Textbooks

Visit `http://localhost:5000/admin/upload-form` to upload PDF textbooks:

- Select PDF file
- Choose class level (9, 10, 11, or 12)
- Select subject (Physics, Chemistry, Biology, Mathematics)
- Optional: Specify chapter name

The system will:
- Extract and clean text from the PDF
- Detect chapter boundaries automatically
- Generate embeddings for all chunks
- Store in Pinecone and Firestore

### 2. Using the Flutter App

#### Class & Subject Selection
```dart
// Navigate to selection screen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ClassSubjectSelectionScreen(userId: currentUser.id),
));
```

#### Enhanced Chat
```dart
// Start a RAG-powered chat
Navigator.push(context, MaterialPageRoute(
  builder: (context) => EnhancedChatScreen(
    classLevel: '10',
    subject: 'Physics',
    chapter: 'Light and Optics',
    userId: currentUser.id,
  ),
));
```

#### Chapter Summaries
```dart
// Generate chapter summary
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ChapterSummaryScreen(
    classLevel: '10',
    subject: 'Physics',
    chapter: 'Light and Optics',
  ),
));
```

#### Chapter Quizzes
```dart
// Generate chapter quiz
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ChapterQuizScreen(
    classLevel: '10',
    subject: 'Physics',
    chapter: 'Light and Optics',
  ),
));
```

### 3. AI Service Integration

The `AIService` now provides both RAG and traditional responses:

```dart
// Use RAG for textbook questions
final ragResponse = await aiService.generateRAGResponse(
  userMessage: "Explain refraction of light",
  classLevel: "10",
  subject: "Physics",
  chapter: "Light and Optics",
  userId: currentUser.id,
);

// Generate summaries
final summary = await aiService.generateChapterSummary(
  classLevel: "10",
  subject: "Physics",
  chapter: "Light and Optics",
);

// Generate quizzes
final quiz = await aiService.generateChapterQuiz(
  classLevel: "10",
  subject: "Physics",
  chapter: "Light and Optics",
  mcqCount: 5,
  shortCount: 2,
);
```

## API Endpoints

### Core RAG Endpoints

#### Upload Textbook
```http
POST /upload-textbook
Content-Type: multipart/form-data

file: [PDF file]
class_level: "10"
subject: "Physics"
chapter_name: "Light and Optics" (optional)
```

#### Ask Question
```http
POST /ask-question
Content-Type: application/json

{
  "question": "What is refraction of light?",
  "class_level": "10",
  "subject": "Physics",
  "chapter": "Light and Optics"
}
```

#### Search Content
```http
POST /search-content
Content-Type: application/json

{
  "query": "refraction",
  "class_level": "10",
  "subject": "Physics",
  "top_k": 5
}
```

#### Generate Summary
```http
POST /generate-summary
Content-Type: application/json

{
  "class_level": "10",
  "subject": "Physics",
  "chapter": "Light and Optics"
}
```

#### Generate Quiz
```http
POST /generate-quiz
Content-Type: application/json

{
  "class_level": "10",
  "subject": "Physics",
  "chapter": "Light and Optics",
  "mcq_count": 5,
  "short_count": 2
}
```

## Data Models

### Chunk Metadata
```python
@dataclass
class ChunkMetadata:
    class_level: str      # "10"
    subject: str          # "Physics"
    chapter: str          # "Light and Optics"
    chunk_id: str         # "10-physics-1-001"
    chapter_number: int   # 1
    page_number: int      # 45
    word_count: int       # 650
    created_at: str       # ISO timestamp
```

### Content Chunk
```dart
class ContentChunk {
  final String chunkId;
  final double score;     // Similarity score (0.0 - 1.0)
  final String text;
  final String classLevel;
  final String subject;
  final String chapter;
  final int pageNumber;
  final int wordCount;
}
```

### RAG Response
```dart
class RAGResponse {
  final String answer;
  final double confidence;
  final List<ContentChunk> sources;
  final String query;
  final String classLevel;
  final String? subject;
  final String? chapter;
}
```

## Configuration

### Chunking Parameters
```python
MIN_CHUNK_SIZE = 300    # Minimum words per chunk
MAX_CHUNK_SIZE = 800    # Maximum words per chunk
```

### Embedding Configuration
```python
EMBEDDING_MODEL = "text-embedding-3-large"  # 1536 dimensions
COMPLETION_MODEL = "gpt-4"                   # For responses
```

### Vector Database
```python
PINECONE_INDEX_NAME = "nctb-textbooks"
PINECONE_DIMENSION = 1536
PINECONE_METRIC = "cosine"
```

## Troubleshooting

### Common Issues

1. **RAG Service Not Available**
   - Check if the server is running on `http://localhost:5000`
   - Verify API keys in `.env` file
   - Check server logs for errors

2. **Poor Answer Quality**
   - Ensure relevant textbooks are uploaded
   - Check if the question matches textbook content
   - Adjust `top_k` parameter for more context

3. **Embedding Errors**
   - Verify OpenAI API key has embedding access
   - Check rate limits and usage
   - Ensure text chunks are not too long

4. **Vector Search Issues**
   - Verify Pinecone index exists and has data
   - Check dimension consistency (1536)
   - Ensure metadata filters are correct

### Performance Optimization

1. **Batch Processing**
   - Upload multiple chapters together
   - Use batch embedding generation
   - Implement caching for frequent queries

2. **Response Time**
   - Reduce `top_k` for faster search
   - Use shorter completion models for quick responses
   - Implement response caching

3. **Cost Management**
   - Monitor OpenAI usage
   - Use GPT-3.5 for less critical responses
   - Implement request throttling

## Curriculum Coverage

### Supported Classes & Subjects

- **Class 9**: Physics, Chemistry, Biology, Mathematics
- **Class 10**: Physics, Chemistry, Biology, Mathematics  
- **Class 11**: Physics, Chemistry, Biology, Mathematics
- **Class 12**: Physics, Chemistry, Biology, Mathematics

### Chapter Examples

Each subject includes multiple chapters:
- **Physics Class 10**: Heat and Temperature, Waves and Sound, Light and Optics, etc.
- **Chemistry Class 10**: Atomic Structure, Periodic Table, Chemical Bonding, etc.
- **Biology Class 10**: Nutrition, Respiration, Transportation, etc.
- **Mathematics Class 10**: Trigonometry, Geometry, Coordinate Geometry, etc.

## Future Enhancements

1. **Advanced Features**
   - Multi-language support (Bengali/English)
   - Voice interaction
   - Diagram/figure recognition
   - Mathematical equation processing

2. **Analytics**
   - Student learning analytics
   - Content effectiveness tracking
   - Performance dashboards

3. **Content Management**
   - Automated textbook updates
   - Version control for content
   - Quality assurance workflows

4. **Scalability**
   - Horizontal scaling
   - CDN integration
   - Advanced caching strategies

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review server logs in the `logs/` directory
3. Test with the web interface at `/admin/upload-form`
4. Verify API connectivity with health check endpoint `/`

The RAG pipeline provides a robust foundation for textbook-powered AI tutoring, ensuring students get accurate, curriculum-aligned responses to their questions.
