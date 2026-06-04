import 'package:shared_preferences/shared_preferences.dart';

class AutoModeSettings {
  static const String _key = 'auto_mode_settings';
  static const String _enabledKey = 'auto_mode_enabled';
  static const String _preferredShopKey = 'preferred_shop_id';
  static const String _defaultCopiesKey = 'default_copies';
  static const String _defaultQualityKey = 'default_quality';
  static const String _autoSelectShopKey = 'auto_select_shop';

  static Future<bool> isAutoModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  static Future<void> setAutoModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<String?> getPreferredShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredShopKey);
  }

  static Future<void> setPreferredShopId(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredShopKey, shopId);
  }

  static Future<int> getDefaultCopies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_defaultCopiesKey) ?? 1;
  }

  static Future<void> setDefaultCopies(int copies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultCopiesKey, copies);
  }

  static Future<String> getDefaultQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultQualityKey) ?? '80gsm';
  }

  static Future<void> setDefaultQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultQualityKey, quality);
  }

  static Future<bool> isAutoSelectShopEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSelectShopKey) ?? false;
  }

  static Future<void> setAutoSelectShopEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSelectShopKey, enabled);
  }

  static Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'autoModeEnabled': prefs.getBool(_enabledKey) ?? false,
      'preferredShopId': prefs.getString(_preferredShopKey),
      'defaultCopies': prefs.getInt(_defaultCopiesKey) ?? 1,
      'defaultQuality': prefs.getString(_defaultQualityKey) ?? '80gsm',
      'autoSelectShop': prefs.getBool(_autoSelectShopKey) ?? false,
    };
  }

  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
