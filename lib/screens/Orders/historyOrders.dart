import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/app_notifications.dart';
import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/engagement_store.dart';
import '../../utils/favorite_stores_store.dart';
import '../../utils/firestore_orders_sync.dart';
import '../../utils/orders_cache_store.dart';
import '../../utils/security_utils.dart';
import '../../utils/search_history_store.dart';
import '../../utils/app_optimizations.dart';
import '../additional/feedback_screen.dart';
import 'order_tracking_screen.dart';
import '../../widgets/Cart/History_item.dart';
import '../../widgets/Cart/no_items.dart';
import '../../widgets/common/pill_appbar_title.dart';

class HistoryOrders extends StatefulWidget {
  static const routeName = "/historyOrders";
  final String accessToken;

  const HistoryOrders({super.key, required this.accessToken});

  @override
  State<HistoryOrders> createState() => _HistoryOrdersState();
}

class _HistoryOrdersState extends State<HistoryOrders> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  List<dynamic> _orders = [];
  bool isLoading = false;
  bool _isFetching = false;
  String _query = "";
  String _sortMode = "newest";
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = const <String>[];
  List<String> _archivedOrderIds = const <String>[];
  Map<String, dynamic> _collectedPhotos = const <String, dynamic>{};
  bool _showArchived = false;

  static const List<String> _sortModes = <String>[
    "newest",
    "oldest",
    "status",
    "amount_high",
    "amount_low",
  ];

  List<Map<String, dynamic>> _mergeHistoryOrders(
    List<dynamic> primary,
    List<dynamic> secondary,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    void ingest(List<dynamic> list) {
      for (final raw in list) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final id = _asText(
          item["orderId"],
          fallback: _asText(item["_Id"], fallback: _asText(item["orderDate"])),
        );
        if (id.isEmpty) continue;
        merged[id] = item;
      }
    }

    ingest(primary);
    ingest(secondary);

    final out = merged.values.toList();
    out.sort((a, b) {
      final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return out;
  }

  Future<List<Map<String, dynamic>>> _localHistoryFast() async {
    final localOrders = await DemoOrdersStore.getOrders();
    final filtered =
        localOrders.map((e) => Map<String, dynamic>.from(e)).where((order) {
      final status = (order["status"] ?? "").toString().toLowerCase();
      return status != "rejected" && status != "failed";
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadHistoryExtras();
    _loadOrders();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final searches = await SearchHistoryStore.load("history_orders");
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

  Future<void> _rememberSearch(String value) async {
    final searches = await SearchHistoryStore.add("history_orders", value);
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

  Future<void> _loadHistoryExtras() async {
    final archived = await EngagementStore.getArchivedOrderIds();
    final photos = await EngagementStore.getCollectedPhotos();
    if (!mounted) return;
    setState(() {
      _archivedOrderIds = archived;
      _collectedPhotos = photos;
    });
  }

  String _orderId(Map<String, dynamic> order) =>
      _asText(order["orderId"], fallback: _asText(order["_Id"]));

  Future<void> _toggleFavoriteStore(Map<String, dynamic> order) async {
    final storeId =
        _asText(order["storeId"], fallback: _asText(order["storeName"]));
    final storeName = _asText(order["storeName"], fallback: "Store");
    if (storeId.isEmpty) return;
    final added = await FavoriteStoresStore.toggle(
      FavoriteStore(
        id: storeId,
        name: storeName,
        address: _asText(order["storeAddress"]),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(added
              ? "$storeName added to favorites"
              : "$storeName removed from favorites")),
    );
  }

  void _showHistoryQuickActions(Map<String, dynamic> order) {
    final storeName = _asText(order["storeName"], fallback: "Store");
    final orderId = _orderId(order);
    final isArchived = _archivedOrderIds.contains(orderId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                  isArchived ? Icons.unarchive_rounded : Icons.archive_rounded),
              title: Text(isArchived ? "Unarchive order" : "Archive order"),
              subtitle: Text(orderId.isEmpty ? "No order id" : orderId),
              onTap: () async {
                Navigator.pop(context);
                if (orderId.isEmpty) return;
                if (isArchived) {
                  await EngagementStore.unarchiveOrder(orderId);
                } else {
                  await EngagementStore.archiveOrder(orderId);
                }
                await _loadHistoryExtras();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text("Attach collection photo"),
              subtitle: Text(
                  _collectedPhotos[orderId]?.toString().isEmpty == false
                      ? "Photo already attached"
                      : "Proof of pickup or receipt"),
              onTap: () {
                Navigator.pop(context);
                _attachCollectedPhoto(order);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text("Copy order summary"),
              onTap: () {
                Navigator.pop(context);
                _copyOrderSummary(order);
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review_rounded),
              title: const Text("Review this order"),
              onTap: () {
                Navigator.pop(context);
                if (orderId.isEmpty || _asText(order["storeId"]).isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('This order cannot be reviewed yet.')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FeedbackScreen(
                      orderId: orderId,
                      shopId: _asText(order["storeId"]),
                      shopName: storeName,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_rounded),
              title: const Text("Toggle favorite store"),
              subtitle: Text(storeName),
              onTap: () {
                Navigator.pop(context);
                _toggleFavoriteStore(order);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: const Text("Search this store"),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = storeName;
                setState(() => _query = storeName);
                _rememberSearch(storeName);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.route_rounded, color: ColorPallets.deepBlue),
              title: const Text("Track Order"),
              subtitle: const Text("View order timeline and shop details"),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(order: order),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_rounded),
              title: const Text("Sort by amount high"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _sortMode = "amount_high");
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attachCollectedPhoto(Map<String, dynamic> order) async {
    final orderId = _orderId(order);
    if (orderId.isEmpty) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    await EngagementStore.saveCollectedPhoto(orderId, path);
    await _loadHistoryExtras();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collection photo saved')),
    );
  }

  Future<void> _copyOrderSummary(Map<String, dynamic> order) async {
    final summary = [
      'Order: ${_orderId(order)}',
      'Store: ${_asText(order["storeName"], fallback: "Store")}',
      'Status: ${_asText(order["status"], fallback: "unknown")}',
      'Pages: ${_asText(order["totalPages"], fallback: "0")}',
      'Amount: Rs ${_asText(order["totalCost"], fallback: "0")}',
      'Date: ${_asText(order["orderDate"])}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order summary copied')),
    );
  }

  Future<void> _copyHistoryCsv() async {
    final orders = _visibleOrders;
    final buffer =
        StringBuffer('order_id,store,status,pages,amount,date,archived\n');
    for (final order in orders) {
      String cell(dynamic value) => '"${_asText(value).replaceAll('"', '""')}"';
      final id = _orderId(order);
      buffer.writeln([
        cell(id),
        cell(order['storeName']),
        cell(order['status']),
        cell(order['totalPages']),
        cell(order['totalCost']),
        cell(order['orderDate']),
        cell(_archivedOrderIds.contains(id) ? 'yes' : 'no'),
      ].join(','));
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${orders.length} order(s) exported as CSV')),
    );
  }

  void _showSpendReport() {
    final orders = _visibleOrders;
    final archivedVisible = orders
        .where((order) => _archivedOrderIds.contains(_orderId(order)))
        .length;
    final total = orders.fold<double>(
      0,
      (sum, order) => sum + _asDouble(order['totalCost']),
    );
    final pages = orders.fold<int>(
      0,
      (sum, order) => sum + _asDouble(order['totalPages']).round(),
    );
    final shops = orders
        .map((order) => _asText(order['storeName'], fallback: 'Store'))
        .toSet()
        .length;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('History Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders: ${orders.length}'),
            Text('Pages printed: $pages'),
            Text('Total spend: Rs ${total.toStringAsFixed(2)}'),
            Text('Stores used: $shops'),
            Text('Archived in this view: $archivedVisible'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrders() async {
    if (_isFetching) return;
    final shouldShowLoader = _orders.isEmpty;
    if (mounted && shouldShowLoader) setState(() => isLoading = true);

    final local = await _localHistoryFast();
    if (mounted && local.isNotEmpty) {
      setState(() => _orders = _mergeHistoryOrders(_orders, local));
    }

    try {
      final cloud = await FirestoreOrdersSync.load(scope: "history");
      if (mounted && cloud.isNotEmpty) {
        setState(() => _orders = _mergeHistoryOrders(_orders, cloud));
      }
    } catch (_) {}

    try {
      final cached = await OrdersCacheStore.load(
        accessToken: widget.accessToken,
        scope: "history",
      );

      if (mounted && cached.isNotEmpty) {
        setState(() => _orders = _mergeHistoryOrders(_orders, cached));
      }
    } catch (e) {
      debugPrint("Error loading cache: $e");
    }

    await _fetchOrders(showLoader: false);
  }

  Future<void> _fetchOrders({bool showLoader = true}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (mounted && showLoader && _orders.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      final result = await _collectHistoryOrders();
      if (mounted) {
        final merged = _mergeHistoryOrders(_orders, result);
        setState(() => _orders = merged);
        await OrdersCacheStore.save(
          accessToken: widget.accessToken,
          scope: "history",
          orders: merged,
        );
        await FirestoreOrdersSync.save(scope: "history", orders: merged);
      }
    } catch (e) {
      debugPrint("Error fetching: $e");
      if (mounted && _orders.isEmpty) {
        setState(() => _orders = _getDemoOrders());
      }
    } finally {
      _isFetching = false;
      if (mounted) setState(() => isLoading = false);
    }
  }

  List<dynamic> _getDemoOrders() {
    return const [];
  }

  Future<List<dynamic>> _collectHistoryOrders() async {
    final local = await _localHistoryFast();
    if (widget.accessToken.trim().isEmpty ||
        widget.accessToken == "demo_token") {
      return local;
    }

    final allOrder = <Map<String, dynamic>>[];
    try {
      final uri =
          SecurityUtils.safeWebUri('${ApiEndPoiunts.baseUrl}/orders/list');
      if (uri == null) return local;

      final response = await http
          .get(
            uri,
            headers: SecurityUtils.authHeaders(widget.accessToken),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['responseCode'] == 'OK') {
          final result = decoded["result"];
          final orders = result is Map<String, dynamic>
              ? ((result["data"] as List?) ?? <dynamic>[])
              : <dynamic>[];

          for (final eachOrder in orders) {
            if (eachOrder is! Map) continue;
            final orderMap = Map<String, dynamic>.from(eachOrder);
            final status = (orderMap["status"] ?? "").toString().toLowerCase();
            if (status != "rejected" && status != "failed") {
              final orderData = _parseOrderData(orderMap);
              allOrder.add(orderData);
            }
          }
          return _mergeHistoryOrders(local, allOrder);
        }
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    return local;
  }

  Map<String, dynamic> _parseOrderData(Map<String, dynamic> orderMap) {
    final items = (orderMap["items"] as List?) ?? <dynamic>[];
    return {
      "orderId": orderMap["orderId"] ?? "",
      "_Id": orderMap["_id"] ?? "",
      "orderDate": orderMap["createdAt"] ?? DateTime.now().toIso8601String(),
      "totalPages": orderMap["totalPages"] ?? 0,
      "totalCost": orderMap["totalCost"] ?? 0,
      "status": orderMap["status"] ?? "collected",
      "storeId": orderMap["storeId"] ?? "",
      "storeName": orderMap["storeName"] ?? "Store",
      "storeAddress": orderMap["storeAddress"] ?? "",
      "itemsCount": items.length,
      "items": items.map((item) {
        if (item is! Map) return <String, dynamic>{};
        final itemMap = Map<String, dynamic>.from(item);
        return {
          "downloadUrl": itemMap["documents"] ?? itemMap["downloadUrl"],
          "copies": itemMap["copies"],
          "totalPages": itemMap["totalPages"],
          "itemCost": itemMap["cost"] ?? itemMap["itemCost"],
          "pageRange": itemMap["pageRange"],
          "paperSize": itemMap["paperSize"],
          "printLayout": itemMap["printLayout"],
          "binding": itemMap["binding"],
          "side": itemMap["side"],
          "itemColor": itemMap["itemColor"],
          "notes": itemMap["notes"],
          "collateCopies": itemMap["collateCopies"],
          "numberCopies": itemMap["numberCopies"],
        };
      }).toList(),
    };
  }

  String _asText(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == "null") return fallback;
    return text;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(_asText(value)) ?? fallback;
  }

  List<Map<String, dynamic>> get _visibleOrders {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = _orders
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((order) {
      final status = _asText(order["status"]).toLowerCase();
      final isArchived = _archivedOrderIds.contains(_orderId(order));
      if (!_showArchived && isArchived) return false;
      return normalizedQuery.isEmpty ||
          _asText(order["orderId"]).toLowerCase().contains(normalizedQuery) ||
          _asText(order["_Id"]).toLowerCase().contains(normalizedQuery) ||
          _asText(order["storeName"]).toLowerCase().contains(normalizedQuery) ||
          status.contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(_asText(a["orderDate"])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(_asText(b["orderDate"])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final aAmount = _asDouble(a["totalCost"]);
      final bAmount = _asDouble(b["totalCost"]);
      switch (_sortMode) {
        case "oldest":
          return aDate.compareTo(bDate);
        case "status":
          return _asText(a["status"]).compareTo(_asText(b["status"]));
        case "amount_high":
          return bAmount.compareTo(aAmount);
        case "amount_low":
          return aAmount.compareTo(bAmount);
        case "newest":
        default:
          return bDate.compareTo(aDate);
      }
    });
    return filtered;
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await OrdersCacheStore.clearAll(accessToken: widget.accessToken);
      await DemoOrdersStore.clearAllOrders();
      await OrdersCacheStore.clear(
        accessToken: widget.accessToken,
        scope: "history",
      );
      await SearchHistoryStore.clear("history_orders");
      await EngagementStore.clearHistoryMetadata();
      if (mounted) setState(() => _orders = []);
      await _loadHistoryExtras();
      await _loadSearchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _visibleOrders;
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
            title: 'Order History', icon: Icons.history_rounded),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Hide Archived' : 'Show Archived',
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(_showArchived
                ? Icons.inventory_2_rounded
                : Icons.inventory_2_outlined),
          ),
          IconButton(
            tooltip: 'Copy CSV Export',
            onPressed: _copyHistoryCsv,
            icon: const Icon(Icons.file_download_rounded),
          ),
          IconButton(
            tooltip: 'Spend Report',
            onPressed: _showSpendReport,
            icon: const Icon(Icons.analytics_rounded),
          ),
          IconButton(
            tooltip: 'Test Push',
            onPressed: () {
              context.read<AppNotifications>().addInfo(
                    title: 'Test push notification',
                    body: 'Samsung popup + inbox flow verification.',
                  );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test notification triggered')),
              );
            },
            icon: const Icon(Icons.notifications_active_rounded),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders),
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: _clearHistory),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(child: NoOrders()),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visibleOrders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSearchAndSortCard(visibleOrders.length);
                      }
                      final order = visibleOrders[index - 1];
                      return GestureDetector(
                        onLongPress: () => _showHistoryQuickActions(order),
                        child: HistoryCard(
                          historyXeroxItem: order,
                          accesstoken: widget.accessToken,
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildSearchAndSortCard(int count) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Showing: $count order(s)${_showArchived ? ' including archived' : ''}",
              style: const TextStyle(
                color: ColorPallets.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.analytics_rounded, size: 16),
                  label: const Text('Report'),
                  onPressed: _showSpendReport,
                ),
                ActionChip(
                  avatar: const Icon(Icons.file_download_rounded, size: 16),
                  label: const Text('CSV Export'),
                  onPressed: _copyHistoryCsv,
                ),
                FilterChip(
                  avatar: const Icon(Icons.archive_rounded, size: 16),
                  label: Text('Archived ${_archivedOrderIds.length}'),
                  selected: _showArchived,
                  onSelected: (value) => setState(() => _showArchived = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                // ⚡ Bolt: Added debouncing to prevent UI jank while filtering large lists
                _debouncer.run(() {
                  if (mounted) {
                    setState(() => _query = value);
                  }
                });
              },
              onSubmitted: _rememberSearch,
              decoration: InputDecoration(
                hintText: "Search history by order id, shop, or status",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = "");
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_recentSearches.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final recent = _recentSearches[index];
                    return ActionChip(
                      avatar: const Icon(Icons.history, size: 16),
                      label: Text(recent),
                      onPressed: () {
                        _searchController.text = recent;
                        setState(() => _query = recent);
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _sortMode,
              decoration: const InputDecoration(
                labelText: "Sort by",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _sortModes
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(mode.replaceAll("_", " ")),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sortMode = value);
              },
            ),
            if (count == 0) ...[
              const SizedBox(height: 18),
              const Center(
                child: NoOrders.custom(
                  title: "No Matching Orders",
                  subtitle: "Try changing search text or sort filters.",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
