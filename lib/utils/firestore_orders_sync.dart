import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_sync_guard.dart';

class FirestoreOrdersSync {
  static CollectionReference<Map<String, dynamic>>? _scopeRef(String scope) {
    if (!CloudSyncGuard.cloudSyncEnabled) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders_sync')
        .doc(scope)
        .collection('items');
  }

  static Future<List<dynamic>> load({required String scope}) async {
    final ref = _scopeRef(scope);
    if (ref == null) return const <dynamic>[];
    try {
      final snapshot = await ref.orderBy('orderDate', descending: true).get();
      return snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data()))
          .toList();
    } catch (_) {
      return const <dynamic>[];
    }
  }

  static Future<void> save({
    required String scope,
    required List<dynamic> orders,
  }) async {
    final ref = _scopeRef(scope);
    if (ref == null) return;
    await CloudSyncGuard.runOptionalWrite(() async {
      final batch = FirebaseFirestore.instance.batch();
      final existing = await ref.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (final raw in orders) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final id = (item['orderId'] ?? item['_Id'] ?? '').toString().trim();
        if (id.isEmpty) continue;
        item['orderDate'] = (item['orderDate'] ?? '').toString();
        batch.set(ref.doc(id), item, SetOptions(merge: true));
      }
      await batch.commit();
    });
  }
}
