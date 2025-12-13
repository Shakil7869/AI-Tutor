// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// /// PDF service provider
// final pdfServiceProvider = Provider<PDFService>((ref) {
//   return PDFService();
// });

// /// Custom exception for PDF operations
// class PDFException implements Exception {
//   final String message;
//   PDFException(this.message);
  
//   @override
//   String toString() => 'PDFException: $message';
// }

// /// Service for handling PDF downloads and management with Firebase integration
// class PDFService {
//   // Firebase instances
//   FirebaseStorage? _storage;
//   FirebaseFirestore? _firestore;
//   bool _firebaseInitialized = false;

//   PDFService() {
//     _initializeFirebase();
//   }

//   /// Initialize Firebase if available
//   Future<void> _initializeFirebase() async {
//     try {
//       if (Firebase.apps.isEmpty) {
//         await Firebase.initializeApp();
//       }
      
//       _storage = FirebaseStorage.instance;
//       _firestore = FirebaseFirestore.instance;
//       _firebaseInitialized = true;
      
//       print('🔥 Firebase initialized successfully');
//     } catch (e) {
//       print('⚠️ Firebase initialization failed: $e');
//       print('📱 Continuing with HTTP-only mode');
//       _firebaseInitialized = false;
//     }
//   }

//   /// Get available chapters for a class
//   Future<Map<String, dynamic>> getChapters(int classLevel) async {
//     try {
//       // First try Firestore if available
//       if (_firebaseInitialized && _firestore != null) {
//         try {
//           final doc = await _firestore!
//               .collection('nctb_chapters')
//               .doc('class_$classLevel')
//               .get();
          
//           if (doc.exists) {
//             final data = doc.data() as Map<String, dynamic>;
//             final chapters = data['chapters'] as Map<String, dynamic>? ?? {};
//             print('📊 Retrieved chapters from Firestore');
//             return chapters;
//           }
//         } catch (e) {
//           print('⚠️ Firestore query failed: $e');
//         }
//       }

//       // If Firebase is not available, return default chapters
//       if (!_firebaseInitialized) {
//         throw PDFException('Firebase is not properly configured. Please check your Firebase setup.');
//       } else {
//         throw PDFException('Chapter configuration not found in Firestore. Please ensure the document "nctb_chapters/class_$classLevel" exists.');
//       }
//     } catch (e) {
//       throw PDFException('Error getting chapters: $e');
//     }
//   }

//   /// Download chapter PDF from Firebase Storage or HTTP fallback
//   Future<File?> downloadChapterPDF({
//     required int classLevel,
//     required String chapterId,
//   }) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final filePath = '${directory.path}/chapter_${classLevel}_$chapterId.pdf';
//       final file = File(filePath);
      
//       // Check if file already exists and is recent
//       if (await file.exists()) {
//         final stat = await file.stat();
//         final age = DateTime.now().difference(stat.modified);
//         if (age.inHours < 24) { // Cache for 24 hours
//           print('📁 Using cached PDF: $chapterId');
//           return file;
//         }
//       }

//       // Try Firebase Storage first
//       if (_firebaseInitialized && _storage != null) {
//         try {
//           // First get the specific chapter from Firebase
//           final chapterRef = _storage!.ref().child('chapters/class_${classLevel}_$chapterId.pdf');
          
//           // Try chapter-specific file first (stream to disk)
//           try {
//             await _downloadRefToFile(chapterRef, file);
//             print('🔥 Downloaded chapter PDF from Firebase Storage: $chapterId');
//             return file;
//           } catch (e) {
//             print('⚠️ Chapter-specific PDF not found, trying full textbook: $e');
//           }
          
//           // Fallback to full textbook if chapter-specific not available
//           final textbookRef = _storage!.ref().child('textbooks/nctb_class_${classLevel}_math.pdf');
          
//           // Check if we need to extract chapter from full PDF
//           final metadata = await _getFirestoreMetadata(classLevel, chapterId);
//           if (metadata != null) {
//             final extractedFile = await _extractChapterFromStorageRef(
//               textbookRef,
//               classLevel,
//               chapterId,
//               metadata,
//             );
//             if (extractedFile != null) {
//               print('🔥 Extracted chapter from Firebase textbook: $chapterId');
//               return extractedFile;
//             }
//           }
          
