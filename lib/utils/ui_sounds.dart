import 'package:flutter/services.dart';

import 'notification_sounds.dart';

/// Centralised UI interaction feedback (haptics + system sounds).
/// Call [UiSounds.update] when the app settings change.
///
/// All methods are no-ops when [_enabled] is false or when an exception
/// occurs (never crashes the UI).
class UiSounds {
  UiSounds._();

  static bool _enabled = true;

  /// Call this whenever [AppSettings.uiSounds] changes.
  static void update(bool enabled) => _enabled = enabled;

  /// Light tap feedback — use on standard button presses.
  static Future<void> tap() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Selection feedback — use when switching tabs or selecting list items.
  static Future<void> select() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Success feedback — use when an order is placed or payment succeeds.
  static Future<void> success() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.lightImpact();
      await NotificationSounds.playSound('success');
    } catch (_) {}
  }

  /// Error feedback — use on failures, validation errors.
  static Future<void> error() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await NotificationSounds.playSound('error');
    } catch (_) {}
  }

  /// Heavy celebration — use on order placed confirmation.
  static Future<void> orderPlaced() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.lightImpact();
      await NotificationSounds.playSound('success');
    } catch (_) {}
  }

  /// Tab switch feedback.
  static Future<void> tabSwitch() async {
    if (!_enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
