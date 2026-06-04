import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wallet storage with Firestore as the source of truth.
///
/// Reads: Firestore first → SharedPreferences fallback (offline resilience).
/// Writes: Firestore + SharedPreferences simultaneously (dual-write for offline cache).
///
/// Firestore path: users/{uid}/wallet/balance  → { amount: double, updatedAt: string }
/// Transactions remain in SharedPreferences only (display-only, not synced).
class WalletStore {
  // ── SharedPreferences keys ───────────────────────────────────────────────
  static String _balanceKey([String? token]) =>
      'wallet_balance_v2_${token ?? "global"}';
  static String _txKey([String? token]) =>
      'wallet_transactions_v1_${token ?? "global"}';

  // ── Firestore helpers ───────────────────────────────────────────────────
  static DocumentReference<Map<String, dynamic>>? _balanceDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet')
        .doc('balance');
  }

  // ── Read balance ────────────────────────────────────────────────────────

  /// Returns wallet balance.
  /// Tries Firestore first; falls back to SharedPreferences on any error.
  static Future<double> getBalance([String? accessToken]) async {
    // 1. Try Firestore
    try {
      final ref = _balanceDoc();
      if (ref != null) {
        final doc = await ref.get().timeout(const Duration(seconds: 4));
        if (doc.exists) {
          final amount = (doc.data()?['amount'] as num?)?.toDouble();
          if (amount != null) {
            // Refresh local cache
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble(_balanceKey(accessToken), amount);
            return amount;
          }
        }
      }
    } catch (e) {
      debugPrint('WalletStore.getBalance: Firestore read failed: $e');
    }

    // 2. Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey(accessToken)) ?? 0.0;
  }

  // ── Write balance ───────────────────────────────────────────────────────

  /// Saves wallet balance to both Firestore and SharedPreferences.
  static Future<void> setBalance(String accessToken, double value) async {
    // Write to SharedPreferences immediately (for offline resilience)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balanceKey(accessToken), value);

    // Write to Firestore asynchronously (fire-and-forget)
    unawaited(_setFirestoreBalance(value));
  }

  static Future<void> _setFirestoreBalance(double value) async {
    try {
      final ref = _balanceDoc();
      if (ref == null) return;
      await ref.set({
        'amount': value,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('WalletStore._setFirestoreBalance: failed: $e');
    }
  }

  // ── Transactions (local only — display only, not synced) ────────────────

  static Future<List<Map<String, dynamic>>> getTransactions(
      [String? accessToken]) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_txKey(accessToken));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addTransaction(
    String accessToken, {
    required String type,
    required double amount,
    required String note,
    String? orderId,
    String method = 'UPI',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tx = await getTransactions(accessToken);
    tx.insert(0, {
      'type': type,
      'amount': amount,
      'note': note,
      'orderId': orderId ?? '',
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // Keep at most 100 transactions locally
    final trimmed = tx.take(100).toList();
    await prefs.setString(_txKey(accessToken), jsonEncode(trimmed));
  }

  // ── Legacy helpers (kept for backward compatibility) ───────────────────

  static Future<void> addIncome({
    required double amount,
    required String note,
    String? orderId,
    String method = 'UPI',
  }) async {
    final current = await getBalance();
    await setBalance('global', current + amount);
    final prefs = await SharedPreferences.getInstance();
    final tx = await getTransactions();
    tx.insert(0, {
      'type': 'credit',
      'amount': amount,
      'note': note,
      'orderId': orderId ?? '',
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_txKey(), jsonEncode(tx.take(100).toList()));
  }

  static Future<void> addExpense({
    required double amount,
    required String note,
    String? orderId,
    String method = 'UPI',
  }) async {
    final current = await getBalance();
    final next = (current - amount).clamp(0.0, double.infinity);
    await setBalance('global', next);
    final prefs = await SharedPreferences.getInstance();
    final tx = await getTransactions();
    tx.insert(0, {
      'type': 'debit',
      'amount': amount,
      'note': note,
      'orderId': orderId ?? '',
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_txKey(), jsonEncode(tx.take(100).toList()));
  }
}
