import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PrintJobStatus {
  pending,
  queued,
  printing,
  completed,
  failed,
  cancelled,
}

enum PrintJobPriority {
  low,
  normal,
  high,
  urgent,
}

class PrintJob {
  final String id;
  final String orderId;
  final String customerId;
  final String shopId;
  final List<String> filePaths;
  final int totalPages;
  final int copies;
  final String quality;
  final String size;
  final String side;
  final String colorMode;
  final String binding;
  final double cost;
  PrintJobStatus status;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;
  int printProgress;
  String? errorMessage;
  int retryCount;

  PrintJob({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.shopId,
    required this.filePaths,
    required this.totalPages,
    required this.copies,
    required this.quality,
    required this.size,
    required this.side,
    required this.colorMode,
    required this.binding,
    required this.cost,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.printProgress = 0,
    this.errorMessage,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'customerId': customerId,
    'shopId': shopId,
    'filePaths': filePaths,
    'totalPages': totalPages,
    'copies': copies,
    'quality': quality,
    'size': size,
    'side': side,
    'colorMode': colorMode,
    'binding': binding,
    'cost': cost,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'printProgress': printProgress,
    'errorMessage': errorMessage,
    'retryCount': retryCount,
  };

  factory PrintJob.fromJson(Map<String, dynamic> json) => PrintJob(
    id: json['id'],
    orderId: json['orderId'],
    customerId: json['customerId'],
    shopId: json['shopId'],
    filePaths: List<String>.from(json['filePaths']),
    totalPages: json['totalPages'],
    copies: json['copies'],
    quality: json['quality'],
    size: json['size'],
    side: json['side'],
    colorMode: json['colorMode'],
    binding: json['binding'],
    cost: json['cost'].toDouble(),
    status: PrintJobStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => PrintJobStatus.pending,
    ),
    createdAt: DateTime.parse(json['createdAt']),
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    printProgress: json['printProgress'] ?? 0,
    errorMessage: json['errorMessage'],
    retryCount: json['retryCount'] ?? 0,
  );

  String get uniqueJobCode => '${orderId.substring(0, 3).toUpperCase()}-${id.substring(0, 6).toUpperCase()}';
}

class PrintJobManager {
  static const String _queueKey = 'print_job_queue';
  static const String _historyKey = 'print_job_history';
  static const String _activeKey = 'print_job_active';
  static const int _maxRetries = 3;
  
  final String shopId;
  List<PrintJob> _queue = [];
  PrintJob? _activeJob;
  final List<PrintJob> _history = [];

  PrintJobManager({required this.shopId});

  static Future<PrintJobManager> create(String shopId) async {
    final manager = PrintJobManager(shopId: shopId);
    await manager._loadFromStorage();
    return manager;
  }

  List<PrintJob> get queue => List.unmodifiable(_queue);
  PrintJob? get activeJob => _activeJob;
  List<PrintJob> get history => List.unmodifiable(_history);
  bool get hasActiveJob => _activeJob != null;

  Future<void> addJob({
    required String orderId,
    required String customerId,
    required List<String> filePaths,
    required int totalPages,
    required int copies,
    required String quality,
    required String size,
    required String side,
    required String colorMode,
    required String binding,
    required double cost,
  }) async {
    final job = PrintJob(
      id: '${DateTime.now().millisecondsSinceEpoch}_${customerId.hashCode}',
      orderId: orderId,
      customerId: customerId,
      shopId: shopId,
      filePaths: filePaths,
      totalPages: totalPages,
      copies: copies,
      quality: quality,
      size: size,
      side: side,
      colorMode: colorMode,
      binding: binding,
      cost: cost,
      status: PrintJobStatus.pending,
      createdAt: DateTime.now(),
    );
    
    _queue.add(job);
    _queue.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    await _saveQueue();
    await _logAction('job_added', job);
  }

  Future<PrintJob?> startNextJob() async {
    if (_activeJob != null) {
      throw Exception('Cannot start new job - printer is busy with: ${_activeJob!.orderId}');
    }
    
    if (_queue.isEmpty) return null;
    
    final job = _queue.removeAt(0);
    job.status = PrintJobStatus.queued;
    job.startedAt = DateTime.now();
    _activeJob = job;
    
    await _saveActiveJob();
    await _saveQueue();
    await _logAction('job_started', job);
    
    return job;
  }

