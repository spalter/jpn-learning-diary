/// Theme provider for managing retro theme state.
///
/// Handles theme persistence and provides theme data to the widget tree.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jpn_learning_diary/theme/retro_theme.dart';

/// Provider for managing the retro theme configuration.
class RetroThemeProvider extends ChangeNotifier {
  static const String _keyColorScheme = 'retro_color_scheme';
  static const String _keyScanlinesEnabled = 'retro_scanlines_enabled';
  static const String _keyScanlineOpacity = 'retro_scanline_opacity';
  static const String _keyVignetteEnabled = 'retro_vignette_enabled';
  static const String _keyGlowEnabled = 'retro_glow_enabled';
  static const String _keyFlickerEnabled = 'retro_flicker_enabled';

  RetroColorScheme _colorScheme = RetroColorScheme.phosphorGreen;
  RetroEffectsConfig _effectsConfig = const RetroEffectsConfig();
  bool _isLoaded = false;

  /// Current color scheme.
  RetroColorScheme get colorScheme => _colorScheme;

  /// Current effects configuration.
  RetroEffectsConfig get effectsConfig => _effectsConfig;

  /// Whether preferences have been loaded.
  bool get isLoaded => _isLoaded;

  /// Current color palette based on the selected scheme.
  RetroColorPalette get palette => RetroTheme.getPalette(_colorScheme);

  /// Current theme data.
  ThemeData get themeData => RetroTheme.getThemeData(_colorScheme);

  /// Load saved preferences.
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load color scheme
    final schemeIndex = prefs.getInt(_keyColorScheme) ?? 0;
    if (schemeIndex >= 0 && schemeIndex < RetroColorScheme.values.length) {
      _colorScheme = RetroColorScheme.values[schemeIndex];
    }

    // Load effects config
    _effectsConfig = RetroEffectsConfig(
      scanlinesEnabled: prefs.getBool(_keyScanlinesEnabled) ?? true,
      scanlineOpacity: prefs.getDouble(_keyScanlineOpacity) ?? 0.08,
      vignetteEnabled: prefs.getBool(_keyVignetteEnabled) ?? true,
      glowEnabled: prefs.getBool(_keyGlowEnabled) ?? true,
      flickerEnabled: prefs.getBool(_keyFlickerEnabled) ?? false,
    );

    _isLoaded = true;
    notifyListeners();
  }

  /// Set the color scheme.
  Future<void> setColorScheme(RetroColorScheme scheme) async {
    if (_colorScheme == scheme) return;

    _colorScheme = scheme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorScheme, scheme.index);
  }

  /// Set whether scanlines are enabled.
  Future<void> setScanlinesEnabled(bool enabled) async {
    _effectsConfig = _effectsConfig.copyWith(scanlinesEnabled: enabled);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyScanlinesEnabled, enabled);
  }

  /// Set scanline opacity.
  Future<void> setScanlineOpacity(double opacity) async {
    _effectsConfig = _effectsConfig.copyWith(scanlineOpacity: opacity);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyScanlineOpacity, opacity);
  }

  /// Set whether vignette is enabled.
  Future<void> setVignetteEnabled(bool enabled) async {
    _effectsConfig = _effectsConfig.copyWith(vignetteEnabled: enabled);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVignetteEnabled, enabled);
  }

  /// Set whether glow effect is enabled.
  Future<void> setGlowEnabled(bool enabled) async {
    _effectsConfig = _effectsConfig.copyWith(glowEnabled: enabled);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGlowEnabled, enabled);
  }

  /// Set whether flicker effect is enabled.
  Future<void> setFlickerEnabled(bool enabled) async {
    _effectsConfig = _effectsConfig.copyWith(flickerEnabled: enabled);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFlickerEnabled, enabled);
  }

  /// Update multiple effects at once.
  Future<void> setEffectsConfig(RetroEffectsConfig config) async {
    _effectsConfig = config;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyScanlinesEnabled, config.scanlinesEnabled);
    await prefs.setDouble(_keyScanlineOpacity, config.scanlineOpacity);
    await prefs.setBool(_keyVignetteEnabled, config.vignetteEnabled);
    await prefs.setBool(_keyGlowEnabled, config.glowEnabled);
    await prefs.setBool(_keyFlickerEnabled, config.flickerEnabled);
  }

  /// Cycle to the next color scheme.
  Future<void> nextColorScheme() async {
    final nextIndex = (_colorScheme.index + 1) % RetroColorScheme.values.length;
    await setColorScheme(RetroColorScheme.values[nextIndex]);
  }

  /// Reset to default settings.
  Future<void> resetToDefaults() async {
    await setColorScheme(RetroColorScheme.phosphorGreen);
    await setEffectsConfig(const RetroEffectsConfig());
  }
}

/// Extension to access theme provider from context.
extension RetroThemeContextExtension on BuildContext {
  /// Get the retro theme provider.
  RetroThemeProvider get retroTheme {
    return RetroThemeProvider();
  }
}
