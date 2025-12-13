import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/config/app_config.dart';

/// Main dashboard screen
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to ${AppConfig.appName}'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => context.push('/progress'),
                child: const Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Progress'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  final authService = ref.read(authServiceProvider);
                  await authService.signOut();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildDashboardContent(context, user, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, dynamic user, ThemeData theme) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, user, theme),
            
            const SizedBox(height: 32),
            
            // Quick Actions
            _buildQuickActions(context, user, theme),
            
            const SizedBox(height: 32),
            
            // Subjects Section
            _buildSubjectsSection(context, user, theme),
            
            const SizedBox(height: 32),
            
            // Recent Activity
            _buildRecentActivity(context, user, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, dynamic user, ThemeData theme) {
    final displayName = user?.displayName ?? 'Student';
    final classLevel = user?.profile?.classLevel ?? 9;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $displayName! 👋',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to learn with your AI tutor today?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatsChip(
                icon: Icons.school,
                label: 'Class $classLevel',
                theme: theme,
              ),
              const SizedBox(width: 12),
              _buildStatsChip(
                icon: Icons.book,
                label: 'গণিত (Mathematics)',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // First row - Main features
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.chat,
                title: 'RAG Chat',
                subtitle: 'Textbook AI Tutor',
                color: theme.colorScheme.primary,
                onTap: () => context.push('/class-selection'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.quiz,
                title: 'Practice',
                subtitle: 'Test yourself',
                color: theme.colorScheme.secondary,
                onTap: () => context.push('/subjects?class=${user?.profile?.classLevel ?? 9}'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Second row - Additional features
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.psychology,
                title: 'AI Tutor',
                subtitle: 'Learn with AI',
                color: Colors.purple,
                onTap: () => context.push('/subjects?class=${user?.profile?.classLevel ?? 9}'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.upload_file,
                title: 'Upload PDF',
                subtitle: 'Admin feature',
                color: Colors.orange,
                onTap: () => context.push('/admin/upload'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsSection(BuildContext context, dynamic user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subjects',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/subjects?class=${user?.profile?.classLevel ?? 9}'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'গণিত - ক্লাস ${user?.profile?.classLevel ?? 9}',
          icon: Icons.calculate,
          onPressed: () => context.push('/chapters/mathematics?class=${user?.profile?.classLevel ?? 9}'),
          variant: ButtonVariant.outline,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, dynamic user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Start Learning!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Begin your journey with AI-powered learning',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
