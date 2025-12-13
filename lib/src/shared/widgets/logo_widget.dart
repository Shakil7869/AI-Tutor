import 'package:flutter/material.dart';

/// Logo widget for the app
class LogoWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LogoWidget({
    super.key,
    this.size = 60,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = color ?? theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            logoColor,
            logoColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: logoColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.psychology_alt,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
