import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum OrderStatus {
  pending,
  accepted,
  printing,
  ready,
  pickedUp,
  completed,
  cancelled,
  failed,
}

class OrderStatusSync {
  final String shopId;
  final String baseUrl;
  Timer? _syncTimer;
  final List<OrderUpdateListener> _listeners = [];
  final Map<String, OrderStatus> _statusCache = {};
  int _syncIntervalSeconds = 30;
  final bool _isEnabled = true;

  OrderStatusSync({
    required this.shopId,
    this.baseUrl = 'https://api.dittox.in',
  });

  void addListener(OrderUpdateListener listener) {
    _listeners.add(listener);
  }

  void removeListener(OrderUpdateListener listener) {
    _listeners.remove(listener);
  }

  void startSync() {
    if (_syncTimer != null) return;
    
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) => _syncOrders(),
    );
    
    // Initial sync
    _syncOrders();
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void setSyncInterval(int seconds) {
    _syncIntervalSeconds = seconds;
    if (_syncTimer != null) {
      stopSync();
      startSync();
    }
  }

  Future<void> _syncOrders() async {
    if (!_isEnabled) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId/orders?status=active'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> orders = jsonDecode(response.body);
        
        for (final orderData in orders) {
          final orderId = orderData['orderId'];
          final newStatus = OrderStatus.values.firstWhere(
            (e) => e.name == orderData['status'],
            orElse: () => OrderStatus.pending,
          );
          
          final previousStatus = _statusCache[orderId];
          _statusCache[orderId] = newStatus;
          
          if (previousStatus != null && previousStatus != newStatus) {
            _notifyListeners(orderId, previousStatus, newStatus, orderData);
          }
        }
      }
    } catch (e) {
      debugPrint('Order sync error: $e');
    }
  }

  void _notifyListeners(String orderId, OrderStatus from, OrderStatus to, Map<String, dynamic> data) {
    for (final listener in _listeners) {
      listener.onOrderUpdated(orderId, from, to, data);
    }
  }

  OrderStatus? getStatus(String orderId) => _statusCache[orderId];

  Future<bool> updateOrderStatus(String orderId, OrderStatus status, {String? notes}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status.name,
          'shopId': shopId,
          'notes': notes,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _statusCache[orderId] = status;
        return true;
      }
    } catch (e) {
      debugPrint('Update status error: $e');
    }
    return false;
  }

  Future<void> syncSingleOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final orderData = jsonDecode(response.body);
        final newStatus = OrderStatus.values.firstWhere(
          (e) => e.name == orderData['status'],
          orElse: () => OrderStatus.pending,
        );
        
        _statusCache[orderId] = newStatus;
      }
    } catch (e) {
      debugPrint('Sync single order error: $e');
    }
  }

  void dispose() {
    stopSync();
    _listeners.clear();
  }
}

abstract class OrderUpdateListener {
  void onOrderUpdated(String orderId, OrderStatus from, OrderStatus to, Map<String, dynamic> data);
}

class OrderUpdateCallback implements OrderUpdateListener {
  final Function(String, OrderStatus, OrderStatus, Map<String, dynamic>) callback;

  OrderUpdateCallback(this.callback);

  @override
  void onOrderUpdated(String orderId, OrderStatus from, OrderStatus to, Map<String, dynamic> data) {
    callback(orderId, from, to, data);
  }
}

// Helper extension for status colors
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.printing:
        return 'Printing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.printing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.pickedUp:
        return 4;
      case OrderStatus.completed:
        return 5;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return -1;
    }
  }
}

void debugPrint(String message) {
  assert(() {
    // ignore: avoid_print
    print(message);
    return true;
  }());
}