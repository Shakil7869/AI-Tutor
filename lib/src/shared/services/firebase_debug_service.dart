import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug service to test Firebase connectivity and data
final firebaseDebugServiceProvider = Provider<FirebaseDebugService>((ref) {
  return FirebaseDebugService();
});

class FirebaseDebugService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Test Firestore connection and list all chapters
  Future<Map<String, dynamic>> testFirestoreConnection() async {
    try {
      print('🔥 Testing Firestore connection...');
      
      // Try to read chapters collection
      final query = await _firestore.collection('chapters').limit(10).get();
      
      final chapters = <Map<String, dynamic>>[];
      for (final doc in query.docs) {
        final data = doc.data();
        chapters.add({
          'id': doc.id,
          'data': data,
          'available': data['is_available'] ?? false,
          'hasDownloadUrl': data['download_url'] != null && (data['download_url'] as String).isNotEmpty,
        });
      }

      print('✅ Firestore connected successfully');
      print('📄 Found ${chapters.length} chapters in Firestore');
      
      return {
        'success': true,
        'connected': true,
        'chaptersFound': chapters.length,
        'chapters': chapters,
        'message': 'Firestore connection successful',
      };
    } catch (e) {
      print('❌ Firestore connection failed: $e');
      return {
        'success': false,
        'connected': false,
        'error': e.toString(),
        'message': 'Failed to connect to Firestore',
      };
    }
  }

  /// Test Firebase Storage connection
  Future<Map<String, dynamic>> testStorageConnection() async {
    try {
      print('📦 Testing Firebase Storage connection...');
      
      // Try to list files in chapters folder
      final ref = _storage.ref('chapters');
      final result = await ref.listAll();
      
      final files = <Map<String, dynamic>>[];
      for (final item in result.items) {
        try {
          final metadata = await item.getMetadata();
          final downloadUrl = await item.getDownloadURL();
          files.add({
            'name': item.name,
            'fullPath': item.fullPath,
            'size': metadata.size,
            'timeCreated': metadata.timeCreated?.toIso8601String(),
            'downloadUrl': downloadUrl,
          });
        } catch (e) {
          files.add({
            'name': item.name,
            'fullPath': item.fullPath,
            'error': e.toString(),
          });
        }
      }

      print('✅ Firebase Storage connected successfully');
      print('📦 Found ${files.length} files in Storage');
      
      return {
        'success': true,
        'connected': true,
        'filesFound': files.length,
        'files': files,
        'message': 'Firebase Storage connection successful',
      };
    } catch (e) {
      print('❌ Firebase Storage connection failed: $e');
      return {
        'success': false,
        'connected': false,
        'error': e.toString(),
        'message': 'Failed to connect to Firebase Storage',
      };
    }
  }

  /// Get specific chapter debug info
  Future<Map<String, dynamic>> getChapterDebugInfo({
    required int classLevel,
    required String chapterId,
  }) async {
    try {
      final docId = '${classLevel}_$chapterId';
      print('🔍 Getting debug info for document: $docId');
      
      final doc = await _firestore.collection('chapters').doc(docId).get();
      
      if (!doc.exists) {
        return {
          'success': false,
          'exists': false,
          'docId': docId,
          'message': 'Document does not exist in Firestore',
        };
      }

      final data = doc.data()!;
      final downloadUrl = data['download_url'] as String?;
      
      Map<String, dynamic> urlTest = {};
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        // Test if URL is accessible
        try {
          final storageRef = _storage.refFromURL(downloadUrl);
          final metadata = await storageRef.getMetadata();
          urlTest = {
            'accessible': true,
            'size': metadata.size,
            'contentType': metadata.contentType,
            'timeCreated': metadata.timeCreated?.toIso8601String(),
          };
        } catch (e) {
          urlTest = {
            'accessible': false,
            'error': e.toString(),
          };
        }
      }

      return {
        'success': true,
        'exists': true,
        'docId': docId,
        'data': data,
        'downloadUrl': downloadUrl,
        'urlTest': urlTest,
        'isAvailable': data['is_available'] == true,
        'hasValidUrl': downloadUrl != null && downloadUrl.isNotEmpty,
        'message': 'Chapter found in Firestore',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error getting chapter debug info',
      };
    }
  }

  /// Get full system debug report
  Future<Map<String, dynamic>> getFullDebugReport({
    int? classLevel,
    String? chapterId,
  }) async {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'firestore': await testFirestoreConnection(),
      'storage': await testStorageConnection(),
    };

    if (classLevel != null && chapterId != null) {
      report['specificChapter'] = await getChapterDebugInfo(
        classLevel: classLevel,
        chapterId: chapterId,
      );
    }

    return report;
  }
}
