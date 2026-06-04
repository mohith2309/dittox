import 'package:shared_preferences/shared_preferences.dart';

class ShopAutoModeStore {
  static const String _keyPrefix = 'shop_auto_';
  static const String _autoAcceptKey = 'auto_accept_orders';
  static const String _autoPrintKey = 'auto_print_enabled';
  static const String _printCopiesKey = 'print_copies';
  static const String _printQualityKey = 'print_quality';
  static const String _notificationSoundKey = 'notification_sound';
  static const String _orderValidationKey = 'require_validation';
  static const String _autoRejectKey = 'auto_reject_timeout';

  static Future<bool> isAutoAcceptEnabled(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${shopId}_$_autoAcceptKey') ?? false;
  }

  static Future<void> setAutoAcceptEnabled(String shopId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${shopId}_$_autoAcceptKey', enabled);
  }

  static Future<bool> isAutoPrintEnabled(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${shopId}_$_autoPrintKey') ?? false;
  }

  static Future<void> setAutoPrintEnabled(String shopId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${shopId}_$_autoPrintKey', enabled);
  }

  static Future<int> getPrintCopies(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix${shopId}_$_printCopiesKey') ?? 1;
  }

  static Future<void> setPrintCopies(String shopId, int copies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix${shopId}_$_printCopiesKey', copies);
  }

  static Future<String> getPrintQuality(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix${shopId}_$_printQualityKey') ?? '80gsm';
  }

  static Future<void> setPrintQuality(String shopId, String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${shopId}_$_printQualityKey', quality);
  }

  static Future<bool> isNotificationSoundEnabled(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${shopId}_$_notificationSoundKey') ?? true;
  }

  static Future<void> setNotificationSoundEnabled(String shopId, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${shopId}_$_notificationSoundKey', enabled);
  }

  static Future<bool> isValidationRequired(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix${shopId}_$_orderValidationKey') ?? true;
  }

  static Future<void> setValidationRequired(String shopId, bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix${shopId}_$_orderValidationKey', required);
  }

  static Future<int> getAutoRejectTimeout(String shopId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix${shopId}_$_autoRejectKey') ?? 30;
  }

  static Future<void> setAutoRejectTimeout(String shopId, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix${shopId}_$_autoRejectKey', minutes);
  }

  static Future<Map<String, dynamic>> getAllSettings(String shopId) async {
    return {
      'autoAccept': await isAutoAcceptEnabled(shopId),
      'autoPrint': await isAutoPrintEnabled(shopId),
      'printCopies': await getPrintCopies(shopId),
      'printQuality': await getPrintQuality(shopId),
      'notificationSound': await isNotificationSoundEnabled(shopId),
      'requireValidation': await isValidationRequired(shopId),
      'autoRejectTimeout': await getAutoRejectTimeout(shopId),
    };
  }
}
