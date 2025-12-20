import 'package:flutter/material.dart';

/// A reusable section header widget with optional icon.
///
/// Provides consistent styling for section titles across the application.
/// Can be used with or without a leading icon.
class SectionHeader extends StatelessWidget {
  /// The title text to display.
  final String title;

  /// Optional icon to display before the title.
  final IconData? icon;

  /// Optional bottom padding. Defaults to 16.
  final double bottomPadding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
