import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:async';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/chapter_pdf_service.dart';
import '../../../../shared/services/ai_service.dart';

/// PDF viewer widget with native text selection and floating AI chat
class PDFViewerWidget extends ConsumerStatefulWidget {
  final String chapterId;
  final String chapterName;

  const PDFViewerWidget({
    super.key,
    required this.chapterId,
    required this.chapterName,
  });

  @override
  ConsumerState<PDFViewerWidget> createState() => _PDFViewerWidgetState();
}

class _PDFViewerWidgetState extends ConsumerState<PDFViewerWidget> {
  final Completer<PDFViewController> _controller = Completer<PDFViewController>();
  String? _pdfPath;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 0;
  
  // Text selection and AI chat state
  bool _showAIChat = false;
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isAILoading = false;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadPDF() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final chapterPdfService = ref.read(chapterPdfServiceProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      final classLevel = user?.profile?.classLevel ?? 9;

      print('📊 Loading chapter PDF: ${widget.chapterId} for class $classLevel');

      // Check if PDF is already downloaded
      final isDownloaded = await chapterPdfService.isChapterDownloaded(
        classLevel: classLevel,
        chapterId: widget.chapterId,
      );

      if (isDownloaded) {
        // Get the local file path and load it
        final downloadedFile = await chapterPdfService.downloadChapterPDF(
          classLevel: classLevel,
          chapterId: widget.chapterId,
        );

        if (downloadedFile != null) {
          setState(() {
            _pdfPath = downloadedFile.path;
            _isLoading = false;
          });
          return;
        }
      }

      // Download PDF if not available locally
      final downloadedFile = await chapterPdfService.downloadChapterPDF(
        classLevel: classLevel,
        chapterId: widget.chapterId,
      );

      if (downloadedFile != null) {
        setState(() {
          _pdfPath = downloadedFile.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load PDF. Please check your connection.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading PDF: $e');
      setState(() {
        _error = 'Error loading PDF: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeAIChat() {
    setState(() {
      _showAIChat = true;
    });
    
    // Add welcome message about the current page
    _addChatMessage(
      'আস্সালামু আলাইকুম! আমি ${widget.chapterName} এর পৃষ্ঠা ${_currentPage + 1} সম্পর্কে সাহায্য করতে পারি। এই পৃষ্ঠা সম্পর্কে যেকোনো প্রশ্ন করুন!\n\nউদাহরণ:\n• "পৃষ্ঠাটি উদাহরণসহ ব্যাখ্যা করুন"\n• "এই পৃষ্ঠার মূল বিষয় কী?"\n• "অনুশীলনী প্রশ্ন দিন"',
      isUser: false,
    );
  }

  void _addChatMessage(String text, {required bool isUser}) {
    setState(() {
      _chatMessages.add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty || _isAILoading) return;

    // Add user message
    _addChatMessage(message, isUser: true);
    _chatController.clear();

    setState(() {
      _isAILoading = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      final classLevel = user?.profile?.classLevel ?? 9;

      // Create context with current page information
      final contextMessage = '''
Context from ${widget.chapterName} (Class $classLevel):
Current page: ${_currentPage + 1}

Student is viewing page ${_currentPage + 1} of the PDF and asks: $message

IMPORTANT INSTRUCTIONS:
- Respond ONLY in Bengali/Bangla language
- Use proper mathematical notation like: x², √5, ∫, ∑, π, α, β, etc. (NOT a^2, sqrt(5))
- Format fractions as: ½, ¾, ⅓, ⅔ or use proper division symbols ÷
- Use Bengali mathematical terms and explanations
- Provide examples in the same style as NCTB textbooks
- If asked to "explain the page with examples", provide detailed explanations with practical examples in Bengali
- Use chapter content and provide examples related to the topics on this page
- Make explanations appropriate for Class $classLevel NCTB curriculum

Please provide a helpful explanation about the content on this page in Bengali, appropriate for Class $classLevel level.
''';

      final response = await aiService.generateResponse(
        userMessage: contextMessage,
        topicName: widget.chapterName,
        topicId: widget.chapterId,
        classLevel: classLevel,
        pdfContext: 'Page ${_currentPage + 1} of ${widget.chapterName}',
      );

      _addChatMessage(response, isUser: false);
    } catch (e) {
      _addChatMessage('দুঃখিত, একটি ত্রুটি হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।', isUser: false);
      print('❌ AI chat error: $e');
    } finally {
      setState(() {
        _isAILoading = false;
      });
    }
  }

  void _closeAIChat() {
    setState(() {
      _showAIChat = false;
      _chatMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterName),
        elevation: 0,
        actions: [
          if (_pdfPath != null) ...[
            IconButton(
              icon: Icon(_showAIChat ? Icons.picture_as_pdf : Icons.smart_toy),
              onPressed: () {
                if (_showAIChat) {
                  _closeAIChat();
                } else {
                  _initializeAIChat();
                }
              },
              tooltip: _showAIChat ? 'PDF এ ফিরে যান' : 'AI চ্যাট',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer
          _buildPDFContent(),
          
          // Floating "Ask AI" button - always visible for easy access
          if (!_showAIChat)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: _initializeAIChat,
                backgroundColor: Colors.blue[600],
                icon: const Icon(Icons.smart_toy, color: Colors.white),
                label: const Text(
                  'AI জিজ্ঞাসা',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                tooltip: 'এই পৃষ্ঠা সম্পর্কে AI কে জিজ্ঞাসা করুন',
              ),
            ),
          
          // AI Chat overlay
          if (_showAIChat)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.6,
              child: _buildAIChatDialog(),
            ),
        ],
      ),
    );
  }

  Widget _buildPDFContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('PDF লোড হচ্ছে...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPDF,
              child: const Text('পুনরায় চেষ্টা'),
            ),
          ],
        ),
      );
    }

    if (_pdfPath == null) {
      return const Center(
        child: Text('PDF not available'),
      );
    }

    return PDFView(
      filePath: _pdfPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: false,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        // PDF rendered successfully
      },
      onViewCreated: (PDFViewController controller) {
        _controller.complete(controller);
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
        });
      },
      onError: (error) {
        setState(() {
          _error = 'Error displaying PDF: $error';
          _isLoading = false;
        });
      },
      onPageError: (page, error) {
        print('Page $page error: $error');
      },
    );
  }

  Widget _buildAIChatDialog() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI শিক্ষক - ${widget.chapterName}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _closeAIChat,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: 'চ্যাট ছোট করুন',
                ),
              ],
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length + (_isAILoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _chatMessages.length) {
                  return _buildTypingIndicator();
                }
                
                final message = _chatMessages[index];
                return _buildChatMessage(message);
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'পৃষ্ঠা ${_currentPage + 1} সম্পর্কে জিজ্ঞাসা করুন...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue[600],
                  child: IconButton(
                    onPressed: _isAILoading ? null : _sendChatMessage,
                    icon: Icon(
                      _isAILoading ? Icons.hourglass_empty : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final text = message['text'] as String;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[600] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 600 + (index * 200)),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI চিন্তা করছে...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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
