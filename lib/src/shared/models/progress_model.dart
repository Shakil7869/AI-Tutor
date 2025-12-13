/// Progress tracking model for subjects and topics
class ProgressData {
  final String id;
  final String userId;
  final String subjectId;
  final String topicId;
  final double completionPercentage;
  final int timeSpentMinutes;
  final int questionsAttempted;
  final int questionsCorrect;
  final DateTime lastAccessed;
  final DateTime createdAt;
  final List<String> weakAreas;
  final List<String> masteredConcepts;

  const ProgressData({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.topicId,
    required this.completionPercentage,
    required this.timeSpentMinutes,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.lastAccessed,
    required this.createdAt,
    required this.weakAreas,
    required this.masteredConcepts,
  });

  /// Calculate accuracy percentage
  double get accuracy => questionsAttempted > 0 
      ? (questionsCorrect / questionsAttempted) * 100 
      : 0.0;

  /// Check if topic is mastered (80% accuracy, 10+ questions)
  bool get isMastered => accuracy >= 80.0 && questionsAttempted >= 10;

  /// Check if needs improvement (below 60% accuracy)
  bool get needsImprovement => accuracy < 60.0 && questionsAttempted >= 5;

  factory ProgressData.fromMap(Map<String, dynamic> map) {
    return ProgressData(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      topicId: map['topicId'] ?? '',
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
      timeSpentMinutes: map['timeSpentMinutes'] ?? 0,
      questionsAttempted: map['questionsAttempted'] ?? 0,
      questionsCorrect: map['questionsCorrect'] ?? 0,
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['lastAccessed'] ?? 0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      weakAreas: List<String>.from(map['weakAreas'] ?? []),
      masteredConcepts: List<String>.from(map['masteredConcepts'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subjectId': subjectId,
      'topicId': topicId,
      'completionPercentage': completionPercentage,
      'timeSpentMinutes': timeSpentMinutes,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'lastAccessed': lastAccessed.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'weakAreas': weakAreas,
      'masteredConcepts': masteredConcepts,
    };
  }

  ProgressData copyWith({
    String? id,
    String? userId,
    String? subjectId,
    String? topicId,
    double? completionPercentage,
    int? timeSpentMinutes,
    int? questionsAttempted,
    int? questionsCorrect,
    DateTime? lastAccessed,
    DateTime? createdAt,
    List<String>? weakAreas,
    List<String>? masteredConcepts,
  }) {
    return ProgressData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      questionsAttempted: questionsAttempted ?? this.questionsAttempted,
      questionsCorrect: questionsCorrect ?? this.questionsCorrect,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      createdAt: createdAt ?? this.createdAt,
      weakAreas: weakAreas ?? this.weakAreas,
      masteredConcepts: masteredConcepts ?? this.masteredConcepts,
    );
  }
}

/// Quiz question model
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String difficulty;
  final String topicId;
  final List<String> tags;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.topicId,
    required this.tags,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'medium',
      topicId: map['topicId'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'topicId': topicId,
      'tags': tags,
    };
  }
}

/// Study session model
class StudySession {
  final String id;
  final String userId;
  final String topicId;
  final String mode; // 'learn' or 'practice'
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final Map<String, dynamic> metrics;

  const StudySession({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.mode,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.metrics,
  });

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      topicId: map['topicId'] ?? '',
      mode: map['mode'] ?? 'learn',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      durationMinutes: map['durationMinutes'] ?? 0,
      metrics: Map<String, dynamic>.from(map['metrics'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'topicId': topicId,
      'mode': mode,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'metrics': metrics,
    };
  }
}
