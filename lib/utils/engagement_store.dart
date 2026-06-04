import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EngagementStore {
  static const String _pointsKey = 'dittox_reward_points_v1';
  static const String _checkInKey = 'dittox_last_check_in_v1';
  static const String _featureVotesKey = 'dittox_feature_votes_v1';
  static const String _surveysKey = 'dittox_feedback_surveys_v1';
  static const String _issueReportsKey = 'dittox_issue_reports_v1';
  static const String _archiveKey = 'dittox_archived_orders_v1';
  static const String _collectedPhotosKey = 'dittox_collected_photos_v1';
  static Future<void> _pointsLock = Future.value();

  // ── Firestore sync ────────────────────────────────────────────────────
  static DocumentReference<Map<String, dynamic>>? _engagementDoc() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return null;
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('engagement')
          .doc('summary');
    } catch (_) {
      return null;
    }
  }

  static Future<void> _syncPointsToCloud(int points) async {
    try {
      final ref = _engagementDoc();
      if (ref == null) return;
      await ref.set({
        'points': points,
        'syncedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('EngagementStore._syncPointsToCloud: $e');
    }
  }

  static Future<int> getPoints() async {
    // Try to get the cloud value first (for cross-device sync)
    try {
      final ref = _engagementDoc();
      if (ref != null) {
        final doc = await ref.get().timeout(const Duration(seconds: 3));
        if (doc.exists) {
          final cloudPoints = (doc.data()?['points'] as num?)?.toInt();
          if (cloudPoints != null) {
            // Sync back to local
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_pointsKey, cloudPoints);
            return cloudPoints;
          }
        }
      }
    } catch (_) {}
    // Fallback to local
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  static Future<int> addPoints(int points) async {
    final next = _pointsLock.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final next = (prefs.getInt(_pointsKey) ?? 0) + points;
      await prefs.setInt(_pointsKey, next);
      unawaited(_syncPointsToCloud(next));
      return next;
    });
    _pointsLock = next.then((_) {}, onError: (_) {});
    return next;
  }

  static Future<bool> canCheckInToday() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_checkInKey);
    if (raw == null || raw.isEmpty) return true;
    final last = DateTime.tryParse(raw)?.toLocal();
    if (last == null) return true;
    final now = DateTime.now();
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }

  static Future<int> checkIn() async {
    if (!await canCheckInToday()) return getPoints();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_checkInKey, DateTime.now().toIso8601String());
    return addPoints(10);
  }

  static Future<int> spinWheel() async {
    final reward = [5, 10, 15, 20, 25, 50][Random().nextInt(6)];
    await addPoints(reward);
    return reward;
  }

  static Future<List<String>> getFeatureVotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_featureVotesKey);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<void> voteFeature(String feature) async {
    final votes = await getFeatureVotes();
    if (votes.contains(feature)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_featureVotesKey, jsonEncode([feature, ...votes]));
    await addPoints(3);
  }

  static Future<void> saveSurvey(Map<String, dynamic> survey) async {
    final existing = await _loadList(_surveysKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _surveysKey,
      jsonEncode([
        {'createdAt': DateTime.now().toIso8601String(), ...survey},
        ...existing,
      ]),
    );
    await addPoints(5);
  }

  static Future<void> saveIssue(Map<String, dynamic> issue) async {
    final existing = await _loadList(_issueReportsKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _issueReportsKey,
      jsonEncode([
        {'createdAt': DateTime.now().toIso8601String(), ...issue},
        ...existing,
      ]),
    );
  }

  static Future<List<Map<String, dynamic>>> getIssueReports() =>
      _loadList(_issueReportsKey);

  static Future<List<String>> getArchivedOrderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_archiveKey);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<void> archiveOrder(String orderId) async {
    final ids = await getArchivedOrderIds();
    if (ids.contains(orderId)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_archiveKey, jsonEncode([orderId, ...ids]));
  }

  static Future<void> unarchiveOrder(String orderId) async {
    final ids = await getArchivedOrderIds();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _archiveKey, jsonEncode(ids.where((id) => id != orderId).toList()));
  }

  static Future<void> saveCollectedPhoto(String orderId, String path) async {
    final current = await _loadMap(_collectedPhotosKey);
    current[orderId] = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectedPhotosKey, jsonEncode(current));
    await addPoints(2);
  }

  static Future<Map<String, dynamic>> getCollectedPhotos() =>
      _loadMap(_collectedPhotosKey);

  static Future<void> clearHistoryMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_archiveKey);
    await prefs.remove(_collectedPhotosKey);
  }

  static Future<List<Map<String, dynamic>>> _loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Future<Map<String, dynamic>> _loadMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
