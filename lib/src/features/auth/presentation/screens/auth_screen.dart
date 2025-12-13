import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/logo_widget.dart';

/// Authentication landing screen
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo and App Name
              const LogoWidget(size: 120),
              const SizedBox(height: 24),
              
              Text(
                AppConfig.appName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Learn Math with AI-powered personalized tutoring',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Features List
              _buildFeaturesList(context),
              
              const Spacer(flex: 2),
              
              // Auth Buttons
              Column(
                children: [
                  CustomButton(
                    text: 'Get Started',
                    onPressed: () => context.push('/signup'),
                    variant: ButtonVariant.primary,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomButton(
                    text: 'Already have an account? Sign In',
                    onPressed: () => context.push('/login'),
                    variant: ButtonVariant.text,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      {
        'icon': Icons.psychology,
        'title': 'AI Tutor',
        'description': 'Get personalized explanations',
      },
      {
        'icon': Icons.quiz,
        'title': 'Practice Mode',
        'description': 'Test your knowledge with quizzes',
      },
      {
        'icon': Icons.school,
        'title': 'Exam Relevance',
        'description': 'Know what\'s important for exams',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Progress Tracking',
        'description': 'Track your learning journey',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
