import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_model.dart';

/// Data service provider
final dataServiceProvider = Provider<DataService>((ref) {
  return DataService();
});

/// Data service for Firestore operations
class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _progressCollection = 'progress';
  static const String _sessionsCollection = 'study_sessions';
  static const String _questionsCollection = 'quiz_questions';

  /// Get user progress for a specific topic
  Future<ProgressData?> getUserProgress(String userId, String topicId) async {
    try {
      final doc = await _firestore
          .collection(_progressCollection)
          .doc('${userId}_$topicId')
          .get();

      if (doc.exists) {
        return ProgressData.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw DataException('Failed to get user progress: ${e.toString()}');
    }
  }

  /// Update user progress
  Future<void> updateUserProgress(ProgressData progress) async {
    try {
      await _firestore
          .collection(_progressCollection)
          .doc('${progress.userId}_${progress.topicId}')
          .set(progress.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw DataException('Failed to update progress: ${e.toString()}');
    }
  }

  /// Get all progress for a user
  Future<List<ProgressData>> getUserAllProgress(String userId) async {
    try {
      final query = await _firestore
          .collection(_progressCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return query.docs
          .map((doc) => ProgressData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw DataException('Failed to get user progress: ${e.toString()}');
    }
  }

  /// Save study session
  Future<void> saveStudySession(StudySession session) async {
    try {
      await _firestore
          .collection(_sessionsCollection)
          .doc(session.id)
          .set(session.toMap());
    } catch (e) {
      throw DataException('Failed to save study session: ${e.toString()}');
    }
  }

  /// Get user study sessions
  Future<List<StudySession>> getUserStudySessions(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final query = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => StudySession.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw DataException('Failed to get study sessions: ${e.toString()}');
    }
  }

  /// Get quiz questions for a topic
  Future<List<QuizQuestion>> getQuizQuestions(
    String topicId, {
    String difficulty = 'medium',
    int limit = 10,
  }) async {
    try {
      final query = await _firestore
          .collection(_questionsCollection)
          .where('topicId', isEqualTo: topicId)
          .where('difficulty', isEqualTo: difficulty)
          .limit(limit)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs
            .map((doc) => QuizQuestion.fromMap(doc.data()))
            .toList();
      }

      // If no questions found, return mock questions
      return _getMockQuestions(topicId, difficulty);
    } catch (e) {
      // Return mock questions on error
      return _getMockQuestions(topicId, difficulty);
    }
  }

  /// Create initial progress entry for a user-topic combination
  Future<void> createInitialProgress(String userId, String topicId, String subjectId) async {
    try {
      final progressId = '${userId}_$topicId';
      final existingDoc = await _firestore
          .collection(_progressCollection)
          .doc(progressId)
          .get();

      if (!existingDoc.exists) {
        final progress = ProgressData(
          id: progressId,
          userId: userId,
          subjectId: subjectId,
          topicId: topicId,
          completionPercentage: 0.0,
          timeSpentMinutes: 0,
          questionsAttempted: 0,
          questionsCorrect: 0,
          lastAccessed: DateTime.now(),
          createdAt: DateTime.now(),
          weakAreas: [],
          masteredConcepts: [],
        );

        await updateUserProgress(progress);
      }
    } catch (e) {
      throw DataException('Failed to create initial progress: ${e.toString()}');
    }
  }

  /// Update quiz performance
  Future<void> updateQuizPerformance({
    required String userId,
    required String topicId,
    required String subjectId,
    required int questionsAttempted,
    required int questionsCorrect,
    required int timeSpentMinutes,
  }) async {
    try {
      final progressId = '${userId}_$topicId';
      final existingProgress = await getUserProgress(userId, topicId);

      final updatedProgress = (existingProgress ?? ProgressData(
        id: progressId,
        userId: userId,
        subjectId: subjectId,
        topicId: topicId,
        completionPercentage: 0.0,
        timeSpentMinutes: 0,
        questionsAttempted: 0,
        questionsCorrect: 0,
        lastAccessed: DateTime.now(),
        createdAt: DateTime.now(),
        weakAreas: [],
        masteredConcepts: [],
      )).copyWith(
        questionsAttempted: (existingProgress?.questionsAttempted ?? 0) + questionsAttempted,
        questionsCorrect: (existingProgress?.questionsCorrect ?? 0) + questionsCorrect,
        timeSpentMinutes: (existingProgress?.timeSpentMinutes ?? 0) + timeSpentMinutes,
        lastAccessed: DateTime.now(),
        completionPercentage: _calculateCompletionPercentage(
          (existingProgress?.questionsAttempted ?? 0) + questionsAttempted,
          (existingProgress?.questionsCorrect ?? 0) + questionsCorrect,
        ),
      );

      await updateUserProgress(updatedProgress);
    } catch (e) {
      throw DataException('Failed to update quiz performance: ${e.toString()}');
    }
  }

  /// Calculate completion percentage based on performance
  double _calculateCompletionPercentage(int attempted, int correct) {
    if (attempted == 0) return 0.0;
    
    final accuracy = (correct / attempted) * 100;
    
    // Base completion on accuracy and number of questions attempted
    if (attempted >= 20 && accuracy >= 80) return 100.0;
    if (attempted >= 15 && accuracy >= 70) return 80.0;
    if (attempted >= 10 && accuracy >= 60) return 60.0;
    if (attempted >= 5) return 40.0;
    
    return 20.0;
  }

  /// Get mock questions for fallback
  List<QuizQuestion> _getMockQuestions(String topicId, String difficulty) {
    switch (topicId) {
      case 'quadratic-equations':
        return [
          QuizQuestion(
            id: 'qe_1',
            question: 'Solve the equation: x² - 5x + 6 = 0',
            options: ['x = 2, 3', 'x = 1, 6', 'x = -2, -3', 'x = 5, 1'],
            correctAnswer: 0,
            explanation: 'Factor: (x-2)(x-3) = 0, so x = 2 or x = 3',
            difficulty: difficulty,
            topicId: topicId,
            tags: ['factoring', 'solving'],
          ),
          QuizQuestion(
            id: 'qe_2',
            question: 'What is the discriminant of 2x² + 3x - 1 = 0?',
            options: ['17', '7', '25', '9'],
            correctAnswer: 0,
            explanation: 'Discriminant = b² - 4ac = 9 - 4(2)(-1) = 9 + 8 = 17',
            difficulty: difficulty,
            topicId: topicId,
            tags: ['discriminant', 'formula'],
          ),
        ];

      case 'linear-equations':
        return [
          QuizQuestion(
            id: 'le_1',
            question: 'Solve: 3x + 5 = 2x - 7',
            options: ['x = -12', 'x = 12', 'x = -2', 'x = 2'],
            correctAnswer: 0,
            explanation: '3x - 2x = -7 - 5, so x = -12',
            difficulty: difficulty,
            topicId: topicId,
            tags: ['solving', 'basic'],
          ),
        ];

      default:
        return [
          QuizQuestion(
            id: 'default_1',
            question: 'What is the main concept in this topic?',
            options: ['Concept A', 'Concept B', 'Concept C', 'Concept D'],
            correctAnswer: 0,
            explanation: 'This is a sample question for the topic.',
            difficulty: difficulty,
            topicId: topicId,
            tags: ['general'],
          ),
        ];
    }
  }
}

/// Data service exception
class DataException implements Exception {
  final String message;
  
  const DataException(this.message);
  
  @override
  String toString() => 'DataException: $message';
}
