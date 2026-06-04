import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesStore {
  static const String _addressesKey = 'dittox_saved_addresses_v1';
  static const String _defaultPaymentKey = 'dittox_default_payment_v1';
  static const String _emailPrefsKey = 'dittox_email_prefs_v1';
  static const String _sessionsKey = 'dittox_sessions_v1';
  static const String _profilePhotoKey = 'dittox_profile_photo_path_v1';

  static Future<List<String>> getSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressesKey);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<void> addAddress(String address) async {
    final value = address.trim();
    if (value.isEmpty) return;
    final existing = await getSavedAddresses();
    final next = <String>[
      value,
      ...existing.where((item) => item.toLowerCase() != value.toLowerCase()),
    ].take(10).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressesKey, jsonEncode(next));
  }

  static Future<void> removeAddress(String address) async {
    final existing = await getSavedAddresses();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _addressesKey,
      jsonEncode(existing.where((item) => item != address).toList()),
    );
  }

  static Future<String> getDefaultPayment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultPaymentKey) ?? 'Wallet';
  }

  static Future<void> setDefaultPayment(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultPaymentKey, method);
  }

  static Future<Map<String, bool>> getEmailPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailPrefsKey);
    if (raw == null || raw.isEmpty) {
      return {'orders': true, 'offers': false, 'newsletter': false};
    }
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return {
        'orders': decoded['orders'] == true,
        'offers': decoded['offers'] == true,
        'newsletter': decoded['newsletter'] == true,
      };
    } catch (_) {
      return {'orders': true, 'offers': false, 'newsletter': false};
    }
  }

  static Future<void> setEmailPref(String key, bool value) async {
    final prefsMap = await getEmailPrefs();
    prefsMap[key] = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailPrefsKey, jsonEncode(prefsMap));
  }

  static Future<void> recordCurrentSession() async {
    final sessions = await getSessions();
    final now = DateTime.now().toIso8601String();
    final current = {
      'id': 'this_device',
      'label': 'This device',
      'lastActive': now,
    };
    final next = <Map<String, dynamic>>[
      current,
      ...sessions.where((session) => session['id'] != 'this_device'),
    ].take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionsKey, jsonEncode(next));
  }

  static Future<List<Map<String, dynamic>>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return const <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Future<void> clearSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  static Future<String> exportUserData(Map<String, dynamic> user) async {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'user': user,
      'addresses': await getSavedAddresses(),
      'defaultPayment': await getDefaultPayment(),
      'emailPreferences': await getEmailPrefs(),
      'sessions': await getSessions(),
      'profilePhotoPath': await getProfilePhotoPath(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<String> getProfilePhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePhotoKey) ?? '';
  }

  static Future<void> setProfilePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilePhotoKey, path);
  }

  static Future<void> clearAccountPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_addressesKey);
    await prefs.remove(_defaultPaymentKey);
    await prefs.remove(_emailPrefsKey);
    await prefs.remove(_sessionsKey);
    await prefs.remove(_profilePhotoKey);
  }

  static const String _notificationsKey = 'dittox_notifications_enabled_v1';
  static const String _soundKey = 'dittox_sound_enabled_v1';
  static const String _vibrationKey = 'dittox_vibration_enabled_v1';
  static const String _languageKey = 'dittox_language_v1';
  static const String _distanceUnitKey = 'dittox_distance_unit_v1';

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'English';
  }

  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String> getDistanceUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_distanceUnitKey) ?? 'km';
  }

  static Future<void> setDistanceUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_distanceUnitKey, unit);
  }
}
