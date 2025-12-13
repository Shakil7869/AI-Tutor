import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/app_config.dart';

/// Chapter PDF service provider
final chapterPdfServiceProvider = Provider<ChapterPdfService>((ref) {
  return ChapterPdfService();
});

/// Service for handling chapter-based PDF operations
class ChapterPdfService {
  bool _firebaseInitialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  ChapterPdfService() {
    _initializeFirebase();
  }

  /// Initialize Firebase
  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      _firebaseInitialized = true;
      
      print('🔥 Firebase initialized for chapter PDF service');
    } catch (e) {
      print('⚠️ Firebase initialization failed: $e');
      _firebaseInitialized = false;
    }
  }

  /// Check if Firebase is available
  bool get isFirebaseAvailable => _firebaseInitialized;

  /// Get list of available chapters for a class from Firestore
  Future<Map<String, dynamic>> getAvailableChapters({required int classLevel}) async {
    try {
      final query = await _firestore
          .collection('chapters')
          .where('class_level', isEqualTo: classLevel)
          .where('is_available', isEqualTo: true)
          .get();

      final chapters = query.docs.map((doc) {
        final d = doc.data();
        final nameBn = d['chapter_name'] ?? '';
        final nameEn = d['english_name'] ?? '';
        final chapNo = d['chapter_number'] ?? '';
        return {
          'id': d['chapter_id'],
          'name': nameBn,
          'englishName': nameEn,
          'chapterNumber': chapNo,
          'downloadUrl': d['download_url'],
          'filename': d['filename'],
          'subject': d['subject'] ?? 'Mathematics',
          'uploadDate': (d['upload_date'] is Timestamp)
              ? (d['upload_date'] as Timestamp).toDate().toIso8601String()
              : d['upload_date']?.toString(),
          'fileSizeBytes': d['file_size_bytes'] ?? 0,
          'textChunksCount': d['text_chunks_count'] ?? 0,
          'isAvailable': true,
          'displayTitle': '$chapNo $nameBn',
          'displaySubtitle': nameEn,
          'bengaliName': nameBn,
        };
      }).toList();

      // Optional sort by NCTB sequence if chapter_number is numeric prefix
      chapters.sort((a, b) => (a['displayTitle'] ?? '').toString().compareTo((b['displayTitle'] ?? '').toString()));

      return {
        'success': true,
        'chapters': chapters,
        'totalChapters': chapters.length,
        'classLevel': classLevel,
      };
    } catch (e) {
      print('❌ Error getting available chapters: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get chapter information with proper NCTB formatting
  Future<Map<String, dynamic>?> getChapterInfo({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      final docId = '${classLevel}_$chapterId';
      final snap = await _firestore.collection('chapters').doc(docId).get();
      if (!snap.exists) return null;
      final d = snap.data()!;
      final isReady = (d['is_available'] == true) && (d['download_url'] != null && (d['download_url'] as String).isNotEmpty);
      if (!isReady) return null;

      return {
        'id': d['chapter_id'],
        'name': d['chapter_name'],
        'englishName': d['english_name'],
        'chapterNumber': d['chapter_number'] ?? '',
        'displayTitle': '${d['chapter_number'] ?? ''} ${d['chapter_name'] ?? ''}'.trim(),
        'displaySubtitle': d['english_name'],
        'downloadUrl': d['download_url'],
        'filename': d['filename'],
        'classLevel': d['class_level'],
        'available': true,
        'fileSize': d['file_size_bytes'],
      };
    } catch (e) {
      print('❌ Error getting chapter info: $e');
      return null;
    }
  }

  /// Check if chapter PDF is available for download from Firestore
  Future<bool> isChapterAvailable({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
  print('🔍 Checking availability for class $classLevel, chapter: $chapterId');
  final docId = '${classLevel}_$chapterId';
  final snap = await _firestore.collection('chapters').doc(docId).get();
  if (!snap.exists) return false;
  final d = snap.data()!;
  final ok = (d['is_available'] == true) && (d['download_url'] != null && (d['download_url'] as String).isNotEmpty);
  print(ok ? '✅ Chapter $chapterId available for download' : '❌ Chapter $chapterId not available');
  return ok;
    } catch (e) {
      print('❌ Error checking chapter availability: $e');
      return false;
    }
  }

  /// Get chapter download URL from Firestore
  Future<String?> getChapterDownloadUrl({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
  final docId = '${classLevel}_$chapterId';
  final snap = await _firestore.collection('chapters').doc(docId).get();
  if (!snap.exists) return null;
  final d = snap.data()!;
  final url = d['download_url'];
  if (url is String && url.isNotEmpty) return url;
  return null;
    } catch (e) {
      print('❌ Error getting download URL: $e');
      return null;
    }
  }

  /// Download chapter PDF for offline viewing
  Future<File?> downloadChapterPDF({
    required int classLevel,
    required String chapterId,
    Function(double)? onProgress,
  }) async {
    try {
      // Get app documents directory for permanent storage
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = 'class_${classLevel}_$chapterId.pdf';
      final file = File('${docsDir.path}/chapter_pdfs/$fileName');
      
      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);
      
      // Check if file already exists
      if (file.existsSync()) {
        print('📁 Chapter PDF already downloaded: $chapterId');
        return file;
      }

      print('⬇️ Downloading chapter PDF for class $classLevel, chapter: $chapterId');

      // Get Firebase download URL from Firestore
      final downloadUrl = await getChapterDownloadUrl(
        classLevel: classLevel,
        chapterId: chapterId,
      );

      http.Response response;

      if (downloadUrl != null) {
        print('🔗 Downloading from Firebase: $downloadUrl');
        // Option A: use direct HTTP with tokenized URL
        response = await http.get(
          Uri.parse(downloadUrl),
          headers: {'Accept': 'application/pdf'},
        );
        
        if (response.statusCode != 200) {
          print('❌ Firebase download failed: HTTP ${response.statusCode}');
          throw Exception('Firebase download failed');
        } else {
          print('✅ Downloaded from Firebase successfully');
        }
      } else {
        // Option B: derive from Storage if path known (not required when URL present)
        throw Exception('No download URL found for this chapter');
      }

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await file.writeAsBytes(bytes);
        print('✅ Downloaded PDF successfully (${bytes.length} bytes)');
        print('📁 Saved to: ${file.path}');
        onProgress?.call(1.0); // 100% complete
        return file;
      } else {
        print('❌ Download failed: HTTP ${response.statusCode}');
        if (response.statusCode == 404) {
          throw Exception('Chapter $chapterId not found. Please ensure it has been uploaded.');
        } else {
          throw Exception('Download failed with status ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error downloading PDF: $e');
      onProgress?.call(0.0); // Reset progress on error
      rethrow;
    }
  }

  /// Get downloaded chapter PDF file if it exists
  Future<File?> getDownloadedChapterPDF({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final fileName = 'class_${classLevel}_$chapterId.pdf';
      final file = File('${docsDir.path}/chapter_pdfs/$fileName');
      
      if (file.existsSync()) {
        return file;
      }
      return null;
    } catch (e) {
      print('❌ Error getting downloaded PDF: $e');
      return null;
    }
  }

  /// Check if chapter is downloaded
  Future<bool> isChapterDownloaded({
    required int classLevel,
    required String chapterId,
  }) async {
    final file = await getDownloadedChapterPDF(
      classLevel: classLevel,
      chapterId: chapterId,
    );
    return file != null;
  }

  /// Delete downloaded chapter PDF
  Future<bool> deleteDownloadedChapter({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      final file = await getDownloadedChapterPDF(
        classLevel: classLevel,
        chapterId: chapterId,
      );
      
      if (file != null && file.existsSync()) {
        await file.delete();
        print('🗑️ Deleted downloaded chapter: $chapterId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error deleting chapter: $e');
      return false;
    }
  }

  /// Search chapter content using vector similarity
  Future<List<Map<String, dynamic>>> searchChapterContent({
    required String query,
    int? classLevel,
    String? chapterId,
    String subject = 'Mathematics',
    int topK = 5,
  }) async {
    try {
  // Call local PDF management/search service if available
  final uri = Uri.parse('${AppConfig.pdfServiceBaseUrl}/search').replace(
    queryParameters: {
      'q': query,
      if (classLevel != null) 'class_level': classLevel.toString(),
      if (chapterId != null) 'chapter_id': chapterId,
      'top_k': topK.toString(),
    },
  );

  final resp = await http.get(uri, headers: {'Accept': 'application/json'});
  if (resp.statusCode != 200) {
    print('❌ Search service HTTP ${resp.statusCode}: ${resp.body}');
    return [];
  }

  final data = json.decode(resp.body);
  if (data is! Map || data['results'] is! List) {
    return [];
  }

  // Normalize results
  final List results = data['results'];
  return results.map<Map<String, dynamic>>((item) {
    final text = item['text'] ?? item['content'] ?? '';
    final score = (item['score'] as num?)?.toDouble();
    final page = item['page'] ?? item['page_number'];
    return {
      'text': text,
      'score': score,
      'page': page,
      'chapter_id': item['chapter_id'] ?? chapterId,
      'chapter_name': item['chapter_name'],
      'class_level': item['class_level'] ?? classLevel,
      'section': item['section'] ?? item['heading'],
    };
  }).toList();
    } catch (e) {
      print('❌ Error searching content: $e');
      return [];
    }
  }

  /// Ask AI about selected text from PDF
  Future<String?> askAIAboutText({
    required String selectedText,
    required String question,
    int? classLevel,
    String? chapterId,
  }) async {
    try {
      // Create a comprehensive query combining selected text and question
      final query = '''
Selected Text: "$selectedText"

Question: $question

Please provide a detailed explanation based on the selected text.
''';

      // Search for relevant content
      final searchResults = await searchChapterContent(
        query: query,
        classLevel: classLevel,
        chapterId: chapterId,
        topK: 3,
      );

      if (searchResults.isEmpty) {
        return 'I could not find relevant information about your question in the chapter content.';
      }

      // For now, return the most relevant content
      // In a full implementation, you would send this to OpenAI for a proper response
      final mostRelevant = searchResults.first;
      final context = mostRelevant['text'] ?? '';
      
      return '''
Based on the selected text and chapter content:

Selected: "$selectedText"

Explanation: $context

This content is from ${mostRelevant['chapter_name'] ?? 'the chapter'}.
''';

    } catch (e) {
      print('❌ Error asking AI: $e');
      return 'Sorry, I encountered an error while processing your question.';
    }
  }

  /// Get service status
  Future<Map<String, dynamic>?> getServiceStatus() async {
    try {
      return {
        'firebase_initialized': _firebaseInitialized,
      };
    } catch (e) {
      print('❌ Error getting service status: $e');
      return null;
    }
  }

  /// Get Firebase status and permissions info
  Future<Map<String, dynamic>?> getFirebaseStatus() async {
    try {
      // Simple status using SDKs instead of local API
      return {
        'initialized': _firebaseInitialized,
        'can_read_firestore': _firebaseInitialized,
        'can_access_storage': _firebaseInitialized,
      };
    } catch (e) {
      print('❌ Error getting Firebase status: $e');
      return null;
    }
  }

  /// Clear all downloaded PDFs to free up space
  Future<void> clearAllDownloads() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${docsDir.path}/chapter_pdfs');
      
      if (pdfDir.existsSync()) {
        await pdfDir.delete(recursive: true);
        print('🧹 All downloaded PDFs cleared');
      }
    } catch (e) {
      print('❌ Error clearing downloads: $e');
    }
  }

  /// Get total size of downloaded PDFs
  Future<int> getDownloadedSize() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${docsDir.path}/chapter_pdfs');
      
      if (!pdfDir.existsSync()) return 0;
      
      int totalSize = 0;
      await for (final entity in pdfDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      print('❌ Error calculating download size: $e');
      return 0;
    }
  }

  /// Get list of downloaded chapters
  Future<List<String>> getDownloadedChapters() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${docsDir.path}/chapter_pdfs');
      
      if (!pdfDir.existsSync()) return [];
      
      final List<String> chapters = [];
      await for (final entity in pdfDir.list()) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final filename = entity.path.split('/').last;
          chapters.add(filename.replaceAll('.pdf', ''));
        }
      }
      return chapters;
    } catch (e) {
      print('❌ Error getting downloaded chapters: $e');
      return [];
    }
  }
}
