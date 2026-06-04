import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/notification_item.dart';
import '../utils/notification_sounds.dart';

class AppNotifications extends ChangeNotifier {
  static const String _settingsKey = 'dittox_notif_settings';
  static const Duration _dedupeWindow = Duration(seconds: 2);

  final List<AppNotification> _notifications = [];
  bool _orderUpdatesEnabled = true;
  bool _storeAlertsEnabled = true;
  bool _offersEnabled = false;

  List<AppNotification> get all => List.unmodifiable(_notifications);
  List<AppNotification> get visible =>
      _notifications.where((n) => n.status == 'visible').toList();
  bool get hasUnread => visible.isNotEmpty;
  int get unreadCount => visible.length;
  bool get orderUpdatesEnabled => _orderUpdatesEnabled;
  bool get storeAlertsEnabled => _storeAlertsEnabled;
  bool get offersEnabled => _offersEnabled;

  AppNotifications() {
    _load();
  }

  String _fingerprint({
    required String type,
    required String title,
    required String body,
    String? orderId,
    String? storeId,
  }) {
    return [
      type.trim().toLowerCase(),
      title.trim().toLowerCase(),
      body.trim().toLowerCase(),
      (orderId ?? '').trim().toLowerCase(),
      (storeId ?? '').trim().toLowerCase(),
    ].join('||');
  }

  void _insertOrRefreshNotification(
    AppNotification notification, {
    bool playSound = true,
    bool vibrate = true,
    Future<void> Function()? vibration,
  }) {
    final now = DateTime.now();
    final fp = _fingerprint(
      type: notification.type,
      title: notification.title,
      body: notification.body,
      orderId: notification.orderId,
      storeId: notification.storeId,
    );

    final existingIndex = _notifications.indexWhere((n) {
      final eachFp = _fingerprint(
        type: n.type,
        title: n.title,
        body: n.body,
        orderId: n.orderId,
        storeId: n.storeId,
      );
      if (eachFp != fp) return false;
      final delta = now.difference(n.timestamp).abs();
      return delta <= _dedupeWindow;
    });

    if (existingIndex != -1) {
      final existing = _notifications.removeAt(existingIndex);
      // Keep the same ID so delayed dismiss callbacks still target this entry.
      final refreshed = AppNotification(
        id: existing.id,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        priority: notification.priority,
        timestamp: now,
        orderId: notification.orderId,
        storeId: notification.storeId,
        autoDismissMs: notification.autoDismissMs,
      );
      _notifications.insert(0, refreshed);
      _scheduleDismiss(refreshed.id, refreshed.autoDismissMs);
      notifyListeners();
      return;
    }

    _notifications.insert(0, notification);
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    _scheduleDismiss(notification.id, notification.autoDismissMs);
    if (playSound) {
      NotificationSounds.playSound(notification.type);
    }
    if (vibrate && vibration != null) {
      vibration();
    }
    notifyListeners();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _orderUpdatesEnabled = prefs.getBool('${_settingsKey}_order') ?? true;
    _storeAlertsEnabled = prefs.getBool('${_settingsKey}_store') ?? true;
    _offersEnabled = prefs.getBool('${_settingsKey}_offers') ?? false;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_settingsKey}_order', _orderUpdatesEnabled);
    await prefs.setBool('${_settingsKey}_store', _storeAlertsEnabled);
    await prefs.setBool('${_settingsKey}_offers', _offersEnabled);
  }

  void addOrderUpdate({
    required String orderId,
    required String title,
    required String body,
    String status = 'pending',
  }) {
    if (!_orderUpdatesEnabled) return;

    final notification = AppNotification(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeOrderUpdate,
      priority: _getPriority(status),
      timestamp: DateTime.now(),
      orderId: orderId,
    );

    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.mediumVibrate,
    );
  }

  void addStoreAlert({
    required String storeId,
    required String title,
    required String body,
  }) {
    if (!_storeAlertsEnabled) return;

    final notification = AppNotification(
      id: 'store_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeStoreAlert,
      priority: 'high',
      timestamp: DateTime.now(),
      storeId: storeId,
      autoDismissMs: 0,
    );

    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.vibrate,
    );
  }

  void addOffer({
    required String title,
    required String body,
  }) {
    if (!_offersEnabled) return;

    final notification = AppNotification(
      id: 'offer_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeOffer,
      priority: 'low',
      timestamp: DateTime.now(),
      autoDismissMs: 10000,
    );

    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.mediumVibrate,
    );
  }

  void addError({required String title, required String body}) {
    final notification = AppNotification(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeError,
      priority: 'high',
      timestamp: DateTime.now(),
      autoDismissMs: 0,
    );
    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.vibrate,
    );
  }

  void addInfo({required String title, required String body}) {
    final notification = AppNotification(
      id: 'info_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeInfo,
      priority: 'medium',
      timestamp: DateTime.now(),
      autoDismissMs: 8000,
    );
    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.lightVibrate,
    );
  }

  void addSuccess({required String title, required String body}) {
    final notification = AppNotification(
      id: 'success_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeSuccess,
      priority: 'low',
      timestamp: DateTime.now(),
      autoDismissMs: 5000,
    );
    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.mediumVibrate,
    );
  }

  void addWarning({required String title, required String body}) {
    final notification = AppNotification(
      id: 'warning_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: AppNotification.typeWarning,
      priority: 'high',
      timestamp: DateTime.now(),
      autoDismissMs: 0,
    );
    _insertOrRefreshNotification(
      notification,
      vibration: NotificationSounds.vibrate,
    );
  }

  String _getPriority(String status) {
    switch (status.toLowerCase()) {
      case 'collected':
      case 'completed':
        return 'low';
      case 'ready':
      case 'printing':
        return 'medium';
      default:
        return 'high';
    }
  }

  void _scheduleDismiss(String id, int ms) {
    if (ms <= 0) return;
    Future.delayed(Duration(milliseconds: ms), () => dismiss(id));
  }

  void dismiss(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void dismissAll() {
    _notifications.clear();
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final current = _notifications[index];
    if (current.status == 'read') return;
    current.status = 'read';
    notifyListeners();
  }

  void markAllAsRead() {
    bool changed = false;
    for (final each in _notifications) {
      if (each.status != 'read') {
        each.status = 'read';
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> toggleOrderUpdates(bool value) async {
    _orderUpdatesEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleStoreAlerts(bool value) async {
    _storeAlertsEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleOffers(bool value) async {
    _offersEnabled = value;
    await _saveSettings();
    notifyListeners();
  }
}
