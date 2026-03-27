// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io' show Platform, exit;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jpn_learning_diary/widgets/styled_tooltip.dart';
import 'package:jpn_learning_diary/widgets/drag_to_move_area.dart';
import 'package:jpn_learning_diary/widgets/global_search_dialog.dart';
import 'package:jpn_learning_diary/screens/search_results_page.dart';

/// Custom app bar designed for learning mode pages like practice and study.
///
/// This widget provides a consistent navigation experience across all learning
/// screens that are pushed onto the navigation stack. It features a back button,
/// a centered title, and window control buttons on desktop platforms. The
/// entire bar acts as a drag handle for the window.
///
/// * [title]: The text to display in the center of the app bar.
/// * [onBack]: Optional callback for the back button (defaults to popping the route).
class LearningModeAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// The title to display in the app bar.
  final String title;

  /// Called when the back button is pressed.
  ///
  /// If not provided, the default behavior is to pop the current route from
  /// the navigation stack using Navigator.pop().
  final VoidCallback? onBack;

  /// Optional action widgets displayed before the window controls.
  final List<Widget>? actions;

  /// Creates a learning mode app bar.
  ///
  /// The [title] parameter is required and will be displayed in the center.
  const LearningModeAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
  });

  /// Returns the standard toolbar height as the preferred size for this app bar.
  @override
  Size get preferredSize => const Size.fromHeight(46);

  /// Whether the app is running on a mobile platform without window controls.
  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  /// Builds the app bar with a draggable area containing the navigation elements.
  ///
  /// The layout uses a Row with spacers to keep the title centered while
  /// accommodating the back button on the left and window controls on the right.
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: DragOnlyMoveArea(
        child: Row(
          children: [
            // Left spacing to align with navigation bar
            const SizedBox(width: 8),

            // Back button
            _buildBackButton(context),

            // Title — centered within the available space, truncates if too long
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),

            // Search button
            ExcludeFocus(
              child: StyledTooltip(
                message: 'Search',
                child: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showGlobalSearch(context),
                ),
              ),
            ),

            // Custom action buttons
            if (actions != null) ...actions!,

            // Window control buttons
            ..._buildWindowControls(context),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// Builds the back button with a tooltip that triggers navigation.
  ///
  /// Uses ExcludeFocus to prevent the button from being focused during
  /// keyboard navigation, keeping focus on the learning content.
  Widget _buildBackButton(BuildContext context) {
    return ExcludeFocus(
      child: StyledTooltip(
        message: 'Back',
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Shows the global search dialog.
  Future<void> _showGlobalSearch(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.surface.withAlpha(200),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: const GlobalSearchDialog(),
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(searchQuery: result),
        ),
      );
    }
  }

  /// Builds the minimize, maximize, and close buttons for desktop platforms.
  ///
  /// Returns an empty list on mobile platforms where window controls are not
  /// applicable. The maximize button toggles between maximized and restored
  /// window states.
  List<Widget> _buildWindowControls(BuildContext context) {
    if (_isMobile) {
      return [];
    }
    return [
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Minimize',
          child: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () async {
              await windowManager.minimize();
            },
          ),
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Maximize or hold for Fullscreen',
          child: GestureDetector(
            onLongPress: () async {
              final isFullScreen = await windowManager.isFullScreen();
              await windowManager.setFullScreen(!isFullScreen);
            },
            child: IconButton(
              icon: const Icon(Icons.crop_square),
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
        ),
      ),
      ExcludeFocus(
        child: StyledTooltip(
          message: 'Close',
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                windowManager.close();
              } else {
                exit(0);
              }
            },
          ),
        ),
      ),
    ];
  }
}
