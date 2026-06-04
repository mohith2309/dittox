import 'package:flutter/services.dart';

class NotificationSounds {
  static bool _soundEnabled = true;
  static bool _vibrationEnabled = true;

  static bool get soundEnabled => _soundEnabled;
  static bool get vibrationEnabled => _vibrationEnabled;

  static Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
  }

  static Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
  }

  static Future<void> playSound(String type) async {
    if (!_soundEnabled) return;

    try {
      switch (type) {
        case 'info':
          await _playSoftChime();
          break;
        case 'success':
          await _playWarmSuccess();
          break;
        case 'error':
          await _playErrorChime();
          break;
        case 'warning':
          await _playWarningChime();
          break;
        case 'orderUpdate':
          await _playSoftChime();
          break;
        default:
          await _playSoftChime();
      }
    } catch (_) {}
  }

  static Future<void> _playSoftChime() async {
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> _playWarmSuccess() async {
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await SystemSound.play(SystemSoundType.alert);
  }

  static Future<void> _playWarningChime() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> _playErrorChime() async {
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await SystemSound.play(SystemSoundType.alert);
  }

  static Future<void> vibrate() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> mediumVibrate() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> lightVibrate() async {
    if (!_vibrationEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
