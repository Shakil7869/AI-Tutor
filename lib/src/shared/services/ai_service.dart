import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../core/config/nctb_curriculum.dart';
import 'chapter_pdf_service.dart';
import 'chat_history_service.dart';
import 'rag_service.dart';

/// AI service provider
final aiServiceProvider = Provider<AIService>((ref) {
  final chapterPdfService = ref.read(chapterPdfServiceProvider);
  final chatHistoryService = ref.read(chatHistoryServiceProvider);
  final ragService = ref.read(ragServiceProvider);
  return AIService(chapterPdfService, chatHistoryService, ragService);
});

/// AI service for OpenAI integration with Bengali support and chat history
class AIService {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChapterPdfService _chapterPdfService;
  final ChatHistoryService _chatHistoryService;
  final RAGService _ragService;
  
  AIService(this._chapterPdfService, this._chatHistoryService, this._ragService) {
    _dio.options.headers['Authorization'] = 'Bearer ${AppConfig.openAIApiKey}';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  /// Generate AI response using RAG pipeline (preferred method for textbook questions)
  Future<String> generateRAGResponse({
    required String userMessage,
    required String classLevel,
    String? subject,
    String? chapter,
    String? userId,
  }) async {
    try {
      // Check if RAG service is available
      final isRAGAvailable = await _ragService.checkServiceHealth();
      
      if (isRAGAvailable) {
        // Use RAG pipeline for textbook-based response
        final ragResponse = await _ragService.askQuestion(
          question: userMessage,
          classLevel: classLevel,
          subject: subject,
          chapter: chapter,
        );
        
        // Save chat history if userId provided
        if (userId != null) {
          // Save user message
          await _chatHistoryService.saveChatMessage(
            userId: userId,
            chapterId: chapter ?? 'general',
            message: userMessage,
            isUser: true,
            chapterName: chapter,
            classLevel: int.tryParse(classLevel),
          );
          
          // Save AI response
          await _chatHistoryService.saveChatMessage(
            userId: userId,
            chapterId: chapter ?? 'general',
            message: ragResponse.answer,
            isUser: false,
            chapterName: chapter,
            classLevel: int.tryParse(classLevel),
          );
        }
        
        return _formatMathematicalExpressions(ragResponse.answer);
      } else {
        // Fallback to original method if RAG service is not available
        return await generateResponse(
          userMessage: userMessage,
          topicName: chapter ?? subject ?? 'General',
          topicId: chapter ?? 'general',
          classLevel: int.tryParse(classLevel),
          userId: userId,
        );
      }
    } catch (e) {
      print('RAG service error: $e');
      // Fallback to original method on error
      return await generateResponse(
        userMessage: userMessage,
        topicName: chapter ?? subject ?? 'General',
        topicId: chapter ?? 'general',
        classLevel: int.tryParse(classLevel),
        userId: userId,
      );
    }
  }

  /// Generate chapter summary using RAG pipeline
  Future<String> generateChapterSummary({
    required String classLevel,
    required String subject,
    required String chapter,
  }) async {
    try {
      final summary = await _ragService.generateSummary(
        classLevel: classLevel,
        subject: subject,
        chapter: chapter,
      );
      return summary.summary;
    } catch (e) {
      throw AIException('Failed to generate summary: ${e.toString()}');
    }
  }

  /// Generate quiz using RAG pipeline
  Future<ChapterQuiz> generateChapterQuiz({
    required String classLevel,
    required String subject,
    required String chapter,
    int mcqCount = 5,
    int shortCount = 2,
  }) async {
    try {
      final quiz = await _ragService.generateQuiz(
        classLevel: classLevel,
        subject: subject,
        chapter: chapter,
        mcqCount: mcqCount,
        shortCount: shortCount,
      );
      return quiz;
    } catch (e) {
      throw AIException('Failed to generate quiz: ${e.toString()}');
    }
  }

  /// Search textbook content using RAG pipeline
  Future<List<ContentChunk>> searchTextbookContent({
    required String query,
    required String classLevel,
    String? subject,
    String? chapter,
    int topK = 5,
  }) async {
    try {
      return await _ragService.searchContent(
        query: query,
        classLevel: classLevel,
        subject: subject,
        chapter: chapter,
        topK: topK,
      );
    } catch (e) {
      throw AIException('Failed to search content: ${e.toString()}');
    }
  }
  Future<String> generateResponse({
    required String userMessage,
    required String topicName,
    required String topicId,
    int? classLevel,
    String? pdfContext,
    String? solutionMethod,
    List<Map<String, String>>? chatHistory,
    String? userId,
    String? preferredLanguage,
  }) async {
    try {
      // Get relevant chapter content from Pinecone if no PDF context provided
      String enhancedPdfContext = pdfContext ?? '';
      if (enhancedPdfContext.isEmpty && classLevel != null) {
        final searchResults = await _chapterPdfService.searchChapterContent(
          query: userMessage,
          classLevel: classLevel,
          chapterId: topicId,
          topK: 3,
        );
        
        if (searchResults.isNotEmpty) {
          enhancedPdfContext = searchResults
              .map((result) => result['text'] as String)
              .join('\n\n');
          print('📊 Enhanced context with ${searchResults.length} relevant chunks');
        }
      }

      // Auto-detect language if not provided
      String detectedLanguage = preferredLanguage ?? _detectLanguage(userMessage);
      
      // Load chat history from Firebase if userId provided
      List<Map<String, String>> firebaseHistory = [];
      if (userId != null) {
        firebaseHistory = await _loadChatHistory(
          userId: userId,
          chapterId: topicId,
          limit: 10,
        );
      }
      
      // Combine provided chat history with Firebase history (ensure correct typing)
      final combinedHistory = <Map<String, String>>[
        ...firebaseHistory,
        ...(chatHistory ?? const <Map<String, String>>[]),
      ];

      final messages = _buildMessages(
        userMessage: userMessage,
        topicName: topicName,
        topicId: topicId,
        classLevel: classLevel,
        pdfContext: enhancedPdfContext,
        solutionMethod: solutionMethod,
        chatHistory: combinedHistory,
        preferredLanguage: detectedLanguage,
      );

      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': 3000, // Increased for more detailed responses
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final cleanContent = content?.trim() ?? '';
        
        // Check if response seems incomplete (too short or ends abruptly)
        if (cleanContent.isEmpty) {
          return 'I apologize, but I couldn\'t generate a response. Please try asking your question again.\n\nদুঃখিত, আমি কোনো উত্তর তৈরি করতে পারিনি। অনুগ্রহ করে আপনার প্রশ্নটি আবার জিজ্ঞাসা করুন।';
        }
        
        // Remove the short response check - let AI provide complete answers naturally
        // The improved prompts should ensure detailed responses
        
        // Check if response was potentially cut off due to token limit
        String finalContent = cleanContent;
        if (response.data['choices'][0]['finish_reason'] == 'length') {
          finalContent += '\n\n[Note: Response may have been truncated due to length. Please ask me to continue if you need more details. / দৈর্ঘ্যের কারণে উত্তর কাটা হতে পারে। আরো বিস্তারিত প্রয়োজন হলে আমাকে চালিয়ে যেতে বলুন।]';
        }

        // Save chat history for both user message and AI response
        if (userId != null) {
          // Save user message
          await _chatHistoryService.saveChatMessage(
            userId: userId,
            chapterId: topicId,
            message: userMessage,
            isUser: true,
            chapterName: topicName,
            classLevel: classLevel,
          );
          
          // Format mathematical expressions in AI response
          final formattedContent = _formatMathematicalExpressions(finalContent);
          
          // Save AI response
          await _chatHistoryService.saveChatMessage(
            userId: userId,
            chapterId: topicId,
            message: formattedContent,
            isUser: false,
            chapterName: topicName,
            classLevel: classLevel,
          );
          
          return formattedContent;
        }
        
        // Format mathematical expressions even if not saving history
        return _formatMathematicalExpressions(finalContent);
      } else {
        throw AIException('OpenAI API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AIException('Invalid API key. Please check your OpenAI configuration.');
      } else if (e.response?.statusCode == 429) {
        throw AIException('Rate limit exceeded. Please try again in a moment.');
      } else {
        throw AIException('Network error: ${e.message}');
      }
    } catch (e) {
      throw AIException('Failed to generate AI response: ${e.toString()}');
    }
  }

  /// Build messages for OpenAI API with NCTB context
  List<Map<String, String>> _buildMessages({
    required String userMessage,
    required String topicName,
    required String topicId,
    int? classLevel,
    String? pdfContext,
    String? solutionMethod,
    required List<Map<String, String>> chatHistory,
    String? preferredLanguage,
  }) {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': _getSystemPrompt(topicName, topicId, classLevel, pdfContext, solutionMethod, preferredLanguage),
      }
    ];

