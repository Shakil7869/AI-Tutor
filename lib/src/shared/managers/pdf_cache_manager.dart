// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:student_ai_tutor/src/shared/services/pdf_service.dart';

// /// PDF cache manager provider
// final pdfCacheManagerProvider = Provider<PDFCacheManager>((ref) {
//   final pdfService = ref.read(pdfServiceProvider);
//   return PDFCacheManager(pdfService);
// });

// /// PDF cache state provider
// final pdfCacheStateProvider = StateNotifierProvider<PDFCacheStateNotifier, PDFCacheState>((ref) {
//   final cacheManager = ref.read(pdfCacheManagerProvider);
//   return PDFCacheStateNotifier(cacheManager);
// });

// /// PDF cache state
// class PDFCacheState {
//   final Map<String, CachedChapter> cachedChapters;
//   final bool isLoading;
//   final String? error;
//   final CacheStats? stats;

//   const PDFCacheState({
//     this.cachedChapters = const {},
//     this.isLoading = false,
//     this.error,
//     this.stats,
//   });

//   PDFCacheState copyWith({
//     Map<String, CachedChapter>? cachedChapters,
//     bool? isLoading,
//     String? error,
//     CacheStats? stats,
//   }) {
//     return PDFCacheState(
//       cachedChapters: cachedChapters ?? this.cachedChapters,
//       isLoading: isLoading ?? this.isLoading,
//       error: error,
//       stats: stats ?? this.stats,
//     );
//   }
// }

// /// Cached chapter information
// class CachedChapter {
//   final String chapterId;
//   final int classLevel;
//   final String filePath;
//   final DateTime cachedAt;
//   final int fileSize;
//   final bool hasText;

//   const CachedChapter({
//     required this.chapterId,
//     required this.classLevel,
//     required this.filePath,
//     required this.cachedAt,
//     required this.fileSize,
//     this.hasText = false,
//   });

//   factory CachedChapter.fromFile(File file, int classLevel, String chapterId) {
//     final stat = file.statSync();
//     return CachedChapter(
//       chapterId: chapterId,
//       classLevel: classLevel,
//       filePath: file.path,
//       cachedAt: stat.modified,
//       fileSize: stat.size,
//     );
//   }

//   bool get isStale {
//     final age = DateTime.now().difference(cachedAt);
//     return age.inDays > 7; // Consider stale after 7 days
//   }

//   String get sizeFormatted {
//     if (fileSize < 1024) return '${fileSize}B';
//     if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
//     return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
//   }
// }

// /// Cache statistics
// class CacheStats {
//   final int totalFiles;
//   final int totalSizeBytes;
//   final Map<int, int> filesByClass;
//   final int staleFiles;
//   final DateTime lastUpdated;

//   const CacheStats({
//     required this.totalFiles,
//     required this.totalSizeBytes,
//     required this.filesByClass,
//     required this.staleFiles,
//     required this.lastUpdated,
//   });

//   String get totalSizeFormatted {
//     if (totalSizeBytes < 1024 * 1024) {
//       return '${(totalSizeBytes / 1024).toStringAsFixed(1)}KB';
//     }
//     return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
//   }
// }

// /// PDF cache state notifier
// class PDFCacheStateNotifier extends StateNotifier<PDFCacheState> {
//   final PDFCacheManager _cacheManager;

//   PDFCacheStateNotifier(this._cacheManager) : super(const PDFCacheState()) {
//     _loadCacheState();
//   }

//   Future<void> _loadCacheState() async {
//     state = state.copyWith(isLoading: true);
    
//     try {
//       final cachedChapters = await _cacheManager.getCachedChapters();
//       final stats = await _cacheManager.getCacheStats();
      
//       state = state.copyWith(
//         cachedChapters: cachedChapters,
//         stats: stats,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }

//   Future<void> refreshCache() async {
//     await _loadCacheState();
//   }

//   Future<void> clearCache() async {
//     state = state.copyWith(isLoading: true);
    
//     try {
//       await _cacheManager.clearAllCache();
//       await _loadCacheState();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }

//   Future<void> clearStaleCache() async {
//     state = state.copyWith(isLoading: true);
    
//     try {
//       await _cacheManager.clearStaleCache();
//       await _loadCacheState();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }

//   Future<void> preloadChapters(int classLevel, List<String> chapterIds) async {
//     state = state.copyWith(isLoading: true);
    
