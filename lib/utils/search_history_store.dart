import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStore {
  static const int _maxItems = 8;

  static String _key(String scope) => 'dittox_search_history_$scope';

  static Future<List<String>> load(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(scope));
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

  static Future<List<String>> add(String scope, String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return load(scope);
    final current = await load(scope);
    final next = <String>[
      normalized,
      ...current
          .where((item) => item.toLowerCase() != normalized.toLowerCase()),
    ].take(_maxItems).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(scope), jsonEncode(next));
    return next;
  }

  static Future<void> clear(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(scope));
  }
}
