import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/nctb_curriculum.dart';

/// Chapter list screen
class ChapterListScreen extends ConsumerWidget {
  final String subjectId;
  final int classLevel;

  const ChapterListScreen({
    super.key,
    required this.subjectId,
    required this.classLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Get NCTB Mathematics chapters for the specific class
    final chapters = NCTBCurriculum.getChaptersForClass(classLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text('গণিত - ক্লাস $classLevel', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildChapterCard(
                context: context,
                chapterId: chapter['id']!,
                title: chapter['name']!,
                subtitle: chapter['chapterNumber']!,
                description: chapter['description']!,
                englishName: chapter['englishName']!,
                theme: theme,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChapterCard({
    required BuildContext context,
    required String chapterId,
    required String title,
    required String subtitle,
    required String description,
    required String englishName,
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
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and chapter info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calculate_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      englishName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/learn/$chapterId?subjectId=${this.subjectId}&class=${this.classLevel}&chapterName=${Uri.encodeComponent(title)}');
                  },
                  icon: const Icon(Icons.school, size: 20),
                  label: const Text('Learn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/practice/$chapterId?subjectId=${this.subjectId}&class=${this.classLevel}&chapterName=${Uri.encodeComponent(title)}');
                  },
                  icon: const Icon(Icons.quiz, size: 20),
                  label: const Text('Practice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
