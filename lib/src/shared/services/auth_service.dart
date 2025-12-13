import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

/// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user provider
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserStream;
});

/// Authentication service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Stream of current user
  Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return await _getUserProfile(user.uid);
    });
  }

  /// Sign up with email and password
  Future<AppUser?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required int classLevel,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user profile
        final appUser = AppUser(
          id: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
          profile: UserProfile(
            classLevel: classLevel,
            preferredSubjects: ['Mathematics'],
            subjectProgress: {},
            weakTopics: {},
            strongTopics: {},
            totalStudyTime: 0,
            quizzesCompleted: 0,
            averageScore: 0.0,
          ),
        );

        await _createUserProfile(appUser);
        return appUser;
      }
    } catch (e) {
      throw AuthException('Failed to sign up: ${e.toString()}');
    }
    return null;
  }

  /// Sign in with email and password
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        await _updateLastLogin(user.uid);
        return await _getUserProfile(user.uid);
      }
    } catch (e) {
      throw AuthException('Failed to sign in: ${e.toString()}');
    }
    return null;
  }

  /// Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Check if user exists in Firestore
        final existingUser = await _getUserProfile(user.uid);
        if (existingUser == null) {
          // Create new user profile
          final appUser = AppUser(
            id: user.uid,
            email: user.email!,
            displayName: user.displayName,
            photoURL: user.photoURL,
            createdAt: DateTime.now(),
            profile: const UserProfile(
              classLevel: 9, // Default class
              preferredSubjects: ['Mathematics'],
              subjectProgress: {},
              weakTopics: {},
              strongTopics: {},
              totalStudyTime: 0,
              quizzesCompleted: 0,
              averageScore: 0.0,
            ),
          );
          await _createUserProfile(appUser);
          return appUser;
        } else {
          await _updateLastLogin(user.uid);
          return existingUser;
        }
      }
    } catch (e) {
      throw AuthException('Failed to sign in with Google: ${e.toString()}');
    }
    return null;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthException('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    final user = currentUser;
    if (user == null) throw const AuthException('No user signed in');

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'profile': profile.toJson()});
    } catch (e) {
      throw AuthException('Failed to update profile: ${e.toString()}');
    }
  }

  /// Get user profile from Firestore
  Future<AppUser?> _getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      }
    } catch (e) {
      // Return null if profile doesn't exist
    }
    return null;
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toJson());
    } catch (e) {
      throw AuthException('Failed to create user profile: ${e.toString()}');
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'lastLoginAt': DateTime.now().toIso8601String()});
    } catch (e) {
      // Ignore error if document doesn't exist
    }
  }
}

/// Custom authentication exception
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
