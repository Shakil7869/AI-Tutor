import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration constants
class AppConfig {
  static const String appName = 'Student AI Tutor';
  static const String appVersion = '1.0.0';
  static const String baseUrl = 'https://your-project-id.web.app';
  // Local PDF/Textbook management service (Flask) base URL
  // Used for chapter content semantic search over textbook chunks
  static const String pdfServiceBaseUrl = 'http://127.0.0.1:5001';
  
  // Firebase Configuration
  static const String firestoreVersion = 'v1';
  
  /// Get OpenAI API Key from environment file
  static String get openAIApiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'OpenAI API Key not found. Please ensure OPENAI_API_KEY is set in your .env file',
      );
    }
    return key;
  }
  
  // App Settings
  static const int maxChatHistory = 50;
  static const int quizQuestionLimit = 10;
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  // Supported Classes and Subjects
  static const List<int> supportedClasses = [9, 10];
  static const List<String> supportedSubjects = ['Mathematics'];
  
  // Feature Flags
  static const bool enablePhysics = false;
  static const bool enableChemistry = false;
  static const bool enableBiology = false;
  static const bool enablePremiumFeatures = false;
}
