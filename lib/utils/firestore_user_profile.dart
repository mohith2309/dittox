import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'cloud_sync_guard.dart';

/// Stores the customer's profile fields that a Firebase email/password account
/// does not natively carry (notably the phone number entered at sign-up).
///
/// Firestore path: users/{uid}/profile/main
/// Allowed by firestore.rules (`users/{userId}/{document=**}` for the owner).
class FirestoreUserProfile {
  static DocumentReference<Map<String, dynamic>>? _docFor(String? uid) {
    if (!CloudSyncGuard.cloudSyncEnabled) return null;
    final resolved = (uid ?? FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    if (resolved.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(resolved)
        .collection('profile')
        .doc('main');
  }

  /// Writes the profile while the user is authenticated. Must be called before
  /// any sign-out so the owner-scoped security rule is satisfied.
  static Future<void> save({
    String? uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    final ref = _docFor(uid);
    if (ref == null) return;
    await CloudSyncGuard.runOptionalWrite(() async {
      await ref.set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 6));
    });
  }

  /// Reads the profile for the current (or given) uid. Returns null on any
  /// error or when cloud sync is disabled so callers can fall back gracefully.
  static Future<Map<String, dynamic>?> load({String? uid}) async {
    final ref = _docFor(uid);
    if (ref == null) return null;
    try {
      final doc = await ref.get().timeout(const Duration(seconds: 4));
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('FirestoreUserProfile.load failed: $e');
      return null;
    }
  }
}