//         } catch (e) {
//           print('⚠️ Firebase Storage download failed: $e');
//         }
//       }

//       // If Firebase is not available or failed, show helpful error
//       if (!_firebaseInitialized) {
//         throw PDFException('Firebase is not properly configured. Please check your Firebase setup.');
//       } else {
//         throw PDFException('PDF not found in Firebase Storage. Please ensure the textbook file "textbooks/nctb_class_${classLevel}_math.pdf" exists.');
//       }
//     } catch (e) {
//       throw PDFException('Error downloading PDF: $e');
//     }
//   }

//   /// Get metadata from Firestore for chapter extraction
//   Future<Map<String, dynamic>?> _getFirestoreMetadata(int classLevel, String chapterId) async {
//     if (!_firebaseInitialized || _firestore == null) return null;
    
//     try {
//       final doc = await _firestore!
//           .collection('nctb_chapters')
//           .doc('class_$classLevel')
//           .get();
      
//       if (doc.exists) {
//         final data = doc.data() as Map<String, dynamic>;
//         final chapters = data['chapters'] as Map<String, dynamic>? ?? {};
//         return chapters[chapterId] as Map<String, dynamic>?;
//       }
//     } catch (e) {
//       print('⚠️ Failed to get Firestore metadata: $e');
//     }
//     return null;
//   }

//   /// Extract chapter from full PDF using Firebase Storage streaming download
//   Future<File?> _extractChapterFromStorageRef(
//     Reference textbookRef,
//     int classLevel,
//     String chapterId,
//     Map<String, dynamic> metadata,
//   ) async {
//     try {
//       print('🔥 Attempting to download full textbook from Firebase (streaming)...');
//       final directory = await getApplicationDocumentsDirectory();
//       final textbookPath = '${directory.path}/textbook_class_${classLevel}_math.tmp.pdf';
//       final textbookFile = File(textbookPath);
//       await _downloadRefToFile(textbookRef, textbookFile);

//       // Extract only the needed page range into a new small PDF
//       final start = (metadata['start'] as int?) ?? 1;
//       final end = (metadata['end'] as int?) ?? start;
//       final dstPath = '${directory.path}/chapter_${classLevel}_$chapterId.pdf';
//       final outFile = await _extractPagesToFile(
//         srcFile: textbookFile,
//         startPage: start,
//         endPage: end,
//         outPath: dstPath,
//       );

//       // Cleanup temp textbook file to save space
//       try { if (await textbookFile.exists()) await textbookFile.delete(); } catch (_) {}

//       if (outFile != null) {
//         print('✅ Created compact chapter PDF: ${await outFile.length()} bytes');
//       }
//       return outFile;
//     } catch (e) {
//       print('⚠️ Chapter extraction failed: $e');
//       return null;
//     }
//   }

//   /// Helper: stream a Firebase Storage reference to a local file path
//   Future<void> _downloadRefToFile(Reference ref, File file) async {
//     // Ensure directory exists
//     await file.parent.create(recursive: true);
//     // If file exists, delete before writing to avoid partial leftovers
//     if (await file.exists()) {
//       await file.delete();
//     }
//     final task = ref.writeToFile(file);
//     await task.whenComplete(() => null);
//     // Optionally verify non-zero size
//     final size = await file.length();
//     if (size == 0) {
//       throw PDFException('Downloaded file is empty');
//     }
//   }

//   /// Extract page range [startPage..endPage] from srcFile into outPath (compact chapter PDF)
//   Future<File?> _extractPagesToFile({
//     required File srcFile,
//     required int startPage,
//     required int endPage,
//     required String outPath,
//   }) async {
//     try {
//       final bytes = await srcFile.readAsBytes();
//       final sourceDoc = PdfDocument(inputBytes: bytes);
//       final total = sourceDoc.pages.count;
//       final s = startPage.clamp(1, total);
//       final e = endPage.clamp(1, total);
//       final outDoc = PdfDocument();
//       for (int i = s; i <= e; i++) {
//         final srcPage = sourceDoc.pages[i - 1];
//         final template = srcPage.createTemplate();
//         final width = template.size.width;
//         final height = template.size.height;
//         // Match output page size to source page
//         outDoc.pageSettings.size = ui.Size(width, height);
//         final newPage = outDoc.pages.add();
//         newPage.graphics.drawPdfTemplate(
//           template,
//           ui.Offset.zero,
//         );
//       }
//       final outBytes = outDoc.saveSync();
//       outDoc.dispose();
//       sourceDoc.dispose();
//       final outFile = File(outPath);
//       await outFile.writeAsBytes(outBytes, flush: true);
//       return outFile;
//     } catch (e) {
//       print('❌ Page extraction failed: $e');
//       return null;
//     }
//   }

