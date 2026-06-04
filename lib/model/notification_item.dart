class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String priority;
  final DateTime timestamp;
  final String? orderId;
  final String? storeId;
  String status;
  final int autoDismissMs;

  static const String typeOrderUpdate = 'orderUpdate';
  static const String typeStoreAlert = 'storeAlert';
  static const String typeOffer = 'offer';
  static const String typeError = 'error';
  static const String typeInfo = 'info';
  static const String typeSuccess = 'success';
  static const String typeWarning = 'warning';

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = 'medium',
    required this.timestamp,
    this.orderId,
    this.storeId,
    this.status = 'visible',
    this.autoDismissMs = 5000,
  });

  Duration get autoDismissDuration => Duration(milliseconds: autoDismissMs);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'priority': priority,
        'timestamp': timestamp.toIso8601String(),
        'orderId': orderId,
        'storeId': storeId,
        'status': status,
        'autoDismissMs': autoDismissMs,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: json['type'] ?? 'orderUpdate',
        priority: json['priority'] ?? 'medium',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        orderId: json['orderId'],
        storeId: json['storeId'],
        status: json['status'] ?? 'visible',
        autoDismissMs: json['autoDismissMs'] ?? 5000,
      );
}