//     try {
//       await _cacheManager.preloadChapters(classLevel, chapterIds);
//       await _loadCacheState();
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//     }
//   }
// }

// /// PDF cache manager
// class PDFCacheManager {
//   final PDFService _pdfService;

//   PDFCacheManager(this._pdfService);

//   /// Get all cached chapters
//   Future<Map<String, CachedChapter>> getCachedChapters() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final files = directory.listSync();
//     final cachedChapters = <String, CachedChapter>{};

//     for (final file in files) {
//       if (file is File && file.path.endsWith('.pdf')) {
//         final fileName = file.path.split('/').last;
//         final match = RegExp(r'chapter_(\d+)_(.+)\.pdf').firstMatch(fileName);
        
//         if (match != null) {
//           final classLevel = int.parse(match.group(1)!);
//           final chapterId = match.group(2)!;
//           final key = '${classLevel}_$chapterId';
          
//           cachedChapters[key] = CachedChapter.fromFile(file, classLevel, chapterId);
//         }
//       }
//     }

//     return cachedChapters;
//   }

//   /// Get cache statistics
//   Future<CacheStats> getCacheStats() async {
//     final cachedChapters = await getCachedChapters();
//     final filesByClass = <int, int>{};
//     int totalSize = 0;
//     int staleFiles = 0;

//     for (final chapter in cachedChapters.values) {
//       filesByClass[chapter.classLevel] = (filesByClass[chapter.classLevel] ?? 0) + 1;
//       totalSize += chapter.fileSize;
//       if (chapter.isStale) staleFiles++;
//     }

//     return CacheStats(
//       totalFiles: cachedChapters.length,
//       totalSizeBytes: totalSize,
//       filesByClass: filesByClass,
//       staleFiles: staleFiles,
//       lastUpdated: DateTime.now(),
//     );
//   }

//   /// Check if chapter is cached
//   Future<bool> isChapterCached(int classLevel, String chapterId) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final filePath = '${directory.path}/chapter_${classLevel}_$chapterId.pdf';
//     return File(filePath).exists();
//   }

//   /// Get cached chapter file
//   Future<File?> getCachedChapterFile(int classLevel, String chapterId) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final filePath = '${directory.path}/chapter_${classLevel}_$chapterId.pdf';
//     final file = File(filePath);
    
//     if (await file.exists()) {
//       return file;
//     }
//     return null;
//   }

//   /// Preload chapters for offline use
//   Future<Map<String, bool>> preloadChapters(int classLevel, List<String> chapterIds) async {
//     return _pdfService.preloadChaptersForOffline(
//       classLevel: classLevel,
//       chapterIds: chapterIds,
//     );
//   }

//   /// Clear all cached files
//   Future<void> clearAllCache() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final files = directory.listSync();

//     for (final file in files) {
//       if (file is File && file.path.contains('chapter_') && file.path.endsWith('.pdf')) {
//         await file.delete();
//       }
//     }
//   }

//   /// Clear only stale cached files
//   Future<void> clearStaleCache() async {
//     final cachedChapters = await getCachedChapters();
    
//     for (final chapter in cachedChapters.values) {
//       if (chapter.isStale) {
//         final file = File(chapter.filePath);
//         if (await file.exists()) {
//           await file.delete();
//         }
//       }
//     }
//   }

//   /// Clear cache for specific class
//   Future<void> clearCacheForClass(int classLevel) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final files = directory.listSync();

//     for (final file in files) {
//       if (file is File && file.path.contains('chapter_${classLevel}_') && file.path.endsWith('.pdf')) {
//         await file.delete();
//       }
//     }
//   }

//   /// Get cache size for specific class
//   Future<int> getCacheSizeForClass(int classLevel) async {
//     final cachedChapters = await getCachedChapters();
//     int totalSize = 0;

//     for (final chapter in cachedChapters.values) {
//       if (chapter.classLevel == classLevel) {
//         totalSize += chapter.fileSize;
//       }
//     }

//     return totalSize;
//   }

//   /// Get offline chapters for class
//   Future<List<String>> getOfflineChaptersForClass(int classLevel) async {
//     final cachedChapters = await getCachedChapters();
//     return cachedChapters.values
//         .where((chapter) => chapter.classLevel == classLevel)
//         .map((chapter) => chapter.chapterId)
//         .toList();
//   }
// }
