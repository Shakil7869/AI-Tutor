import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/logo_widget.dart';

/// Class selection screen for onboarding
class ClassSelectionScreen extends ConsumerStatefulWidget {
  const ClassSelectionScreen({super.key});

  @override
  ConsumerState<ClassSelectionScreen> createState() => _ClassSelectionScreenState();
}

class _ClassSelectionScreenState extends ConsumerState<ClassSelectionScreen> {
  int? _selectedClass;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Class'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Logo
              const LogoWidget(size: 100),
              const SizedBox(height: 32),
              
              Text(
                'Choose Your Class Level',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'This helps us provide you with the right content and difficulty level for your studies.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Class Options
              ...AppConfig.supportedClasses.map((classLevel) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildClassCard(
                    classLevel: classLevel,
                    isSelected: _selectedClass == classLevel,
                  ),
                );
              }),
              
              const Spacer(),
              
              // Continue Button
              CustomButton(
                text: 'Continue',
                onPressed: _selectedClass != null ? _continueToApp : null,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard({
    required int classLevel,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedClass = classLevel;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$classLevel',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class $classLevel',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getClassDescription(classLevel),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  String _getClassDescription(int classLevel) {
    switch (classLevel) {
      case 9:
        return 'Foundation concepts in Mathematics, preparing for Class 10';
      case 10:
        return 'Board exam preparation with advanced topics and problem solving';
      default:
        return 'Mathematics curriculum for Class $classLevel';
    }
  }

  Future<void> _continueToApp() async {
    if (_selectedClass == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user?.profile != null) {
        final updatedProfile = user!.profile!.copyWith(
          classLevel: _selectedClass!,
        );
        
        final authService = ref.read(authServiceProvider);
        await authService.updateUserProfile(updatedProfile);
      }
      
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
