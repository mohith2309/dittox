import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'cloud_sync_guard.dart';

class OperationalStatusChange {
  final String orderId;
  final String fromStatus;
  final String toStatus;
  final String reason;
  final Map<String, dynamic> order;

  const OperationalStatusChange({
    required this.orderId,
    required this.fromStatus,
    required this.toStatus,
    required this.reason,
    required this.order,
  });
}

class OperationalOrderProcessingResult {
  final List<Map<String, dynamic>> orders;
  final int duplicateCount;
  final int agingAlertCount;
  final int expiredCount;
  final List<OperationalStatusChange> statusChanges;

  const OperationalOrderProcessingResult({
    required this.orders,
    required this.duplicateCount,
    required this.agingAlertCount,
    required this.expiredCount,
    required this.statusChanges,
  });
}

class OperationalOrderService {
  static const String ordersCollection = 'operational_orders';
  static const String eventsCollection = 'operational_events';
  static const String webhookOutboxCollection = 'webhook_outbox';
  static const String notificationIntentsCollection = 'notification_intents';
  static const String printerQueueCollection = 'printer_queue';
  static const String paymentConfirmationsCollection = 'payment_confirmations';
  static const String paymentRetryCollection = 'payment_retry_queue';

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String orderIdOf(Map<String, dynamic> order) {
    final candidates = <dynamic>[
      order['orderId'],
      order['_id'],
      order['id'],
      order['razorpay_order_id'],
    ];
    for (final candidate in candidates) {
      final value = (candidate ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String normalizeStatus(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    if (raw.isEmpty) return 'pending';
    if (raw == 'in_printing' || raw == 'inprinting' || raw == 'in-progress') {
      return 'printing';
    }
    if (raw == 'done' || raw == 'completed' || raw == 'pickedup') {
      return 'collected';
    }
    if (raw == 'cancelled' || raw == 'canceled') return 'rejected';
    return raw;
  }

  static OperationalOrderProcessingResult processLoadedOrders({
    required List<Map<String, dynamic>> orders,
    required String shopId,
    int autoRejectAfterMinutes = 30,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final deduped = <String, Map<String, dynamic>>{};
    final duplicates = <Map<String, dynamic>>[];

    for (final rawOrder in orders) {
      final order = Map<String, dynamic>.from(rawOrder);
      final key = _dedupeKey(order);
      final existing = deduped[key];
      if (existing == null) {
        deduped[key] = order;
        continue;
      }

      duplicates.add(order);
      final existingDate = _orderDate(existing);
      final orderDate = _orderDate(order);
      if (orderDate.isAfter(existingDate)) {
        deduped[key] = order;
      }
    }

    for (final duplicate in duplicates) {
      unawaited(recordDuplicateOrder(duplicate, shopId: shopId));
    }

    var agingAlertCount = 0;
    var expiredCount = 0;
    final statusChanges = <OperationalStatusChange>[];
    final output = <Map<String, dynamic>>[];
    final timeout = autoRejectAfterMinutes <= 0 ? 30 : autoRejectAfterMinutes;
    final warningAfter = timeout <= 10 ? timeout : (timeout / 2).round();

    for (final entry in deduped.values) {
      final order = Map<String, dynamic>.from(entry);
      final status = normalizeStatus(order['status']);
      final age = clock.difference(_orderDate(order));
      final orderId = orderIdOf(order);
      final effectiveShopId = _shopIdOf(order, fallback: shopId);

      if (status == 'pending' && age.inMinutes >= timeout) {
        order['status'] = 'rejected';
        order['rejectionReason'] = 'auto_rejected_expired';
        order['operationalUpdatedAt'] = clock.toIso8601String();
        expiredCount++;
        statusChanges.add(
          OperationalStatusChange(
            orderId: orderId,
            fromStatus: status,
            toStatus: 'rejected',
            reason: 'order_aging_timeout',
            order: order,
          ),
        );
      } else if ((status == 'pending' || status == 'accepted') &&
          age.inMinutes >= warningAfter) {
        order['operationalAlert'] = 'aging';
        order['orderAgeMinutes'] = age.inMinutes;
        agingAlertCount++;
        unawaited(
          recordAgingAlert(
            order,
            shopId: effectiveShopId,
            ageMinutes: age.inMinutes,
          ),
        );
      }

      output.add(order);
    }

    return OperationalOrderProcessingResult(
      orders: output,
      duplicateCount: duplicates.length,
      agingAlertCount: agingAlertCount,
      expiredCount: expiredCount,
      statusChanges: statusChanges,
    );
  }

  static Future<void> recordOrderReceived(
    Map<String, dynamic> order, {
    String source = 'client',
  }) async {
    final orderId = orderIdOf(order);
    if (orderId.isEmpty) return;
    final shopId = _shopIdOf(order);
    final payload = _cleanOrderPayload(order);

    await CloudSyncGuard.runOptionalWrite(() async {
      final batch = _db.batch();
      final orderRef = _db.collection(ordersCollection).doc(orderId);
      batch.set(
        orderRef,
        {
          ...payload,
          'orderId': orderId,
          'shopId': shopId,
          'status': normalizeStatus(order['status']),
          'source': source,
          'receivedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _setEventInBatch(
        batch,
        type: 'order.received',
        orderId: orderId,
        shopId: shopId,
        payload: payload,
        dedupeSuffix: source,
      );
      _setWebhookInBatch(
        batch,
        type: 'order.received',
        orderId: orderId,
        shopId: shopId,
        payload: payload,
        dedupeSuffix: source,
      );
      await batch.commit();
    });
  }

  static Future<void> recordStatusChange({
    required Map<String, dynamic> order,
    required String fromStatus,
    required String toStatus,
    String actor = 'client',
    String reason = 'manual',
  }) async {
    final orderId = orderIdOf(order);
    if (orderId.isEmpty) return;
    final shopId = _shopIdOf(order);
    final normalizedFrom = normalizeStatus(fromStatus);
    final normalizedTo = normalizeStatus(toStatus);
    final payload = _cleanOrderPayload(order);
    final eventPayload = {
      ...payload,
      'fromStatus': normalizedFrom,
      'toStatus': normalizedTo,
      'actor': actor,
      'reason': reason,
    };

    await CloudSyncGuard.runOptionalWrite(() async {
      final batch = _db.batch();
      batch.set(
        _db.collection(ordersCollection).doc(orderId),
        {
          ...payload,
          'orderId': orderId,
          'shopId': shopId,
          'status': normalizedTo,
          'updatedAt': FieldValue.serverTimestamp(),
          if (normalizedTo == 'collected') 'deletedFromActive': true,
        },
        SetOptions(merge: true),
      );

      _setEventInBatch(
        batch,
        type: 'order.status_changed',
        orderId: orderId,
        shopId: shopId,
        payload: eventPayload,
        dedupeSuffix: '$normalizedFrom-$normalizedTo-$reason',
      );
      _setWebhookInBatch(
        batch,
        type: 'order.status_changed',
        orderId: orderId,
        shopId: shopId,
        payload: eventPayload,
        dedupeSuffix: '$normalizedFrom-$normalizedTo-$reason',
      );
      _setNotificationIntentInBatch(
        batch,
        orderId: orderId,
        shopId: shopId,
        channel: 'push',
        title: 'Order $normalizedTo',
        body: 'Order $orderId moved from $normalizedFrom to $normalizedTo.',
        payload: eventPayload,
        dedupeSuffix: '$normalizedFrom-$normalizedTo-push',
      );
      _setNotificationIntentInBatch(
        batch,
        orderId: orderId,
        shopId: shopId,
        channel: 'email',
        title: 'Dittox order update',
        body: 'Order $orderId is now $normalizedTo.',
        payload: eventPayload,
        dedupeSuffix: '$normalizedFrom-$normalizedTo-email',
      );
      _setNotificationIntentInBatch(
        batch,
        orderId: orderId,
        shopId: shopId,
        channel: 'sms',
        title: 'Dittox',
        body: 'Order $orderId: $normalizedTo.',
        payload: eventPayload,
        dedupeSuffix: '$normalizedFrom-$normalizedTo-sms',
      );
      await batch.commit();
    });
  }

  static Future<void> recordCollectedAndDeleted(
    Map<String, dynamic> order, {
    String actor = 'client',
  }) {
    return recordStatusChange(
      order: order,
      fromStatus: normalizeStatus(order['status']),
      toStatus: 'collected',
      actor: actor,
      reason: 'collected_delete_active_order',
    );
  }

  static Future<void> batchUpdateStatuses({
    required List<Map<String, dynamic>> orders,
    required String toStatus,
    String actor = 'client',
    String reason = 'batch_update',
  }) async {
    for (final order in orders) {
      await recordStatusChange(
        order: order,
        fromStatus: normalizeStatus(order['status']),
        toStatus: toStatus,
        actor: actor,
        reason: reason,
      );
    }
  }

  static Future<void> enqueuePrinterJobForOrder({
    required Map<String, dynamic> order,
    required String printerId,
    required String printerName,
    String priority = 'normal',
  }) async {
    final orderId = orderIdOf(order);
    if (orderId.isEmpty) return;
    final shopId = _shopIdOf(order);
    final totalPages = _asInt(order['totalPages']);
    final jobId = _safeDocId(
        '$orderId-$printerId-${DateTime.now().millisecondsSinceEpoch}');

    await CloudSyncGuard.runOptionalWrite(() async {
      final batch = _db.batch();
      batch.set(
        _db.collection(printerQueueCollection).doc(jobId),
        {
          'jobId': jobId,
          'orderId': orderId,
          'shopId': shopId,
          'printerId': printerId,
          'printerName': printerName,
          'priority': priority,
          'totalPages': totalPages,
          'status': 'queued',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'payload': _cleanOrderPayload(order),
        },
      );
      _setEventInBatch(
        batch,
        type: 'printer.job_queued',
        orderId: orderId,
        shopId: shopId,
        payload: {
          'printerId': printerId,
          'printerName': printerName,
          'priority': priority,
          'totalPages': totalPages,
        },
        dedupeSuffix: jobId,
      );
      await batch.commit();
    });
  }

  static Future<void> recordPaymentConfirmation({
    required String paymentId,
    required double amount,
    String? orderId,
    String method = 'razorpay',
    String status = 'confirmed',
  }) async {
    final cleanPaymentId = paymentId.trim();
    if (cleanPaymentId.isEmpty) return;
    final docId = _safeDocId(cleanPaymentId);

    await CloudSyncGuard.runOptionalWrite(() async {
      await _db.collection(paymentConfirmationsCollection).doc(docId).set({
        'paymentId': cleanPaymentId,
        'orderId': orderId?.trim() ?? '',
        'amount': amount,
        'method': method,
        'status': status,
        'confirmedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> scheduleFailedPaymentRetry({
    required String reason,
    double amount = 0,
    String? orderId,
    String? paymentId,
    int retryAttempt = 1,
  }) async {
    final retryId = _safeDocId(
      '${orderId ?? paymentId ?? 'payment'}-$retryAttempt-${DateTime.now().millisecondsSinceEpoch}',
    );

    await CloudSyncGuard.runOptionalWrite(() async {
      await _db.collection(paymentRetryCollection).doc(retryId).set({
        'retryId': retryId,
        'orderId': orderId?.trim() ?? '',
        'paymentId': paymentId?.trim() ?? '',
        'amount': amount,
        'reason': reason,
        'retryAttempt': retryAttempt,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'nextRetryAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 2 * retryAttempt)),
        ),
      });
    });
  }

  static Future<void> recordDuplicateOrder(
    Map<String, dynamic> order, {
    required String shopId,
  }) async {
    final orderId = orderIdOf(order);
    final dedupeKey = _dedupeKey(order);

    await CloudSyncGuard.runOptionalWrite(() async {
      await _db
          .collection(eventsCollection)
          .doc(
            _eventDocId('order.duplicate_detected', orderId, dedupeKey),
          )
          .set({
        'type': 'order.duplicate_detected',
        'orderId': orderId,
        'shopId': _shopIdOf(order, fallback: shopId),
        'dedupeKey': dedupeKey,
        'payload': _cleanOrderPayload(order),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> recordAgingAlert(
    Map<String, dynamic> order, {
    required String shopId,
    required int ageMinutes,
  }) async {
    final orderId = orderIdOf(order);
    if (orderId.isEmpty) return;
    final bucket = (ageMinutes / 5).floor() * 5;

    await CloudSyncGuard.runOptionalWrite(() async {
      final batch = _db.batch();
      _setEventInBatch(
        batch,
        type: 'order.aging_alert',
        orderId: orderId,
        shopId: _shopIdOf(order, fallback: shopId),
        payload: {
          'ageMinutes': ageMinutes,
          'status': normalizeStatus(order['status']),
          'order': _cleanOrderPayload(order),
        },
        dedupeSuffix: 'bucket_$bucket',
      );
      _setNotificationIntentInBatch(
        batch,
        orderId: orderId,
        shopId: _shopIdOf(order, fallback: shopId),
        channel: 'push',
        title: 'Order waiting',
        body: 'Order $orderId has been waiting for $ageMinutes minutes.',
        payload: _cleanOrderPayload(order),
        dedupeSuffix: 'aging_bucket_$bucket',
      );
      await batch.commit();
    });
  }

  static String _dedupeKey(Map<String, dynamic> order) {
    final orderId = orderIdOf(order);
    if (orderId.isNotEmpty) return _safeDocId('id_$orderId');
    return _safeDocId([
      _shopIdOf(order),
      (order['orderDate'] ?? order['createdAt'] ?? '').toString(),
      _asInt(order['totalPages']),
      _asDouble(order['totalCost']).toStringAsFixed(2),
      _asInt(order['itemsCount']),
    ].join('_'));
  }

  static DateTime _orderDate(Map<String, dynamic> order) {
    final candidates = <dynamic>[
      order['orderDate'],
      order['createdAt'],
      order['receivedAt'],
      order['updatedAt'],
    ];
    for (final candidate in candidates) {
      if (candidate is Timestamp) return candidate.toDate();
      final parsed = DateTime.tryParse((candidate ?? '').toString());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static String _shopIdOf(
    Map<String, dynamic> order, {
    String fallback = '',
  }) {
    final value = (order['storeId'] ?? order['shopId'] ?? fallback).toString();
    return value.trim();
  }

  static Map<String, dynamic> _cleanOrderPayload(Map<String, dynamic> order) {
    final clean = <String, dynamic>{};
    for (final entry in order.entries) {
      final key = entry.key.toString();
      if (key.trim().isEmpty) continue;
      final value = entry.value;
      if (value == null ||
          value is String ||
          value is num ||
          value is bool ||
          value is Timestamp ||
          value is List ||
          value is Map) {
        clean[key] = value;
      } else {
        clean[key] = value.toString();
      }
    }
    return clean;
  }

  static void _setEventInBatch(
    WriteBatch batch, {
    required String type,
    required String orderId,
    required String shopId,
    required Map<String, dynamic> payload,
    required String dedupeSuffix,
  }) {
    batch.set(
      _db
          .collection(eventsCollection)
          .doc(_eventDocId(type, orderId, dedupeSuffix)),
      {
        'type': type,
        'orderId': orderId,
        'shopId': shopId,
        'payload': payload,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static void _setWebhookInBatch(
    WriteBatch batch, {
    required String type,
    required String orderId,
    required String shopId,
    required Map<String, dynamic> payload,
    required String dedupeSuffix,
  }) {
    batch.set(
      _db
          .collection(webhookOutboxCollection)
          .doc(_eventDocId(type, orderId, dedupeSuffix)),
      {
        'type': type,
        'orderId': orderId,
        'shopId': shopId,
        'payload': payload,
        'status': 'pending',
        'attempts': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static void _setNotificationIntentInBatch(
    WriteBatch batch, {
    required String orderId,
    required String shopId,
    required String channel,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    required String dedupeSuffix,
  }) {
    batch.set(
      _db
          .collection(notificationIntentsCollection)
          .doc(_eventDocId('notification.$channel', orderId, dedupeSuffix)),
      {
        'orderId': orderId,
        'shopId': shopId,
        'channel': channel,
        'title': title,
        'body': body,
        'payload': payload,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static String _eventDocId(String type, String orderId, String suffix) {
    return _safeDocId('$type-$orderId-$suffix');
  }

  static String _safeDocId(String raw) {
    final safe = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safe.isEmpty) return DateTime.now().millisecondsSinceEpoch.toString();
    return safe.length <= 180 ? safe : safe.substring(0, 180);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static void logSkipped(String feature, Object error) {
    debugPrint('Operational feature skipped: $feature ($error)');
  }
}
