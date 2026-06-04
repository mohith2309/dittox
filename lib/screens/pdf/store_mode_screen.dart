import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_notifications.dart';
import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/security_utils.dart';
import '../../utils/shop_auto_mode_store.dart';
import '../../utils/store_auth_store.dart';
import '../../utils/printer_service.dart';
import '../../utils/operational_order_service.dart';
import '../../widgets/store/printer_selection_sheet.dart';

import 'store_login_screen.dart';
import 'shop_auto_mode_screen.dart';
import 'print_queue_screen.dart';

class StoreModeScreen extends StatefulWidget {
  static const routeName = "/storeMode";
  const StoreModeScreen({super.key});

  @override
  State<StoreModeScreen> createState() => _StoreModeScreenState();
}

class _StoreModeScreenState extends State<StoreModeScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isActionBusy = false;
  bool _autoRefreshEnabled = false;
  bool _needsLogin = false;
  String _loadError = "";
  Timer? _autoRefreshTimer;
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  String _statusFilter = "all";
  String _orderQuery = "";
  String _linkedStoreId = "";
  String _storeName = "";
  int _autoRefreshSeconds = 15;
  String _sortBy = "newest";

  static const List<String> _filters = <String>[
    "all",
    "pending",
    "accepted",
    "printing",
    "ready",
    "collected",
    "rejected",
  ];
  static const List<String> _allOrderStatuses = <String>[
    "pending",
    "accepted",
    "printing",
    "ready",
    "collected",
    "rejected",
  ];
  static const List<int> _autoRefreshOptions = <int>[10, 15, 30, 60];
  static const String _defaultAutoModeKey = "_global_store";

  void _notifyInfo(String message) {
    if (!mounted) return;
    context
        .read<AppNotifications>()
        .addInfo(title: "Store Mode", body: message);
  }

  void _notifySuccess(String message) {
    if (!mounted) return;
    context
        .read<AppNotifications>()
        .addSuccess(title: "Store Mode", body: message);
  }

  void _notifyWarning(String message) {
    if (!mounted) return;
    context
        .read<AppNotifications>()
        .addWarning(title: "Store Mode", body: message);
  }

  void _notifyError(String message) {
    if (!mounted) return;
    context
        .read<AppNotifications>()
        .addError(title: "Store Mode", body: message);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<String> _readAccessToken({SharedPreferences? prefs}) async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      final token = (sp.getString("AccessToken") ?? "").trim();
      return token;
    } catch (_) {
      return "";
    }
  }

  List<Map<String, dynamic>> _normalizedFromCachePayload(dynamic payload) {
    if (payload is! Map<String, dynamic>) return <Map<String, dynamic>>[];
    final rawOrders = payload["orders"];
    if (rawOrders is! List) return <Map<String, dynamic>>[];
    final out = <Map<String, dynamic>>[];
    for (final each in rawOrders) {
      if (each is Map) out.add(Map<String, dynamic>.from(each));
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> _readCachedOrdersFromPrefs({
    SharedPreferences? prefs,
    required String accessToken,
  }) async {
    try {
      final sp = prefs ?? await SharedPreferences.getInstance();
      final token = accessToken.trim();
      if (token.isEmpty) return <Map<String, dynamic>>[];
      final keys = <String>[
        "dittox_orders_cache_v1::ongoing::$token",
        "dittox_orders_cache_v1::paylater::$token",
      ];
      final all = <Map<String, dynamic>>[];
      for (final key in keys) {
        final raw = sp.getString(key);
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = json.decode(raw);
          all.addAll(_normalizedFromCachePayload(decoded));
        } catch (_) {
          continue;
        }
      }
      return all;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  List<Map<String, dynamic>> _normalizeRemoteOrders(dynamic payload) {
    final remoteOrders = <Map<String, dynamic>>[];
    if (payload is! Map<String, dynamic>) return remoteOrders;
    if (payload['responseCode'] != 'OK') return remoteOrders;

    final result = payload["result"];
    final list = result is Map<String, dynamic>
        ? ((result["data"] as List?) ?? <dynamic>[])
        : <dynamic>[];

    for (final eachOrder in list) {
      if (eachOrder is! Map) continue;
      final orderMap = Map<String, dynamic>.from(eachOrder);
      final itemsRaw = (orderMap["items"] as List?) ?? <dynamic>[];
      remoteOrders.add(<String, dynamic>{
        "orderId": (orderMap["orderId"] ?? "").toString(),
        "orderDate": (orderMap["createdAt"] ?? "").toString(),
        "totalPages": orderMap["totalPages"] ?? 0,
        "totalCost": orderMap["totalCost"] ?? 0,
        "status": _normalizedStatus(orderMap["status"]),
        "storeId": (orderMap["storeId"] ?? "").toString(),
        "storeName": (orderMap["storeName"] ?? "Store").toString(),
        "storeAddress": (orderMap["storeAddress"] ?? "").toString(),
        "itemsCount": itemsRaw.length,
        "items": itemsRaw.map((item) {
          if (item is! Map) return <String, dynamic>{};
          final m = Map<String, dynamic>.from(item);
          return <String, dynamic>{
            "downloadUrl": m["documents"],
            "copies": m["copies"],
            "totalPages": m["totalPages"],
            "itemCost": m["cost"],
          };
        }).toList(),
      });
    }

    return remoteOrders;
  }

  String _normalizedStatus(dynamic value) {
    final raw = (value ?? "").toString().trim().toLowerCase();
    if (raw.isEmpty) return "pending";
    if (raw == "in_printing" || raw == "inprinting" || raw == "in-progress") {
      return "printing";
    }
    if (raw == "done" || raw == "completed") return "collected";
    if (raw == "cancelled") return "rejected";
    return raw;
  }

  Future<List<Map<String, dynamic>>> _collectAllOrders() async {
    final prefsFuture = SharedPreferences.getInstance();
    final prefs = await prefsFuture;
    final token = await _readAccessToken(prefs: prefs);
    final cachedOrders = await _readCachedOrdersFromPrefs(
      prefs: prefs,
      accessToken: token,
    );

    final localRaw = await DemoOrdersStore.getOrders();
    final localAndCloudOrders =
        localRaw.map((e) => Map<String, dynamic>.from(e)).where((order) {
      final status = _normalizedStatus(order["status"]);
      return status != "collected";
    }).toList();

    if (token.isEmpty || token == "demo_token") {
      return [...localAndCloudOrders, ...cachedOrders];
    }

    try {
      final uri =
          SecurityUtils.safeWebUri('${ApiEndPoiunts.baseUrl}/orders/list');
      if (uri == null) return [...localAndCloudOrders, ...cachedOrders];

      final response = await http
          .get(
            uri,
            headers: SecurityUtils.authHeaders(token),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) {
        return [...localAndCloudOrders, ...cachedOrders];
      }
      final decoded = json.decode(response.body);
      final remoteOrders = _normalizeRemoteOrders(decoded);

      final merged = <String, Map<String, dynamic>>{};
      for (final o in [
        ...localAndCloudOrders,
        ...cachedOrders,
        ...remoteOrders
      ]) {
        final key = (o["orderId"] ?? "").toString().trim().isNotEmpty
            ? (o["orderId"] ?? "").toString().trim()
            : (o["orderDate"] ?? DateTime.now().toIso8601String()).toString();
        merged[key] = o;
      }
      final mergedList = merged.values.toList();
      mergedList.removeWhere(
          (order) => _normalizedStatus(order["status"]) == "collected");
      return mergedList;
    } catch (_) {
      return [...localAndCloudOrders, ...cachedOrders];
    }
  }

  Future<List<Map<String, dynamic>>> _applyAutoModeRules(
    List<Map<String, dynamic>> orders,
    String linkedStoreId,
  ) async {
    if (linkedStoreId.trim().isEmpty) return orders;
    final settings = await ShopAutoModeStore.getAllSettings(linkedStoreId);
    final autoAccept = settings['autoAccept'] == true;
    final autoPrint = settings['autoPrint'] == true;
    if (!autoAccept && !autoPrint) return orders;

    var changed = false;
    final output = <Map<String, dynamic>>[];
    for (final item in orders) {
      final order = Map<String, dynamic>.from(item);
      final status = _normalizedStatus(order["status"]);

      if (autoAccept && status == "pending") {
        order["status"] = "accepted";
        final id = (order["orderId"] ?? "").toString();
        if (id.isNotEmpty) {
          await DemoOrdersStore.updateOrderStatus(
              orderId: id, status: "accepted");
        }
        changed = true;
      }

      if (autoPrint && _normalizedStatus(order["status"]) == "accepted") {
        order["status"] = "printing";
        final id = (order["orderId"] ?? "").toString();
        if (id.isNotEmpty) {
          await DemoOrdersStore.updateOrderStatus(
              orderId: id, status: "printing");
        }
        changed = true;
      }

      output.add(order);
    }

    if (changed) {
      if (autoAccept && autoPrint) {
        _notifyInfo("Auto Mode moved pending orders into printing.");
      } else if (autoAccept) {
        _notifyInfo("Auto Mode accepted pending orders.");
      } else {
        _notifyInfo("Auto Mode started printing accepted orders.");
      }
    }
    return output;
  }

  Future<List<Map<String, dynamic>>> _applyOperationalRules(
    List<Map<String, dynamic>> orders,
    String shopId,
  ) async {
    final settings = await ShopAutoModeStore.getAllSettings(shopId);
    final autoRejectAfter = (settings['autoRejectTimeout'] as int?) ?? 30;
    final result = OperationalOrderService.processLoadedOrders(
      orders: orders,
      shopId: shopId,
      autoRejectAfterMinutes: autoRejectAfter,
    );

    for (final change in result.statusChanges) {
      if (change.orderId.trim().isEmpty) continue;
      unawaited(
        DemoOrdersStore.updateOrderStatus(
          orderId: change.orderId,
          status: change.toStatus,
        ),
      );
      unawaited(
        OperationalOrderService.recordStatusChange(
          order: change.order,
          fromStatus: change.fromStatus,
          toStatus: change.toStatus,
          actor: 'store_mode',
          reason: change.reason,
        ),
      );
    }

    if (result.expiredCount > 0) {
      _notifyWarning(
        'Auto-rejected ${result.expiredCount} expired order(s).',
      );
    }
    if (result.duplicateCount > 0) {
      _notifyInfo(
        'Hidden ${result.duplicateCount} duplicate order(s) from this view.',
      );
    }

    return result.orders;
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _isRefreshing = false;
        _loadError = "";
      });
    } else {
      if (mounted) {
        setState(() {
          _isRefreshing = true;
          _loadError = "";
        });
      } else {
        _loadError = "";
      }
    }
    try {
      final active = await StoreAuthStore.getActiveStore();
      if (active == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _needsLogin = true;
        });
        return;
      }
      _needsLogin = false;
      final linkedStoreId = (active["linkedStoreId"] ?? "").toString();
      final autoModeKey = linkedStoreId.trim().isEmpty
          ? _defaultAutoModeKey
          : linkedStoreId.trim();
      final storeName = (active["storeName"] ?? "Store").toString();
      final allOrders = await _collectAllOrders();
      List<Map<String, dynamic>> data = allOrders;
      if (linkedStoreId.trim().isNotEmpty) {
        final linked = linkedStoreId.trim().toLowerCase();
        final filtered = allOrders.where((order) {
          final orderStoreId =
              (order["storeId"] ?? "").toString().toLowerCase();
          return orderStoreId == linked;
        }).toList();
        if (filtered.isNotEmpty) {
          data = filtered;
        }
      }
      data = data
          .where((order) => _normalizedStatus(order["status"]) != "collected")
          .toList();
      data = await _applyOperationalRules(data, autoModeKey);
      data = await _applyAutoModeRules(data, autoModeKey);
      if (_sortBy == "amount_desc") {
        data.sort((a, b) {
          final aCost = (a["totalCost"] as num?)?.toDouble() ?? 0;
          final bCost = (b["totalCost"] as num?)?.toDouble() ?? 0;
          return bCost.compareTo(aCost);
        });
      } else if (_sortBy == "amount_asc") {
        data.sort((a, b) {
          final aCost = (a["totalCost"] as num?)?.toDouble() ?? 0;
          final bCost = (b["totalCost"] as num?)?.toDouble() ?? 0;
          return aCost.compareTo(bCost);
        });
      } else {
        data.sort((a, b) {
          final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
      }
      if (!mounted) return;
      setState(() {
        _orders = data;
        _linkedStoreId = linkedStoreId;
        _storeName = storeName;
        _isLoading = false;
        _isRefreshing = false;
        _loadError = "";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _loadError = "Could not load Store Mode data.";
      });
      _notifyError("Failed to load store orders. Pull to retry.");
    }
  }

  void _setAutoRefresh(bool enabled) {
    setState(() => _autoRefreshEnabled = enabled);
    _autoRefreshTimer?.cancel();
    if (!enabled) return;
    _autoRefreshTimer =
        Timer.periodic(Duration(seconds: _autoRefreshSeconds), (_) async {
      if (!mounted || _isLoading || _isRefreshing || _isActionBusy) return;
      await _load(silent: true);
    });
  }

  void _setAutoRefreshInterval(int seconds) {
    if (_autoRefreshSeconds == seconds) return;
    setState(() => _autoRefreshSeconds = seconds);
    if (_autoRefreshEnabled) {
      _setAutoRefresh(true);
    }
  }

  Map<String, int> get _statusCounts {
    final out = <String, int>{for (final s in _filters) s: 0};
    out["all"] = _orders.length;
    for (final order in _orders) {
      final status = _normalizedStatus(order["status"]);
      out[status] = (out[status] ?? 0) + 1;
    }
    return out;
  }

  bool _applyStatusLocally(String orderId, String nextStatus) {
    final target = orderId.trim().toLowerCase();
    if (target.isEmpty) return false;
    var changed = false;
    final updated = _orders.map((order) {
      final currentId =
          (order["orderId"] ?? "").toString().trim().toLowerCase();
      if (currentId != target) return order;
      changed = true;
      final next = Map<String, dynamic>.from(order);
      next["status"] = nextStatus;
      return next;
    }).toList();
    if (changed && mounted) {
      setState(() => _orders = updated);
    }
    return changed;
  }

  bool _removeOrderLocally(String orderId) {
    final target = orderId.trim().toLowerCase();
    if (target.isEmpty) return false;
    final before = _orders.length;
    final next = _orders.where((order) {
      final currentId =
          (order["orderId"] ?? "").toString().trim().toLowerCase();
      return currentId != target;
    }).toList();
    if (next.length == before) return false;
    if (mounted) {
      setState(() => _orders = next);
    }
    return true;
  }

  Future<void> _changeStatus(
    String orderId,
    String nextStatus, {
    bool force = false,
  }) async {
    if (_isActionBusy && !force) return;
    setState(() => _isActionBusy = true);
    final normalizedNext = _normalizedStatus(nextStatus);
    final existingOrder = _orders.firstWhere(
      (order) =>
          (order["orderId"] ?? "").toString().trim().toLowerCase() ==
          orderId.trim().toLowerCase(),
      orElse: () => <String, dynamic>{},
    );
    final previousStatus = _normalizedStatus(existingOrder["status"]);
    bool ok;
    if (normalizedNext == "collected") {
      ok = await DemoOrdersStore.deleteOrder(orderId: orderId);
      if (!ok) {
        ok = _removeOrderLocally(orderId);
      } else {
        _removeOrderLocally(orderId);
      }
    } else {
      ok = await DemoOrdersStore.updateOrderStatus(
        orderId: orderId,
        status: normalizedNext,
      );
      if (!ok) {
        ok = _applyStatusLocally(orderId, normalizedNext);
      } else {
        _applyStatusLocally(orderId, normalizedNext);
      }
    }
    try {
      if (!mounted) return;
      if (!ok) {
        _notifyError("Could not update order status");
        return;
      }
      if (existingOrder.isNotEmpty) {
        final operationalOrder = Map<String, dynamic>.from(existingOrder);
        operationalOrder["status"] = normalizedNext;
        unawaited(
          normalizedNext == "collected"
              ? OperationalOrderService.recordCollectedAndDeleted(
                  operationalOrder,
                  actor: 'store_mode',
                )
              : OperationalOrderService.recordStatusChange(
                  order: operationalOrder,
                  fromStatus: previousStatus,
                  toStatus: normalizedNext,
                  actor: 'store_mode',
                ),
        );
      }
      if (!mounted) return;
      _notifySuccess(
        normalizedNext == "collected"
            ? "Order collected and removed"
            : "Order moved to $normalizedNext",
      );
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  String _normalizeRef(dynamic value) {
    if (value == null) return "";
    if (value is String) return value.trim();
    if (value is Map) {
      final candidates = [
        value["downloadUrl"],
        value["documents"],
        value["url"],
        value["path"],
      ];
      for (final each in candidates) {
        final normalized = _normalizeRef(each);
        if (normalized.isNotEmpty) return normalized;
      }
      return "";
    }
    if (value is List && value.isNotEmpty) {
      return _normalizeRef(value.first);
    }
    return value.toString().trim();
  }

  List<String> _extractDocumentRefs(Map<String, dynamic> order) {
    final items = (order["items"] as List?) ?? <dynamic>[];
    final refs = <String>[];
    for (final item in items) {
      if (item is! Map) continue;
      final candidates = [
        _normalizeRef(item["downloadUrl"]),
        _normalizeRef(item["documents"]),
        _normalizeRef(item["url"]),
      ];
      for (final candidate in candidates) {
        if (candidate.isNotEmpty && !refs.contains(candidate)) {
          refs.add(candidate);
        }
      }
    }
    return refs;
  }

  File? _resolveLocalFileFromRef(String ref) {
    if (ref.trim().isEmpty) return null;
    if (ref.startsWith("local://")) {
      final localPath = ref.replaceFirst("local://", "");
      if (localPath.trim().isEmpty) return null;
      return File(localPath);
    }

    if (ref.startsWith("uploaded://")) {
      final raw = ref.replaceFirst("uploaded://", "").trim();
      if (raw.startsWith("/")) {
        return File(raw);
      }
      if (raw.startsWith("file://")) {
        return File(Uri.parse(raw).toFilePath());
      }
    }

    final uri = Uri.tryParse(ref);
    if (uri != null && uri.scheme == "file") {
      return File(uri.toFilePath());
    }

    // Some refs are saved as plain absolute paths without any URI scheme.
    if (ref.startsWith("/")) {
      return File(ref);
    }
    return null;
  }

  Future<File?> _downloadOrderFile(Map<String, dynamic> order) async {
    final refs = _extractDocumentRefs(order);
    for (final ref in refs) {
      if (ref.isEmpty) continue;

      final localFile = _resolveLocalFileFromRef(ref);
      if (localFile != null) {
        if (await localFile.exists()) return localFile;
        continue;
      }

      var normalizedRef = ref;
      if (normalizedRef.startsWith("uploaded://")) {
        normalizedRef = normalizedRef.replaceFirst("uploaded://", "").trim();
      }

      final uri = SecurityUtils.safeWebUri(normalizedRef, allowHttp: false);
      if (uri == null) continue;

      try {
        final response =
            await http.get(uri).timeout(const Duration(seconds: 20));
        if (response.statusCode < 200 || response.statusCode >= 300) continue;

        final dir = await getTemporaryDirectory();
        final orderId =
            (order["orderId"] ?? DateTime.now().millisecondsSinceEpoch)
                .toString();
        final file = File("${dir.path}/$orderId.pdf");
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<bool> _openRefExternally(Map<String, dynamic> order) async {
    final refs = _extractDocumentRefs(order);
    for (var ref in refs) {
      if (ref.startsWith("uploaded://")) {
        ref = ref.replaceFirst("uploaded://", "").trim();
      }
      final uri = SecurityUtils.safeWebUri(ref, allowHttp: false);
      if (uri == null) continue;
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return true;
    }
    return false;
  }

  Future<void> _startPrintingFlow(Map<String, dynamic> order) async {
    if (_isActionBusy) return;
    setState(() => _isActionBusy = true);
    final orderId = (order["orderId"] ?? "").toString();
    if (orderId.isEmpty) {
      if (mounted) setState(() => _isActionBusy = false);
      return;
    }

    try {
      final printerSelection = await PrinterSelectionSheet.show(context);
      if (printerSelection == null) return;
      final selectedPrinter = printerSelection.printer;

      _notifyInfo("Preparing ${selectedPrinter.name}...");

      File? downloadedFile;
      try {
        downloadedFile = await _downloadOrderFile(order);
      } catch (_) {
        downloadedFile = null;
      }

      if (!mounted) return;

      if (downloadedFile == null) {
        final openedRemote = await _openRefExternally(order);
        if (openedRemote) {
          await _changeStatus(orderId, "printing", force: true);
          if (!mounted) return;
          _notifySuccess("Opened document menu. Choose your print app.");
          return;
        }

        _notifyError(
            "Could not open/download file. Check document URL and network.");
        return;
      }

      var sentToPrinter = false;
      try {
        sentToPrinter = await PrinterService.sendRawPdf(
          printer: selectedPrinter,
          file: downloadedFile,
        );
      } catch (_) {
        sentToPrinter = false;
      }
      final openResult = sentToPrinter
          ? null
          : await OpenFilex.open(
              downloadedFile.path,
              type: "application/pdf",
            );
      final opened = sentToPrinter || openResult?.type == ResultType.done;

      if (!mounted) return;

      await _changeStatus(orderId, "printing", force: true);
      if (!mounted) return;
      unawaited(
        OperationalOrderService.enqueuePrinterJobForOrder(
          order: order,
          printerId: selectedPrinter.id,
          printerName: selectedPrinter.name,
        ),
      );

      if (sentToPrinter) {
        _notifySuccess("Sent to ${selectedPrinter.name}.");
      } else if (opened) {
        _notifySuccess("Opened print sheet for ${selectedPrinter.name}.");
      } else {
        _notifyWarning("File downloaded. Open from Files app to print.");
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final query = _orderQuery.trim().toLowerCase();
    return _orders.where((o) {
      final status = _normalizedStatus(o["status"]);
      final orderId = (o["orderId"] ?? "").toString().toLowerCase();
      final store = (o["storeName"] ?? "").toString().toLowerCase();
      final statusMatch = _statusFilter == "all" || status == _statusFilter;
      final queryMatch = query.isEmpty ||
          orderId.contains(query) ||
          store.contains(query) ||
          status.contains(query);
      return statusMatch && queryMatch;
    }).toList();
  }

  Future<void> _bulkMove({
    required String fromStatus,
    required String toStatus,
    required String label,
  }) async {
    if (_isActionBusy) return;
    final candidates = _orders.where((o) {
      return _normalizedStatus(o["status"]) == fromStatus;
    }).toList();
    if (candidates.isEmpty) {
      _notifyInfo("No $fromStatus orders available.");
      return;
    }

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(label),
            content: Text(
              "Move ${candidates.length} order(s) from $fromStatus to $toStatus?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(88, 42),
                ),
                child: const Text("Proceed"),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    setState(() => _isActionBusy = true);
    var updated = 0;
    final normalizedTo = _normalizedStatus(toStatus);
    try {
      for (final order in candidates) {
        final orderId = (order["orderId"] ?? "").toString();
        if (orderId.isEmpty) continue;
        bool ok;
        if (normalizedTo == "collected") {
          ok = await DemoOrdersStore.deleteOrder(orderId: orderId);
          if (!ok) {
            ok = _removeOrderLocally(orderId);
          } else {
            _removeOrderLocally(orderId);
          }
        } else {
          ok = await DemoOrdersStore.updateOrderStatus(
            orderId: orderId,
            status: normalizedTo,
          );
          if (!ok) {
            ok = _applyStatusLocally(orderId, normalizedTo);
          } else {
            _applyStatusLocally(orderId, normalizedTo);
          }
        }
        if (ok) updated++;
      }
      if (!mounted) return;
      if (updated > 0) {
        unawaited(
          OperationalOrderService.batchUpdateStatuses(
            orders: candidates,
            toStatus: normalizedTo,
            actor: 'store_mode',
            reason: 'bulk_action',
          ),
        );
        _notifySuccess(
          normalizedTo == "collected"
              ? "Removed $updated collected order(s)."
              : "Updated $updated order(s) to $normalizedTo.",
        );
      } else {
        _notifyWarning("No matching orders were updated.");
      }
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.4)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: ColorPallets.deepBlue),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: ColorPallets.deepBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderActionButton({
    required String label,
    required VoidCallback? onTap,
    bool filled = true,
  }) {
    const borderColor = ColorPallets.deepBlue;
    final fillColor = filled ? ColorPallets.deepBlue : Colors.white;
    final textColor = filled ? Colors.white : ColorPallets.deepBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              color: fillColor,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _actionsForOrder(Map<String, dynamic> order) {
    final status = _normalizedStatus(order["status"]);
    final orderId = (order["orderId"] ?? "").toString();

    if (status == "pending") {
      return <Widget>[
        _buildOrderActionButton(
          label: "Reject",
          filled: false,
          onTap:
              _isActionBusy ? null : () => _changeStatus(orderId, "rejected"),
        ),
        _buildOrderActionButton(
          label: "Accept",
          onTap:
              _isActionBusy ? null : () => _changeStatus(orderId, "accepted"),
        ),
      ];
    }
    if (status == "accepted") {
      return <Widget>[
        _buildOrderActionButton(
          label: "Start Printing",
          onTap: _isActionBusy ? null : () => _startPrintingFlow(order),
        ),
      ];
    }
    if (status == "printing") {
      return <Widget>[
        _buildOrderActionButton(
          label: "Mark Ready",
          onTap: _isActionBusy ? null : () => _changeStatus(orderId, "ready"),
        ),
      ];
    }
    if (status == "ready") {
      return <Widget>[
        _buildOrderActionButton(
          label: "Mark Collected",
          onTap:
              _isActionBusy ? null : () => _changeStatus(orderId, "collected"),
        ),
      ];
    }
    return const <Widget>[];
  }

  void _showStoreOrderQuickActions(Map<String, dynamic> order) {
    final orderId = (order["orderId"] ?? "").toString();
    final status = _normalizedStatus(order["status"]);
    if (orderId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.filter_alt_rounded),
              title: Text("Show $status orders"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _statusFilter = status);
              },
            ),
            if (status == "pending")
              ListTile(
                leading: const Icon(Icons.check_circle_rounded),
                title: const Text("Accept now"),
                onTap: () {
                  Navigator.pop(context);
                  _changeStatus(orderId, "accepted");
                },
              ),
            if (status == "accepted")
              ListTile(
                leading: const Icon(Icons.local_printshop_rounded),
                title: const Text("Start printing"),
                onTap: () {
                  Navigator.pop(context);
                  _startPrintingFlow(order);
                },
              ),
            if (status == "printing")
              ListTile(
                leading: const Icon(Icons.inventory_2_rounded),
                title: const Text("Mark ready"),
                onTap: () {
                  Navigator.pop(context);
                  _changeStatus(orderId, "ready");
                },
              ),
            if (status == "ready")
              ListTile(
                leading: const Icon(Icons.done_all_rounded),
                title: const Text("Mark collected"),
                onTap: () {
                  Navigator.pop(context);
                  _changeStatus(orderId, "collected");
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.storefront_rounded, size: 20),
              SizedBox(width: 8),
              Text("Store Mode"),
            ],
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsLogin) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.storefront_rounded, size: 20),
              SizedBox(width: 8),
              Text("Store Mode"),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 44),
                const SizedBox(height: 10),
                const Text(
                  "Store login required",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please sign in to continue in Store Mode.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const StoreLoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 42),
                  ),
                  child: const Text("Open Store Login"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visibleOrders = _filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, size: 20),
            SizedBox(width: 8),
            Text("Store Mode"),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PrintQueueScreen(initialOrders: _orders),
                ),
              );
            },
            icon: const Icon(Icons.local_printshop_rounded),
            tooltip: "Print Queue",
          ),
          IconButton(
            onPressed: () {
              final settingsShopId = _linkedStoreId.trim().isEmpty
                  ? _defaultAutoModeKey
                  : _linkedStoreId.trim();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShopAutoModeScreen(shopId: settingsShopId),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            tooltip: "Auto Mode Settings",
          ),
          IconButton(
            onPressed: () async {
              await StoreAuthStore.logoutStore();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StoreLoginScreen()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: () => _load(silent: true),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isActionBusy || _isRefreshing)
                const LinearProgressIndicator(minHeight: 2),
              if (_loadError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loadError,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _load,
                          child: const Text("Retry"),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _loadError = ""),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.tune,
                        size: 18, color: ColorPallets.deepBlue),
                    const SizedBox(width: 8),
                    Text(
                      "Live orders: ${_orders.length}",
                      style: const TextStyle(
                        color: ColorPallets.deepBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "Auto-refresh",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch.adaptive(
                      value: _autoRefreshEnabled,
                      onChanged: _setAutoRefresh,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Text(
                      "Interval",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _autoRefreshSeconds,
                      items: _autoRefreshOptions
                          .map((s) => DropdownMenuItem<int>(
                              value: s, child: Text("${s}s")))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        _setAutoRefreshInterval(v);
                      },
                    ),
                    const Spacer(),
                    const Text(
                      "Sort",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(
                            value: "newest", child: Text("Newest")),
                        DropdownMenuItem(
                            value: "amount_desc", child: Text("Amount high")),
                        DropdownMenuItem(
                            value: "amount_asc", child: Text("Amount low")),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _sortBy = v);
                        _load(silent: true);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final key = _filters[index];
                    final count = _statusCounts[key] ?? 0;
                    return Chip(
                      label: Text("${key.toUpperCase()}: $count"),
                      backgroundColor: Colors.blueGrey.shade50,
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemCount: _filters.length,
                ),
              ),
              if (_storeName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Signed in as: $_storeName (${_linkedStoreId.isEmpty ? "No store id" : _linkedStoreId})",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (_storeName.isNotEmpty) const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final active = filter == _statusFilter;
                    return ChoiceChip(
                      label: Text(filter.toUpperCase()),
                      selected: active,
                      onSelected: (_) => setState(() => _statusFilter = filter),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _filters.length,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  onChanged: (value) => setState(() => _orderQuery = value),
                  decoration: InputDecoration(
                    hintText: "Search order id or status",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _orderQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(() => _orderQuery = ""),
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBulkActionButton(
                      icon: Icons.done_all,
                      label: "Accept All Pending",
                      onTap: _isActionBusy
                          ? null
                          : () => _bulkMove(
                                fromStatus: "pending",
                                toStatus: "accepted",
                                label: "Accept All Pending",
                              ),
                    ),
                    const SizedBox(width: 8),
                    _buildBulkActionButton(
                      icon: Icons.cancel_schedule_send_outlined,
                      label: "Reject All Pending",
                      onTap: _isActionBusy
                          ? null
                          : () => _bulkMove(
                                fromStatus: "pending",
                                toStatus: "rejected",
                                label: "Reject All Pending",
                              ),
                    ),
                    const SizedBox(width: 8),
                    _buildBulkActionButton(
                      icon: Icons.local_printshop_outlined,
                      label: "Start All Accepted",
                      onTap: _isActionBusy
                          ? null
                          : () => _bulkMove(
                                fromStatus: "accepted",
                                toStatus: "printing",
                                label: "Start All Accepted",
                              ),
                    ),
                    const SizedBox(width: 8),
                    _buildBulkActionButton(
                      icon: Icons.inventory_2_outlined,
                      label: "Mark Printing Ready",
                      onTap: _isActionBusy
                          ? null
                          : () => _bulkMove(
                                fromStatus: "printing",
                                toStatus: "ready",
                                label: "Mark All Printing Ready",
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: visibleOrders.isEmpty
                    ? const Center(
                        child: Text(
                          "No store orders found",
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _load(silent: true),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: visibleOrders.length,
                          itemBuilder: (context, index) {
                            final order = visibleOrders[index];
                            final status = _normalizedStatus(order["status"]);
                            final actions = _actionsForOrder(order);
                            return GestureDetector(
                              onLongPress: () =>
                                  _showStoreOrderQuickActions(order),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              order["storeName"]?.toString() ??
                                                  "Store",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: status == "rejected"
                                                  ? Colors.red.shade100
                                                  : status == "collected"
                                                      ? Colors.green.shade100
                                                      : Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: "Change status",
                                            onSelected: (next) async {
                                              final orderId =
                                                  (order["orderId"] ?? "")
                                                      .toString();
                                              if (orderId.isEmpty) return;
                                              await _changeStatus(
                                                  orderId, next);
                                            },
                                            itemBuilder: (context) {
                                              return _allOrderStatuses
                                                  .map(
                                                    (s) =>
                                                        PopupMenuItem<String>(
                                                      value: s,
                                                      child: Text(
                                                          "Set ${s.toUpperCase()}"),
                                                    ),
                                                  )
                                                  .toList();
                                            },
                                            icon: const Icon(Icons.more_vert),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                          "Order ID: ${order["orderId"] ?? "-"}"),
                                      Text(
                                          "Pages: ${order["totalPages"] ?? 0}"),
                                      Text(
                                          "Amount: ₹${(order["totalCost"] ?? 0).toString()}"),
                                      Text(
                                          "Customer type: ${(order["orderLater"] == true) ? "Pay Later" : "Paid"}"),
                                      if (actions.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: actions
                                              .map((w) => Align(
                                                    widthFactor: 1,
                                                    child: w,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
