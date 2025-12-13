# PDF Book Management System for NCTB AI Tutor

## Overview
This system allows you to upload NCTB mathematics PDF textbooks and automatically organize them by chapters with specific page ranges. Students can then view the relevant PDF pages while chatting with the AI tutor and select text from PDFs to ask specific questions.

## System Architecture

### 1. Python PDF Management Service
- Upload PDF books for Class 9 and 10
- Configure page ranges for each NCTB chapter
- Extract text content for AI integration
- Serve PDF pages to Flutter app

### 2. Flutter PDF Viewer Integration
- Display PDF pages in chat screen
- Text selection functionality
- AI integration with selected PDF content
- Chapter-based PDF navigation

## Features

### For Administrators/Teachers:
1. **PDF Upload**: Upload NCTB mathematics textbooks (Class 9 & 10)
2. **Chapter Configuration**: Set page ranges for each of the 17 chapters
3. **Content Management**: Organize PDFs by class and chapter
4. **Text Extraction**: Automatic text extraction for AI context

### For Students:
1. **Chapter-Based PDF Access**: View only relevant pages for current chapter
2. **Text Selection**: Select text from PDF to ask AI questions
3. **Integrated Learning**: Seamless transition between PDF reading and AI chat
4. **Multiple Solution Methods**: AI can solve problems in different ways

## Setup Instructions

### Phase 1: Python PDF Service Setup

1. **Install Python Dependencies**:
   ```bash
   pip install flask pymupdf pillow firebase-admin google-cloud-storage
   ```

2. **Configure Firebase**:
   - Create Firebase project
   - Enable Cloud Storage
   - Download service account key
   - Set up storage bucket

3. **Run PDF Management Service**:
   ```bash
   python pdf_manager.py
   ```

4. **Upload PDF Books**:
   - Access web interface at `http://localhost:5000`
   - Upload Class 9 and Class 10 NCTB math books
   - Configure page ranges for each chapter

### Phase 2: Flutter App Integration

1. **Add PDF Dependencies** to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_pdfview: ^1.3.2
     syncfusion_flutter_pdfviewer: ^25.2.7
     http: ^1.1.0
     path_provider: ^2.1.1
   ```

2. **Update Firebase Configuration**:
   - Enable Storage rules
   - Configure PDF download permissions

3. **Test Integration**:
   - Open chapter in app
   - Verify PDF loads with correct page range
   - Test text selection and AI integration

## Configuration Format

### Chapter Page Ranges (Example for Class 9):
```json
{
  "class_9": {
    "real_numbers": {"start": 2, "end": 20, "chapter_number": 1},
    "sets_functions": {"start": 21, "end": 35, "chapter_number": 2},
    "algebraic_expressions": {"start": 36, "end": 52, "chapter_number": 3},
    // ... continue for all 17 chapters
  }
}
```

## API Endpoints

### Python PDF Service:

1. **Upload PDF**: `POST /upload`
   - Upload PDF file for specific class
   - Parameters: `file`, `class_level`

2. **Configure Chapters**: `POST /configure`
   - Set page ranges for chapters
   - Parameters: `class_level`, `chapter_ranges`

3. **Get PDF Pages**: `GET /pdf/<class>/<chapter>`
   - Returns PDF with specific page range
   - Parameters: `class`, `chapter`

4. **Extract Text**: `GET /text/<class>/<chapter>/<page>`
   - Returns extracted text from specific page
   - Parameters: `class`, `chapter`, `page`

### Flutter API Integration:

1. **PDF Service Provider**: Manages PDF downloads and caching
2. **Text Selection Service**: Handles text extraction from selected areas
3. **AI Integration Service**: Sends selected text to AI with PDF context

## Workflow

### Administrator Workflow:
1. Start Python PDF service
2. Access web interface
3. Upload NCTB PDF books for Class 9 and 10
4. Configure page ranges for each chapter:
   - Chapter 1 (বাস্তব সংখ্যা): Pages 2-20
   - Chapter 2 (সেট ও ফাংশন): Pages 21-35
   - etc.
5. Verify uploads and page ranges

### Student Workflow:
1. Open chapter in Flutter app
2. Tap "View PDF Book" button in chat
3. See only relevant pages for current chapter
4. Select text from PDF
5. Ask AI questions about selected content
6. Request different solution methods if needed

## File Structure

```
pdf_management_service/
├── pdf_manager.py              # Main Python service
├── templates/
│   ├── upload.html            # Web interface for uploads
│   └── configure.html         # Chapter configuration interface
├── static/
│   └── style.css             # Basic styling
├── config/
│   └── firebase_config.json  # Firebase service account
└── data/
    ├── chapter_ranges.json   # Chapter page configurations
    └── uploads/              # Temporary PDF storage

flutter_app/
├── lib/src/shared/services/
│   ├── pdf_service.dart      # PDF download and management
│   └── pdf_text_service.dart # Text selection and extraction
├── lib/src/features/learn/presentation/
│   ├── widgets/
│   │   ├── pdf_viewer_widget.dart    # PDF display component
│   │   └── text_selection_overlay.dart # Text selection UI
│   └── screens/
│       └── learn_mode_screen.dart    # Updated with PDF integration
```

## Security Considerations

1. **Authentication**: Secure admin interface for PDF uploads
2. **Storage Rules**: Firebase Storage rules for PDF access
3. **Content Validation**: Verify PDF content and page ranges
4. **Rate Limiting**: Prevent abuse of PDF download endpoints

## Next Steps

1. **Create Python PDF Management Service** ✓
2. **Implement Flutter PDF Integration** ✓
3. **Add Text Selection Functionality** ✓
4. **Enhance AI with PDF Context** ✓
5. **Test with Real NCTB Textbooks**
6. **Deploy and Configure Production Environment**

## Usage Examples

### Configuring Chapter Ranges:
```python
# Example: Setting up Class 9 chapter ranges
chapter_ranges = {
    "real_numbers": {"start": 2, "end": 20},
    "sets_functions": {"start": 21, "end": 35},
    "algebraic_expressions": {"start": 36, "end": 52},
    # ... continue for all chapters
}
```

### AI Integration with PDF Content:
```dart
// When student selects text from PDF
final selectedText = await pdfTextService.getSelectedText();
final aiResponse = await aiService.generateResponse(
  userMessage: "Explain this: $selectedText",
  topicName: currentChapter,
  pdfContext: selectedText,
  solutionMethod: "alternative", // or "standard"
);
```

This system will provide students with seamless access to their NCTB textbooks while getting AI assistance for any mathematical concept or problem they encounter in the PDF.
