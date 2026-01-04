/// Retro-styled UI components for the Japanese Learning Diary.
///
/// Provides sharp-edged, monochrome styled widgets that match
/// the old-school CRT terminal aesthetic.
library;

import 'package:flutter/material.dart';

/// A retro-styled card with sharp edges and optional border animation.
class RetroCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool selected;
  final bool showGlow;
  final double borderWidth;

  const RetroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.onTap,
    this.selected = false,
    this.showGlow = false,
    this.borderWidth = 1,
  });

  @override
  State<RetroCard> createState() => _RetroCardState();
}

class _RetroCardState extends State<RetroCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = widget.selected || _isHovered
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: borderColor,
          width: widget.selected ? widget.borderWidth + 1 : widget.borderWidth,
        ),
        boxShadow: widget.showGlow && (widget.selected || _isHovered)
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.zero,
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      card = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A retro-styled button with sharp edges.
class RetroButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const RetroButton({
    super.key,
    required this.child,
    this.onPressed,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.width,
    this.height,
  });

  /// Creates a retro button with text label.
  factory RetroButton.text({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool selected = false,
  }) {
    return RetroButton(
      key: key,
      onPressed: onPressed,
      selected: selected,
      child: Text(text),
    );
  }

  /// Creates a retro button with an icon.
  factory RetroButton.icon({
    Key? key,
    required IconData icon,
    String? tooltip,
    VoidCallback? onPressed,
    bool selected = false,
  }) {
    Widget child = Icon(icon, size: 20);
    if (tooltip != null) {
      child = Tooltip(message: tooltip, child: child);
    }
    return RetroButton(
      key: key,
      onPressed: onPressed,
      selected: selected,
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.selected || _isHovered;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (_isPressed) {
      backgroundColor = theme.colorScheme.primary;
      foregroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.primary;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.15);
      foregroundColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
    } else {
      backgroundColor = theme.colorScheme.surface;
      foregroundColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.outline;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: foregroundColor,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
            child: IconTheme(
              data: IconThemeData(color: foregroundColor),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A retro-styled text field with sharp edges and terminal appearance.
class RetroTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final bool autofocus;

  const RetroTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  State<RetroTextField> createState() => _RetroTextFieldState();
}

class _RetroTextFieldState extends State<RetroTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              color: theme.colorScheme.secondary,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: _isFocused
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            maxLines: widget.maxLines,
            autofocus: widget.autofocus,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
            ),
            cursorColor: theme.colorScheme.primary,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: theme.colorScheme.tertiary,
                fontFamily: 'monospace',
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A retro-styled section header with decorative lines.
class RetroSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const RetroSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // Left decorator
          Container(
            width: 8,
            height: 2,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          // Title
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
          const SizedBox(width: 8),
          // Expanding line
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outline,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A retro-styled divider with terminal appearance.
class RetroDivider extends StatelessWidget {
  final String? label;
  final double thickness;
  final EdgeInsetsGeometry padding;

  const RetroDivider({
    super.key,
    this.label,
    this.thickness = 1,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label == null) {
      return Padding(
        padding: padding,
        child: Container(
          height: thickness,
          color: theme.colorScheme.outline,
        ),
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Container(height: thickness, color: theme.colorScheme.outline),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!,
              style: TextStyle(
                color: theme.colorScheme.tertiary,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Container(height: thickness, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

/// A retro-styled badge/chip.
class RetroBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final bool filled;

  const RetroBadge({
    super.key,
    required this.label,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? badgeColor : Colors.transparent,
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: filled ? theme.colorScheme.surface : badgeColor,
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// A retro-styled progress bar.
class RetroProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final String? label;
  final bool showPercentage;

  const RetroProgressBar({
    super.key,
    required this.value,
    this.height = 16,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                if (showPercentage)
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: Stack(
            children: [
              // Progress fill with block pattern
              FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  color: theme.colorScheme.primary,
                  child: CustomPaint(
                    painter: _BlockPatternPainter(
                      color: theme.colorScheme.surface.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painter for block pattern inside progress bars.
class _BlockPatternPainter extends CustomPainter {
  final Color color;

  _BlockPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const blockWidth = 4.0;
    const gap = 2.0;

    for (double x = 0; x < size.width; x += blockWidth + gap) {
      canvas.drawRect(
        Rect.fromLTWH(x + blockWidth, 0, gap, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BlockPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// A retro-styled stat display widget.
class RetroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const RetroStat({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RetroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
