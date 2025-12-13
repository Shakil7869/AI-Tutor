// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../../shared/services/ai_service.dart';
// import '../../../../shared/services/session_tracking_service.dart';
// import '../../../../shared/services/auth_service.dart';
// import '../../../../shared/services/chapter_pdf_service.dart';
// import '../widgets/chapter_pdf_viewer_widget.dart';

// /// Learn mode screen with AI tutor chat
// class LearnModeScreen extends ConsumerStatefulWidget {
//   final String chapterId;
//   final String chapterName;
//   final String? subject;

//   const LearnModeScreen({
//     super.key,
//     required this.chapterId,
//     required this.chapterName,
//     this.subject,
//   });

//   @override
//   ConsumerState<LearnModeScreen> createState() => _LearnModeScreenState();
// }

// class _LearnModeScreenState extends ConsumerState<LearnModeScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<Map<String, dynamic>> _messages = [];
//   bool _isLoading = false;
//   bool _isTyping = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializeSession();
//     _addWelcomeMessage();
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     _endSession();
//     super.dispose();
//   }

//   void _initializeSession() async {
//     try {
//       final sessionService = ref.read(sessionTrackingProvider);
//       await sessionService.startSession(
//         topicId: widget.chapterId,
//         mode: 'learn',
//       );
//     } catch (e) {
//       print('Error starting session: $e');
//     }
//   }

//   void _endSession() async {
//     try {
//       final sessionService = ref.read(sessionTrackingProvider);
//       await sessionService.endSession();
//     } catch (e) {
//       print('Error ending session: $e');
//     }
//   }

//   void _addWelcomeMessage() {
//     _messages.add({
//       'text': 'Welcome to ${widget.chapterName} learning session!\n\n'
//               'You can:\n'
//               '• Click the PDF icon to open the chapter material\n'
//               '• Ask me questions about the chapter\n'
//               '• Highlight text in the PDF to get explanations\n\n'
//               '${widget.chapterName} শেখার সেশনে স্বাগতম!\n\n'
//               'আপনি করতে পারেন:\n'
//               '• অধ্যায়ের উপাদান খুলতে PDF আইকনে ক্লিক করুন\n'
//               '• অধ্যায় সম্পর্কে আমাকে প্রশ্ন করুন\n'
//               '• ব্যাখ্যা পেতে PDF-তে টেক্সট হাইলাইট করুন',
//       'isUser': false,
//       'timestamp': DateTime.now(),
//     });
//   }

//   void _openPDFViewer() async {
//     try {
//       print('🔍 Opening chapter PDF viewer...');
      
//       // Check if user is authenticated
//       final userAsync = ref.read(currentUserProvider);
//       final user = userAsync.value;
//       if (user == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Please sign in to access PDF content.'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         return;
//       }

//       final classLevel = user.profile?.classLevel ?? 9;
      
//       print('📚 Opening chapter for class $classLevel, topic: ${widget.chapterId}');
      
//       // Check if chapter PDF service is available
//       final chapterPdfService = ref.read(chapterPdfServiceProvider);
//       final isAvailable = await chapterPdfService.isChapterAvailable(
//         classLevel: classLevel,
//         chapterId: widget.chapterId,
//       );
      
//       if (!isAvailable) {
//         print('❌ Chapter ${widget.chapterId} not available');
//         if (mounted) {
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text('Chapter Not Available'),
//               content: Text(
//                 'The chapter "${widget.chapterName}" is not available yet. '
//                 'Please contact your teacher to upload this chapter.',
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text('OK'),
//                 ),
//               ],
//             ),
//           );
//         }
//         return;
//       }

//       print('✅ Chapter PDF available, opening viewer...');

//       // Open chapter PDF viewer
//       if (mounted) {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (context) => PDFViewerWidget(
//               chapterId: widget.chapterId,
//               chapterName: widget.chapterName,
//               onTextSelected: _handlePDFTextSelection,
//             ),
//           ),
//         );
//       }
//     } catch (e, stackTrace) {
//       print('❌ Error in _openPDFViewer: $e');
//       print('🔍 Stack trace: $stackTrace');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error opening PDF: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             action: SnackBarAction(
//               label: 'Retry',
//               onPressed: _openPDFViewer,
//             ),
//           ),
//         );
//       }
//     }
//   }

//   void _handlePDFTextSelection(String selectedText) {
//     // Close PDF viewer and add selected text to chat
//     Navigator.of(context).pop();
    
//     // Add the selected text as a user message with context
//     final contextMessage = "From PDF: \"$selectedText\"\n\nPlease explain this concept or solve this problem.\n\nPDF থেকে: \"$selectedText\"\n\nদয়া করে এই ধারণাটি ব্যাখ্যা করুন বা এই সমস্যাটি সমাধান করুন।";
    
