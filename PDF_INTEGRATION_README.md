# NCTB PDF Book Integration System

## 🎯 Overview

This system provides seamless integration of NCTB mathematics textbooks with the AI tutor app. Students can view chapter-specific PDF pages and select text to ask AI questions about specific problems or concepts.

## 🏗️ System Architecture

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Python PDF       │    │   Flutter App       │    │   OpenAI API        │
│   Management        │◄──►│   with PDF          │◄──►│   with PDF          │
│   Service           │    │   Integration       │    │   Context           │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

## 🚀 Quick Start

### For Administrators (Upload PDFs):

1. **Start the PDF Management Service:**
   ```bash
   cd pdf_management_service
   ./start_service.sh        # Linux/Mac
   # OR
   start_service.bat         # Windows
   ```

2. **Access the web interface:**
   - Open: http://localhost:5000
   - Upload NCTB math textbooks for Class 9 and 10
   - Configure chapter page ranges

3. **Configure chapters:**
   - Go to: http://localhost:5000/configure
   - Set page ranges for each of the 17 NCTB chapters
   - Save configuration

### For Students (Use in Flutter App):

1. **Open any chapter in the AI tutor app**
2. **Tap the book icon** (📖) in the top-right corner
3. **View chapter-specific PDF pages**
4. **Select text** from the PDF to ask AI questions
5. **Get explanations** tailored to NCTB curriculum

## 📋 Prerequisites

### Python Service:
- Python 3.8 or higher
- pip package manager
- 100MB+ disk space for PDFs

### Flutter App:
- Updated pubspec.yaml with PDF dependencies
- Network access to the Python service

## 🛠️ Installation

### 1. Python Service Setup

```bash
# Navigate to PDF service directory
cd pdf_management_service

# Install Python dependencies
pip install -r requirements.txt

# Start the service
python pdf_manager.py
```

### 2. Flutter App Dependencies

Add to your `pubspec.yaml`:
```yaml
dependencies:
  syncfusion_flutter_pdfviewer: ^25.2.7
  http: ^1.1.0
  path_provider: ^2.1.1
```

Then run:
```bash
flutter pub get
```

## 📚 Features

### 🔧 Admin Features:
- **PDF Upload Interface**: Easy web-based upload for textbooks
- **Chapter Configuration**: Set specific page ranges for each chapter
- **Preview System**: Verify uploaded PDFs and page ranges
- **Status Monitoring**: Check service health and Firebase connectivity

### 👨‍🎓 Student Features:
- **Chapter-Specific PDFs**: See only relevant pages for current topic
- **Text Selection**: Select any text from PDF pages
- **AI Integration**: Ask questions about selected text
- **Multiple Solution Methods**: Request alternative problem-solving approaches
- **Seamless Navigation**: Switch between PDF reading and AI chat

### 🤖 AI Enhancement:
- **PDF Context Awareness**: AI understands selected text from PDFs
- **NCTB Curriculum Alignment**: Responses follow textbook methodology
- **Alternative Solutions**: Can provide different solving approaches
- **Bengali-English Support**: Mixed language explanations

## 📖 Chapter Configuration

### Sample Page Ranges (Class 9):
```json
{
  "real_numbers": {"start": 2, "end": 20},
  "sets_functions": {"start": 21, "end": 35},
  "algebraic_expressions": {"start": 36, "end": 52},
  "indices_logarithms": {"start": 53, "end": 68},
  "linear_equations": {"start": 69, "end": 85},
  "lines_angles_triangles": {"start": 86, "end": 105},
  "practical_geometry": {"start": 106, "end": 120},
  "circles": {"start": 121, "end": 140},
  "trigonometric_ratios": {"start": 141, "end": 160},
  "distance_height": {"start": 161, "end": 175},
  "algebraic_ratios": {"start": 176, "end": 190},
  "simultaneous_equations": {"start": 191, "end": 208},
  "finite_series": {"start": 209, "end": 225},
  "ratio_similarity_symmetry": {"start": 226, "end": 245},
  "area_theorems": {"start": 246, "end": 265},
  "mensuration": {"start": 266, "end": 285},
  "statistics": {"start": 286, "end": 300}
}
```

## 🔗 API Endpoints

