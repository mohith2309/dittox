import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central settings provider for the Dittox app.
/// Controls dark mode, potato mode (performance), UI sounds, and animation speed.
class AppSettings extends ChangeNotifier {
  static const String _darkModeKey = 'dittox_dark_mode_enabled';
  static const String _potatoModeKey = 'dittox_potato_mode_v1';
  static const String _uiSoundsKey = 'dittox_ui_sounds_v1';
  static const String _reduceAnimKey = 'dittox_reduce_animations_v1';

  bool _isDarkMode = false;
  bool _potatoMode = false;
  bool _uiSounds = true;
  bool _reduceAnimations = false;
  bool _loaded = false;

  bool get isDarkMode => _isDarkMode;

  /// Potato Mode: disables BackdropFilter/blur, heavy gradients, and complex
  /// animations. Dramatically improves performance on low-end devices.
  bool get potatoMode => _potatoMode;

  /// UI Sounds: enables haptic feedback and system sounds on button taps,
  /// tab switches, and key actions.
  bool get uiSounds => _uiSounds;

  /// When true (or when potatoMode is true), skip non-essential animations.
  bool get reduceAnimations => _reduceAnimations || _potatoMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _potatoMode = prefs.getBool(_potatoModeKey) ?? false;
    _uiSounds = prefs.getBool(_uiSoundsKey) ?? true;
    _reduceAnimations = prefs.getBool(_reduceAnimKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setPotatoMode(bool value) async {
    if (_potatoMode == value) return;
    _potatoMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_potatoModeKey, value);
  }

  Future<void> setUiSounds(bool value) async {
    if (_uiSounds == value) return;
    _uiSounds = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_uiSoundsKey, value);
  }

  Future<void> setReduceAnimations(bool value) async {
    if (_reduceAnimations == value) return;
    _reduceAnimations = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reduceAnimKey, value);
  }
}
