import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthStore {
  static const String _usersKey = 'local_auth_users_v1';
  static const String _idPrefix = 'local_user_';
  static const String _tokenPrefix = 'local_token_';

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return [];
    }
    if (decoded is! List) {
      return [];
    }
    return decoded.map<Map<String, dynamic>>((e) {
      return Map<String, dynamic>.from(e as Map);
    }).toList();
  }

  static Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static String _newUserId() {
    return '$_idPrefix${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _newToken(String userId) {
    return '$_tokenPrefix${userId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final users = await _getUsers();
    final normalizedEmail = _normalizeEmail(email);
    final exists = users.any((u) => u['email'] == normalizedEmail);
    if (exists) {
      return null;
    }

    final userId = _newUserId();
    final token = _newToken(userId);
    final user = <String, dynamic>{
      'userId': userId,
      'name': name.trim(),
      'email': normalizedEmail,
      'phone': phone.trim(),
      'password': password,
      'accessToken': token,
    };

    users.add(user);
    await _saveUsers(users);
    return user;
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final users = await _getUsers();
    final normalizedEmail = _normalizeEmail(email);
    final index = users.indexWhere(
      (u) => u['email'] == normalizedEmail && u['password'] == password,
    );
    if (index < 0) {
      return null;
    }

    final current = Map<String, dynamic>.from(users[index]);
    current['accessToken'] = _newToken(current['userId'].toString());
    users[index] = current;
    await _saveUsers(users);
    return current;
  }
}
