import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/services/ai_service.dart';
import '../shared/services/rag_service.dart';

class EnhancedChatScreen extends ConsumerStatefulWidget {
  final String classLevel;
  final String? subject;
  final String? chapter;
  final String? userId;

  const EnhancedChatScreen({
    super.key,
    required this.classLevel,
    this.subject,
    this.chapter,
    this.userId,
  });

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _useRAG = true; // Toggle between RAG and regular AI

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final welcomeText = widget.chapter != null
        ? 'Hi! I\'m your AI tutor for Class ${widget.classLevel} ${widget.subject} - ${widget.chapter}. '
          'Ask me anything about this chapter!'
        : 'Hi! I\'m your AI tutor for Class ${widget.classLevel}${widget.subject != null ? ' ${widget.subject}' : ''}. '
          'Ask me any questions!';

    _messages.add(ChatMessage(
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String response;
      List<ContentChunk> sourceChunks = [];

      if (_useRAG) {
        // Use RAG pipeline
        final aiService = ref.read(aiServiceProvider);
        response = await aiService.generateRAGResponse(
          userMessage: text,
          classLevel: widget.classLevel,
          subject: widget.subject,
          chapter: widget.chapter,
          userId: widget.userId,
        );

        // Get source chunks for reference
        try {
          sourceChunks = await aiService.searchTextbookContent(
            query: text,
            classLevel: widget.classLevel,
            subject: widget.subject,
            chapter: widget.chapter,
            topK: 3,
          );
        } catch (e) {
          // Ignore error if source chunks can't be retrieved
        }
      } else {
        // Use regular AI service
        final aiService = ref.read(aiServiceProvider);
        response = await aiService.generateResponse(
          userMessage: text,
          topicName: widget.chapter ?? widget.subject ?? 'General',
          topicId: widget.chapter ?? 'general',
          classLevel: int.tryParse(widget.classLevel),
          userId: widget.userId,
        );
      }

      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        sourceChunks: sourceChunks,
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      setState(() {
        _messages.add(errorMessage);
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Tutor Chat'),
            Text(
              'Class ${widget.classLevel}${widget.subject != null ? ' ${widget.subject}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_rag':
                  setState(() {
                    _useRAG = !_useRAG;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_useRAG 
                        ? 'Switched to Textbook AI (RAG)' 
                        : 'Switched to General AI'),
                    ),
                  );
                  break;
                case 'clear_chat':
                  setState(() {
                    _messages.clear();
                  });
                  _addWelcomeMessage();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_rag',
                child: Row(
                  children: [
                    Icon(_useRAG ? Icons.book : Icons.psychology),
                    const SizedBox(width: 8),
                    Text(_useRAG ? 'Use General AI' : 'Use Textbook AI'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_chat',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // RAG status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _useRAG ? Colors.green.shade50 : Colors.blue.shade50,
            child: Row(
              children: [
                Icon(
                  _useRAG ? Icons.book : Icons.psychology,
                  size: 16,
                  color: _useRAG ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _useRAG 
                    ? 'Using Textbook Knowledge (RAG)' 
                    : 'Using General AI Knowledge',
                  style: TextStyle(
                    fontSize: 12,
                    color: _useRAG ? Colors.green.shade700 : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: message.isUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isError
                  ? Colors.red.shade100
                  : message.isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isError
                        ? Colors.red.shade800
                        : message.isUser
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  if (message.sourceChunks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSourceChips(message.sourceChunks),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceChips(List<ContentChunk> chunks) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chunks.take(3).map((chunk) {
        return Chip(
          label: Text(
            '${chunk.subject} Ch.${chunk.chapter.split(' ').first}',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: Colors.blue.shade100,
          padding: const EdgeInsets.all(2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onDeleted: () {
            _showChunkDetails(chunk);
          },
          deleteIcon: const Icon(Icons.info_outline, size: 14),
        );
      }).toList(),
    );
  }

  void _showChunkDetails(ContentChunk chunk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Source: ${chunk.subject} - ${chunk.chapter}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class ${chunk.classLevel}'),
            Text('Page ${chunk.pageNumber}'),
            Text('Relevance: ${(chunk.score * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16),
            Text(
              chunk.text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
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

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('AI is thinking...'),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ContentChunk> sourceChunks;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sourceChunks = const [],
    this.isError = false,
  });
}
