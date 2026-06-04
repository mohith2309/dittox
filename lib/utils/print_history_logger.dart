import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrintHistoryLogger {
  static const String _key = 'print_history_log';
  static const int _maxLogs = 1000;
  
  final String shopId;
  List<PrintLogEntry> _logs = [];

  PrintHistoryLogger({required this.shopId});

  static Future<PrintHistoryLogger> create(String shopId) async {
    final logger = PrintHistoryLogger(shopId: shopId);
    await logger._loadLogs();
    return logger;
  }

  List<PrintLogEntry> get logs => List.unmodifiable(_logs);

  Future<void> log({
    required String action,
    required String orderId,
    String? jobId,
    Map<String, dynamic>? metadata,
    PrintLogLevel level = PrintLogLevel.info,
  }) async {
    final entry = PrintLogEntry(
      timestamp: DateTime.now(),
      shopId: shopId,
      action: action,
      orderId: orderId,
      jobId: jobId,
      metadata: metadata,
      level: level,
    );
    
    _logs.insert(0, entry);
    
    // Keep only last N logs
    if (_logs.length > _maxLogs) {
      _logs = _logs.sublist(0, _maxLogs);
    }
    
    await _saveLogs();
  }

  Future<void> logJobStarted(String orderId, String jobId, Map<String, dynamic> jobDetails) async {
    await log(
      action: 'JOB_STARTED',
      orderId: orderId,
      jobId: jobId,
      metadata: jobDetails,
      level: PrintLogLevel.info,
    );
  }

  Future<void> logJobCompleted(String orderId, String jobId, Map<String, dynamic> stats) async {
    await log(
      action: 'JOB_COMPLETED',
      orderId: orderId,
      jobId: jobId,
      metadata: stats,
      level: PrintLogLevel.success,
    );
  }

  Future<void> logJobFailed(String orderId, String jobId, String error) async {
    await log(
      action: 'JOB_FAILED',
      orderId: orderId,
      jobId: jobId,
      metadata: {'error': error},
      level: PrintLogLevel.error,
    );
  }

  Future<void> logOrderReceived(String orderId, Map<String, dynamic> orderDetails) async {
    await log(
      action: 'ORDER_RECEIVED',
      orderId: orderId,
      metadata: orderDetails,
      level: PrintLogLevel.info,
    );
  }

  Future<void> logOrderStatusChange(String orderId, String fromStatus, String toStatus) async {
    await log(
      action: 'STATUS_CHANGED',
      orderId: orderId,
      metadata: {'from': fromStatus, 'to': toStatus},
      level: PrintLogLevel.info,
    );
  }

  Future<void> logPrintProgress(String orderId, String jobId, int progress) async {
    await log(
      action: 'PROGRESS_UPDATE',
      orderId: orderId,
      jobId: jobId,
      metadata: {'progress': progress},
      level: PrintLogLevel.debug,
    );
  }

  List<PrintLogEntry> getLogsForOrder(String orderId) {
    return _logs.where((log) => log.orderId == orderId).toList();
  }

  List<PrintLogEntry> getLogsByAction(String action) {
    return _logs.where((log) => log.action == action).toList();
  }

  List<PrintLogEntry> getLogsByLevel(PrintLogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  List<PrintLogEntry> getErrorLogs() {
    return _logs.where((log) => log.level == PrintLogLevel.error).toList();
  }

  Map<String, int> getActionCounts() {
    final counts = <String, int>{};
    for (final log in _logs) {
      counts[log.action] = (counts[log.action] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _saveLogs();
  }

  Future<void> clearOldLogs({required DateTime olderThan}) async {
    _logs.removeWhere((log) => log.timestamp.isBefore(olderThan));
    await _saveLogs();
  }

  Future<String> exportLogs() async {
    return jsonEncode(_logs.map((e) => e.toJson()).toList());
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_key-$shopId');
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      _logs = decoded.map((e) => PrintLogEntry.fromJson(e)).toList();
    }
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_logs.map((e) => e.toJson()).toList());
    await prefs.setString('$_key-$shopId', json);
  }
}

enum PrintLogLevel { debug, info, success, warning, error }

class PrintLogEntry {
  final DateTime timestamp;
  final String shopId;
  final String action;
  final String orderId;
  final String? jobId;
  final Map<String, dynamic>? metadata;
  final PrintLogLevel level;

  PrintLogEntry({
    required this.timestamp,
    required this.shopId,
    required this.action,
    required this.orderId,
    this.jobId,
    this.metadata,
    this.level = PrintLogLevel.info,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'shopId': shopId,
    'action': action,
    'orderId': orderId,
    'jobId': jobId,
    'metadata': metadata,
    'level': level.name,
  };

  factory PrintLogEntry.fromJson(Map<String, dynamic> json) => PrintLogEntry(
    timestamp: DateTime.parse(json['timestamp']),
    shopId: json['shopId'],
    action: json['action'],
    orderId: json['orderId'],
    jobId: json['jobId'],
    metadata: json['metadata'],
    level: PrintLogLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => PrintLogLevel.info,
    ),
  );
}