//   /// Download full textbook for a class to local storage (streaming)
//   Future<File?> downloadTextbook({
//     required int classLevel,
//   }) async {
//     if (!_firebaseInitialized || _storage == null) {
//       throw PDFException('Firebase is not initialized');
//     }
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final filePath = '${directory.path}/textbook_class_${classLevel}_math.pdf';
//       final file = File(filePath);

//       final ref = _storage!.ref().child('textbooks/nctb_class_${classLevel}_math.pdf');
//       await _downloadRefToFile(ref, file);
//       return file;
//     } catch (e) {
//       print('❌ Failed to download textbook: $e');
//       return null;
//     }
//   }

//   /// Extract text from specific page with Firebase caching
//   Future<String?> getPageText({
//     required int classLevel,
//     required String chapterId,
//     required int pageNumber,
//   }) async {
//     try {
//       // Try Firebase cache first
//       if (_firebaseInitialized && _firestore != null) {
//         try {
//           final doc = await _firestore!
//               .collection('nctb_text_cache')
//               .doc('class_${classLevel}_${chapterId}_page_$pageNumber')
//               .get();
          
//           if (doc.exists) {
//             final data = doc.data() as Map<String, dynamic>;
//             final text = data['text'] as String?;
//             if (text != null && text.isNotEmpty) {
//               print('📊 Retrieved page text from Firebase cache');
//               return text;
//             }
//           }
//         } catch (e) {
//           print('⚠️ Firebase text cache query failed: $e');
//         }
//       }

//       // Since we're using Firebase only, return null if not found in cache
//       // Text extraction would need to be done on the client side from the PDF
//       print('ℹ️ Page text not found in Firebase cache. Client-side PDF text extraction needed.');
//       return null;
//     } catch (e) {
//       print('Error getting page text: $e');
//       return null;
//     }
//   }
  
//   /// Extract text from entire chapter with Firebase caching
//   Future<String?> getChapterText({
//     required int classLevel,
//     required String chapterId,
//   }) async {
//     try {
//       // Try Firebase cache first
//       if (_firebaseInitialized && _firestore != null) {
//         try {
//           final doc = await _firestore!
//               .collection('nctb_text_cache')
//               .doc('class_${classLevel}_${chapterId}_full')
//               .get();
          
//           if (doc.exists) {
//             final data = doc.data() as Map<String, dynamic>;
//             final text = data['text'] as String?;
//             if (text != null && text.isNotEmpty) {
//               print('📊 Retrieved chapter text from Firebase cache');
//               return text;
//             }
//           }
//         } catch (e) {
//           print('⚠️ Firebase text cache query failed: $e');
//         }
//       }

//       // Since we're using Firebase only, return null if not found in cache
//       // Chapter text extraction would need to be done on the client side from the PDF
//       print('ℹ️ Chapter text not found in Firebase cache. Client-side PDF text extraction needed.');
//       return null;
//     } catch (e) {
//       print('Error getting chapter text: $e');
//       return null;
//     }
//   }

//   /// Cache extracted text in Firebase
//   Future<void> _cacheTextInFirebase(int classLevel, String chapterId, int? pageNumber, String text) async {
//     try {
//       final docId = pageNumber != null 
//           ? 'class_${classLevel}_${chapterId}_page_$pageNumber'
//           : 'class_${classLevel}_${chapterId}_full';
      
//       await _firestore!.collection('nctb_text_cache').doc(docId).set({
//         'text': text,
//         'class_level': classLevel,
//         'chapter_id': chapterId,
//         'page_number': pageNumber,
//         'cached_at': FieldValue.serverTimestamp(),
//         'text_length': text.length,
//       });
      
