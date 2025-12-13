import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat history service provider
final chatHistoryServiceProvider = Provider<ChatHistoryService>((ref) {
  return ChatHistoryService();
});

/// Service for managing chat history in Firebase
class ChatHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a chat message to Firebase
  Future<void> saveChatMessage({
    required String userId,
    required String chapterId,
    required String message,
    required bool isUser,
    String? chapterName,
    int? classLevel,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .add({
        'message': message,
        'isUser': isUser,
        'timestamp': FieldValue.serverTimestamp(),
        'chapterId': chapterId,
        'chapterName': chapterName,
        'classLevel': classLevel,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving chat message: $e');
    }
  }

  /// Get chat history for a user and chapter
  Future<List<Map<String, dynamic>>> getChatHistory({
    required String userId,
    required String chapterId,
    int limit = 50,
  }) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .where('chapterId', isEqualTo: chapterId)
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'message': data['message'],
          'isUser': data['isUser'],
          'timestamp': data['timestamp'],
          'chapterId': data['chapterId'],
          'chapterName': data['chapterName'],
          'classLevel': data['classLevel'],
        };
      }).toList();
    } catch (e) {
      print('Error getting chat history: $e');
      return [];
    }
  }

  /// Get recent chat sessions for a user
  Future<List<Map<String, dynamic>>> getRecentChatSessions({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .orderBy('timestamp', descending: true)
          .limit(limit * 5) // Get more to group by chapter
          .get();

      // Group by chapter and get the latest message from each
      final Map<String, Map<String, dynamic>> sessions = {};
      
      for (final doc in query.docs) {
        final data = doc.data();
        final chapterId = data['chapterId'];
        
        if (!sessions.containsKey(chapterId)) {
          sessions[chapterId] = {
            'chapterId': chapterId,
            'chapterName': data['chapterName'],
            'lastMessage': data['message'],
            'lastTimestamp': data['timestamp'],
            'isUserMessage': data['isUser'],
          };
        }
      }

      final sessionList = sessions.values.toList();
      sessionList.sort((a, b) {
        final aTime = a['lastTimestamp'] as Timestamp?;
        final bTime = b['lastTimestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return sessionList.take(limit).toList();
    } catch (e) {
      print('Error getting recent chat sessions: $e');
      return [];
    }
  }

  /// Delete chat history for a specific chapter
  Future<void> deleteChatHistory({
    required String userId,
    required String chapterId,
  }) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .where('chapterId', isEqualTo: chapterId)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting chat history: $e');
    }
  }

  /// Clear all chat history for a user
  Future<void> clearAllChatHistory({required String userId}) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing all chat history: $e');
    }
  }
}