  Future<void> updateProgress(int progress) async {
    if (_activeJob == null) return;
    
    _activeJob!.printProgress = progress;
    await _saveActiveJob();
  }

  Future<void> completeJob() async {
    if (_activeJob == null) return;
    
    _activeJob!.status = PrintJobStatus.completed;
    _activeJob!.completedAt = DateTime.now();
    _activeJob!.printProgress = 100;
    
    _history.add(_activeJob!);
    _activeJob = null;
    
    await _saveActiveJob();
    await _saveHistory();
    await _logAction('job_completed', _history.last);
  }

  Future<void> failJob(String error) async {
    if (_activeJob == null) return;
    
    _activeJob!.retryCount++;
    _activeJob!.errorMessage = error;
    
    if (_activeJob!.retryCount < _maxRetries) {
      // Re-queue for retry
      _activeJob!.status = PrintJobStatus.pending;
      _activeJob!.printProgress = 0;
      _queue.insert(0, _activeJob!);
    } else {
      _activeJob!.status = PrintJobStatus.failed;
      _history.add(_activeJob!);
      await _logAction('job_failed', _activeJob!);
    }
    
    _activeJob = null;
    await _saveActiveJob();
    await _saveQueue();
    await _saveHistory();
  }

  Future<void> cancelJob(String jobId) async {
    // Remove from queue
    _queue.removeWhere((j) => j.id == jobId);
    
    // Cancel active if it matches
    if (_activeJob?.id == jobId) {
      _activeJob!.status = PrintJobStatus.cancelled;
      _activeJob!.completedAt = DateTime.now();
      _history.add(_activeJob!);
      _activeJob = null;
      await _saveActiveJob();
      await _saveHistory();
    }
    
    await _saveQueue();
    await _logAction('job_cancelled', {'jobId': jobId});
  }

  PrintJob? getJobById(String jobId) {
    if (_activeJob?.id == jobId) return _activeJob;
    return _queue.cast<PrintJob?>().firstWhere(
      (j) => j?.id == jobId,
      orElse: () => null,
    ) ?? _history.cast<PrintJob?>().firstWhere(
      (j) => j?.id == jobId,
      orElse: () => null,
    );
  }

  PrintJob? getJobByOrderId(String orderId) {
    if (_activeJob?.orderId == orderId) return _activeJob;
    return _queue.cast<PrintJob?>().firstWhere(
      (j) => j?.orderId == orderId,
      orElse: () => null,
    ) ?? _history.cast<PrintJob?>().firstWhere(
      (j) => j?.orderId == orderId,
      orElse: () => null,
    );
  }

  Future<void> clearHistory({DateTime? olderThan}) async {
    if (olderThan != null) {
      _history.removeWhere((j) => j.completedAt?.isBefore(olderThan) ?? false);
    } else {
      _history.clear();
    }
    await _saveHistory();
  }

  // Storage methods
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load queue
    final queueJson = prefs.getString('$_queueKey-$shopId');
    if (queueJson != null) {
      final List<dynamic> decoded = jsonDecode(queueJson);
      _queue = decoded.map((e) => PrintJob.fromJson(e)).toList();
    }
    
    // Load active job
    final activeJson = prefs.getString('$_activeKey-$shopId');
    if (activeJson != null && activeJson.isNotEmpty && activeJson != 'null') {
      _activeJob = PrintJob.fromJson(jsonDecode(activeJson));
    }
    
    // Load history
    final historyJson = prefs.getString('$_historyKey-$shopId');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _history.addAll(decoded.map((e) => PrintJob.fromJson(e)));
    }
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_queue.map((e) => e.toJson()).toList());
    await prefs.setString('$_queueKey-$shopId', json);
  }

  Future<void> _saveActiveJob() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeJob != null) {
      await prefs.setString('$_activeKey-$shopId', jsonEncode(_activeJob!.toJson()));
    } else {
      await prefs.setString('$_activeKey-$shopId', 'null');
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_history.map((e) => e.toJson()).toList());
    await prefs.setString('$_historyKey-$shopId', json);
  }

  Future<void> _logAction(String action, dynamic data) async {
    // Log for debugging and analytics
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'action': action,
      'shopId': shopId,
      'data': data is PrintJob ? data.toJson() : data,
    };
    debugPrint('PrintJobManager: ${jsonEncode(logEntry)}');
  }
}