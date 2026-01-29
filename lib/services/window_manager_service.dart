// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

/// A service that handles desktop window configuration and management.
///
/// This singleton encapsulates all logic related to the desktop window environment,
/// including initialization of the window manager, setting minimum dimensions,
/// and configuring custom frame styles. It conditionally executes platform-specific
/// code to ensure proper behavior across Windows, Linux, and macOS.
class WindowManagerService {
  WindowManagerService._();

  static final WindowManagerService instance = WindowManagerService._();

  /// Initializes the window manager and sets up the window properties.
  Future<void> initialize() async {
    // Only run on desktop platforms since mobile platforms do not require window management.
    if (Platform.isAndroid || Platform.isIOS) return;

    await Window.initialize();
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(700, 300));
    await windowManager.center();

    // Hide titlebar for custom implementation
    if (Platform.isWindows || Platform.isLinux) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    } else if (Platform.isMacOS) {
      await Window.hideTitle();
      await Window.makeTitlebarTransparent();
      await Window.enableFullSizeContentView();
      await Window.hideWindowControls();
    }
  }
}