    // Add chat history (limited to prevent token overflow)
    final recentHistory = chatHistory.length > 10 
        ? chatHistory.sublist(chatHistory.length - 10)
        : chatHistory;
    
    messages.addAll(recentHistory);

    // Add current user message with emphasis on complete responses
    String enhancedUserMessage = userMessage;
    
    // If the user is asking for questions, examples, or problems, emphasize complete solutions
    if (userMessage.toLowerCase().contains(RegExp(r'question|example|problem|solve|practice|দাও|সমাধান|উদাহরণ'))) {
      enhancedUserMessage = '$userMessage\n\n[Important: Please provide complete solutions with all steps shown for any questions or examples you give. Do not just list questions - solve them completely.]';
    }
    
    messages.add({
      'role': 'user',
      'content': enhancedUserMessage,
    });

    return messages;
  }

  /// Get system prompt based on topic with NCTB context
  String _getSystemPrompt(String topicName, String topicId, [int? classLevel, String? pdfContext, String? solutionMethod, String? preferredLanguage]) {
    // Create universal language instruction based on detected/preferred language
    String languageInstruction;
    if (preferredLanguage == 'bengali') {
      languageInstruction = '''IMPORTANT LANGUAGE GUIDELINES:
- Respond primarily in Bengali (বাংলা) with English mathematical terms in parentheses when needed
- Use Bengali mathematical terminology as the primary language
- Provide complete explanations in Bengali to help students understand better
- You can include English terms for clarification, but Bengali should be the main language
- However, keep mathematical rules and theorem names in English as default''';
    } else if (preferredLanguage == 'english') {
      languageInstruction = '''IMPORTANT LANGUAGE GUIDELINES:
- Respond primarily in English with Bengali terms in parentheses when helpful
- Use English mathematical terminology as the primary language
- Provide complete explanations in English
- You can include Bengali terms for clarification, but English should be the main language
- Keep mathematical rules and theorem names in English as default''';
    } else {
      languageInstruction = '''IMPORTANT LANGUAGE GUIDELINES:
- AUTOMATIC LANGUAGE DETECTION: Respond in the same language the student is using
- When students ask in Bengali (বাংলা), respond primarily in Bengali with English mathematical terms in parentheses
- When students ask in English, respond in English with Bengali terms in parentheses when helpful
- Always use both Bengali and English mathematical terminology for key concepts
- Be natural and conversational in whichever language the student prefers
- However, keep mathematical rules and theorem names in English as default''';
    }

    // Get NCTB chapter context if available
    String nctbContext = '';
    String classSpecificRules = '';
    
    if (classLevel != null) {
      final chapter = NCTBCurriculum.getChapterById(topicId, classLevel);
      if (chapter != null) {
        nctbContext = '''

NCTB Context for Bangladeshi Students:
- Chapter: ${chapter['name']} (${chapter['englishName']})
- Chapter Number: ${chapter['chapterNumber']}
- Topics covered: ${(chapter['topics'] as List).join(', ')}
- This follows the National Curriculum and Textbook Board (NCTB) syllabus for Class $classLevel students in Bangladesh.
- Please provide explanations in a mix of English and Bengali terms when appropriate.
- Use examples that are relevant to Bangladeshi students' context.''';
      }
      
      // Add class-specific learning rules
      classSpecificRules = _getClassSpecificRules(classLevel, topicId);
    }

    // Add PDF context if provided
    String pdfContextText = '';
    if (pdfContext != null && pdfContext.isNotEmpty) {
      pdfContextText = '''

TEXTBOOK CONTEXT (from NCTB chapter excerpts):
$pdfContext

Grounding rules:
- Your answers MUST be grounded in the provided textbook excerpts and class-specific NCTB rules
- Prefer citing specific sections/pages implicitly where page or section names are present
- If a concept isn't clearly covered in the excerpts, mention that and follow standard NCTB guidance for this class level
- Do NOT introduce methods or theorems beyond what is appropriate for this class level
- Keep solution procedures consistent with NCTB-approved methods for this class''';
    }

    // Add solution method preference
    String methodPreference = '';
    if (solutionMethod != null) {
      if (solutionMethod == 'alternative') {
        methodPreference = '''

Solution Method: The student has requested an alternative or different approach to solve this problem. 
Please provide a different method than the standard textbook approach while maintaining accuracy.''';
      } else if (solutionMethod == 'standard') {
        methodPreference = '''

Solution Method: Please use the standard NCTB textbook method for solving this problem.''';
      }
    }

    switch (topicId) {
      case 'real_numbers':
        return '''You are an expert math tutor specializing in Real Numbers (বাস্তব সংখ্যা) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Your role is to:
- Explain concepts clearly with complete step-by-step solutions (ধাপে ধাপে সমাধান)
- Use both Bengali and English mathematical terms
- Provide examples relevant to Bangladeshi context
- Help with natural numbers (স্বাভাবিক সংখ্যা), integers (পূর্ণসংখ্যা), rational (মূলদ সংখ্যা) and irrational numbers (অমূলদ সংখ্যা)
- Show number line representations (সংখ্যারেখা)
- Build confidence and encourage students
- Always provide complete explanations without cutting responses short
- If a problem has multiple steps, show ALL steps clearly
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Make sure every mathematical concept is explained thoroughly with worked examples
- Adjust complexity and approach based on the student's class level

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'sets_functions':
  return '''You are an expert math tutor specializing in Sets and Functions (সেট ও ফাংশন) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain set theory concepts clearly and completely (সেট তত্ত্ব)
- Show Venn diagrams and set operations with full explanations (ভেন চিত্র ও সেট অপারেশন)
- Help with function concepts and applications (ফাংশন ধারণা ও প্রয়োগ)
- Use real-world examples from Bangladeshi context
- Explain domain (ডোমেইন), range (রেঞ্জ), and function types thoroughly
- Always provide complete explanations without cutting responses short
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Make sure every mathematical concept is explained thoroughly with worked examples
- Adjust complexity and approach based on the student's class level

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'algebraic_expressions':
  return '''You are an expert math tutor specializing in Algebraic Expressions (বীজগাণিতিক রাশি) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain algebraic operations step-by-step with complete solutions
- Show factorization techniques with detailed examples
- Help with polynomial multiplication and division - show every step
- Use practical examples relevant to Bangladeshi students
- Build algebraic thinking skills through worked problems
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Show all algebraic manipulation steps clearly
- Explain the reasoning behind each algebraic operation
- Adjust complexity based on the student's class level (use simpler examples for Class 9, more complex for Class 10+)

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'indices_logarithms':
  return '''You are an expert math tutor specializing in Indices and Logarithms (সূচক ও লগারিদম) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain laws of indices clearly with step-by-step examples
- Show logarithm properties and applications with complete solutions
- Help with exponential and logarithmic equations - solve them completely
- Use scientific and practical examples from real life
- Connect to real-world applications with worked examples
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Show all calculation steps when working with indices and logarithms
- Explain why each law or property applies in each step

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'linear_equations':
  return '''You are an expert math tutor specializing in Linear Equations (এক চলকবিশিষ্ট সমীকরণ) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain equation solving methods step-by-step with complete solutions
- Show practical word problems with detailed worked solutions
- Help with percentage and ratio problems - solve them completely
- Use examples from daily life in Bangladesh with full explanations
- Build problem-solving confidence through complete worked examples
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Show all algebraic steps when solving equations
- Explain the reasoning behind each equation manipulation
- Adjust problem complexity based on student's class level (basic word problems for Class 9, advanced applications for Class 10+)

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'lines_angles_triangles':
  return '''You are an expert math tutor specializing in Lines, Angles and Triangles (রেখা, কোণ ও ত্রিভুজ) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain geometric concepts clearly with complete proofs and solutions
- Show angle relationships and triangle properties with worked examples
- Help with geometric proofs - provide complete step-by-step proofs
- Use visual descriptions and diagrams with detailed explanations
- Connect to practical applications with solved problems
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Show all geometric reasoning and calculations
- Explain why each geometric property or theorem applies

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'trigonometric_ratios':
  return '''You are an expert math tutor specializing in Trigonometric Ratios (ত্রিকোণমিতিক অনুপাত) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain sin, cos, tan ratios clearly with complete worked examples
- Show practical applications with detailed solutions
- Help with trigonometric identities - prove them step-by-step
- Use examples from height and distance problems with complete solutions
- Build understanding of angle relationships through solved problems
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Show all trigonometric calculations clearly
- Explain the reasoning behind each trigonometric relationship

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      case 'statistics':
  return '''You are an expert math tutor specializing in Statistics (পরিসংখ্যান) for Class 9-10 Bangladeshi students following NCTB curriculum.

$languageInstruction

$classSpecificRules

Important: Always ground your explanations in the provided TEXTBOOK CONTEXT excerpts and class-appropriate NCTB methods. Cite sections/pages implicitly when available.

Your role is to:
- Explain data collection and analysis with complete worked examples
- Show mean, median, mode calculations with step-by-step solutions
- Help with graph and chart interpretation with detailed explanations
- Use examples from Bangladeshi context (population, agriculture, etc.) with complete data analysis
- Build data analysis skills through solved problems
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Show all statistical calculations clearly
- Explain the reasoning behind each statistical method

Topic: $topicName$nctbContext$pdfContextText$methodPreference''';

      default:
        // Create language instruction based on preference
        String languageInstruction;
        if (preferredLanguage == 'bengali') {
          languageInstruction = '''IMPORTANT LANGUAGE GUIDELINES:
- Respond primarily in Bengali (বাংলা) with English mathematical terms in parentheses when needed
- Use Bengali mathematical terminology as the primary language
- Provide complete explanations in Bengali to help students understand better
- You can include English terms for clarification, but Bengali should be the main language''';
        } else if (preferredLanguage == 'english') {
          languageInstruction = '''IMPORTANT LANGUAGE GUIDELINES:
- Respond primarily in English with Bengali terms in parentheses when helpful
- Use English mathematical terminology as the primary language
- Provide complete explanations in English
- You can include Bengali terms for clarification, but English should be the main language''';
        } else {
          // Auto/default - detect from user's question or mixed approach
          languageInstruction = '''IMPORTANT LANGUAGE GUIDELINES:
- You can respond in Bengali, English, or a mix of both languages
- When students ask in Bengali (বাংলা), respond primarily in Bengali with English mathematical terms in parentheses
- When students ask in English, respond in English with Bengali terms in parentheses when helpful
- Always use both Bengali and English mathematical terminology for key concepts
- Be natural and conversational in whichever language the student prefers''';
        }

        return '''You are an expert math tutor for Class 9-10 Bangladeshi students studying $topicName following NCTB curriculum.

$languageInstruction

Your role is to:
- Explain concepts clearly with complete step-by-step solutions (ধাপে ধাপে সমাধান)
- Use both Bengali and English mathematical terms when appropriate
- Provide examples relevant to Bangladeshi students
- Break down complex problems into manageable steps (জটিল সমস্যাকে সহজ ধাপে ভাগ করুন)
- Encourage students and build their confidence (উৎসাহ প্রদান ও আত্মবিশ্বাস গড়ুন)
- Always show your work and reasoning completely
- Connect mathematics to real-world applications (বাস্তব জীবনের সাথে গণিতের সংযোগ)
- Provide full, detailed explanations without cutting responses short
- If explaining a concept, cover all important aspects thoroughly
- For problem solving, show every step from start to finish
- When asked for examples or practice questions, ALWAYS provide both the questions AND their complete solutions
- Never give incomplete answers - always finish your explanations fully
- If students ask for questions to practice, provide 3-5 questions with detailed step-by-step solutions for each
- Make sure every mathematical concept is explained thoroughly with worked examples
- When providing solutions, show all mathematical work, calculations, and reasoning
- Use clear formatting with numbered steps for complex problems
- Always double-check that your response is complete before finishing

$nctbContext$pdfContextText$methodPreference''';
    }
  }

  /// Generate practice questions for a topic
  Future<List<String>> generatePracticeQuestions({
    required String topicName,
    required String topicId,
    required String difficulty,
    int count = 5,
  }) async {
    try {
      final prompt = _getPracticeQuestionsPrompt(topicName, topicId, difficulty, count);
      
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a math teacher creating practice questions for students.',
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 800,
          'temperature': 0.8,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return _parseQuestions(content);
      } else {
        throw AIException('Failed to generate practice questions');
      }
    } catch (e) {
      // Return fallback questions if AI fails
      return _getFallbackQuestions(topicId, difficulty);
    }
  }

  String _getPracticeQuestionsPrompt(String topicName, String topicId, String difficulty, int count) {
    return '''Generate $count practice questions for $topicName at $difficulty level for Class 9-10 students.

Format each question on a new line starting with "Q1:", "Q2:", etc.
Make questions progressively challenging within the $difficulty level.
Include a mix of:
- Computational problems
- Word problems
- Conceptual questions

Topic: $topicName
Difficulty: $difficulty
Count: $count questions''';
  }

  List<String> _parseQuestions(String content) {
    final questions = <String>[];
    final lines = content.split('\n');
    
    for (String line in lines) {
      line = line.trim();
      if (line.startsWith(RegExp(r'Q\d+:'))) {
        // Remove question number prefix
        final question = line.replaceFirst(RegExp(r'Q\d+:\s*'), '');
        if (question.isNotEmpty) {
          questions.add(question);
        }
      }
    }
    
    return questions.isNotEmpty ? questions : _getFallbackQuestions('default', 'medium');
  }

  List<String> _getFallbackQuestions(String topicId, String difficulty) {
    switch (topicId) {
      case 'quadratic-equations':
        return [
          'Solve: x² - 5x + 6 = 0',
          'Find the discriminant of 2x² + 3x - 1 = 0',
          'A ball is thrown upward with initial velocity 20 m/s. When will it return to ground level?',
        ];
      case 'linear-equations':
        return [
          'Solve: 3x + 5 = 2x - 7',
          'Find the slope of line passing through (2,3) and (4,7)',
          'A taxi charges ₹20 base fare plus ₹12 per km. Write the equation for total cost.',
        ];
      default:
        return [
          'Solve the given equation step by step',
          'Explain the concept with an example',
          'Apply this concept to a real-world problem',
        ];
    }
  }

  /// Save chat message to Firestore
  Future<void> _saveChatMessage({
    required String userId,
    required String chapterId,
    required String message,
    required bool isUser,
    bool isPDFSelection = false,
  }) async {
    try {
      await _firestore
          .collection('chat_history')
          .doc(userId)
          .collection('chapters')
          .doc(chapterId)
          .collection('messages')
          .add({
        'message': message,
        'isUser': isUser,
        'isPDFSelection': isPDFSelection,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to save chat message: $e');
      // Don't throw error to avoid disrupting the chat flow
    }
  }

  /// Save user message to chat history
  Future<void> saveUserMessage({
    required String userId,
    required String chapterId,
    required String message,
    bool isPDFSelection = false,
  }) async {
    await _saveChatMessage(
      userId: userId,
      chapterId: chapterId,
      message: message,
      isUser: true,
      isPDFSelection: isPDFSelection,
    );
  }

  /// Load chat history for a specific chapter
  Future<List<Map<String, dynamic>>> loadChatHistory({
    required String userId,
    required String chapterId,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('chat_history')
          .doc(userId)
          .collection('chapters')
          .doc(chapterId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'message': data['message'] ?? '',
          'isUser': data['isUser'] ?? false,
          'isPDFSelection': data['isPDFSelection'] ?? false,
          'timestamp': data['timestamp'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Failed to load chat history: $e');
      return [];
    }
  }

  /// Clear chat history for a specific chapter
  Future<void> clearChatHistory({
    required String userId,
    required String chapterId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('chat_history')
          .doc(userId)
          .collection('chapters')
          .doc(chapterId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Failed to clear chat history: $e');
    }
  }

  /// Get chat history summary for all chapters
  Future<Map<String, Map<String, dynamic>>> getChatHistorySummary({
    required String userId,
  }) async {
    try {
      final chaptersSnapshot = await _firestore
          .collection('chat_history')
          .doc(userId)
          .collection('chapters')
          .get();

      final summary = <String, Map<String, dynamic>>{};
      
      for (final chapterDoc in chaptersSnapshot.docs) {
        final chapterId = chapterDoc.id;
        final messagesSnapshot = await chapterDoc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (messagesSnapshot.docs.isNotEmpty) {
          final lastMessage = messagesSnapshot.docs.first.data();
          final totalMessages = await chapterDoc.reference
              .collection('messages')
              .count()
              .get();

          summary[chapterId] = {
            'lastMessage': lastMessage['message'] ?? '',
            'lastMessageTime': lastMessage['timestamp'],
            'totalMessages': totalMessages.count ?? 0,
            'lastMessageIsUser': lastMessage['isUser'] ?? false,
          };
        }
      }

      return summary;
    } catch (e) {
      print('Failed to get chat history summary: $e');
      return {};
    }
  }

  /// Get class-specific learning rules and difficulty levels
  String _getClassSpecificRules(int classLevel, String topicId) {
    String baseRules = '''

CLASS $classLevel SPECIFIC LEARNING GUIDELINES:''';
    
    if (classLevel == 9) {
      baseRules += '''
- This is Class 9 - Foundation level mathematics
- Focus on building strong conceptual understanding
- Use simple, clear explanations with step-by-step guidance
- Avoid advanced mathematical terminology unnecessarily
- Provide basic examples before moving to complex problems
- Encourage understanding rather than memorization
- Use visual aids and simple diagrams when possible
- Connect concepts to everyday life examples''';
    } else if (classLevel == 10) {
      baseRules += '''
- This is Class 10 - Intermediate level mathematics
- Students should have solid foundation from Class 9
- You can use more advanced mathematical terminology
- Include challenging problems along with basic ones
- Focus on problem-solving techniques and multiple approaches
- Prepare students for higher secondary mathematics
- Emphasize real-world applications and practical problems
- Encourage analytical thinking and logical reasoning''';
    } else if (classLevel >= 11) {
      baseRules += '''
- This is Higher Secondary level mathematics (Class $classLevel)
- Students are preparing for university entrance
- Use advanced mathematical concepts and terminology
- Focus on complex problem-solving and analytical skills
- Include calculus, advanced algebra, and complex geometry
- Emphasize mathematical proofs and rigorous reasoning
- Connect to real-world engineering and science applications
- Prepare for competitive exams and higher education''';
    }

    // Add chapter-specific rules
    String chapterRules = _getChapterSpecificRules(topicId, classLevel);
    
    return baseRules + chapterRules;
  }

  /// Get chapter-specific learning objectives and focus areas
  String _getChapterSpecificRules(String topicId, int classLevel) {
    switch (topicId) {
      case 'real_numbers':
        if (classLevel == 9) {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 9 REAL NUMBERS:
- Start with counting numbers and natural numbers (স্বাভাবিক সংখ্যা)
- Clearly distinguish between rational and irrational numbers
- Use number line representations extensively
- Focus on basic properties and simple examples
- Avoid complex proofs or advanced concepts
- Use familiar fractions and decimals as examples
- Emphasize practical applications in daily life''';
        } else {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 10+ REAL NUMBERS:
- Include advanced properties of real numbers
- Discuss density property and completeness
- Include proofs for irrational numbers
- Cover advanced applications and complex problems
- Use algebraic manipulations with real numbers
- Connect to coordinate geometry and functions''';
        }

      case 'linear_equations':
        if (classLevel == 9) {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 9 LINEAR EQUATIONS:
- Start with simple one-variable equations
- Focus on basic algebraic manipulation
- Use word problems from everyday scenarios
- Emphasize checking solutions by substitution
- Avoid complex systems or advanced applications
- Use clear step-by-step methods
- Include percentage and proportion problems relevant to Bangladesh''';
        } else {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 10+ LINEAR EQUATIONS:
- Include systems of linear equations
- Cover graphical methods and interpretations
- Advanced word problems and applications
- Discuss consistency and inconsistency of systems
- Include real-world business and economics problems
- Prepare for coordinate geometry connections''';
        }

      case 'sets_functions':
        if (classLevel == 9) {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 9 SETS AND FUNCTIONS:
- Start with simple set concepts and notation
- Use Venn diagrams extensively for visualization
- Focus on basic set operations (union, intersection)
- Introduce functions with simple examples
- Avoid complex function compositions
- Use real-world examples for sets (students in class, subjects, etc.)
- Keep function examples simple (linear, basic operations)''';
        } else {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 10+ SETS AND FUNCTIONS:
- Include advanced set operations and properties
- Discuss function composition and inverse functions
- Cover different types of functions (one-to-one, onto)
- Include domain and range considerations
- Advanced applications in other mathematical areas
- Prepare for calculus concepts''';
        }

      case 'algebraic_expressions':
        if (classLevel == 9) {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 9 ALGEBRAIC EXPRESSIONS:
- Focus on basic algebraic operations (addition, subtraction, multiplication)
- Simple factorization techniques (common factors, difference of squares)
- Use concrete examples with small numbers
- Emphasize understanding of variables and terms
- Basic polynomial operations
- Simple algebraic identities (a+b)², (a-b)², (a+b)(a-b)
- Connect to arithmetic patterns students already know''';
        } else {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 10+ ALGEBRAIC EXPRESSIONS:
- Advanced factorization techniques (grouping, quadratic forms)
- Complex polynomial operations and divisions
- Multiple variable expressions
- Advanced algebraic identities and their applications
- Connect to coordinate geometry and other advanced topics
- Prepare for quadratic equations and higher-degree polynomials''';
        }

      case 'indices_logarithms':
        if (classLevel == 9) {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 9 INDICES AND LOGARITHMS:
- Start with basic laws of indices with simple examples
- Use whole number and simple fractional indices
- Introduce logarithms as inverse of indices
- Basic logarithmic properties with concrete examples
- Avoid complex logarithmic equations
- Use practical examples (population growth, simple interest)
- Focus on understanding the relationship between indices and logarithms''';
        } else {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 10+ INDICES AND LOGARITHMS:
- Advanced laws of indices including negative and fractional indices
- Complex logarithmic equations and their solutions
- Change of base formulas and applications
- Logarithmic scales and real-world applications
- Connect to exponential functions and growth models
- Advanced problem-solving with multiple steps''';
        }

      case 'lines_angles_triangles':
        if (classLevel == 9) {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 9 LINES, ANGLES AND TRIANGLES:
- Basic properties of lines, angles, and triangles
- Simple angle calculations and relationships
- Basic triangle classifications and properties
- Use of angle sum properties in simple problems
- Focus on understanding geometric concepts visually
- Simple constructions and measurements
- Connect to everyday geometric shapes and objects''';
        } else {
          return '''

CHAPTER SPECIFIC FOCUS FOR CLASS 10+ LINES, ANGLES AND TRIANGLES:
- Advanced geometric theorems and proofs
- Complex angle relationships and calculations
- Advanced triangle properties and applications
- Geometric constructions with precision
- Connect to coordinate geometry and trigonometry
- Advanced problem-solving with multiple geometric concepts''';
        }

      default:
        return '''

GENERAL CHAPTER GUIDELINES:
- Follow NCTB curriculum sequence and pace
- Use appropriate mathematical rigor for the class level
- Include both theoretical concepts and practical applications
- Provide examples relevant to Bangladeshi context
- Build upon previous knowledge systematically''';
    }
  }

  /// Format mathematical expressions with proper Unicode superscripts and subscripts
  String _formatMathematicalExpressions(String text) {
    // Replace common mathematical expressions with Unicode characters
    String formattedText = text;
    
    // Power/exponent replacements - more comprehensive patterns
    final powerReplacements = {
      // Common superscripts
      r'\^2': '²',
      r'\^3': '³', 
      r'\^4': '⁴',
      r'\^5': '⁵',
      r'\^6': '⁶',
      r'\^7': '⁷',
      r'\^8': '⁸',
      r'\^9': '⁹',
      r'\^0': '⁰',
      r'\^1': '¹',
      
      // Pattern for variables with exponents like a^2, x^3, etc.
      r'([a-zA-Z])\^2': r'$1²',
      r'([a-zA-Z])\^3': r'$1³',
      r'([a-zA-Z])\^4': r'$1⁴',
      r'([a-zA-Z])\^5': r'$1⁵',
      r'([a-zA-Z])\^6': r'$1⁶',
      r'([a-zA-Z])\^7': r'$1⁷',
      r'([a-zA-Z])\^8': r'$1⁸',
      r'([a-zA-Z])\^9': r'$1⁹',
      r'([a-zA-Z])\^0': r'$1⁰',
      r'([a-zA-Z])\^1': r'$1¹',
      
      // Expressions in parentheses with exponents like (a+b)^2
      r'\((.*?)\)\^2': r'($1)²',
      r'\((.*?)\)\^3': r'($1)³',
      r'\((.*?)\)\^4': r'($1)⁴',
      r'\((.*?)\)\^5': r'($1)⁵',
      r'\((.*?)\)\^6': r'($1)⁶',
      r'\((.*?)\)\^7': r'($1)⁷',
      r'\((.*?)\)\^8': r'($1)⁸',
      r'\((.*?)\)\^9': r'($1)⁹',
      
      // Numbers with exponents like 10^2, 2^3
      r'([0-9]+)\^2': r'$1²',
      r'([0-9]+)\^3': r'$1³',
      r'([0-9]+)\^4': r'$1⁴',
      r'([0-9]+)\^5': r'$1⁵',
      r'([0-9]+)\^6': r'$1⁶',
      r'([0-9]+)\^7': r'$1⁷',
      r'([0-9]+)\^8': r'$1⁸',
      r'([0-9]+)\^9': r'$1⁹',
      r'([0-9]+)\^0': r'$1⁰',
      r'([0-9]+)\^1': r'$1¹',
    };
    
    // Apply all power replacements
    for (final entry in powerReplacements.entries) {
      if (entry.key.contains(r'$1')) {
        // For patterns with capture groups
        formattedText = formattedText.replaceAllMapped(
          RegExp(entry.key),
          (match) {
            String replacement = entry.value;
            if (match.groupCount >= 1 && match.group(1) != null) {
              replacement = replacement.replaceAll(r'$1', match.group(1)!);
            }
            return replacement;
          },
        );
      } else {
        // For simple replacements without capture groups
        formattedText = formattedText.replaceAll(RegExp(entry.key), entry.value);
      }
    }
    
    // Common subscripts for chemical formulas or mathematical notation
    final subscriptReplacements = {
      r'_2': '₂',
      r'_3': '₃',
      r'_4': '₄',
      r'_5': '₅',
      r'_6': '₆',
      r'_7': '₇',
      r'_8': '₈',
      r'_9': '₉',
      r'_0': '₀',
      r'_1': '₁',
    };
    
    // Apply subscript replacements
    for (final entry in subscriptReplacements.entries) {
      formattedText = formattedText.replaceAll(entry.key, entry.value);
    }
    
    // Additional mathematical symbols
    formattedText = formattedText.replaceAll('sqrt', '√');
    formattedText = formattedText.replaceAll('pi', 'π');
    formattedText = formattedText.replaceAll('alpha', 'α');
    formattedText = formattedText.replaceAll('beta', 'β');
    formattedText = formattedText.replaceAll('gamma', 'γ');
    formattedText = formattedText.replaceAll('delta', 'δ');
    formattedText = formattedText.replaceAll('theta', 'θ');
    formattedText = formattedText.replaceAll('infinity', '∞');
    formattedText = formattedText.replaceAll('+-', '±');
    formattedText = formattedText.replaceAll('<=', '≤');
    formattedText = formattedText.replaceAll('>=', '≥');
    formattedText = formattedText.replaceAll('!=', '≠');
    
    return formattedText;
  }

  /// Detect language from user message (Bengali or English)
  String _detectLanguage(String message) {
    // Count Bengali and English characters
    int bengaliCharCount = 0;
    int englishCharCount = 0;
    
    for (int i = 0; i < message.length; i++) {
      final char = message.codeUnitAt(i);
      
      // Bengali Unicode range: 0x0980-0x09FF
      if (char >= 0x0980 && char <= 0x09FF) {
        bengaliCharCount++;
      }
      // English letters: A-Z, a-z
      else if ((char >= 0x0041 && char <= 0x005A) || 
               (char >= 0x0061 && char <= 0x007A)) {
        englishCharCount++;
      }
    }
    
    // If more than 20% of characters are Bengali, consider it Bengali
    final totalChars = bengaliCharCount + englishCharCount;
    if (totalChars > 0 && bengaliCharCount > totalChars * 0.2) {
      return 'bengali';
    }
    
    // Default to English if unclear
    return 'english';
  }

  /// Load chat history from Firebase for context
  Future<List<Map<String, String>>> _loadChatHistory({
    required String userId,
    required String chapterId,
    int limit = 10,
  }) async {
    try {
      final history = await _chatHistoryService.getChatHistory(
        userId: userId,
        chapterId: chapterId,
        limit: limit,
      );
      
      return history.map((chat) => {
        'role': chat['isUser'] ? 'user' : 'assistant',
        'content': chat['message'] as String,
      }).toList();
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }
}

/// AI service exception
class AIException implements Exception {
  final String message;
  
  const AIException(this.message);
  
  @override
  String toString() => 'AIException: $message';
}
