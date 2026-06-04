import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/pdfFile.dart';
import '../model/shop.dart';
import 'cloud_sync_guard.dart';
import 'operational_order_service.dart';

class DemoOrdersStore {
  static const String _key = 'demo_orders';
  static const String _cloudCollection = 'orders_demo';
  static const String _userOrdersCollection = 'orders';
  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  static Stream<void> get changes => _changes.stream;

  static void _notifyChanged() {
    if (!_changes.isClosed) _changes.add(null);
  }

  static String _newOrderId(DateTime now) {
    final user = FirebaseAuth.instance.currentUser;
    if (!CloudSyncGuard.cloudSyncEnabled || user == null) {
      return "LOCAL-${now.millisecondsSinceEpoch}";
    }
    return "ORD-${now.millisecondsSinceEpoch}";
  }

  static String createOrderId() => _newOrderId(DateTime.now());

  static bool _isActiveStatus(dynamic value) {
    final status = (value ?? '').toString().trim().toLowerCase();
    return status != 'collected' &&
        status != 'completed' &&
        status != 'rejected' &&
        status != 'failed';
  }

  static String _mimeTypeFromPdf(PdfData pdf) {
    for (final line in pdf.additionDesciption.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('mimetype=')) {
        return trimmed.substring('mimeType='.length).trim();
      }
    }
    final name = pdf.name.toLowerCase();
    if (name.endsWith('.pdf')) return 'application/pdf';
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    final document = pdf.documents.toLowerCase();
    if (document.startsWith('data:')) {
      final end = document.indexOf(';');
      if (end > 5) return document.substring(5, end);
    }
    return 'application/octet-stream';
  }

  static dynamic _jsonSafe(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return value
          .map((key, child) => MapEntry(key.toString(), _jsonSafe(child)));
    }
    if (value is List) return value.map(_jsonSafe).toList();
    return value;
  }

  static Map<String, dynamic> _jsonSafeOrder(Map<String, dynamic> order) {
    return Map<String, dynamic>.from(_jsonSafe(order) as Map);
  }

  static String _orderKey(Map<String, dynamic> order) {
    return (order["orderId"] ?? order["_id"] ?? order["orderDate"] ?? '')
        .toString()
        .trim();
  }

  static DateTime _orderUpdatedAt(Map<String, dynamic> order) {
    return DateTime.tryParse((order['updatedAt'] ?? '').toString()) ??
        DateTime.tryParse((order['orderDate'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static void _sortNewest(List<Map<String, dynamic>> orders) {
    orders.sort((a, b) => _orderUpdatedAt(b).compareTo(_orderUpdatedAt(a)));
  }

  static String _matchText(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  static String _digits(dynamic value) {
    return (value ?? '').toString().replaceAll(RegExp(r'\D+'), '');
  }

  static List<Map<String, dynamic>> _mergeOrders(
    Iterable<Map<String, dynamic>> orders,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final order in orders) {
      final key = _orderKey(order);
      if (key.isEmpty) continue;
      final current = merged[key];
      if (current == null ||
          !_orderUpdatedAt(current).isAfter(_orderUpdatedAt(order))) {
        merged[key] = order;
      }
    }
    final out = merged.values.toList();
    _sortNewest(out);
    return out;
  }

  static List<Map<String, dynamic>> _decodeLocalOrders(String? raw) {
    final normalized = <Map<String, dynamic>>[];
    if (raw == null || raw.isEmpty) return normalized;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return normalized;
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        normalized.add(item);
      } else if (item is Map) {
        normalized.add(Map<String, dynamic>.from(item));
      }
    }
    _sortNewest(normalized);
    return normalized;
  }

  static Map<String, dynamic> _orderFromCloudDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _jsonSafeOrder({
      ...data,
      'orderId': (data['orderId'] ?? doc.id).toString(),
    });
  }

  static Future<List<Map<String, dynamic>>> _loadUserCloudOrders(
    String uid,
  ) async {
    if (!CloudSyncGuard.cloudSyncEnabled) return const <Map<String, dynamic>>[];
    if (uid.isEmpty) return const <Map<String, dynamic>>[];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(_userOrdersCollection)
          .get()
          .timeout(const Duration(seconds: 4));
      final orders = snapshot.docs.map(_orderFromCloudDoc).toList();
      _sortNewest(orders);
      return orders;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Future<List<Map<String, dynamic>>> _loadSharedCloudOrders({
    String? userId,
    String? storeId,
  }) async {
    if (!CloudSyncGuard.cloudSyncEnabled) return const <Map<String, dynamic>>[];
    final uid = (userId ?? '').trim();
    final sid = (storeId ?? '').trim();
    if (uid.isEmpty && sid.isEmpty) return const <Map<String, dynamic>>[];

    try {
      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection(_cloudCollection);
      if (uid.isNotEmpty) query = query.where('userId', isEqualTo: uid);
      if (sid.isNotEmpty) query = query.where('storeId', isEqualTo: sid);
      final snapshot = await query.get().timeout(const Duration(seconds: 4));
      final orders = snapshot.docs.map(_orderFromCloudDoc).toList();
      _sortNewest(orders);
      return orders;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Future<List<Map<String, dynamic>>>
      _loadRecentSharedCloudOrders() async {
    if (!CloudSyncGuard.cloudSyncEnabled) return const <Map<String, dynamic>>[];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_cloudCollection)
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 4));
      final orders = snapshot.docs.map(_orderFromCloudDoc).toList();
      _sortNewest(orders);
      return orders;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  static Future<Map<String, dynamic>?> _loadSharedCloudOrderById(
    String orderId,
  ) async {
    if (!CloudSyncGuard.cloudSyncEnabled) return null;
    final id = orderId.trim();
    if (id.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_cloudCollection)
          .doc(id)
          .get()
          .timeout(const Duration(seconds: 4));
      if (!doc.exists || doc.data() == null) return null;
      return _jsonSafeOrder({
        ...doc.data()!,
        'orderId': (doc.data()!['orderId'] ?? doc.id).toString(),
      });
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _ordersWithCloudFallback(
    List<Map<String, dynamic>> orders,
    String orderId,
  ) async {
    final target = orderId.trim().toLowerCase();
    if (target.isEmpty) return orders;
    final exists = orders.any((order) {
      final current = (order['orderId'] ?? '').toString().trim().toLowerCase();
      return current == target;
    });
    if (exists) return orders;
    final cloud = await _loadSharedCloudOrderById(orderId);
    if (cloud == null) return orders;
    return _mergeOrders([cloud, ...orders]);
  }

  static Stream<List<Map<String, dynamic>>> watchCustomerOrders() {
    if (!CloudSyncGuard.cloudSyncEnabled) return const Stream.empty();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection(_cloudCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(_orderFromCloudDoc).toList();
      _sortNewest(orders);
      return orders;
    });
  }

  static Stream<List<Map<String, dynamic>>> watchStoreOrders({
    required String storeId,
  }) {
    if (!CloudSyncGuard.cloudSyncEnabled) return const Stream.empty();
    final sid = storeId.trim();
    if (sid.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection(_cloudCollection)
        .where('storeId', isEqualTo: sid)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(_orderFromCloudDoc).toList();
      _sortNewest(orders);
      return orders;
    });
  }

  static Future<void> _syncOrderToCloud(Map<String, dynamic> order) async {
    final orderId = (order["orderId"] ?? "").toString();
    if (orderId.isEmpty) return;
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final orderUid = (order['userId'] ?? authUid ?? '').toString().trim();
    final now = DateTime.now().toIso8601String();
    final payload = _jsonSafeOrder({
      ...order,
      if (orderUid.isNotEmpty) 'userId': orderUid,
      'updatedAt': now,
    });

    await CloudSyncGuard.runOptionalWrite(() async {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final active = _isActiveStatus(payload['status']);

      if (authUid != null &&
          authUid.isNotEmpty &&
          (orderUid.isEmpty || orderUid == authUid)) {
        final userRoot = db.collection('users').doc(authUid);
        final userOrder =
            userRoot.collection(_userOrdersCollection).doc(orderId);
        final ongoing = userRoot
            .collection('orders_sync')
            .doc('ongoing')
            .collection('items')
            .doc(orderId);
        final history = userRoot
            .collection('orders_sync')
            .doc('history')
            .collection('items')
            .doc(orderId);

        batch.set(userOrder, payload, SetOptions(merge: true));
        batch.set(history, payload, SetOptions(merge: true));
        if (active) {
          batch.set(ongoing, payload, SetOptions(merge: true));
        } else {
          batch.delete(ongoing);
        }
      }

      batch.set(
        db.collection(_cloudCollection).doc(orderId),
        payload,
        SetOptions(merge: true),
      );

      await batch.commit();
    });
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final normalized = _decodeLocalOrders(raw);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final cloud = <Map<String, dynamic>>[];
      if (uid != null && uid.isNotEmpty) {
        cloud.addAll(await _loadUserCloudOrders(uid));
        cloud.addAll(await _loadSharedCloudOrders(userId: uid));
      }
      if (cloud.isEmpty) return normalized;

      final out = _mergeOrders([...normalized, ...cloud]);
      unawaited(prefs.setString(_key, jsonEncode(out)));
      return out;
    } catch (_) {
      return normalized;
    }
  }

  static bool isLocalFallbackOrder(Map<String, dynamic> order) {
    if (order["createdLocally"] == true) return true;
    final source = (order["source"] ?? "").toString().trim().toLowerCase();
    if (source == "local_fallback") return true;
    final orderId = (order["orderId"] ?? "").toString().trim().toUpperCase();
    return orderId.startsWith("LOCAL-");
  }

  static bool isUnpaidPayLater(Map<String, dynamic> order) {
    final isPayLater = order["orderLater"] == true;
    final status = (order["status"] ?? "").toString().toLowerCase();
    final paidAt = (order["paidAt"] ?? "").toString();
    final isClosed = status == "collected" ||
        status == "rejected" ||
        status == "failed" ||
        status == "paid";
    return isPayLater && paidAt.isEmpty && !isClosed;
  }

  static Future<List<Map<String, dynamic>>> getPayLaterOrders() async {
    final orders = await getOrders();
    return orders.where((order) => order["orderLater"] == true).toList();
  }

  static Future<int> getUnpaidPayLaterCount() async {
    final orders = await getOrders();
    return orders.where(isUnpaidPayLater).length;
  }

  static Future<void> clearPayLaterDuesForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final paidAt = DateTime.now().toIso8601String();
    var changed = false;

    for (final order in orders) {
      if (!isUnpaidPayLater(order)) continue;
      order["orderLater"] = false;
      order["paidAt"] = paidAt;
      order["paymentMethod"] = "Test reset";
      if ((order["status"] ?? "").toString().toLowerCase() == "pending") {
        order["status"] = "accepted";
      }
      changed = true;
    }

    if (changed) {
      await prefs.setString(_key, jsonEncode(orders));
      _notifyChanged();
    }
  }

  static Future<String> addOrder({
    required Shop shop,
    required List<PdfData> pdfs,
    required bool payLater,
    String? orderId,
    String fulfillmentMode = 'Pickup',
    String pickupSlot = '',
    bool rushOrder = false,
    String deliveryAddress = '',
    String defaultPaymentMethod = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final hasCloudUser =
        CloudSyncGuard.cloudSyncEnabled && uid != null && uid.isNotEmpty;

    int totalPages = 0;
    double totalCost = 0;
    final items = <Map<String, dynamic>>[];

    for (final pdf in pdfs) {
      final pages = pdf.selectedPagesCount * pdf.copies;
      totalPages += pages;
      final rate = double.tryParse(
              shop.costBlack.isNotEmpty ? shop.costBlack : shop.costOneSide) ??
          2.0;
      final itemCost = pages * rate;
      totalCost += itemCost;
      items.add({
        "fileName": pdf.name,
        "downloadUrl": pdf.documents,
        "documentUrl": pdf.documents,
        "mimeType": _mimeTypeFromPdf(pdf),
        "fileSize": pdf.size,
        "copies": pdf.copies,
        "totalPages": pdf.selectedPagesCount,
        "pageRange": pdf.pageRange,
        "paperSize": pdf.paperSize,
        "printLayout": pdf.pdfPrintLayout,
        "binding": pdf.binding,
        "side": pdf.pdfSides,
        "itemColor": pdf.color,
        "notes": pdf.additionDesciption,
        "collateCopies": pdf.collateCopies,
        "numberCopies": pdf.numberCopies,
        "itemCost": itemCost,
      });
    }
    final fileNames = items
        .map((item) => (item['fileName'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final order = <String, dynamic>{
      "orderId": (orderId ?? '').trim().isEmpty ? _newOrderId(now) : orderId,
      "orderDate": now.toIso8601String(),
      "totalPages": totalPages,
      "totalCost": totalCost,
      "status": "pending",
      "createdLocally": !hasCloudUser,
      "source": hasCloudUser ? "cloud_client" : "local_fallback",
      "syncStatus": hasCloudUser ? "pending_cloud_sync" : "local_only",
      if (uid != null && uid.isNotEmpty) "userId": uid,
      "customerEmail": user?.email ?? "",
      "customerName": user?.displayName ?? user?.email ?? "",
      "orderLater": payLater,
      "paymentStatus": payLater ? "pending" : "paid",
      if (!payLater) "paidAt": now.toIso8601String(),
      "fulfillmentMode": fulfillmentMode,
      "pickupSlot": pickupSlot,
      "rushOrder": rushOrder,
      "deliveryAddress": deliveryAddress,
      "defaultPaymentMethod": defaultPaymentMethod,
      "storeId": shop.id,
      "storeName": shop.storeName,
      "storeAddress": shop.address,
      "storeLocationX": shop.locationX,
      "storeLocationY": shop.locationY,
      "storeEmail": shop.email,
      "storeContactNumber": shop.contactNumber,
      "storeOpeningTime": shop.openingTime,
      "storeClosingTime": shop.closingTime,
      "itemsCount": items.length,
      "primaryFileName": fileNames.isEmpty ? "Website upload" : fileNames.first,
      "fileNames": fileNames,
      "items": items,
    };

    orders.insert(0, order);
    await prefs.setString(_key, jsonEncode(orders));
    _notifyChanged();
    unawaited(_syncOrderToCloud(order));
    unawaited(
      OperationalOrderService.recordOrderReceived(
        order,
        source: 'demo_orders_store',
      ),
    );
    return order["orderId"] as String;
  }

  static Future<List<Map<String, dynamic>>> getStoreOrders({
    String? storeId,
    String? storeName,
    String? storeEmail,
    String? storeContactNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final local = _decodeLocalOrders(prefs.getString(_key));
    final sid = storeId?.trim() ?? '';
    final name = _matchText(storeName);
    final email = _matchText(storeEmail);
    final phone = _digits(storeContactNumber);
    final cloud = sid.isEmpty
        ? const <Map<String, dynamic>>[]
        : await _loadSharedCloudOrders(storeId: sid);
    var orders = _mergeOrders([...local, ...cloud]);
    if (cloud.isEmpty &&
        (sid.isNotEmpty || name.isNotEmpty || email.isNotEmpty)) {
      final broadCloud = await _loadRecentSharedCloudOrders();
      orders = _mergeOrders([...orders, ...broadCloud]);
    }
    if (cloud.isNotEmpty || orders.length != local.length) {
      unawaited(prefs.setString(_key, jsonEncode(orders)));
    }
    if (sid.isEmpty && name.isEmpty && email.isEmpty && phone.isEmpty) {
      return orders;
    }

    final matched = orders.where((order) {
      final orderStoreId = (order["storeId"] ?? "").toString().trim();
      if (sid.isNotEmpty && orderStoreId == sid) return true;
      if (name.isNotEmpty && _matchText(order["storeName"]) == name) {
        return true;
      }
      if (email.isNotEmpty && _matchText(order["storeEmail"]) == email) {
        return true;
      }
      if (phone.isNotEmpty && _digits(order["storeContactNumber"]) == phone) {
        return true;
      }
      return false;
    }).toList();

    // If store metadata was changed locally, avoid hiding every order.
    return matched.isEmpty ? orders : matched;
  }

  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? cancelReason,
  }) async {
    if (orderId.trim().isEmpty) return false;
    if (status.trim().toLowerCase() == "collected") {
      return deleteOrder(orderId: orderId);
    }
    final prefs = await SharedPreferences.getInstance();
    var orders = await getOrders();
    orders = await _ordersWithCloudFallback(orders, orderId);
    bool updated = false;
    String previousStatus = 'pending';
    Map<String, dynamic>? updatedOrder;
    final target = orderId.trim().toLowerCase();
    for (final order in orders) {
      final currentId =
          (order["orderId"] ?? "").toString().trim().toLowerCase();
      if (currentId == target) {
        previousStatus = (order["status"] ?? "pending").toString();
        order["status"] = status;
        if (cancelReason != null && cancelReason.trim().isNotEmpty) {
          order["cancelReason"] = cancelReason.trim();
        }
        order["updatedAt"] = DateTime.now().toIso8601String();
        updatedOrder = Map<String, dynamic>.from(order);
        updated = true;
        break;
      }
    }
    if (!updated) return false;
    await prefs.setString(_key, jsonEncode(orders));
    _notifyChanged();
    if (updatedOrder != null) {
      unawaited(_syncOrderToCloud(updatedOrder));
      unawaited(
        OperationalOrderService.recordStatusChange(
          order: updatedOrder,
          fromStatus: previousStatus,
          toStatus: status,
          actor: 'demo_orders_store',
        ),
      );
    }
    return true;
  }

  static Future<void> clearAllOrders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _notifyChanged();
  }

  static Future<bool> deleteOrder({
    required String orderId,
  }) async {
    final target = orderId.trim().toLowerCase();
    if (target.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    var orders = await getOrders();
    orders = await _ordersWithCloudFallback(orders, orderId);
    Map<String, dynamic>? updatedOrder;
    var updated = false;
    final now = DateTime.now().toIso8601String();
    for (final order in orders) {
      final currentId =
          (order["orderId"] ?? "").toString().trim().toLowerCase();
      if (currentId == target) {
        order["status"] = "collected";
        order["deletedFromActive"] = true;
        order["collectedAt"] = now;
        order["updatedAt"] = now;
        updatedOrder = Map<String, dynamic>.from(order);
        updated = true;
        break;
      }
    }
    if (!updated) return false;
    await prefs.setString(_key, jsonEncode(orders));
    _notifyChanged();
    if (updatedOrder != null) {
      unawaited(_syncOrderToCloud(updatedOrder));
      unawaited(
        OperationalOrderService.recordCollectedAndDeleted(
          updatedOrder,
          actor: 'demo_orders_store',
        ),
      );
    }
    return true;
  }

  static Future<bool> markPayLaterPaid({
    required String orderId,
    required String method,
  }) async {
    if (orderId.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    var orders = await getOrders();
    orders = await _ordersWithCloudFallback(orders, orderId);
    bool updated = false;
    Map<String, dynamic>? updatedOrder;
    for (final order in orders) {
      if ((order["orderId"] ?? "").toString() == orderId) {
        order["orderLater"] = false;
        order["paidAt"] = DateTime.now().toIso8601String();
        order["paymentMethod"] = method;
        if ((order["status"] ?? "").toString().toLowerCase() == "pending") {
          order["status"] = "accepted";
        }
        order["paymentStatus"] = "paid";
        order["updatedAt"] = DateTime.now().toIso8601String();
        updated = true;
        updatedOrder = order;
        break;
      }
    }
    if (!updated) return false;
    await prefs.setString(_key, jsonEncode(orders));
    _notifyChanged();
    if (updatedOrder != null) {
      unawaited(_syncOrderToCloud(updatedOrder));
      unawaited(
        OperationalOrderService.recordPaymentConfirmation(
          paymentId:
              'paylater_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
          orderId: orderId,
          amount: (updatedOrder["totalCost"] as num?)?.toDouble() ?? 0,
          method: method,
        ),
      );
    }
    return true;
  }
}
