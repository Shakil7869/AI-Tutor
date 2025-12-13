import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Subject list screen - simplified for chapter PDF system
class SubjectListScreen extends ConsumerWidget {
  final int classLevel;

  const SubjectListScreen({
    super.key,
    required this.classLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // For now, we'll show a simple mathematics subject
    // This can be expanded later to support multiple subjects
    return Scaffold(
      appBar: AppBar(
        title: Text('Class $classLevel Subjects'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Subjects',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Mathematics subject card
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calculate,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('Mathematics'),
                subtitle: Text('Class $classLevel Mathematics'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  context.push('/chapters/mathematics?class=$classLevel');
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Placeholder for future subjects
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.science,
                    color: theme.colorScheme.outline,
                  ),
                ),
                title: Text(
                  'Physics',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                subtitle: Text(
                  'Coming Soon',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                enabled: false,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.biotech,
                    color: theme.colorScheme.outline,
                  ),
                ),
                title: Text(
                  'Chemistry',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                subtitle: Text(
                  'Coming Soon',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                enabled: false,
              ),
            ),
            
            const Spacer(),
            
            // Info message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Currently using the new Chapter PDF system. Individual chapters are now available for direct access.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
