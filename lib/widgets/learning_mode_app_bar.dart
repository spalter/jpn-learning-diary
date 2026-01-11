import 'dart:io' show Platform, exit;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom app bar for learning mode pages (practice, study, etc.).
///
/// Provides a consistent navigation bar with:
/// - Back button on the left to return to the previous page
/// - Centered title
/// - Window control buttons (minimize, maximize, close) on the right
/// - Draggable area to move the window
///
/// This widget is designed to be used as the appBar in Scaffold for
/// learning mode pages that are pushed onto the navigation stack.
class LearningModeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The title to display in the app bar.
  final String title;

  /// Optional callback when back button is pressed.
  /// If not provided, defaults to Navigator.pop(context).
  final VoidCallback? onBack;

  /// Creates a learning mode app bar.
  ///
  /// The [title] parameter is required and will be displayed in the center.
  const LearningModeAppBar({super.key, required this.title, this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: DragToMoveArea(
        child: Row(
          children: [
            // Back button
            _buildBackButton(context),

            // Spacer to center the title
            const Spacer(),

            // Title
            Text(title, style: Theme.of(context).textTheme.titleLarge),

            // Spacer to balance the layout
            const Spacer(),

            // Window control buttons
            ..._buildWindowControls(context),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// Builds the back button.
  Widget _buildBackButton(BuildContext context) {
    return ExcludeFocus(
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Builds the window control buttons (minimize, maximize, close).
  List<Widget> _buildWindowControls(BuildContext context) {
    return [
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.remove),
          tooltip: 'Minimize',
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.crop_square),
          tooltip: 'Maximize',
          onPressed: () async {
            final isMaximized = await windowManager.isMaximized();
            if (isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
      ),
      ExcludeFocus(
        child: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () {
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
              windowManager.close();
            } else {
              exit(0);
            }
          },
        ),
      ),
    ];
  }
}
