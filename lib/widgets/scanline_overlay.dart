/// Scanline overlay widget that simulates CRT monitor effects.
///
/// This widget provides visual effects commonly associated with
/// old CRT monitors including:
/// - Horizontal scanlines
/// - Vignette (darkening at edges)
/// - Optional flicker effect
/// - Phosphor glow effect
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:jpn_learning_diary/theme/retro_theme.dart';

/// A widget that overlays CRT-style visual effects on its child.
class ScanlineOverlay extends StatefulWidget {
  /// The child widget to display under the scanline effect.
  final Widget child;

  /// Configuration for the visual effects.
  final RetroEffectsConfig config;

  /// The color scheme for tinting effects.
  final RetroColorScheme colorScheme;

  const ScanlineOverlay({
    super.key,
    required this.child,
    this.config = const RetroEffectsConfig(),
    this.colorScheme = RetroColorScheme.phosphorGreen,
  });

  @override
  State<ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<ScanlineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _flickerAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );

    if (widget.config.flickerEnabled) {
      _startFlicker();
    }
  }

  void _startFlicker() {
    Future.doWhile(() async {
      if (!mounted || !widget.config.flickerEnabled) return false;
      
      // Random delay between flickers (1-5 seconds)
      await Future.delayed(
        Duration(milliseconds: 1000 + math.Random().nextInt(4000)),
      );
      
      if (!mounted) return false;
      
      await _flickerController.forward();
      await _flickerController.reverse();
      
      return mounted && widget.config.flickerEnabled;
    });
  }

  @override
  void didUpdateWidget(ScanlineOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.flickerEnabled && !oldWidget.config.flickerEnabled) {
      _startFlicker();
    }
  }

  @override
  void dispose() {
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = RetroTheme.getPalette(widget.colorScheme);
    Widget result = widget.child;

    // Apply flicker effect if enabled
    if (widget.config.flickerEnabled) {
      result = AnimatedBuilder(
        animation: _flickerAnimation,
        builder: (context, child) {
          return Opacity(opacity: _flickerAnimation.value, child: child);
        },
        child: result,
      );
    }

    // Stack effects on top
    return Stack(
      children: [
        result,
        // Glow effect - subtle phosphor color tint overlay
        if (widget.config.glowEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlowPainter(
                  color: palette.glow,
                ),
              ),
            ),
          ),
        if (widget.config.scanlinesEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinePainter(
                  opacity: widget.config.scanlineOpacity,
                  spacing: widget.config.scanlineSpacing,
                ),
              ),
            ),
          ),
        if (widget.config.vignetteEnabled)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _VignettePainter(
                  color: palette.background,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for drawing horizontal scanlines.
class _ScanlinePainter extends CustomPainter {
  final double opacity;
  final double spacing;

  _ScanlinePainter({
    required this.opacity,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw horizontal lines across the entire canvas
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.spacing != spacing;
  }
}

/// Custom painter for drawing a vignette (edge darkening) effect.
class _VignettePainter extends CustomPainter {
  final Color color;

  _VignettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.sqrt(
      math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2),
    );

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.transparent,
        color.withOpacity(0.3),
        color.withOpacity(0.6),
      ],
      stops: const [0.0, 0.5, 0.8, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_VignettePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Custom painter for phosphor glow effect.
/// Creates a subtle radial glow from the center of the screen.
class _GlowPainter extends CustomPainter {
  final Color color;

  _GlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.sqrt(
      math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2),
    );

    // Radial gradient that's brighter in the center, fading out
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        color.withOpacity(0.06),
        color.withOpacity(0.03),
        color.withOpacity(0.01),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// A widget that adds a subtle glow effect to its child.
///
/// Useful for making text and UI elements appear to emit light
/// like phosphors on a CRT display.
class RetroGlow extends StatelessWidget {
  final Widget child;
  final Color? glowColor;
  final double blurRadius;
  final bool enabled;

  const RetroGlow({
    super.key,
    required this.child,
    this.glowColor,
    this.blurRadius = 4.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final color = glowColor ?? Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        // Glow layer (blurred duplicate)
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ColorFilter.mode(
              color.withOpacity(0.5),
              BlendMode.srcATop,
            ),
            child: ImageFiltered(
              imageFilter: ColorFilter.mode(
                color.withOpacity(0.3),
                BlendMode.srcATop,
              ),
              child: child,
            ),
          ),
        ),
        // Original widget on top
        child,
      ],
    );
  }
}

/// Animated text widget that types out characters one by one.
/// 
/// Creates a classic terminal typing effect.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration characterDelay;
  final VoidCallback? onComplete;
  final bool showCursor;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.characterDelay = const Duration(milliseconds: 50),
    this.onComplete,
    this.showCursor = true,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();
    _typeText();
    if (widget.showCursor) {
      _blinkCursor();
    }
  }

  Future<void> _typeText() async {
    for (int i = 0; i <= widget.text.length; i++) {
      if (!mounted) return;
      await Future.delayed(widget.characterDelay);
      if (!mounted) return;
      setState(() {
        _displayedText = widget.text.substring(0, i);
      });
    }
    widget.onComplete?.call();
  }

  Future<void> _blinkCursor() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 530));
      if (!mounted) return;
      setState(() {
        _showCursor = !_showCursor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursor = widget.showCursor && _showCursor ? '█' : ' ';
    return Text(
      '$_displayedText$cursor',
      style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// A blinking cursor widget for input fields.
class BlinkingCursor extends StatefulWidget {
  final Color? color;
  final double width;
  final double height;

  const BlinkingCursor({
    super.key,
    this.color,
    this.width = 8,
    this.height = 16,
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: widget.width,
            height: widget.height,
            color: color,
          ),
        );
      },
    );
  }
}
