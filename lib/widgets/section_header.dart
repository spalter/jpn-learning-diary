import 'package:flutter/material.dart';

/// A reusable section header widget with optional icon.
///
/// Provides consistent retro-styled section titles across the application.
/// Features sharp edges, decorative lines, and monospace typography.
class SectionHeader extends StatelessWidget {
  /// The title text to display.
  final String title;

  /// Optional icon to display before the title.
  final IconData? icon;

  /// Optional bottom padding. Defaults to 16.
  final double bottomPadding;

  /// Optional trailing widget.
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.bottomPadding = 16,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          // Left decorator
          Container(
            width: 4,
            height: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          // Extending line
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
