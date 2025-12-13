import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Practice mode screen
class PracticeModeScreen extends ConsumerWidget {
  final String chapterId;
  final String subjectId;
  final int classLevel;
  final String chapterName;

  const PracticeModeScreen({
    super.key,
    required this.chapterId,
    required this.subjectId,
    required this.classLevel,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice: $chapterName'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Practice Mode',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Quiz Modes
              _buildPracticeCard(
                context: context,
                title: 'Quick Quiz',
                description: '5 questions to test your understanding',
                icon: Icons.flash_on,
                color: theme.colorScheme.primary,
                difficulty: 'easy',
                onTap: () => context.push('/quiz/$chapterId?difficulty=easy'),
              ),
              
              const SizedBox(height: 16),
              
              _buildPracticeCard(
                context: context,
                title: 'Standard Practice',
                description: '10 questions with mixed difficulty',
                icon: Icons.quiz,
                color: theme.colorScheme.secondary,
                difficulty: 'medium',
                onTap: () => context.push('/quiz/$chapterId?difficulty=medium'),
              ),
              
              const SizedBox(height: 16),
              
              _buildPracticeCard(
                context: context,
                title: 'Challenge Mode',
                description: '15 advanced questions for experts',
                icon: Icons.emoji_events,
                color: theme.colorScheme.tertiary,
                difficulty: 'hard',
                onTap: () => context.push('/quiz/$chapterId?difficulty=hard'),
              ),
              
              const Spacer(),
              
              // Study Tips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Study Tips',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Start with Quick Quiz to warm up'),
                    const Text('• Review concepts in Learn Mode if needed'),
                    const Text('• Challenge yourself with harder questions'),
                    const Text('• Track your progress in the dashboard'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String difficulty,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          difficulty.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
