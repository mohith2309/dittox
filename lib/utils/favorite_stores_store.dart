import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FavoriteStore {
  final String id;
  final String name;
  final String address;

  const FavoriteStore({
    required this.id,
    required this.name,
    this.address = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
      };

  factory FavoriteStore.fromJson(Map<String, dynamic> json) {
    return FavoriteStore(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Store').toString(),
      address: (json['address'] ?? '').toString(),
    );
  }
}

class FavoriteStoresStore {
  static const String _key = 'dittox_favorite_stores_v1';

  static Future<List<FavoriteStore>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const <FavoriteStore>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <FavoriteStore>[];
      return decoded
          .whereType<Map>()
          .map(
              (item) => FavoriteStore.fromJson(Map<String, dynamic>.from(item)))
          .where((store) => store.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const <FavoriteStore>[];
    }
  }

  static Future<bool> isFavorite(String id) async {
    final favorites = await load();
    return favorites.any((store) => store.id == id);
  }

  static Future<bool> toggle(FavoriteStore store) async {
    final favorites = await load();
    final exists = favorites.any((item) => item.id == store.id);
    final next = exists
        ? favorites.where((item) => item.id != store.id).toList()
        : <FavoriteStore>[store, ...favorites];
    await _save(next);
    return !exists;
  }

  static Future<void> remove(String id) async {
    final favorites = await load();
    await _save(favorites.where((item) => item.id != id).toList());
  }

  static Future<void> _save(List<FavoriteStore> stores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(stores.map((store) => store.toJson()).toList()));
  }
}
