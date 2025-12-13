import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Topic list screen
class TopicListScreen extends ConsumerWidget {
  final String chapterId;
  final String subjectId;
  final int classLevel;

  const TopicListScreen({
    super.key,
    required this.chapterId,
    required this.subjectId,
    required this.classLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Dummy data for topics based on chapter
    final topics = _getTopicsForChapter(chapterId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getChapterName(chapterId)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTopicCard(
                context: context,
                topicId: topic['id']!,
                title: topic['name']!,
                description: topic['description']!,
                examRelevance: topic['examRelevance']!,
                theme: theme,
              ),
            );
          },
        ),
      ),
    );
  }

  String _getChapterName(String chapterId) {
    switch (chapterId) {
      case 'algebra':
        return 'Algebra';
      case 'geometry':
        return 'Geometry';
      case 'trigonometry':
        return 'Trigonometry';
      case 'statistics':
        return 'Statistics';
      default:
        return 'Chapter';
    }
  }

  List<Map<String, String>> _getTopicsForChapter(String chapterId) {
    switch (chapterId) {
      case 'algebra':
        return [
          {
            'id': 'quadratic-equations',
            'name': 'Quadratic Equations',
            'description': 'Solving quadratic equations using different methods',
            'examRelevance': 'JEE Main 2023, Board Exams',
          },
          {
            'id': 'linear-equations',
            'name': 'Linear Equations',
            'description': 'Pair of linear equations in two variables',
            'examRelevance': 'NEET 2022, State Boards',
          },
          {
            'id': 'polynomials',
            'name': 'Polynomials',
            'description': 'Zeros of polynomials and their relationships',
            'examRelevance': 'CBSE Board, ICSE',
          },
        ];
      case 'geometry':
        return [
          {
            'id': 'circles',
            'name': 'Circles',
            'description': 'Properties of circles, tangents, and secants',
            'examRelevance': 'JEE Advanced, Board Exams',
          },
          {
            'id': 'triangles',
            'name': 'Triangles',
            'description': 'Similarity and congruence of triangles',
            'examRelevance': 'NTSE, Olympiad',
          },
        ];
      default:
        return [
          {
            'id': 'sample-topic',
            'name': 'Sample Topic',
            'description': 'This is a sample topic',
            'examRelevance': 'Sample Exam',
          },
        ];
    }
  }

  Widget _buildTopicCard({
    required BuildContext context,
    required String topicId,
    required String title,
    required String description,
    required String examRelevance,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Class $classLevel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          
          // Exam Relevance Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.tertiary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: theme.colorScheme.tertiary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Exam Relevance: $examRelevance',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/learn/$topicId?topicName=$title'),
                  icon: const Icon(Icons.psychology, size: 18),
                  label: const Text('Learn'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/practice/$topicId?topicName=$title'),
                  icon: const Icon(Icons.quiz, size: 18),
                  label: const Text('Practice'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