//       print('💾 Cached text in Firebase: $docId');
//     } catch (e) {
//       print('⚠️ Failed to cache text in Firebase: $e');
//     }
//   }
  
//   /// Check if chapter PDF is available
//   Future<bool> isChapterAvailable({
//     required int classLevel,
//     required String chapterId,
//   }) async {
//     try {
//       final chapters = await getChapters(classLevel);
//       return chapters.containsKey(chapterId);
//     } catch (e) {
//       print('Error checking chapter availability: $e');
//       return false;
//     }
//   }
  
//   /// Get chapter page range information
//   Future<Map<String, int>?> getChapterPageRange({
//     required int classLevel,
//     required String chapterId,
//   }) async {
//     try {
//       final chapters = await getChapters(classLevel);
//       final chapterData = chapters[chapterId] as Map<String, dynamic>?;
      
//       if (chapterData != null) {
//         return {
//           'start': chapterData['start'] as int,
//           'end': chapterData['end'] as int,
//           'total': (chapterData['end'] as int) - (chapterData['start'] as int) + 1,
//         };
//       }
      
//       return null;
//     } catch (e) {
//       print('Error getting chapter page range: $e');
//       return null;
//     }
//   }

//   /// Upload PDF to Firebase Storage (for admin/teacher functionality)
//   Future<bool> uploadPdfToFirebase({
//     required File pdfFile,
//     required int classLevel,
//   }) async {
//     try {
//       if (!_firebaseInitialized || _storage == null) {
//         print('❌ Firebase not initialized');
//         return false;
//       }

//       final fileName = 'nctb_class_${classLevel}_math.pdf';
//       final ref = _storage!.ref().child('textbooks/$fileName');
      
//       await ref.putFile(pdfFile);
//       print('✅ PDF uploaded to Firebase Storage: $fileName');
      
//       // Update metadata in Firestore
//       if (_firestore != null) {
//         await _firestore!.collection('nctb_pdfs').doc('class_$classLevel').set({
//           'filename': fileName,
//           'uploaded_at': FieldValue.serverTimestamp(),
//           'class_level': classLevel,
//           'file_size': await pdfFile.length(),
//         });
//         print('✅ PDF metadata saved to Firestore');
//       }
      
//       return true;
//     } catch (e) {
//       print('❌ Error uploading to Firebase: $e');
//       return false;
//     }
//   }

//   /// Save chapter configuration to Firestore
//   Future<bool> saveChapterConfiguration({
//     required int classLevel,
//     required Map<String, dynamic> chapters,
//   }) async {
//     try {
//       if (!_firebaseInitialized || _firestore == null) {
//         print('❌ Firebase not initialized');
//         return false;
//       }

//       await _firestore!.collection('nctb_chapters').doc('class_$classLevel').set({
//         'chapters': chapters,
//         'updated_at': FieldValue.serverTimestamp(),
//         'class_level': classLevel,
//       });
      
//       print('✅ Chapter configuration saved to Firestore');
//       return true;
//     } catch (e) {
//       print('❌ Error saving chapter configuration: $e');
//       return false;
//     }
//   }
  
//   /// Clear cached PDFs
//   Future<void> clearCache() async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final files = directory.listSync().where((file) => 
//           file.path.contains('chapter_') && file.path.endsWith('.pdf'));
      
//       for (final file in files) {
//         await file.delete();
//       }
//       print('🗑️ PDF cache cleared');
//     } catch (e) {
//       print('Error clearing cache: $e');
//     }
//   }
  
//   /// Check service status with Firebase health check
//   Future<bool> checkServiceStatus() async {
//     try {
//       // Check Firebase connection 
//       if (_firebaseInitialized) {
//         try {
//           // Test Firebase connectivity with a lightweight operation
//           await Future.wait([
//             _firestore?.collection('nctb_chapters').limit(1).get() ?? Future.value(),
//             _storage?.ref().child('textbooks').listAll() ?? Future.value(),
//           ]);
//           print('🔥 Firebase connection OK');
//           return true;
//         } catch (e) {
//           print('⚠️ Firebase connection failed: $e');
//           return false;
//         }
//       }

//       print('⚠️ Firebase not initialized');
//       return false;
//     } catch (e) {
//       print('PDF Service Error: $e');
//       return false;
//     }
//   }

