import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Compact section heading used inside reference-driven pages and cards.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.icon,
    this.trailing,
    this.accentColor,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.navy;

    return Row(
      children: [
        if (icon != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(icon, color: color, size: 19),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.navy,
              fontSize: 14,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
