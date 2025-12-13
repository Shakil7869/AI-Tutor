/// Subject model
class Subject {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final List<int> supportedClasses;
  final bool isActive;

  const Subject({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.supportedClasses,
    required this.isActive,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      supportedClasses: List<int>.from(json['supportedClasses'] as List),
      isActive: json['isActive'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'supportedClasses': supportedClasses,
      'isActive': isActive,
    };
  }
}

/// Chapter model
class Chapter {
  final String id;
  final String subjectId;
  final String name;
  final String description;
  final int classLevel;
  final int orderIndex;
  final List<String> topicIds;
  final String? thumbnailUrl;

  const Chapter({
    required this.id,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.classLevel,
    required this.orderIndex,
    required this.topicIds,
    this.thumbnailUrl,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      classLevel: json['classLevel'] as int,
      orderIndex: json['orderIndex'] as int,
      topicIds: List<String>.from(json['topicIds'] as List),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'description': description,
      'classLevel': classLevel,
      'orderIndex': orderIndex,
      'topicIds': topicIds,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

/// Topic model
class Topic {
  final String id;
  final String chapterId;
  final String subjectId;
  final String name;
  final String description;
  final int classLevel;
  final int orderIndex;
  final String content;
  final List<String> keywords;
  final List<ExamRelevance> examRelevance;
  final DifficultyLevel difficulty;
  final int estimatedDuration; // in minutes

  const Topic({
    required this.id,
    required this.chapterId,
    required this.subjectId,
    required this.name,
    required this.description,
    required this.classLevel,
    required this.orderIndex,
    required this.content,
    required this.keywords,
    required this.examRelevance,
    required this.difficulty,
    required this.estimatedDuration,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      chapterId: json['chapterId'] as String,
      subjectId: json['subjectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      classLevel: json['classLevel'] as int,
      orderIndex: json['orderIndex'] as int,
      content: json['content'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      examRelevance: (json['examRelevance'] as List)
          .map((e) => ExamRelevance.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: DifficultyLevel.values.byName(json['difficulty'] as String),
      estimatedDuration: json['estimatedDuration'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapterId': chapterId,
      'subjectId': subjectId,
      'name': name,
      'description': description,
      'classLevel': classLevel,
      'orderIndex': orderIndex,
      'content': content,
      'keywords': keywords,
      'examRelevance': examRelevance.map((e) => e.toJson()).toList(),
      'difficulty': difficulty.name,
      'estimatedDuration': estimatedDuration,
    };
  }
}

/// Exam relevance model
class ExamRelevance {
  final String examName;
  final int year;
  final String category; // 'medical', 'engineering', 'government', etc.
  final int frequency; // how often this topic appears

  const ExamRelevance({
    required this.examName,
    required this.year,
    required this.category,
    required this.frequency,
  });

  factory ExamRelevance.fromJson(Map<String, dynamic> json) {
    return ExamRelevance(
      examName: json['examName'] as String,
      year: json['year'] as int,
      category: json['category'] as String,
      frequency: json['frequency'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examName': examName,
      'year': year,
      'category': category,
      'frequency': frequency,
    };
  }
}

/// Difficulty levels
enum DifficultyLevel {
  easy,
  medium,
  hard,
}

/// Extension for difficulty level display
extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case DifficultyLevel.easy:
        return '😊';
      case DifficultyLevel.medium:
        return '🤔';
      case DifficultyLevel.hard:
        return '😰';
    }
  }
}