//   /// Sync chapters with Firebase
//   Future<void> syncChaptersWithFirebase() async {
//     if (!_firebaseInitialized || _firestore == null) {
//       print('⚠️ Firebase not available for sync');
//       return;
//     }

//     try {
//       // Get all available class levels
//       for (int classLevel in [6, 7, 8, 9, 10]) {
//         final chapters = await getChapters(classLevel);
//         if (chapters.isNotEmpty) {
//           await _firestore!.collection('nctb_chapters').doc('class_$classLevel').set({
//             'chapters': chapters,
//             'synced_at': FieldValue.serverTimestamp(),
//             'class_level': classLevel,
//             'total_chapters': chapters.length,
//           }, SetOptions(merge: true));
//         }
//       }
//       print('🔄 Chapters synced with Firebase');
//     } catch (e) {
//       print('⚠️ Chapter sync failed: $e');
//     }
//   }

//   /// Get offline-available chapters
//   Future<List<String>> getOfflineChapters(int classLevel) async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final files = directory.listSync();
      
//       final offlineChapters = <String>[];
//       final prefix = 'chapter_${classLevel}_';
      
//       for (final file in files) {
//         if (file is File && file.path.contains(prefix) && file.path.endsWith('.pdf')) {
//           final fileName = file.path.split('/').last;
//           final chapterId = fileName
//               .replaceFirst(prefix, '')
//               .replaceFirst('.pdf', '');
//           offlineChapters.add(chapterId);
//         }
//       }
      
//       print('📱 Found ${offlineChapters.length} offline chapters for class $classLevel');
//       return offlineChapters;
//     } catch (e) {
//       print('Error getting offline chapters: $e');
//       return [];
//     }
//   }

//   /// Preload chapters for offline use
//   Future<Map<String, bool>> preloadChaptersForOffline({
//     required int classLevel,
//     required List<String> chapterIds,
//   }) async {
//     final results = <String, bool>{};
    
//     for (final chapterId in chapterIds) {
//       try {
//         print('📥 Preloading chapter: $chapterId');
//         final file = await downloadChapterPDF(
//           classLevel: classLevel,
//           chapterId: chapterId,
//         );
//         results[chapterId] = file != null;
        
//         // Also preload chapter text for better offline experience
//         if (file != null) {
//           await getChapterText(
//             classLevel: classLevel,
//             chapterId: chapterId,
//           );
//         }
//       } catch (e) {
//         print('⚠️ Failed to preload $chapterId: $e');
//         results[chapterId] = false;
//       }
//     }
    
//     final successCount = results.values.where((success) => success).length;
//     print('✅ Preloaded $successCount/${chapterIds.length} chapters');
    
//     return results;
//   }

//   /// Get Firebase connection status
//   bool get isFirebaseAvailable => _firebaseInitialized;

//   /// Get current storage mode
//   String get storageMode {
//   if (_firebaseInitialized) return 'Firebase only';
//   return 'Offline';
//   }

//   /// Get cache statistics
//   Future<Map<String, dynamic>> getCacheStats() async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final files = directory.listSync().where((file) => 
//           file.path.contains('chapter_') && file.path.endsWith('.pdf'));
      
//       int totalSize = 0;
//       int fileCount = 0;
//       final classCounts = <int, int>{};
      
//       for (final file in files) {
//         if (file is File) {
//           final stat = await file.stat();
//           totalSize += stat.size;
//           fileCount++;
          
//           // Extract class level from filename
//           final fileName = file.path.split('/').last;
//           final match = RegExp(r'chapter_(\d+)_').firstMatch(fileName);
//           if (match != null) {
//             final classLevel = int.parse(match.group(1)!);
//             classCounts[classLevel] = (classCounts[classLevel] ?? 0) + 1;
//           }
//         }
//       }
      
//       return {
//         'total_files': fileCount,
//         'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
//         'by_class': classCounts,
//         'firebase_enabled': _firebaseInitialized,
//         'storage_mode': storageMode,
//       };
//     } catch (e) {
//       print('Error getting cache stats: $e');
//       return {
//         'error': e.toString(),
//         'firebase_enabled': _firebaseInitialized,
//         'storage_mode': storageMode,
//       };
//     }
//   }
// }
