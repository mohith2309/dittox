import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User stats with Firestore sync.
/// Firestore path: users/{uid}/stats/summary (single document)
class UserStatsStore {
  static const String _kProSubscriber = 'dittox_pro_subscriber';
  static const String _kProPlan = 'dittox_pro_plan';
  static const String _kProStartedAt = 'dittox_pro_started_at';
  static const String _kDiscountSaved = 'dittox_discount_saved';
  static const String _kProTopupBonusSaved = 'dittox_pro_topup_bonus_saved';

  static DocumentReference<Map<String, dynamic>>? _statsDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('summary');
  }

  // ── Firestore helpers ───────────────────────────────────────────────────

  static Future<void> _syncToFirestore() async {
    try {
      final ref = _statsDoc();
      if (ref == null) return;
      final prefs = await SharedPreferences.getInstance();
      await ref.set({
        'isProSubscriber': prefs.getBool(_kProSubscriber) ?? false,
        'proPlan': prefs.getString(_kProPlan) ?? '',
        'proStartedAt': prefs.getString(_kProStartedAt) ?? '',
        'discountSaved': prefs.getDouble(_kDiscountSaved) ?? 0.0,
        'topupBonusSaved': prefs.getDouble(_kProTopupBonusSaved) ?? 0.0,
        'syncedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('UserStatsStore._syncToFirestore: $e');
    }
  }

  static Future<Map<String, dynamic>?> _loadFromFirestore() async {
    try {
      final ref = _statsDoc();
      if (ref == null) return null;
      final doc = await ref.get().timeout(const Duration(seconds: 4));
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('UserStatsStore._loadFromFirestore: $e');
      return null;
    }
  }

  // ── Pro subscriber ──────────────────────────────────────────────────────

  static Future<void> markProSubscribed({required String planId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProSubscriber, true);
    await prefs.setString(_kProPlan, planId);
    await prefs.setString(_kProStartedAt, DateTime.now().toIso8601String());
    unawaited(_syncToFirestore());
  }

  static Future<bool> isProSubscriber() async {
    // Try Firestore first
    final remote = await _loadFromFirestore();
    if (remote != null) {
      final isPro = remote['isProSubscriber'] == true;
      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kProSubscriber, isPro);
      return isPro;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProSubscriber) ?? false;
  }

  static Future<String> getProPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kProPlan) ?? '';
  }

  // ── Discount saved ──────────────────────────────────────────────────────

  static Future<void> addDiscountSaved(double amount) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_kDiscountSaved) ?? 0;
    await prefs.setDouble(_kDiscountSaved, current + amount);
    unawaited(_syncToFirestore());
  }

  static Future<double> getDiscountSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kDiscountSaved) ?? 0;
  }

  // ── Topup bonus saved ───────────────────────────────────────────────────

  static Future<void> addTopupBonusSaved(double amount) async {
    if (amount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getDouble(_kProTopupBonusSaved) ?? 0;
    await prefs.setDouble(_kProTopupBonusSaved, current + amount);
    unawaited(_syncToFirestore());
  }

  static Future<double> getTopupBonusSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kProTopupBonusSaved) ?? 0;
  }
}
