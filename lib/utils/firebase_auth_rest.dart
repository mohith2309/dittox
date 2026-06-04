import 'dart:convert';

import 'package:http/http.dart' as http;

import '../firebase_options.dart';

class FirebaseAuthRest {
  static String get _apiKey => DefaultFirebaseOptions.android.apiKey;
  static Uri _signInUri() => Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey',
      );
  static Uri _signUpUri() => Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
      );

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _signInUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password.trim(),
        'returnSecureToken': true,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || body['error'] != null) {
      throw Exception(
          body['error']?['message']?.toString() ?? 'SIGN_IN_FAILED');
    }
    return body;
  }

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      _signUpUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password.trim(),
        'returnSecureToken': true,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || body['error'] != null) {
      throw Exception(
          body['error']?['message']?.toString() ?? 'SIGN_UP_FAILED');
    }
    return body;
  }
}
