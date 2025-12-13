import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/data_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/session_tracking_service.dart';
import '../../../../shared/models/progress_model.dart';

/// Quiz screen with questions and answers
class QuizScreen extends ConsumerStatefulWidget {
  final String chapterId;
  final String difficulty;

  const QuizScreen({
    super.key,
    required this.chapterId,
    required this.difficulty,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int currentQuestionIndex = 0;
  int? selectedAnswer;
  bool showAnswer = false;
  int score = 0;
  bool quizCompleted = false;
  List<QuizQuestion> questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _startSession();
  }

  @override
  void dispose() {
    _endSession();
    super.dispose();
  }

  void _startSession() {
    final sessionService = ref.read(sessionTrackingProvider);
    sessionService.startSession(
      topicId: widget.chapterId,
      mode: 'practice',
    );
  }

  void _endSession() {
    final sessionService = ref.read(sessionTrackingProvider);
    sessionService.endSession();
  }

  void _loadQuestions() async {
    try {
      final dataService = ref.read(dataServiceProvider);
      final loadedQuestions = await dataService.getQuizQuestions(
        widget.chapterId,
        difficulty: widget.difficulty,
        limit: 5,
      );
      
      setState(() {
        questions = loadedQuestions;
      });
    } catch (e) {
      // Fallback to generated questions on error
      setState(() {
        questions = _generateQuestions(widget.chapterId, widget.difficulty);
      });
    }
  }

  List<QuizQuestion> _generateQuestions(String topicId, String difficulty) {
    if (topicId == 'quadratic-equations') {
      return [
        QuizQuestion(
          id: 'qe_1',
          question: 'What is the quadratic formula?',
          options: [
            'x = (-b ± √(b² - 4ac)) / 2a',
            'x = (-b ± √(b² + 4ac)) / 2a',
            'x = (b ± √(b² - 4ac)) / 2a',
            'x = (-b ± √(b² - 4ac)) / a',
          ],
          correctAnswer: 0,
          explanation: 'The quadratic formula is x = (-b ± √(b² - 4ac)) / 2a, used to find the roots of ax² + bx + c = 0.',
          difficulty: difficulty,
          topicId: topicId,
          tags: ['formula', 'roots'],
        ),
        QuizQuestion(
          id: 'qe_2',
          question: 'For the equation x² - 5x + 6 = 0, what are the roots?',
          options: ['x = 2, 3', 'x = 1, 6', 'x = -2, -3', 'x = 0, 5'],
          correctAnswer: 0,
          explanation: 'Using factoring: (x-2)(x-3) = 0, so x = 2 or x = 3.',
          difficulty: difficulty,
          topicId: topicId,
          tags: ['factoring', 'solving'],
        ),
        QuizQuestion(
          id: 'qe_3',
          question: 'What is the discriminant of 2x² + 3x + 1 = 0?',
          options: ['1', '2', '3', '4'],
          correctAnswer: 0,
          explanation: 'Discriminant = b² - 4ac = 9 - 8 = 1.',
          difficulty: difficulty,
          topicId: topicId,
          tags: ['discriminant'],
        ),
      ];
    }
    
    // Default questions for other topics
    return [
      QuizQuestion(
        id: 'default_1',
        question: 'Sample question for ${topicId.replaceAll('-', ' ')}?',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctAnswer: 0,
        explanation: 'This is a sample explanation.',
        difficulty: difficulty,
        topicId: topicId,
        tags: ['general'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (quizCompleted) {
      return _buildResultScreen(theme);
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}/${questions.length}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: theme.colorScheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        question.question,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Options
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildOptionCard(
                              option: question.options[index],
                              index: index,
                              isSelected: selectedAnswer == index,
                              isCorrect: showAnswer && index == question.correctAnswer,
                              isWrong: showAnswer && selectedAnswer == index && index != question.correctAnswer,
                              theme: theme,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Explanation (shown after answer)
                    if (showAnswer) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explanation:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.explanation,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _getButtonAction(),
                        child: Text(_getButtonText()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String option,
    required int index,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required ThemeData theme,
  }) {
    Color? backgroundColor;
    Color? borderColor;
    
    if (showAnswer) {
      if (isCorrect) {
        backgroundColor = theme.colorScheme.tertiary.withOpacity(0.1);
        borderColor = theme.colorScheme.tertiary;
      } else if (isWrong) {
        backgroundColor = theme.colorScheme.error.withOpacity(0.1);
        borderColor = theme.colorScheme.error;
      }
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
      borderColor = theme.colorScheme.primary;
    }

    return GestureDetector(
      onTap: showAnswer ? null : () => _selectAnswer(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? theme.colorScheme.outline.withOpacity(0.3),
            width: borderColor != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected || isCorrect || isWrong
                    ? (isCorrect ? theme.colorScheme.tertiary : 
                       isWrong ? theme.colorScheme.error : theme.colorScheme.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: theme.colorScheme.outline,
                ),
              ),
              child: (isSelected || isCorrect || isWrong)
                  ? Icon(
                      isCorrect ? Icons.check : 
                      isWrong ? Icons.close : Icons.circle,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(ThemeData theme) {
    final percentage = (score / questions.length * 100).round();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Score Circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                _getResultMessage(percentage),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You scored $score out of ${questions.length} questions correctly!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _retakeQuiz(),
                      child: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back to Practice'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getResultMessage(int percentage) {
    if (percentage >= 90) return 'Excellent! 🎉';
    if (percentage >= 80) return 'Great Job! 👏';
    if (percentage >= 70) return 'Good Work! 👍';
    if (percentage >= 60) return 'Not Bad! 😊';
    return 'Keep Practicing! 💪';
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswer = index;
    });
  }

  VoidCallback? _getButtonAction() {
    if (!showAnswer && selectedAnswer != null) {
      return _checkAnswer;
    } else if (showAnswer && currentQuestionIndex < questions.length - 1) {
      return _nextQuestion;
    } else if (showAnswer && currentQuestionIndex == questions.length - 1) {
      return _finishQuiz;
    }
    return null;
  }

  String _getButtonText() {
    if (!showAnswer) {
      return selectedAnswer != null ? 'Check Answer' : 'Select an option';
    } else if (currentQuestionIndex < questions.length - 1) {
      return 'Next Question';
    } else {
      return 'Finish Quiz';
    }
  }

  void _checkAnswer() {
    setState(() {
      showAnswer = true;
      final isCorrect = selectedAnswer == questions[currentQuestionIndex].correctAnswer;
      if (isCorrect) {
        score++;
      }
      
      // Track answer in session
      final sessionService = ref.read(sessionTrackingProvider);
      sessionService.recordQuizAnswer(isCorrect: isCorrect);
    });
  }

  void _nextQuestion() {
    setState(() {
      currentQuestionIndex++;
      selectedAnswer = null;
      showAnswer = false;
    });
  }

  void _finishQuiz() {
    setState(() {
      quizCompleted = true;
    });
    
    // Save quiz performance to Firebase
    _saveQuizPerformance();
  }

  Future<void> _saveQuizPerformance() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        final dataService = ref.read(dataServiceProvider);
        await dataService.updateQuizPerformance(
          userId: user.id,
          topicId: widget.chapterId,
          subjectId: 'mathematics', // Default for now
          questionsAttempted: questions.length,
          questionsCorrect: score,
          timeSpentMinutes: 10, // Approximate time
        );
      }
    } catch (e) {
      // Log error but don't break the flow
      debugPrint('Failed to save quiz performance: $e');
    }
  }

  void _retakeQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      selectedAnswer = null;
      showAnswer = false;
      score = 0;
      quizCompleted = false;
    });
  }
}
