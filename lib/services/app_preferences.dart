import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing persistent application preferences.
///
/// Handles storage and retrieval of user preferences including:
/// - Custom database path
/// - Other app configuration settings
class AppPreferences {
  static const String _keyCustomDbPath = 'custom_db_path';
  static const String _keyViewMode = 'view_mode';

  /// Gets the custom database path if set by the user.
  ///
  /// Returns null if no custom path has been set.
  static Future<String?> getCustomDatabasePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomDbPath);
  }

  /// Sets a custom database path.
  ///
  /// The app will need to restart for this change to take effect.
  /// Pass null to reset to the default path.
  static Future<void> setCustomDatabasePath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_keyCustomDbPath);
    } else {
      await prefs.setString(_keyCustomDbPath, path);
    }
  }

  /// Clears the custom database path, reverting to default.
  static Future<void> clearCustomDatabasePath() async {
    await setCustomDatabasePath(null);
  }

  /// Checks if a custom database path is currently set.
  static Future<bool> hasCustomDatabasePath() async {
    final path = await getCustomDatabasePath();
    return path != null && path.isNotEmpty;
  }

  /// Gets the preferred view mode (grid or list).
  ///
  /// Returns 'grid' or 'list'. Defaults to 'list' if not set.
  static Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyViewMode) ?? 'list';
  }

  /// Sets the preferred view mode.
  ///
  /// [mode] should be either 'grid' or 'list'.
  static Future<void> setViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyViewMode, mode);
  }
}
