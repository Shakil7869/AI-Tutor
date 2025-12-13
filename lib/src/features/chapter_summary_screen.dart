import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/services/ai_service.dart';
import '../shared/services/rag_service.dart';

class ChapterSummaryScreen extends ConsumerStatefulWidget {
  final String classLevel;
  final String subject;
  final String chapter;

  const ChapterSummaryScreen({
    super.key,
    required this.classLevel,
    required this.subject,
    required this.chapter,
  });

  @override
  ConsumerState<ChapterSummaryScreen> createState() => _ChapterSummaryScreenState();
}

class _ChapterSummaryScreenState extends ConsumerState<ChapterSummaryScreen> {
  String? _summary;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final summary = await aiService.generateChapterSummary(
        classLevel: widget.classLevel,
        subject: widget.subject,
        chapter: widget.chapter,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapter} - Summary'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class ${widget.classLevel} ${widget.subject}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.chapter,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _buildContent(),
            ),

            // Action buttons
            if (_summary != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChapterQuizScreen(
                              classLevel: widget.classLevel,
                              subject: widget.subject,
                              chapter: widget.chapter,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Take Quiz'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateSummary,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating chapter summary...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error generating summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateSummary,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_summary != null) {
      return SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chapter Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _summary!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class ChapterQuizScreen extends ConsumerStatefulWidget {
  final String classLevel;
  final String subject;
  final String chapter;

  const ChapterQuizScreen({
    super.key,
    required this.classLevel,
    required this.subject,
    required this.chapter,
  });

  @override
  ConsumerState<ChapterQuizScreen> createState() => _ChapterQuizScreenState();
}

class _ChapterQuizScreenState extends ConsumerState<ChapterQuizScreen> {
  ChapterQuiz? _quiz;
  bool _isLoading = false;
  String? _error;
  
  // Quiz state
  List<String?> _mcqAnswers = [];
  List<String> _shortAnswers = [];
  bool _showingMCQs = true;
  bool _quizCompleted = false;
  int _mcqScore = 0;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final quiz = await aiService.generateChapterQuiz(
        classLevel: widget.classLevel,
        subject: widget.subject,
        chapter: widget.chapter,
      );

      setState(() {
        _quiz = quiz;
        _mcqAnswers = List.filled(quiz.mcqs.length, null);
        _shortAnswers = List.filled(quiz.shortQuestions.length, '');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _submitQuiz() {
    if (_quiz == null) return;

    // Calculate MCQ score
    _mcqScore = 0;
    for (int i = 0; i < _quiz!.mcqs.length; i++) {
      if (_mcqAnswers[i] == _quiz!.mcqs[i].correctAnswer) {
        _mcqScore++;
      }
    }

    setState(() {
      _quizCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chapter} - Quiz'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating quiz...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error generating quiz', 
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateQuiz,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_quiz == null) return const SizedBox.shrink();

    if (_quizCompleted) {
      return _buildQuizResults();
    }

    return Column(
      children: [
        // Quiz navigation
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showingMCQs = true),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _showingMCQs ? Theme.of(context).primaryColor : null,
                    foregroundColor: _showingMCQs ? Colors.white : null,
                  ),
                  child: Text('MCQs (${_quiz!.mcqs.length})'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showingMCQs = false),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: !_showingMCQs ? Theme.of(context).primaryColor : null,
                    foregroundColor: !_showingMCQs ? Colors.white : null,
                  ),
                  child: Text('Short Q (${_quiz!.shortQuestions.length})'),
                ),
              ),
            ],
          ),
        ),

        // Quiz content
        Expanded(
          child: _showingMCQs ? _buildMCQSection() : _buildShortSection(),
        ),

        // Submit button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitQuiz,
              child: const Text('Submit Quiz'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMCQSection() {
    if (_quiz!.mcqs.isEmpty) {
      return const Center(child: Text('No MCQs available'));
    }

    return PageView.builder(
      itemCount: _quiz!.mcqs.length,
      itemBuilder: (context, index) {
        final mcq = _quiz!.mcqs[index];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${index + 1} of ${_quiz!.mcqs.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                mcq.question,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              ...mcq.options.map((option) {
                final optionLetter = option.substring(0, 1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    title: Text(option),
                    value: optionLetter,
                    groupValue: _mcqAnswers[index],
                    onChanged: (value) {
                      setState(() {
                        _mcqAnswers[index] = value;
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortSection() {
    if (_quiz!.shortQuestions.isEmpty) {
      return const Center(child: Text('No short questions available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quiz!.shortQuestions.length,
      itemBuilder: (context, index) {
        final question = _quiz!.shortQuestions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write your answer here...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _shortAnswers[index] = value;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizResults() {
    final mcqPercentage = _quiz!.mcqs.isNotEmpty 
        ? (_mcqScore / _quiz!.mcqs.length * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Quiz Completed!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MCQ Score: $_mcqScore/${_quiz!.mcqs.length} ($mcqPercentage%)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Show MCQ answers with explanations
          if (_quiz!.mcqs.isNotEmpty) ...[
            Text(
              'MCQ Answers & Explanations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _quiz!.mcqs.length,
                itemBuilder: (context, index) {
                  final mcq = _quiz!.mcqs[index];
                  final userAnswer = _mcqAnswers[index];
                  final isCorrect = userAnswer == mcq.correctAnswer;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Q${index + 1}: ${mcq.question}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Your answer: ${userAnswer ?? 'Not answered'}',
                                style: TextStyle(
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          Text('Correct answer: ${mcq.correctAnswer}'),
                          const SizedBox(height: 8),
                          Text(
                            mcq.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Chapter'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _quizCompleted = false;
                      _mcqAnswers = List.filled(_quiz!.mcqs.length, null);
                      _shortAnswers = List.filled(_quiz!.shortQuestions.length, '');
                      _mcqScore = 0;
                    });
                  },
                  child: const Text('Retake Quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
