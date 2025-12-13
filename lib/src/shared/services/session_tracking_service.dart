import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/progress_model.dart';
import 'data_service.dart';
import 'auth_service.dart';

/// Session tracking provider
final sessionTrackingProvider = Provider<SessionTrackingService>((ref) {
  return SessionTrackingService(ref);
});

/// Service to track user study sessions
class SessionTrackingService {
  final Ref _ref;
  final Uuid _uuid = const Uuid();
  StudySession? _currentSession;

  SessionTrackingService(this._ref);

  /// Start a new study session
  Future<void> startSession({
    required String topicId,
    required String mode, // 'learn' or 'practice'
  }) async {
    try {
      final user = _ref.read(currentUserProvider).value;
      if (user == null) return;

      _currentSession = StudySession(
        id: _uuid.v4(),
        userId: user.id,
        topicId: topicId,
        mode: mode,
        startTime: DateTime.now(),
        durationMinutes: 0,
        metrics: {
          'questionsAttempted': 0,
          'questionsCorrect': 0,
          'aiInteractions': 0,
          'hintsUsed': 0,
        },
      );
    } catch (e) {
      // Log error but don't break the flow
      print('Failed to start session: $e');
    }
  }

  /// Update session metrics
  void updateMetrics({
    int? questionsAttempted,
    int? questionsCorrect,
    int? aiInteractions,
    int? hintsUsed,
  }) {
    if (_currentSession == null) return;

    final currentMetrics = Map<String, dynamic>.from(_currentSession!.metrics);
    
    if (questionsAttempted != null) {
      currentMetrics['questionsAttempted'] = 
          (currentMetrics['questionsAttempted'] ?? 0) + questionsAttempted;
    }
    
    if (questionsCorrect != null) {
      currentMetrics['questionsCorrect'] = 
          (currentMetrics['questionsCorrect'] ?? 0) + questionsCorrect;
    }
    
    if (aiInteractions != null) {
      currentMetrics['aiInteractions'] = 
          (currentMetrics['aiInteractions'] ?? 0) + aiInteractions;
    }
    
    if (hintsUsed != null) {
      currentMetrics['hintsUsed'] = 
          (currentMetrics['hintsUsed'] ?? 0) + hintsUsed;
    }

    _currentSession = _currentSession!.copyWith(metrics: currentMetrics);
  }

  /// End current session and save to Firebase
  Future<void> endSession() async {
    if (_currentSession == null) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(_currentSession!.startTime).inMinutes;

      final finalSession = _currentSession!.copyWith(
        endTime: endTime,
        durationMinutes: duration,
      );

      final dataService = _ref.read(dataServiceProvider);
      await dataService.saveStudySession(finalSession);

      _currentSession = null;
    } catch (e) {
      print('Failed to end session: $e');
    }
  }

  /// Get current session info
  StudySession? get currentSession => _currentSession;

  /// Record AI interaction
  void recordAIInteraction() {
    updateMetrics(aiInteractions: 1);
  }

  /// Record hint usage
  void recordHintUsage() {
    updateMetrics(hintsUsed: 1);
  }

  /// Record quiz answer
  void recordQuizAnswer({required bool isCorrect}) {
    updateMetrics(
      questionsAttempted: 1,
      questionsCorrect: isCorrect ? 1 : 0,
    );
  }
}

/// Extension for StudySession to add copyWith method
extension StudySessionExtension on StudySession {
  StudySession copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? mode,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    Map<String, dynamic>? metrics,
  }) {
    return StudySession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      mode: mode ?? this.mode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      metrics: metrics ?? this.metrics,
    );
  }
}
