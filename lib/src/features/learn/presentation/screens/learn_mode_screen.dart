import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../../shared/services/session_tracking_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/chapter_pdf_service.dart';
import '../../../../shared/services/firebase_debug_service.dart';
import '../widgets/chapter_pdf_viewer_widget_new.dart';

/// Learn mode screen with AI tutor chat
class LearnModeScreen extends ConsumerStatefulWidget {
  final String chapterId;
  final String chapterName;
  final String? subject;

  const LearnModeScreen({
    super.key,
    required this.chapterId,
    required this.chapterName,
    this.subject,
  });

  @override
  ConsumerState<LearnModeScreen> createState() => _LearnModeScreenState();
}

class _LearnModeScreenState extends ConsumerState<LearnModeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _endSession();
    super.dispose();
  }

  void _initializeSession() async {
    try {
      final sessionService = ref.read(sessionTrackingProvider);
      await sessionService.startSession(
        topicId: widget.chapterId,
        mode: 'learn',
      );
    } catch (e) {
      print('Error starting session: $e');
    }
  }

  void _endSession() async {
    try {
      final sessionService = ref.read(sessionTrackingProvider);
      await sessionService.endSession();
    } catch (e) {
      print('Error ending session: $e');
    }
  }

  void _addWelcomeMessage() {
    _messages.add({
      'text': 'Welcome to ${widget.chapterName} learning session!\n\n'
              'You can:\n'
              '• Click the PDF icon to open the chapter material\n'
              '• Click the download icon to save PDF for offline viewing\n'
              '• Ask me questions about the chapter\n'
              '• Highlight text in the PDF to get explanations\n\n'
              '${widget.chapterName} শেখার সেশনে স্বাগতম!\n\n'
              'আপনি করতে পারেন:\n'
              '• অধ্যায়ের উপাদান খুলতে PDF আইকনে ক্লিক করুন\n'
              '• অফলাইন দেখার জন্য PDF সেভ করতে ডাউনলোড আইকনে ক্লিক করুন\n'
              '• অধ্যায় সম্পর্কে আমাকে প্রশ্ন করুন\n'
              '• ব্যাখ্যা পেতে PDF-তে টেক্সট হাইলাইট করুন',
      'isUser': false,
      'timestamp': DateTime.now(),
    });
  }

  void _openPDFViewer() async {
    try {
      print('🔍 Opening chapter PDF viewer...');
      
      // Check if user is authenticated
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to access PDF content.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final classLevel = user.profile?.classLevel ?? 9;
      
      print('📚 Opening chapter for class $classLevel, topic: ${widget.chapterId}');
      
      // Check Firebase connection first
      final chapterPdfService = ref.read(chapterPdfServiceProvider);
      print('🔥 Checking Firebase connection...');
      
      // Get Firebase status
      final firebaseStatus = await chapterPdfService.getFirebaseStatus();
      print('📊 Firebase status: $firebaseStatus');
      
      if (firebaseStatus == null || firebaseStatus['initialized'] != true) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Firebase Connection Issue'),
              content: const Text(
                'Cannot connect to Firebase. Please check your internet connection and try again.\n\n'
                'If the problem persists, the app may need to be configured with proper Firebase credentials.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Get chapter info from Firebase
      final chapterInfo = await chapterPdfService.getChapterInfo(
        classLevel: classLevel,
        chapterId: widget.chapterId,
      );
      
      print('📄 Chapter info from Firebase: $chapterInfo');
      
      if (chapterInfo == null) {
        print('❌ Chapter ${widget.chapterId} not found in Firebase');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chapter Not Found'),
              content: Text(
                'The chapter "${widget.chapterName}" (${widget.chapterId}) was not found in Firebase.\n\n'
                'Class Level: $classLevel\n'
                'Chapter ID: ${widget.chapterId}\n\n'
                'Please ask your teacher to upload this chapter via the admin panel at:\n'
                'http://localhost:5001\n\n'
                'The chapter document should be saved as: ${classLevel}_${widget.chapterId}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAvailableChapters(classLevel);
                  },
                  child: const Text('Show Available'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Check if chapter PDF service is available
      final isAvailable = await chapterPdfService.isChapterAvailable(
        classLevel: classLevel,
        chapterId: widget.chapterId,
      );
      
      if (!isAvailable) {
        print('❌ Chapter ${widget.chapterId} not available');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Chapter Not Available'),
              content: Text(
                'The chapter "${widget.chapterName}" is found in Firebase but is not marked as available or has no download URL.\n\n'
                'Firebase Document: ${classLevel}_${widget.chapterId}\n'
                'Download URL: ${chapterInfo['downloadUrl'] ?? 'Missing'}\n\n'
                'Please contact your teacher to re-upload this chapter.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      print('✅ Chapter PDF available, opening viewer...');

      // Open chapter PDF viewer
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PDFViewerWidget(
              chapterId: widget.chapterId,
              chapterName: widget.chapterName,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error in _openPDFViewer: $e');
      print('🔍 Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _openPDFViewer,
            ),
          ),
        );
      }
    }
  }

  void _showAvailableChapters(int classLevel) async {
    try {
      final chapterPdfService = ref.read(chapterPdfServiceProvider);
      final availableChapters = await chapterPdfService.getAvailableChapters(classLevel: classLevel);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Available Chapters - Class $classLevel'),
            content: SizedBox(
              width: double.maxFinite,
              child: availableChapters['success'] == true 
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total: ${availableChapters['totalChapters']} chapters'),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: (availableChapters['chapters'] as List).length,
                          itemBuilder: (context, index) {
                            final chapter = (availableChapters['chapters'] as List)[index];
                            return ListTile(
                              dense: true,
                              title: Text(chapter['name'] ?? ''),
                              subtitle: Text(chapter['englishName'] ?? ''),
                              trailing: chapter['id'] == widget.chapterId 
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : Text('Error: ${availableChapters['error']}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error showing available chapters: $e');
    }
  }

  void _showFirebaseDebug() async {
    try {
      final debugService = ref.read(firebaseDebugServiceProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      final classLevel = user?.profile?.classLevel ?? 9;
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            title: const Text('Firebase Debug Info'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: FutureBuilder<Map<String, dynamic>>(
                future: debugService.getFullDebugReport(
                  classLevel: classLevel,
                  chapterId: widget.chapterId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  
                  final report = snapshot.data ?? {};
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDebugSection('Firestore Status', report['firestore']),
                        const SizedBox(height: 16),
                        _buildDebugSection('Storage Status', report['storage']),
                        const SizedBox(height: 16),
                        if (report['specificChapter'] != null)
                          _buildDebugSection('Current Chapter', report['specificChapter']),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error showing Firebase debug: $e');
    }
  }

  Widget _buildDebugSection(String title, Map<String, dynamic>? data) {
    if (data == null) return Container();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...data.entries.map((entry) {
              final value = entry.value;
              final displayValue = value is Map || value is List 
                ? '${value.runtimeType}(${value is Map ? value.length : (value as List).length} items)'
                : value.toString();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 12,
                          color: entry.key == 'success' && value == true
                              ? Colors.green
                              : entry.key == 'error'
                                  ? Colors.red
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _downloadChapterPDF() async {
    try {
      print('⬇️ Starting chapter PDF download...');
      
      // Check if user is authenticated
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to download PDF content.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final classLevel = user.profile?.classLevel ?? 9;
      final chapterPdfService = ref.read(chapterPdfServiceProvider);

      // Check if already downloaded
      final isDownloaded = await chapterPdfService.isChapterDownloaded(
        classLevel: classLevel,
        chapterId: widget.chapterId,
      );

      if (isDownloaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.chapterName} is already downloaded and ready for offline viewing.'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                onPressed: _openPDFViewer,
              ),
            ),
          );
        }
        return;
      }

      // Check availability
      final isAvailable = await chapterPdfService.isChapterAvailable(
        classLevel: classLevel,
        chapterId: widget.chapterId,
      );

      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.chapterName} is not available for download yet.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show download progress
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Downloading PDF'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Downloading ${widget.chapterName}...\nThis may take a few moments.'),
              ],
            ),
          ),
        );
      }

      // Download the PDF
      final pdfFile = await chapterPdfService.downloadChapterPDF(
        classLevel: classLevel,
        chapterId: widget.chapterId,
        onProgress: (progress) {
          print('Download progress: ${(progress * 100).toInt()}%');
        },
      );

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (pdfFile != null) {
        print('✅ PDF downloaded successfully: ${pdfFile.path}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.chapterName} downloaded successfully! You can now view it offline.'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                onPressed: _openPDFViewer,
              ),
            ),
          );
        }
      } else {
        throw Exception('Download failed - no file returned');
      }

    } catch (e, stackTrace) {
      print('❌ Error downloading PDF: $e');
      print('🔍 Stack trace: $stackTrace');
      
      // Close progress dialog if open
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _downloadChapterPDF,
            ),
          ),
        );
      }
    }
  }

  void _handlePDFTextSelection(String selectedText) {
    // Don't close PDF viewer immediately - let students ask multiple questions
    // Navigator.of(context).pop();
    
    // Get user class level for context
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    final classLevel = user?.profile?.classLevel ?? 9;
    
    // Show a dialog to let students choose how to interact with the selected text
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selected Text from PDF'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedText,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              const Text('What would you like to do with this text?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _askAIAboutSelectedText(selectedText, 'explain', classLevel);
            },
            child: const Text('Explain This'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _askAIAboutSelectedText(selectedText, 'solve', classLevel);
            },
            child: const Text('Solve This'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _askAIAboutSelectedText(selectedText, 'examples', classLevel);
            },
            child: const Text('Give Examples'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCustomQuestionDialog(selectedText, classLevel);
            },
            child: const Text('Ask Custom Question'),
          ),
        ],
      ),
    );
  }

  void _askAIAboutSelectedText(String selectedText, String requestType, int classLevel) {
    String contextMessage;
    
    switch (requestType) {
      case 'explain':
        contextMessage = '''📖 Selected from ${widget.chapterName} PDF (Class $classLevel):
"$selectedText"

Please explain this concept step-by-step. Break it down so I can understand it clearly according to my class level.

📖 PDF থেকে নির্বাচিত (ক্লাস $classLevel):
"$selectedText"

দয়া করে এই ধারণাটি ধাপে ধাপে ব্যাখ্যা করুন। আমার ক্লাসের মানের অনুযায়ী এটা ভেঙে দিন যাতে আমি স্পষ্টভাবে বুঝতে পারি।''';
        break;
        
      case 'solve':
        contextMessage = '''🔢 Selected problem from ${widget.chapterName} PDF (Class $classLevel):
"$selectedText"

Please solve this problem step-by-step. Show me all the steps and explain why each step is needed.

🔢 PDF থেকে নির্বাচিত সমস্যা (ক্লাস $classLevel):
"$selectedText"

দয়া করে এই সমস্যাটি ধাপে ধাপে সমাধান করুন। সব ধাপ দেখান এবং ব্যাখ্যা করুন কেন প্রতিটি ধাপ প্রয়োজন।''';
        break;
        
      case 'examples':
        contextMessage = '''💡 Selected concept from ${widget.chapterName} PDF (Class $classLevel):
"$selectedText"

Please give me 2-3 similar examples with solutions to help me practice this concept.

💡 PDF থেকে নির্বাচিত ধারণা (ক্লাস $classLevel):
"$selectedText"

দয়া করে আমাকে এই ধারণাটি অনুশীলন করতে সাহায্য করার জন্য সমাধানসহ ২-৩টি অনুরূপ উদাহরণ দিন।''';
        break;
        
      default:
        contextMessage = '''📚 From ${widget.chapterName} PDF (Class $classLevel): "$selectedText"

Please help me understand this according to Class $classLevel NCTB curriculum.

📚 PDF থেকে (ক্লাস $classLevel): "$selectedText"

দয়া করে ক্লাস $classLevel NCTB পাঠ্যক্রম অনুযায়ী এটি বুঝতে সাহায্য করুন।''';
    }
    
    // Add the message to chat and send to AI
    setState(() {
      _messages.add({
        'text': contextMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
        'selectedText': selectedText, // Store for potential follow-up
        'requestType': requestType,
      });
    });
    
    _sendMessage(contextMessage, selectedText);
    _scrollToBottom();
  }

  void _showCustomQuestionDialog(String selectedText, int classLevel) {
    final questionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask About Selected Text'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  selectedText.length > 100 
                    ? '${selectedText.substring(0, 100)}...' 
                    : selectedText,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  hintText: 'What do you want to know about this text?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final question = questionController.text.trim();
              if (question.isNotEmpty) {
                Navigator.of(context).pop();
                _askCustomQuestionAboutText(selectedText, question, classLevel);
              }
            },
            child: const Text('Ask'),
          ),
        ],
      ),
    );
  }

  void _askCustomQuestionAboutText(String selectedText, String question, int classLevel) {
    final contextMessage = '''❓ Question about selected text from ${widget.chapterName} PDF (Class $classLevel):

Selected text: "$selectedText"

My question: $question

Please answer my question based on the selected text and explain according to Class $classLevel level.

❓ PDF থেকে নির্বাচিত টেক্সট সম্পর্কে প্রশ্ন (ক্লাস $classLevel):

নির্বাচিত টেক্সট: "$selectedText"

আমার প্রশ্ন: $question

দয়া করে নির্বাচিত টেক্সটের ভিত্তিতে আমার প্রশ্নের উত্তর দিন এবং ক্লাস $classLevel এর মানের অনুযায়ী ব্যাখ্যা করুন।''';

    setState(() {
      _messages.add({
        'text': contextMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
        'selectedText': selectedText,
        'customQuestion': question,
      });
    });
    
    _sendMessage(contextMessage, selectedText);
    _scrollToBottom();
  }

  void _sendMessage([String? customMessage, String? selectedText]) async {
    final message = customMessage ?? _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      if (customMessage == null) {
        _messages.add({
          'text': message,
          'isUser': true,
          'timestamp': DateTime.now(),
        });
      }
      _messageController.clear();
      _isLoading = true;
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      
      final response = await aiService.generateResponse(
        userMessage: message,
        topicName: widget.chapterName,
        topicId: widget.chapterId,
        classLevel: user?.profile?.classLevel ?? 9,
        userId: user?.id,
        preferredLanguage: 'mixed', // English and Bengali mix
        pdfContext: selectedText, // Pass selected PDF text as context
      );

      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Sorry, I encountered an error. Please try again.\n\nদুঃখিত, আমি একটি ত্রুটির সম্মুখীন হয়েছি। অনুগ্রহ করে আবার চেষ্টা করুন।',
          'isUser': false,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterName),
        actions: [
          IconButton(
            onPressed: _downloadChapterPDF,
            icon: const Icon(Icons.download),
            tooltip: 'Download Chapter PDF',
          ),
          IconButton(
            onPressed: _openPDFViewer,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Open Chapter PDF',
          ),
          // Debug button for Firebase testing
          IconButton(
            onPressed: _showFirebaseDebug,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Firebase Debug Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator(theme);
                      }
                      return _buildMessage(_messages[index], theme);
                    },
                  ),
          ),
          
          // Input area
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about ${widget.chapterName}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, ThemeData theme) {
    final isUser = message['isUser'] as bool;
    final text = message['text'] as String;
    final timestamp = message['timestamp'] as DateTime;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.smart_toy,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is thinking...',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