//     setState(() {
//       _messages.add({
//         'text': contextMessage,
//         'isUser': true,
//         'timestamp': DateTime.now(),
//       });
//     });
    
//     _sendMessage(contextMessage);
//     _scrollToBottom();
//   }

//   void _sendMessage([String? customMessage]) async {
//     final message = customMessage ?? _messageController.text.trim();
//     if (message.isEmpty) return;

//     setState(() {
//       if (customMessage == null) {
//         _messages.add({
//           'text': message,
//           'isUser': true,
//           'timestamp': DateTime.now(),
//         });
//       }
//       _messageController.clear();
//       _isLoading = true;
//       _isTyping = true;
//     });

//     _scrollToBottom();

//     try {
//       final aiService = ref.read(aiServiceProvider);
//       final userAsync = ref.read(currentUserProvider);
//       final user = userAsync.value;
      
//       final response = await aiService.generateResponse(
//         userMessage: message,
//         topicName: widget.chapterName,
//         topicId: widget.chapterId,
//         classLevel: user?.profile?.classLevel ?? 9,
//         userId: user?.id,
//         preferredLanguage: 'mixed', // English and Bengali mix
//       );

//       setState(() {
//         _messages.add({
//           'text': response,
//           'isUser': false,
//           'timestamp': DateTime.now(),
//         });
//         _isLoading = false;
//         _isTyping = false;
//       });
//     } catch (e) {
//       setState(() {
//         _messages.add({
//           'text': 'Sorry, I encountered an error. Please try again.\n\nদুঃখিত, আমি একটি ত্রুটির সম্মুখীন হয়েছি। অনুগ্রহ করে আবার চেষ্টা করুন।',
//           'isUser': false,
//           'timestamp': DateTime.now(),
//         });
//         _isLoading = false;
//         _isTyping = false;
//       });
//     }

//     _scrollToBottom();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
    
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.chapterName),
//         actions: [
//           IconButton(
//             onPressed: _openPDFViewer,
//             icon: const Icon(Icons.picture_as_pdf),
//             tooltip: 'Open Chapter PDF',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Chat messages
//           Expanded(
//             child: _messages.isEmpty
//                 ? const Center(
//                     child: CircularProgressIndicator(),
//                   )
//                 : ListView.builder(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.all(16),
//                     itemCount: _messages.length + (_isTyping ? 1 : 0),
//                     itemBuilder: (context, index) {
//                       if (index == _messages.length && _isTyping) {
//                         return _buildTypingIndicator(theme);
//                       }
//                       return _buildMessage(_messages[index], theme);
//                     },
//                   ),
//           ),
          
//           // Input area
//           Container(
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surface,
//               border: Border(
//                 top: BorderSide(
//                   color: theme.colorScheme.outline.withOpacity(0.2),
//                 ),
//               ),
//             ),
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: 'Ask about ${widget.chapterName}...',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(24),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                     ),
//                     maxLines: null,
//                     textInputAction: TextInputAction.send,
//                     onSubmitted: (_) => _sendMessage(),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   onPressed: _isLoading ? null : () => _sendMessage(),
//                   icon: _isLoading
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.send),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessage(Map<String, dynamic> message, ThemeData theme) {
//     final isUser = message['isUser'] as bool;
//     final text = message['text'] as String;
//     final timestamp = message['timestamp'] as DateTime;
    
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (!isUser) ...[
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: theme.colorScheme.primary,
//               child: Icon(
//                 Icons.smart_toy,
//                 size: 16,
//                 color: theme.colorScheme.onPrimary,
//               ),
//             ),
//             const SizedBox(width: 8),
//           ],
//           Expanded(
//             child: Column(
//               crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: isUser
//                         ? theme.colorScheme.primary
//                         : theme.colorScheme.surfaceContainerHighest,
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Text(
//                     text,
//                     style: TextStyle(
//                       color: isUser
//                           ? theme.colorScheme.onPrimary
//                           : theme.colorScheme.onSurface,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (isUser) ...[
//             const SizedBox(width: 8),
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: theme.colorScheme.primary,
//               child: Icon(
//                 Icons.person,
//                 size: 16,
//                 color: theme.colorScheme.onPrimary,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTypingIndicator(ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 16,
//             backgroundColor: theme.colorScheme.primary,
//             child: Icon(
//               Icons.smart_toy,
//               size: 16,
//               color: theme.colorScheme.onPrimary,
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.surfaceContainerHighest,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: theme.colorScheme.primary,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'AI is thinking...',
//                   style: TextStyle(
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
