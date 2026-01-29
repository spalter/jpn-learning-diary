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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for syncing database files with cloud storage on Android.
///
/// This service implements a manual sync pattern using the Storage Access Framework
/// (SAF) to bridge the gap between Android's content URIs and SQLite's file
/// requirement. It manages the lifecycle of the database file by copying it from
/// the cloud provider on launch, working with a local copy, and pushing changes
/// back to the cloud when the app is paused or closed.
class CloudSyncService {
  /// SharedPreferences key for storing the cloud file URI
  static const String _keyCloudUri = 'cloud_database_uri';

  /// SharedPreferences key for storing the cloud file display name
  static const String _keyCloudDisplayName = 'cloud_database_display_name';

  /// MethodChannel for communicating with native Android code
  static const MethodChannel _channel = MethodChannel(
    'com.jpn_learning_diary/cloud_sync',
  );

  /// Local filename for the synced database
  static const String _localSyncedDbName = 'synced_diary.db';

  /// Saves a cloud storage URI for persistent access.
  ///
  /// After user selects a file via SAF picker, call this to:
  /// 1. Take persistent URI permission (survives app restarts)
  /// 2. Store the URI in preferences
  ///
  /// **Parameters:**
  /// - [uri]: The content:// URI from the SAF picker
  /// - [displayName]: Human-readable name to show in settings
  ///
  /// **Returns:** `true` if successful, `false` otherwise
  static Future<bool> saveCloudUri(String uri, String displayName) async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      // Take persistent permission for this URI
      final success = await _channel.invokeMethod<bool>(
        'takePersistentPermission',
        {'uri': uri},
      );

      if (success == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyCloudUri, uri);
        await prefs.setString(_keyCloudDisplayName, displayName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving cloud URI: $e');
      return false;
    }
  }

  /// Gets the saved cloud URI, if any.
  static Future<String?> getCloudUri() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCloudUri);
  }

  /// Gets the display name of the cloud file.
  static Future<String?> getCloudDisplayName() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCloudDisplayName);
  }

  /// Clears the saved cloud URI and removes persistent permission.
  static Future<void> clearCloudUri() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = prefs.getString(_keyCloudUri);

      if (uri != null) {
        await _channel.invokeMethod('releasePersistentPermission', {
          'uri': uri,
        });
      }

      await prefs.remove(_keyCloudUri);
      await prefs.remove(_keyCloudDisplayName);
    } catch (e) {
      debugPrint('Error clearing cloud URI: $e');
    }
  }

  /// Returns the local path where the synced database is stored.
  static Future<String> getLocalSyncedDbPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, _localSyncedDbName);
  }

  /// Syncs the database file from cloud storage to local.
  ///
  /// Downloads the file from the cloud URI to the local working directory.
  /// Call this on app startup before opening the database.
  ///
  /// **Returns:**
  /// - The local file path if sync was successful
  /// - `null` if no cloud URI is configured or sync failed
  static Future<String?> syncFromCloud() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = prefs.getString(_keyCloudUri);

      if (uri == null || uri.isEmpty) {
        return null;
      }

      final localPath = await getLocalSyncedDbPath();

      final success = await _channel.invokeMethod<bool>('copyFromUri', {
        'uri': uri,
        'destinationPath': localPath,
      });

      if (success == true) {
        return localPath;
      }

      return null;
    } catch (e) {
      debugPrint('Error syncing from cloud: $e');
      return null;
    }
  }

  /// Syncs the local database file back to cloud storage.
  ///
  /// Uploads the local working copy back to the cloud URI.
  /// Call this when the app goes to background or closes.
  ///
  /// **Returns:** `true` if sync was successful, `false` otherwise
  static Future<bool> syncToCloud() async {
    if (!Platform.isAndroid) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = prefs.getString(_keyCloudUri);

      if (uri == null || uri.isEmpty) {
        return false;
      }

      final localPath = await getLocalSyncedDbPath();
      final localFile = File(localPath);

      if (!await localFile.exists()) {
        debugPrint('Cloud sync: Local file does not exist, nothing to sync');
        return false;
      }

      final success = await _channel.invokeMethod<bool>('copyToUri', {
        'uri': uri,
        'sourcePath': localPath,
      });

      if (success == true) {
        debugPrint('Cloud sync: Uploaded database to cloud');
        return true;
      }

      debugPrint('Cloud sync: Failed to upload to cloud');
      return false;
    } catch (e) {
      debugPrint('Error syncing to cloud: $e');
      return false;
    }
  }

  /// Checks if cloud sync is configured and available.
  static Future<bool> isCloudSyncEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final uri = await getCloudUri();
    return uri != null && uri.isNotEmpty;
  }

  /// Opens the SAF file picker to select a database file.
  ///
  /// **Returns:** A map with 'uri' and 'displayName' if selected, null if cancelled
  static Future<Map<String, String>?> pickCloudFile() async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'openFilePicker',
        {
          'mimeTypes': ['application/octet-stream', 'application/x-sqlite3'],
        },
      );

      if (result != null) {
        return {
          'uri': result['uri'] as String,
          'displayName': result['displayName'] as String? ?? 'database.db',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error opening file picker: $e');
      return null;
    }
  }
}
