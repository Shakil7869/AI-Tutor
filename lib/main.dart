import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/core/config/app_config.dart';
import 'firebase_options.dart';
import 'src/core/config/theme_config.dart';
import 'src/core/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load();
  
  // Initialize Firebase
  try {
    // If default app doesn't exist, this will throw and we'll initialize it.
    Firebase.app();
  } catch (_) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const ProviderScope(child: StudentAITutorApp()));
}

class StudentAITutorApp extends ConsumerWidget {
  const StudentAITutorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Ai Tutor',
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
