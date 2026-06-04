import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PaymentPreferencesStore {
  static const String _savedCardsKey = 'dittox_saved_cards_v1';

  static Future<List<String>> getSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedCardsKey);
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

  static Future<void> addSavedCard(String label) async {
    final value = label.trim();
    if (value.isEmpty) return;
    final cards = await getSavedCards();
    final next = <String>[
      value,
      ...cards.where((card) => card.toLowerCase() != value.toLowerCase()),
    ].take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedCardsKey, jsonEncode(next));
  }
}
