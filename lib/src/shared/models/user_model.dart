/// User model representing a student
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserProfile? profile;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.profile,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserProfile? profile,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profile: profile ?? this.profile,
    );
  }
}

/// User profile with academic information
class UserProfile {
  final int classLevel;
  final List<String> preferredSubjects;
  final Map<String, int> subjectProgress; // subject -> percentage
  final Map<String, List<String>> weakTopics; // subject -> topics
  final Map<String, List<String>> strongTopics; // subject -> topics
  final DateTime? lastStudySession;
  final int totalStudyTime; // in minutes
  final int quizzesCompleted;
  final double averageScore;

  const UserProfile({
    required this.classLevel,
    required this.preferredSubjects,
    required this.subjectProgress,
    required this.weakTopics,
    required this.strongTopics,
    this.lastStudySession,
    required this.totalStudyTime,
    required this.quizzesCompleted,
    required this.averageScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      classLevel: json['classLevel'] as int,
      preferredSubjects: List<String>.from(json['preferredSubjects'] as List),
      subjectProgress: Map<String, int>.from(json['subjectProgress'] as Map),
      weakTopics: Map<String, List<String>>.from(
        (json['weakTopics'] as Map).map(
          (key, value) => MapEntry(key as String, List<String>.from(value as List)),
        ),
      ),
      strongTopics: Map<String, List<String>>.from(
        (json['strongTopics'] as Map).map(
          (key, value) => MapEntry(key as String, List<String>.from(value as List)),
        ),
      ),
      lastStudySession: json['lastStudySession'] != null
          ? DateTime.parse(json['lastStudySession'] as String)
          : null,
      totalStudyTime: json['totalStudyTime'] as int,
      quizzesCompleted: json['quizzesCompleted'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classLevel': classLevel,
      'preferredSubjects': preferredSubjects,
      'subjectProgress': subjectProgress,
      'weakTopics': weakTopics,
      'strongTopics': strongTopics,
      'lastStudySession': lastStudySession?.toIso8601String(),
      'totalStudyTime': totalStudyTime,
      'quizzesCompleted': quizzesCompleted,
      'averageScore': averageScore,
    };
  }

  UserProfile copyWith({
    int? classLevel,
    List<String>? preferredSubjects,
    Map<String, int>? subjectProgress,
    Map<String, List<String>>? weakTopics,
    Map<String, List<String>>? strongTopics,
    DateTime? lastStudySession,
    int? totalStudyTime,
    int? quizzesCompleted,
    double? averageScore,
  }) {
    return UserProfile(
      classLevel: classLevel ?? this.classLevel,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      weakTopics: weakTopics ?? this.weakTopics,
      strongTopics: strongTopics ?? this.strongTopics,
      lastStudySession: lastStudySession ?? this.lastStudySession,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
      averageScore: averageScore ?? this.averageScore,
    );
  }
}
