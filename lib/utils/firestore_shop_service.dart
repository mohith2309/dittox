import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/shop.dart';

/// Loads shop profiles from Firestore `shop_profiles` collection.
/// Falls back gracefully to an empty list on any error.
///
/// Firestore document shape (all fields optional, defaults used for missing ones):
/// {
///   name: string, storeName: string, address: string,
///   locationX: double, locationY: double,
///   email: string, contactNumber: string,
///   openingTime: string, closingTime: string,
///   avgRating: double, isActive: bool,
///   costOneSide: string, costTwoSide: string,
///   costBlack: string, costColor: string,
///   sizeA4: string, sizeA5: string, legal: string, letter: string,
///   sizeB5: string, sizeA6: string, postCard: string,
///   size5X7: string, size4X6: string, size35X5: string,
///   spiralBinding: string, staplesBinding: string, stickFile: string,
///   bondPage: string, quality100Gsm: string, quality80gsm: string,
/// }
class FirestoreShopService {
  static const String _collection = 'shop_profiles';

  /// Load all active shops from Firestore.
  /// Returns an empty list if Firestore is unreachable or the collection is empty.
  static Future<List<Shop>> loadShops() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 6));

      if (snapshot.docs.isEmpty) return const <Shop>[];

      return snapshot.docs.map((doc) => _fromDoc(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint(
          'FirestoreShopService: Firestore error ${e.code}: ${e.message}');
      return const <Shop>[];
    } catch (e) {
      debugPrint('FirestoreShopService: failed to load shops: $e');
      return const <Shop>[];
    }
  }

  static Shop _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Shop(
      id: doc.id,
      name: _s(d, 'name', doc.id),
      storeName: _s(d, 'storeName', _s(d, 'name', 'Shop')),
      address: _s(d, 'address'),
      locationX: _f(d, 'locationX', 12.9716),
      locationY: _f(d, 'locationY', 77.5946),
      email: _s(d, 'email'),
      contactNumber: _s(d, 'contactNumber'),
      openingTime: _s(d, 'openingTime'),
      closingTime: _s(d, 'closingTime'),
      avgRating: _f(d, 'avgRating', 4.0),
      costOneSide: _s(d, 'costOneSide', '1.0'),
      costTwoSide: _s(d, 'costTwoSide', '1.5'),
      costBlack: _s(d, 'costBlack', '2.0'),
      costColor: _s(d, 'costColor', '10.0'),
      sizeA4: _s(d, 'sizeA4', '0.5'),
      sizeA5: _s(d, 'sizeA5', '0.3'),
      legal: _s(d, 'legal', '1.0'),
      letter: _s(d, 'letter', '0.5'),
      sizeB5: _s(d, 'sizeB5', '0.4'),
      sizeA6: _s(d, 'sizeA6', '0.2'),
      postCard: _s(d, 'postCard', '2.0'),
      size5X7: _s(d, 'size5X7', '3.0'),
      size4X6: _s(d, 'size4X6', '2.5'),
      size35X5: _s(d, 'size35X5', '1.0'),
      spiralBinding: _s(d, 'spiralBinding', '30.0'),
      staplesBinding: _s(d, 'staplesBinding', '5.0'),
      stickFile: _s(d, 'stickFile', '10.0'),
      bondPage: _s(d, 'bondPage', '5.0'),
      quality100Gsm: _s(d, 'quality100Gsm', '5.0'),
      quality80gsm: _s(d, 'quality80gsm', '3.0'),
      distance: '',
      duration: '',
      feedback: const [],
      reviewer: const [],
    );
  }

  static String _s(Map<String, dynamic> d, String key, [String fallback = '']) {
    final v = d[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static double _f(Map<String, dynamic> d, String key, [double fallback = 0]) {
    final v = d[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
