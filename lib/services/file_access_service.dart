// ============================================================================
//
// Japanese Learning Diary
// Copyright (c) 2025-2026 spalter
//
// This source file is part of the jpn-learning-diary project.
//
// ============================================================================

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing persistent file access on macOS using security-scoped bookmarks.
///
/// ## Background
/// macOS App Sandbox restricts access to files outside the app container.
/// Security-scoped bookmarks allow apps to store persistent access permissions
/// to user-selected files, eliminating the need to re-select files after app restarts.
///
/// ## Platform Support
/// - **macOS**: Uses native security-scoped bookmark APIs
/// - **Other platforms**: Methods are no-ops and return success (not needed)
///
/// ## Usage Flow
/// 1. User selects a file via FilePicker
/// 2. Call [saveBookmark] with the file path to create a bookmark for the parent directory
/// 3. On app restart, call [resolveBookmark] to regain access
/// 4. Call [stopAccessingResource] when done (optional, handled on app termination)
///
/// ## Implementation Notes
/// Communicates with native macOS code via MethodChannel.
/// Bookmark data is stored as base64-encoded string in SharedPreferences.
/// Bookmarks are created for the parent directory to allow SQLite to create temporary files.
///
/// See [AppDelegate.swift] for the native implementation.
class FileAccessService {
  /// SharedPreferences key for storing bookmark data
  static const String _keyBookmarkData = 'file_bookmark_data';
  
  /// MethodChannel for communicating with native macOS code
  static const MethodChannel _channel =
      MethodChannel('com.jpn_learning_diary/file_access');

  /// Creates and saves a security-scoped bookmark for the given file path.
  ///
  /// This grants the app persistent permission to access the file's parent directory
  /// across app restarts, which allows SQLite to create temporary files (WAL, SHM, journal).
  ///
  /// **Parameters:**
  /// - [filePath]: Absolute path to the file (must be selected via FilePicker first)
  ///
  /// **Returns:**
  /// - `true` if bookmark was created and saved successfully (or not needed on non-macOS)
  /// - `false` if bookmark creation failed on macOS
  ///
  /// **Platform Behavior:**
  /// - macOS: Creates bookmark for parent directory and stores it in SharedPreferences
  /// - Other platforms: Always returns `true` (no-op)
  ///
  /// **Important:** The file must first be selected through a file picker dialog
  /// to grant initial access before creating a bookmark.
  static Future<bool> saveBookmark(String filePath) async {
    if (!Platform.isMacOS) {
      return true; // Not needed on other platforms
    }

    try {
      // Get parent directory - this ensures SQLite can create temporary files
      final file = File(filePath);
      final directory = file.parent.path;
      
      final bookmarkData = await _channel.invokeMethod<String>(
        'createBookmark',
        {'path': directory},
      );

      if (bookmarkData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyBookmarkData, bookmarkData);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating bookmark: $e');
      return false;
    }
  }

  /// Resolves a previously saved bookmark and starts accessing the security-scoped resource.
  ///
  /// Call this method on app startup to regain access to a directory that was
  /// previously selected and bookmarked. The bookmark must have been created
  /// using [saveBookmark] in a previous app session.
  ///
  /// **Returns:**
  /// - The resolved absolute directory path if bookmark exists and is valid
  /// - `null` if no bookmark exists, bookmark is invalid, or on non-macOS platforms
  ///
  /// **Platform Behavior:**
  /// - macOS: Resolves bookmark and starts accessing the security-scoped resource
  /// - Other platforms: Always returns `null` (not needed)
  ///
  /// **Important:** Once called successfully, the resource remains accessible until:
  /// - [stopAccessingResource] is called
  /// - The app terminates (cleanup happens automatically)
  ///
  /// **Error Handling:**
  /// Prints debug messages on failure. Returns `null` on any error.
  static Future<String?> resolveBookmark() async {
    if (!Platform.isMacOS) {
      return null; // Not needed on other platforms
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkData = prefs.getString(_keyBookmarkData);

      if (bookmarkData == null) {
        return null;
      }

      final resolvedPath = await _channel.invokeMethod<String>(
        'resolveBookmark',
        {'bookmarkData': bookmarkData},
      );

      return resolvedPath;
    } catch (e) {
      debugPrint('Error resolving bookmark: $e');
      return null;
    }
  }

  /// Stops accessing the security-scoped resource.
  ///
  /// Releases the access permission granted by [resolveBookmark].
  /// This is optional as cleanup happens automatically when the app terminates.
  ///
  /// **Platform Behavior:**
  /// - macOS: Calls native API to stop accessing the resource
  /// - Other platforms: No-op
  ///
  /// **When to call:**
  /// - Manually if you want to release access before app termination
  /// - Usually not necessary as [AppDelegate] handles this on app exit
  static Future<void> stopAccessingResource() async {
    if (!Platform.isMacOS) {
      return;
    }

    try {
      await _channel.invokeMethod('stopAccessing');
    } catch (e) {
      debugPrint('Error stopping access: $e');
    }
  }

  /// Clears the saved bookmark data from SharedPreferences.
  ///
  /// Use this when the user wants to reset database path to default
  /// or if the bookmarked file is no longer valid.
  ///
  /// After calling this, [resolveBookmark] will return `null` until
  /// a new bookmark is created with [saveBookmark].
  static Future<void> clearBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBookmarkData);
  }
}
