import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OrdersCacheStore {
  static const String _kPrefix = "dittox_orders_cache_v1";

  static String _key(String token, String scope) => "$_kPrefix::$scope::$token";

  static Future<void> save({
    required String accessToken,
    required String scope,
    required List<dynamic> orders,
  }) async {
    if (accessToken.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(accessToken, scope),
      jsonEncode({
        "savedAt": DateTime.now().toIso8601String(),
        "orders": orders,
      }),
    );
  }

  static Future<List<dynamic>> load({
    required String accessToken,
    required String scope,
  }) async {
    if (accessToken.trim().isEmpty) return <dynamic>[];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(accessToken, scope));
    if (raw == null || raw.isEmpty) return <dynamic>[];

    try {
      final decoded = jsonDecode(raw);
      final orders = (decoded is Map<String, dynamic> ? decoded["orders"] : null) as List?;
      return orders ?? <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  static Future<void> clear({
    required String accessToken,
    required String scope,
  }) async {
    if (accessToken.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(accessToken, scope));
  }

  static Future<void> clearAll({String? accessToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = accessToken?.trim();
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith(_kPrefix)) return false;
      if (token == null || token.isEmpty) return true;
      return key.endsWith("::$token");
    }).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
