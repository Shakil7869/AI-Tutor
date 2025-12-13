import 'content_model.dart';

/// Chat message model for AI interactions
class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final String? topicId;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.topicId,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.byName(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      topicId: json['topicId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'topicId': topicId,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    String? topicId,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      topicId: topicId ?? this.topicId,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Message types
enum MessageType {
  user,
  ai,
  system,
}

/// Quiz question model
class QuizQuestion {
  final String id;
  final String topicId;
  final String question;
  final List<String> options;
  final int correctAnswer; // index of correct option
  final String explanation;
  final DifficultyLevel difficulty;
  final List<String> hints;
  final String? mathExpression; // LaTeX format for math questions

  const QuizQuestion({
    required this.id,
    required this.topicId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.hints,
    this.mathExpression,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String,
      difficulty: DifficultyLevel.values.byName(json['difficulty'] as String),
      hints: List<String>.from(json['hints'] as List),
      mathExpression: json['mathExpression'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty.name,
      'hints': hints,
      'mathExpression': mathExpression,
    };
  }
}

/// Quiz result model
class QuizResult {
  final String id;
  final String userId;
  final String topicId;
  final List<QuizAnswer> answers;
  final int score; // percentage
  final int totalQuestions;
  final int correctAnswers;
  final DateTime completedAt;
  final int timeTaken; // in seconds
  final DifficultyLevel difficulty;

  const QuizResult({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.completedAt,
    required this.timeTaken,
    required this.difficulty,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] as String,
      userId: json['userId'] as String,
      topicId: json['topicId'] as String,
      answers: (json['answers'] as List)
          .map((e) => QuizAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      timeTaken: json['timeTaken'] as int,
      difficulty: DifficultyLevel.values.byName(json['difficulty'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'topicId': topicId,
      'answers': answers.map((e) => e.toJson()).toList(),
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken,
      'difficulty': difficulty.name,
    };
  }
}

/// Individual quiz answer
class QuizAnswer {
  final String questionId;
  final int selectedAnswer;
  final bool isCorrect;
  final int timeTaken; // in seconds

  const QuizAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeTaken,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'] as String,
      selectedAnswer: json['selectedAnswer'] as int,
      isCorrect: json['isCorrect'] as bool,
      timeTaken: json['timeTaken'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
    };
  }
}
