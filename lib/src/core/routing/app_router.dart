import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/onboarding/presentation/screens/class_selection_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/subjects/presentation/screens/subject_list_screen.dart';
import '../../features/subjects/presentation/screens/chapter_list_screen.dart';
import '../../features/learn/presentation/screens/learn_mode_screen.dart';
import '../../features/practice/presentation/screens/practice_mode_screen.dart';
import '../../features/practice/presentation/screens/quiz_screen.dart';
import '../../features/progress/presentation/screens/progress_dashboard_screen.dart';
import '../../features/class_subject_selection_screen.dart';
import '../../features/enhanced_chat_screen.dart';
import '../../features/admin/pdf_upload_screen.dart';
import '../../shared/services/auth_service.dart';

/// Router configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  return GoRouter(
    initialLocation: '/dashboard', // Start with dashboard for testing
    redirect: (context, state) {
      final isLoggedIn = authService.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup');
      
      // For development, skip auth redirect
      if (state.matchedLocation.startsWith('/class-selection') ||
          state.matchedLocation.startsWith('/admin') ||
          state.matchedLocation.startsWith('/chat')) {
        return null; // Allow direct access
      }
      
      // If not logged in and not on auth route, redirect to auth
      if (!isLoggedIn && !isAuthRoute && state.matchedLocation != '/dashboard') {
        return '/auth';
      }
      
      // If logged in and on auth route, redirect to dashboard
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Onboarding Routes
      GoRoute(
        path: '/class-selection',
        name: 'class-selection',
        builder: (context, state) => const ClassSelectionScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Subject Routes
      GoRoute(
        path: '/subjects',
        name: 'subjects',
        builder: (context, state) {
          final classLevel = state.uri.queryParameters['class'] ?? '9';
          return SubjectListScreen(classLevel: int.parse(classLevel));
        },
      ),
      GoRoute(
        path: '/chapters/:subjectId',
        name: 'chapters',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId']!;
          final classLevel = state.uri.queryParameters['class'] ?? '9';
          return ChapterListScreen(
            subjectId: subjectId,
            classLevel: int.parse(classLevel),
          );
        },
      ),
      // Learn Mode Routes - directly from chapters
      GoRoute(
        path: '/learn/:chapterId',
        name: 'learn',
        builder: (context, state) {
          final chapterId = state.pathParameters['chapterId']!;
          final chapterName = state.uri.queryParameters['chapterName'] ?? chapterId;
          final subject = state.uri.queryParameters['subject'] ?? 'Mathematics';
          return LearnModeScreen(
            chapterId: chapterId,
            chapterName: chapterName,
            subject: subject,
          );
        },
      ),
      
      // Practice Mode Routes - directly from chapters
      GoRoute(
        path: '/practice/:chapterId',
        name: 'practice',
        builder: (context, state) {
          final chapterId = state.pathParameters['chapterId']!;
          final subjectId = state.uri.queryParameters['subjectId'] ?? '';
          final classLevel = state.uri.queryParameters['class'] ?? '9';
          final chapterName = state.uri.queryParameters['chapterName'] ?? '';
          return PracticeModeScreen(
            chapterId: chapterId,
            subjectId: subjectId,
            classLevel: int.parse(classLevel),
            chapterName: chapterName,
          );
        },
      ),
      GoRoute(
        path: '/quiz/:chapterId',
        name: 'quiz',
        builder: (context, state) {
          final chapterId = state.pathParameters['chapterId']!;
          final difficulty = state.uri.queryParameters['difficulty'] ?? 'medium';
          return QuizScreen(
            chapterId: chapterId,
            difficulty: difficulty,
          );
        },
      ),
      
      // Progress Routes
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const ProgressDashboardScreen(),
      ),
      
      // RAG System Routes
      GoRoute(
        path: '/class-selection',
        name: 'class-selection-rag',
        builder: (context, state) => ClassSubjectSelectionScreen(
          userId: state.uri.queryParameters['userId'],
        ),
      ),
      GoRoute(
        path: '/chat/:classLevel',
        name: 'chat',
        builder: (context, state) {
          final classLevel = state.pathParameters['classLevel']!;
          final subject = state.uri.queryParameters['subject'];
          final chapter = state.uri.queryParameters['chapter'];
          final userId = state.uri.queryParameters['userId'];
          return EnhancedChatScreen(
            classLevel: classLevel,
            subject: subject,
            chapter: chapter,
            userId: userId,
          );
        },
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin/upload',
        name: 'admin-upload',
        builder: (context, state) => const PDFUploadScreen(),
      ),
    ],
  );
});
