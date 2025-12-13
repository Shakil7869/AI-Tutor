import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// PDF service provider
final pdfServiceProvider = Provider<PDFService>((ref) {
  return PDFService();
});

/// Service for managing PDF books and chapters with Firebase integration
class PDFService {
  // Firebase instances
  FirebaseStorage? _storage;
  FirebaseFirestore? _firestore;
  bool _firebaseInitialized = false;

  PDFService() {
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (!_firebaseInitialized) {
        await Firebase.initializeApp();
        _storage = FirebaseStorage.instance;
        _firestore = FirebaseFirestore.instance;
        _firebaseInitialized = true;
        print('🔥 Firebase initialized for PDF service');
      }
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      _firebaseInitialized = false;
    }
  }

  /// Download and cache chapter PDF
  Future<String?> getChapterPdf({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      if (!_firebaseInitialized || _firestore == null || _storage == null) {
        throw PDFException('Firebase not initialized');
      }

      // Prefer Firestore download_url if present
      final docId = '${classLevel}_$chapterId';
      final snap = await _firestore!.collection('chapters').doc(docId).get();
      if (!snap.exists) {
        throw PDFException('Chapter not found in Firestore');
      }
      final data = snap.data()!;

      Uint8List? bytes;
      final String? downloadUrl = data['download_url'] as String?;
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        // Use Storage SDK to fetch data via firebase_path when possible
        final String? firebasePath = data['firebase_path'] as String?;
        if (firebasePath != null && firebasePath.isNotEmpty) {
          final ref = _storage!.ref(firebasePath);
          bytes = await ref.getData();
        }
      }

      // Fallback to conventional path if firebase_path missing
      bytes ??= await _storage!
          .ref('chapters/class_${classLevel}/$chapterId.pdf')
          .getData();

      if (bytes == null) throw PDFException('Failed to download chapter PDF');

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/chapter_${classLevel}_$chapterId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      print('📥 Downloaded chapter PDF from Firebase Storage');
      return filePath;
    } catch (e) {
      throw PDFException('Error downloading PDF: $e');
    }
  }
  
  /// Get available chapters for a class
  Future<Map<String, dynamic>> getChapters(int classLevel) async {
    try {
      if (!_firebaseInitialized || _firestore == null) {
        throw PDFException('Firebase not initialized');
      }

      final query = await _firestore!
          .collection('chapters')
          .where('class_level', isEqualTo: classLevel)
          .where('is_available', isEqualTo: true)
          .get();

      final Map<String, dynamic> chapters = {};
      for (final doc in query.docs) {
        final d = doc.data();
        chapters[d['chapter_id']] = {
          'name': d['chapter_name'],
          'englishName': d['english_name'],
          'chapterNumber': d['chapter_number'],
          'downloadUrl': d['download_url'],
          'filename': d['filename'],
        };
      }
      print('📊 Retrieved chapters from Firestore');
      return chapters;
    } catch (e) {
      throw PDFException('Error getting chapters: $e');
    }
  }
  
  /// Extract text from specific page
  Future<String?> getPageText({
    required int classLevel,
    required String chapterId,
    required int pageNumber,
  }) async {
    try {
  // No local service available. Consider adding a Cloud Function.
  return null;
    } catch (e) {
      print('Error getting page text: $e');
      return null;
    }
  }
  
  /// Extract text from entire chapter
  Future<String?> getChapterText({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
  // No local service available. Consider adding a Cloud Function.
  return null;
    } catch (e) {
      print('Error getting chapter text: $e');
      return null;
    }
  }
  
  /// Check if chapter PDF is available
  Future<bool> isChapterAvailable({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      final chapters = await getChapters(classLevel);
      return chapters.containsKey(chapterId);
    } catch (e) {
      print('Error checking chapter availability: $e');
      return false;
    }
  }
  
  /// Get chapter page range information
  Future<Map<String, int>?> getChapterPageRange({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      final chapters = await getChapters(classLevel);
      final chapterData = chapters[chapterId] as Map<String, dynamic>?;
      
      if (chapterData != null) {
        return {
          'start': chapterData['start'] as int,
          'end': chapterData['end'] as int,
          'total': (chapterData['end'] as int) - (chapterData['start'] as int) + 1,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting chapter page range: $e');
      return null;
    }
  }

  /// Upload PDF to Firebase Storage (for admin/teacher functionality)
  Future<bool> uploadPdfToFirebase({
    required File pdfFile,
    required int classLevel,
  }) async {
    try {
      if (!_firebaseInitialized || _storage == null) {
        print('❌ Firebase not initialized');
        return false;
      }

      final fileName = 'nctb_class_${classLevel}_math.pdf';
      final ref = _storage!.ref().child('textbooks/$fileName');
      
      await ref.putFile(pdfFile);
      print('✅ PDF uploaded to Firebase Storage: $fileName');
      
      // Update metadata in Firestore
      if (_firestore != null) {
        await _firestore!.collection('nctb_pdfs').doc('class_$classLevel').set({
          'filename': fileName,
          'uploaded_at': FieldValue.serverTimestamp(),
          'class_level': classLevel,
          'file_size': await pdfFile.length(),
        });
        print('✅ PDF metadata saved to Firestore');
      }
      
      return true;
    } catch (e) {
      print('❌ Error uploading to Firebase: $e');
      return false;
    }
  }

  /// Save chapter configuration to Firestore
  Future<bool> saveChapterConfiguration({
    required int classLevel,
    required Map<String, dynamic> chapters,
  }) async {
    try {
      if (!_firebaseInitialized || _firestore == null) {
        print('❌ Firebase not initialized');
        return false;
      }

      await _firestore!.collection('nctb_chapters').doc('class_$classLevel').set({
        'chapters': chapters,
        'updated_at': FieldValue.serverTimestamp(),
        'class_level': classLevel,
      });
      
      print('✅ Chapter configuration saved to Firestore');
      return true;
    } catch (e) {
      print('❌ Error saving chapter configuration: $e');
      return false;
    }
  }
  
  /// Clear cached PDFs
  Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().where((file) => 
          file.path.contains('chapter_') && file.path.endsWith('.pdf'));
      
      for (final file in files) {
        await file.delete();
      }
      print('🗑️ PDF cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
  
  /// Check service status
  Future<bool> checkServiceStatus() async {
    try {
      if (_firebaseInitialized) {
        await _firestore?.collection('chapters').limit(1).get();
        print('🔥 Firebase connection OK');
        return true;
      }
      return false;
    } catch (e) {
      print('PDF Service Error: $e');
      return false;
    }
  }

  /// Get Firebase connection status
  bool get isFirebaseAvailable => _firebaseInitialized;

  /// Get current storage mode
  String get storageMode {
  if (_firebaseInitialized) return 'Firebase Only';
  return 'Unavailable';
  }
}

/// PDF service exception
class PDFException implements Exception {
  final String message;
  
  const PDFException(this.message);
  
  @override
  String toString() => 'PDFException: $message';
}
