import 'package:flutter/material.dart';

/// Button variants
enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

/// Custom button widget with consistent styling
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget button;
    
    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonContent(),
        );
        break;
        
      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          child: _buildButtonContent(),
        );
        break;
        
      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonContent(),
        );
        break;
        
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildButtonContent(),
        );
        break;
    }

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