### Python Service API:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Upload interface |
| `/upload` | POST | Upload PDF file |
| `/configure` | GET/POST | Configure chapter ranges |
| `/pdf/<class>/<chapter>` | GET | Get chapter PDF |
| `/text/<class>/<chapter>` | GET | Extract chapter text |
| `/text/<class>/<chapter>/<page>` | GET | Extract page text |
| `/chapters/<class>` | GET | Get configured chapters |
| `/status` | GET | Service status |

### Flutter Integration:

```dart
// Get chapter PDF
final pdfPath = await pdfService.getChapterPdf(
  classLevel: 9,
  chapterId: 'real_numbers',
);

// Handle text selection
void _handlePDFTextSelection(String selectedText) {
  // Send to AI with PDF context
  final response = await aiService.generateResponse(
    userMessage: selectedText,
    pdfContext: selectedText,
    solutionMethod: 'alternative',
  );
}
```

## 🔧 Configuration

### Firebase Setup (Optional):
1. Create Firebase project
2. Enable Cloud Storage
3. Download service account key
4. Save as `config/firebase_config.json`

### Production Deployment:
1. Update `baseUrl` in Flutter PDF service
2. Configure production server for Python service
3. Set up proper authentication and rate limiting
4. Use HTTPS for secure PDF transfer

## 🧪 Testing

### Test PDF Upload:
1. Start Python service
2. Access http://localhost:5000
3. Upload a sample PDF
4. Configure page ranges
5. Test PDF download via API

### Test Flutter Integration:
1. Run Flutter app
2. Navigate to any chapter
3. Tap book icon
4. Verify PDF loads with correct pages
5. Test text selection and AI response

## 🚨 Troubleshooting

### Common Issues:

**PDF Service Not Starting:**
- Check Python installation
- Verify all dependencies installed
- Check port 5000 availability

**PDF Not Loading in App:**
- Verify Python service is running
- Check network connectivity
- Ensure chapter is configured with page ranges

**Text Selection Not Working:**
- Verify PDF has selectable text (not scanned images)
- Check Syncfusion PDF viewer configuration
- Test with different PDF files

**AI Not Understanding PDF Context:**
- Verify text extraction is working
- Check AI service integration
- Test with simpler text selections

## 📁 File Structure

```
pdf_management_service/
├── pdf_manager.py              # Main Python service
├── requirements.txt            # Python dependencies
├── start_service.sh           # Linux/Mac startup script
├── start_service.bat          # Windows startup script
├── templates/
│   ├── upload.html           # Upload interface
│   └── configure.html        # Configuration interface
├── config/
│   └── firebase_config.json  # Firebase credentials (optional)
└── data/
    ├── uploads/              # Uploaded PDF files
    └── chapter_ranges.json   # Chapter configuration

flutter_app/
├── lib/src/shared/services/
│   └── pdf_service.dart      # PDF download service
├── lib/src/features/learn/presentation/
│   ├── widgets/
│   │   └── pdf_viewer_widget.dart  # PDF viewer component
│   └── screens/
│       └── learn_mode_screen.dart  # Enhanced with PDF button
└── pubspec.yaml              # Updated dependencies
```

## 🔄 Workflow

### Admin Workflow:
1. **Start Service** → 2. **Upload PDFs** → 3. **Configure Chapters** → 4. **Verify Setup**

### Student Workflow:
1. **Open Chapter** → 2. **Tap Book Icon** → 3. **View PDF** → 4. **Select Text** → 5. **Ask AI**

## 🌟 Benefits

- **Contextual Learning**: Students see exact textbook content
- **Improved Comprehension**: AI explanations aligned with textbook
- **Flexible Problem Solving**: Multiple solution approaches available
- **NCTB Compliance**: Perfect alignment with national curriculum
- **Enhanced Engagement**: Seamless PDF-to-AI interaction

## 🔮 Future Enhancements

- **Offline PDF Caching**: Local storage for better performance
- **Voice Questions**: Audio input for PDF text
- **Handwriting Recognition**: Students can draw problems
- **Smart Bookmarks**: Save important PDF sections
- **Progress Tracking**: Monitor PDF reading progress
- **Multi-Subject Support**: Extend to Physics, Chemistry, Biology

---

**Ready to transform NCTB mathematics learning with integrated PDF books and AI tutoring!** 🎓📚🤖
