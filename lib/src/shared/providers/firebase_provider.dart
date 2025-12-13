import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase configuration provider
final firebaseConfigProvider = Provider<FirebaseConfig>((ref) {
  return FirebaseConfig();
});

/// Firebase configuration state
final firebaseStateProvider = StateNotifierProvider<FirebaseStateNotifier, FirebaseState>((ref) {
  return FirebaseStateNotifier();
});

/// Firebase state
class FirebaseState {
  final bool isInitialized;
  final bool isConnected;
  final String? error;
  final Map<String, dynamic>? features;

  const FirebaseState({
    this.isInitialized = false,
    this.isConnected = false,
    this.error,
    this.features,
  });

  FirebaseState copyWith({
    bool? isInitialized,
    bool? isConnected,
    String? error,
    Map<String, dynamic>? features,
  }) {
    return FirebaseState(
      isInitialized: isInitialized ?? this.isInitialized,
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
      features: features ?? this.features,
    );
  }
}

/// Firebase state notifier
class FirebaseStateNotifier extends StateNotifier<FirebaseState> {
  FirebaseStateNotifier() : super(const FirebaseState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      state = state.copyWith(isInitialized: true);
      await _checkConnectivity();
    } catch (e) {
      state = state.copyWith(
        isInitialized: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      // Test Firebase services
      final futures = await Future.wait([
        FirebaseFirestore.instance.collection('_test').limit(1).get(),
        FirebaseStorage.instance.ref().child('_test').listAll(),
      ]);

      state = state.copyWith(
        isConnected: true,
        features: {
          'firestore': true,
          'storage': true,
          'last_check': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshConnection() async {
    await _checkConnectivity();
  }
}

/// Firebase configuration management
class FirebaseConfig {
  static const String _storageBasePath = 'textbooks';
  static const String _chaptersCollection = 'nctb_chapters';
  static const String _textCacheCollection = 'nctb_text_cache';
  static const String _pdfsCollection = 'nctb_pdfs';

  /// Get Firebase Storage reference for textbooks
  Reference getTextbookRef(String fileName) {
    return FirebaseStorage.instance.ref().child('$_storageBasePath/$fileName');
  }

  /// Get Firebase Storage reference for chapters
  Reference getChapterRef(String fileName) {
    return FirebaseStorage.instance.ref().child('chapters/$fileName');
  }

  /// Get Firestore collection for chapters
  CollectionReference getChaptersCollection() {
    return FirebaseFirestore.instance.collection(_chaptersCollection);
  }

  /// Get Firestore collection for text cache
  CollectionReference getTextCacheCollection() {
    return FirebaseFirestore.instance.collection(_textCacheCollection);
  }

  /// Get Firestore collection for PDF metadata
  CollectionReference getPdfsCollection() {
    return FirebaseFirestore.instance.collection(_pdfsCollection);
  }

  /// Get chapter document reference
  DocumentReference getChapterDoc(int classLevel) {
    return getChaptersCollection().doc('class_$classLevel');
  }

  /// Get PDF metadata document reference
  DocumentReference getPdfDoc(int classLevel) {
    return getPdfsCollection().doc('class_$classLevel');
  }

  /// Firebase Security Rules for the app
  static const String firestoreRules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // NCTB chapters - read-only for all, write for authenticated users
    match /nctb_chapters/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // PDF metadata - read-only for all, write for authenticated users
    match /nctb_pdfs/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Text cache - read for all, write for system
    match /nctb_text_cache/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
''';

  static const String storageRules = '''
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Textbooks - public read, authenticated write
    match /textbooks/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Chapters - public read, authenticated write
    match /chapters/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
''';
}

/// Firebase health check provider
final firebaseHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final stopwatch = Stopwatch()..start();
    
    // Test Firestore
    final firestoreStart = stopwatch.elapsedMilliseconds;
    await FirebaseFirestore.instance.collection('nctb_chapters').limit(1).get();
    final firestoreTime = stopwatch.elapsedMilliseconds - firestoreStart;
    
    // Test Storage
    final storageStart = stopwatch.elapsedMilliseconds;
    await FirebaseStorage.instance.ref().child('textbooks').listAll();
    final storageTime = stopwatch.elapsedMilliseconds - storageStart;
    
    stopwatch.stop();
    
    return {
      'status': 'healthy',
      'total_time_ms': stopwatch.elapsedMilliseconds,
      'firestore_time_ms': firestoreTime,
      'storage_time_ms': storageTime,
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {
      'status': 'error',
      'error': e.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
});
