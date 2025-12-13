import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

/// RAG service provider
final ragServiceProvider = Provider<RAGService>((ref) {
  // Use cloud function (set to true for local development)
  return RAGService(useLocal: false);
});

/// RAG service for textbook-powered AI responses
class RAGService {
  final Dio _dio = Dio();
  
  // Use environment-based URL selection
  static const String _cloudFunctionUrl = 'https://us-central1-ai-tutor-oshan.cloudfunctions.net/ragApi';
  static const String _localUrl = 'http://10.0.2.2:5001/ai-tutor-oshan/us-central1/ragApi';
  
  // Default to cloud function, but can be overridden for development
  final String _baseUrl;
  
  RAGService({bool useLocal = false}) : _baseUrl = useLocal ? _localUrl : _cloudFunctionUrl {
    print('🔧 RAGService initialized with:');
    print('   useLocal: $useLocal');
    print('   _baseUrl: $_baseUrl');
    print('   Mode: ${useLocal ? '🔧 LOCAL EMULATOR' : '☁️ CLOUD FUNCTIONS'}');
    
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 5); // Increased for cloud functions
  }

  /// Ask a question using RAG pipeline
  Future<RAGResponse> askQuestion({
    required String question,
    required String classLevel,
    String? subject,
    String? chapter,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/ask-question',
        data: {
          'question': question,
          'class_level': classLevel,
          'subject': subject,
          'chapter': chapter,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return RAGResponse.fromJson(data);
      } else {
        throw RAGException('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        throw RAGException('Server error: ${e.response?.data['error'] ?? 'Unknown error'}');
      } else {
        throw RAGException('Network error: ${e.message}');
      }
    } catch (e) {
      throw RAGException('Failed to get answer: ${e.toString()}');
    }
  }

  /// Search for relevant content chunks
  Future<List<ContentChunk>> searchContent({
    required String query,
    required String classLevel,
    String? subject,
    String? chapter,
    int topK = 5,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/search-content',
        data: {
          'query': query,
          'class_level': classLevel,
          'subject': subject,
          'chapter': chapter,
          'top_k': topK,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final chunks = (data['chunks'] as List)
            .map((chunk) => ContentChunk.fromJson(chunk))
            .toList();
        return chunks;
      } else {
        throw RAGException('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw RAGException('Network error: ${e.message}');
    } catch (e) {
      throw RAGException('Failed to search content: ${e.toString()}');
    }
  }

  /// Generate chapter summary
  Future<ChapterSummary> generateSummary({
    required String classLevel,
    required String subject,
    required String chapter,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/generate-summary',
        data: {
          'class_level': classLevel,
          'subject': subject,
          'chapter': chapter,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ChapterSummary.fromJson(data);
      } else {
        throw RAGException('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw RAGException('Network error: ${e.message}');
    } catch (e) {
      throw RAGException('Failed to generate summary: ${e.toString()}');
    }
  }

  /// Generate quiz for chapter
  Future<ChapterQuiz> generateQuiz({
    required String classLevel,
    required String subject,
    required String chapter,
    int mcqCount = 5,
    int shortCount = 2,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/generate-quiz',
        data: {
          'class_level': classLevel,
          'subject': subject,
          'chapter': chapter,
          'mcq_count': mcqCount,
          'short_count': shortCount,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return ChapterQuiz.fromJson(data);
      } else {
        throw RAGException('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw RAGException('Network error: ${e.message}');
    } catch (e) {
      throw RAGException('Failed to generate quiz: ${e.toString()}');
    }
  }

  /// Get available subjects for each class
  Future<Map<String, List<String>>> getAvailableSubjects() async {
    try {
      final response = await _dio.get('$_baseUrl/list-subjects');

      if (response.statusCode == 200) {
        final data = response.data;
        final curriculum = data['curriculum'] as Map<String, dynamic>;
        
        final result = <String, List<String>>{};
        curriculum.forEach((classLevel, subjects) {
          result[classLevel] = (subjects as Map<String, dynamic>).keys.toList();
        });
        
        return result;
      } else {
        throw RAGException('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw RAGException('Network error: ${e.message}');
    } catch (e) {
      throw RAGException('Failed to get subjects: ${e.toString()}');
    }
  }

  /// Upload and process a textbook PDF
  Future<UploadResponse> uploadTextbook({
    required File file,
    required String classLevel,
    required String subject,
    String? chapterName,
  }) async {
    try {
      print('🔧 RAGService.uploadTextbook called');
      print('   File path: ${file.path}');
      print('   File exists: ${await file.exists()}');
      print('   Class level: $classLevel');
      print('   Subject: $subject');
      print('   Chapter name: $chapterName');
      print('   Base URL: $_baseUrl');
      
      // Get file info for debugging
      if (await file.exists()) {
        final fileStat = await file.stat();
        print('   File size: ${fileStat.size} bytes');
        print('   File type: ${fileStat.type}');
      }
      
      // Parse filename carefully
      String filename;
      try {
        // Handle both Windows and Unix path separators
        final parts = file.path.replaceAll('\\', '/').split('/');
        filename = parts.last;
        print('   Parsed filename: $filename');
      } catch (e) {
        print('   ❌ Error parsing filename: $e');
        filename = 'unknown.pdf'; // fallback
      }

      print('🔨 Creating FormData...');
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: filename,
        ),
        'class_level': classLevel,
        'subject': subject,
        if (chapterName != null && chapterName.isNotEmpty) 
          'chapter_name': chapterName,
      });
      print('✅ FormData created successfully');

      print('📡 Sending POST request to: $_baseUrl/upload-textbook');
      final response = await _dio.post(
        '$_baseUrl/upload-textbook',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('📥 Response received: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('✅ Creating UploadResponse from JSON...');
        return UploadResponse.fromJson(data);
      } else {
        throw RAGException('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException in uploadTextbook: $e');
      print('❌ DioException type: ${e.type}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Stack trace: ${e.stackTrace}');
      
      if (e.response?.statusCode == 500) {
        // Handle both JSON and string error responses
        String errorMessage = 'Unknown server error';
        try {
          final responseData = e.response?.data;
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['error']?.toString() ?? 'Server returned error';
          } else if (responseData is String) {
            errorMessage = responseData;
          } else {
            errorMessage = responseData?.toString() ?? 'Server error';
          }
        } catch (parseError) {
          print('❌ Error parsing server response: $parseError');
          errorMessage = 'Server error (response parsing failed)';
        }
        throw RAGException('Server error: $errorMessage');
      } else {
        throw RAGException('Network error: ${e.message}');
      }
    } catch (e, stackTrace) {
      print('❌ General exception in uploadTextbook: $e');
      print('❌ Stack trace: $stackTrace');
      throw RAGException('Failed to upload textbook: ${e.toString()}');
    }
  }

  /// Check if RAG service is available
  Future<bool> checkServiceHealth() async {
    try {
      final response = await _dio.get('$_baseUrl/');
      return response.statusCode == 200 && 
             response.data['rag_initialized'] == true;
    } catch (e) {
      return false;
    }
  }
}

/// RAG response model
class RAGResponse {
  final String answer;
  final double confidence;
  final int sourceChunksCount;
  final List<ContentChunk> sources;
  final String query;
  final String classLevel;
  final String? subject;
  final String? chapter;

  RAGResponse({
    required this.answer,
    required this.confidence,
    required this.sourceChunksCount,
    required this.sources,
    required this.query,
    required this.classLevel,
    this.subject,
    this.chapter,
  });

  factory RAGResponse.fromJson(Map<String, dynamic> json) {
    return RAGResponse(
      answer: json['answer'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      sourceChunksCount: json['source_chunks_count'] ?? 0,
      sources: (json['sources'] as List<dynamic>? ?? [])
          .map((source) => ContentChunk.fromJson(source))
          .toList(),
      query: json['query'] ?? '',
      classLevel: json['class_level'] ?? '',
      subject: json['subject'],
      chapter: json['chapter'],
    );
  }
}

/// Content chunk model
class ContentChunk {
  final String chunkId;
  final double score;
  final String text;
  final String classLevel;
  final String subject;
  final String chapter;
  final int pageNumber;
  final int wordCount;

  ContentChunk({
    required this.chunkId,
    required this.score,
    required this.text,
    required this.classLevel,
    required this.subject,
    required this.chapter,
    required this.pageNumber,
    required this.wordCount,
  });

  factory ContentChunk.fromJson(Map<String, dynamic> json) {
    return ContentChunk(
      chunkId: json['chunk_id'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      text: json['text'] ?? '',
      classLevel: json['class_level'] ?? '',
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
      pageNumber: json['page_number'] ?? 0,
      wordCount: json['word_count'] ?? 0,
    );
  }
}

/// Chapter summary model
class ChapterSummary {
  final String summary;
  final String chapter;
  final String classLevel;
  final String subject;
  final int sourceChunks;

  ChapterSummary({
    required this.summary,
    required this.chapter,
    required this.classLevel,
    required this.subject,
    required this.sourceChunks,
  });

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      summary: json['summary'] ?? '',
      chapter: json['chapter'] ?? '',
      classLevel: json['class_level'] ?? '',
      subject: json['subject'] ?? '',
      sourceChunks: json['source_chunks'] ?? 0,
    );
  }
}

/// Quiz models
class ChapterQuiz {
  final List<MCQQuestion> mcqs;
  final List<ShortQuestion> shortQuestions;
  final String chapter;
  final String classLevel;
  final String subject;
  final int sourceChunks;

  ChapterQuiz({
    required this.mcqs,
    required this.shortQuestions,
    required this.chapter,
    required this.classLevel,
    required this.subject,
    required this.sourceChunks,
  });

  factory ChapterQuiz.fromJson(Map<String, dynamic> json) {
    final quizData = json['quiz'] as Map<String, dynamic>? ?? {};
    
    return ChapterQuiz(
      mcqs: (quizData['mcqs'] as List<dynamic>? ?? [])
          .map((mcq) => MCQQuestion.fromJson(mcq))
          .toList(),
      shortQuestions: (quizData['short_questions'] as List<dynamic>? ?? [])
          .map((sq) => ShortQuestion.fromJson(sq))
          .toList(),
      chapter: json['chapter'] ?? '',
      classLevel: json['class_level'] ?? '',
      subject: json['subject'] ?? '',
      sourceChunks: json['source_chunks'] ?? 0,
    );
  }
}

class MCQQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  MCQQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory MCQQuestion.fromJson(Map<String, dynamic> json) {
    return MCQQuestion(
      question: json['question'] ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((option) => option.toString())
          .toList(),
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }
}

class ShortQuestion {
  final String question;
  final String sampleAnswer;

  ShortQuestion({
    required this.question,
    required this.sampleAnswer,
  });

  factory ShortQuestion.fromJson(Map<String, dynamic> json) {
    return ShortQuestion(
      question: json['question'] ?? '',
      sampleAnswer: json['sample_answer'] ?? '',
    );
  }
}

/// RAG exception
class RAGException implements Exception {
  final String message;
  RAGException(this.message);
  
  @override
  String toString() => 'RAGException: $message';
}

/// Upload response model
class UploadResponse {
  final String status;
  final String message;
  final int chunksCount;
  final bool pineconeStored;
  final bool firestoreStored;
  final String classLevel;
  final String subject;
  final String? chapterName;

  UploadResponse({
    required this.status,
    required this.message,
    required this.chunksCount,
    required this.pineconeStored,
    required this.firestoreStored,
    required this.classLevel,
    required this.subject,
    this.chapterName,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      chunksCount: json['chunks_count'] ?? 0,
      pineconeStored: json['pinecone_stored'] ?? false,
      firestoreStored: json['firestore_stored'] ?? false,
      classLevel: json['class_level'] ?? '',
      subject: json['subject'] ?? '',
      chapterName: json['chapter_name'],
    );
  }
}
