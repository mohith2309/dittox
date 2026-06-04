import "package:dittox/widgets/Cart/no_items.dart";
import "package:flutter/material.dart";

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import "../../utils/api_endpoints.dart";
import "../../utils/color_pallets.dart";
import "../../utils/demo_orders_store.dart";
import "../../utils/dynamicSizing.dart";
import "../../utils/firestore_orders_sync.dart";
import "../../utils/favorite_stores_store.dart";
import "../../utils/orders_cache_store.dart";
import "../../utils/security_utils.dart";
import "../../utils/search_history_store.dart";
import "../../widgets/Cart/onGoing_xerox_Item.dart";
import '../../widgets/common/pill_appbar_title.dart';

class CartScreen extends StatefulWidget {
  static const routeName = "/cartScreen";
  final String accessToken;
  final int refreshToken;
  const CartScreen({
    super.key,
    required this.accessToken,
    this.refreshToken = 0,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> listOrders = [];
  bool isLoading = false;
  bool _isFetching = false;
  String _query = "";
  String _statusFilter = "all";
  String _sortMode = "newest";
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<String> _recentSearches = const <String>[];

  double? _cachedPaddingV;
  double? _cachedPaddingH;

  static const List<String> _statusFilters = <String>[
    "all",
    "pending",
    "accepted",
    "printing",
    "ready",
    "rejected",
  ];
  static const List<String> _sortModes = <String>[
    "newest",
    "oldest",
    "status",
    "amount_high",
    "amount_low",
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _warmStartAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final searches = await SearchHistoryStore.load("orders");
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

  Future<void> _rememberSearch(String value) async {
    final searches = await SearchHistoryStore.add("orders", value);
    if (!mounted) return;
    setState(() => _recentSearches = searches);
  }

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

  Future<void> _cancelOrderWithReason(Map<String, dynamic> order) async {
    final orderId = _asText(order["orderId"]);
    if (orderId.isEmpty) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Cancel Order"),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Reason",
            hintText: "Example: Uploaded wrong document",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Keep Order"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Cancel Order"),
          ),
        ],
      ),
    );
    if (!mounted) return;
    controller.dispose();
    if (reason == null) return;

    final updated = await DemoOrdersStore.updateOrderStatus(
      orderId: orderId,
      status: "rejected",
      cancelReason: reason,
    );
    if (!mounted) return;
    setState(() {
      for (final raw in listOrders) {
        if (raw is! Map) continue;
        if (_asText(raw["orderId"]) != orderId) continue;
        raw["status"] = "rejected";
        raw["cancelReason"] = reason;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(updated ? "Order cancelled" : "Order cancelled locally")),
    );
  }

  void _showOrderQuickActions(Map<String, dynamic> order) {
    final storeName = _asText(order["storeName"], fallback: "Store");
    final status = _asText(order["status"], fallback: "all").toLowerCase();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              leading: const Icon(Icons.filter_alt_rounded),
              title: Text("Filter $status orders"),
              onTap: () {
                Navigator.pop(context);
                if (_statusFilters.contains(status)) {
                  setState(() => _statusFilter = status);
                }
              },
            ),
            if (status == "pending" || status == "accepted")
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: Colors.red),
                title: const Text("Cancel with reason"),
                onTap: () {
                  Navigator.pop(context);
                  _cancelOrderWithReason(order);
                },
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _mergeOrderLists(
    List<dynamic> primary,
    List<dynamic> secondary,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    void ingest(List<dynamic> list) {
      for (final raw in list) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final key = (item["orderId"] ?? item["_Id"] ?? item["orderDate"] ?? "")
            .toString();
        if (key.isEmpty) continue;
        merged[key] = item;
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

  Future<List<Map<String, dynamic>>> _loadLocalOngoingFast() async {
    final localOrders = await DemoOrdersStore.getOrders();
    final localOngoing =
        localOrders.map((e) => Map<String, dynamic>.from(e)).where((order) {
      final status = (order["status"] ?? "").toString().toLowerCase();
      return status != "collected" &&
          status != "completed" &&
          status != "rejected" &&
          status != "failed";
    }).toList();

    localOngoing.sort((a, b) {
      final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return localOngoing;
  }

  Future<void> _warmStartAndFetch() async {
    final local = await _loadLocalOngoingFast();
    if (mounted && local.isNotEmpty) {
      setState(() {
        listOrders = _mergeOrderLists(listOrders, local);
      });
    }

    final cloud = await FirestoreOrdersSync.load(scope: "ongoing");
    if (mounted && cloud.isNotEmpty) {
      setState(() {
        listOrders = _mergeOrderLists(listOrders, cloud);
      });
    }

    final cached = await OrdersCacheStore.load(
      accessToken: widget.accessToken,
      scope: "ongoing",
    );
    if (mounted && cached.isNotEmpty) {
      setState(() {
        listOrders = _mergeOrderLists(listOrders, cached);
      });
    }
    await _fetchOrdersWithRetry();
  }

  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _fetchOrdersWithRetry();
    }
  }

  Future<void> _fetchOrdersWithRetry() async {
    if (_isFetching || !mounted) return;
    _isFetching = true;
    final showLoader = listOrders.isEmpty;
    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }
    try {
      final result = await collectAllOnGoingOrders();
      if (!mounted) return;

      setState(() {
        listOrders = result;
      });
      await OrdersCacheStore.save(
        accessToken: widget.accessToken,
        scope: "ongoing",
        orders: result,
      );
      await FirestoreOrdersSync.save(scope: "ongoing", orders: result);

      if (result.isEmpty && widget.accessToken != "demo_token") {
        await Future.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        final retryResult = await collectAllOnGoingOrders();
        if (!mounted) return;
        setState(() {
          listOrders = retryResult;
        });
      }
    } catch (error) {
      if (error is! TimeoutException) {
        debugPrint("Error fetching orders: $error");
      }
    } finally {
      if (mounted) {
        _isFetching = false;
        if (isLoading) setState(() => isLoading = false);
      }
    }
  }

  Future<List<dynamic>> collectAllOnGoingOrders() async {
    final allOrder = <Map<String, dynamic>>[];
    final localOrders = await DemoOrdersStore.getOrders();
    final localOngoing =
        localOrders.map((e) => Map<String, dynamic>.from(e)).where((order) {
      final status = (order["status"] ?? "").toString().toLowerCase();
      return status != "collected" && status != "completed";
    }).toList();

    if (widget.accessToken.trim().isEmpty ||
        widget.accessToken == "demo_token") {
      localOngoing.sort((a, b) {
        final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return localOngoing;
    }

    try {
      final uri =
          SecurityUtils.safeWebUri('${ApiEndPoiunts.baseUrl}/orders/list');
      if (uri == null) return localOngoing;
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
            if (orderMap["status"] != "collected") {
              final orderData = <String, dynamic>{
                "orderId": orderMap["orderId"] ?? "",
                "orderDate":
                    orderMap["createdAt"] ?? DateTime.now().toIso8601String(),
                "totalPages": orderMap["totalPages"] ?? 0,
                "totalCost": orderMap["totalCost"] ?? 0,
                "status": orderMap["status"] ?? "pending",
                "storeId": orderMap["storeId"] ?? "",
              };

              orderData.addAll({
                "storeName": orderMap["storeName"] ?? "Store",
                "storeAddress": orderMap["storeAddress"] ?? "",
                "storeLocationX": (orderMap["storeLocationX"] ?? 0).toDouble(),
                "storeLocationY": (orderMap["storeLocationY"] ?? 0).toDouble(),
                "storeEmail": orderMap["storeEmail"] ?? "",
                "storeContactNumber": orderMap["storeContactNumber"] ?? "",
                "storeOpeningTime": orderMap["storeOpeningTime"] ?? "",
                "storeClosingTime": orderMap["storeClosingTime"] ?? "",
              });

              final items = (orderMap["items"] as List?) ?? <dynamic>[];
              orderData["itemsCount"] = items.length;
              orderData["items"] = items.map((item) {
                if (item is! Map) return <String, dynamic>{};
                final itemMap = Map<String, dynamic>.from(item);
                return {
                  "downloadUrl": itemMap["documents"],
                  "copies": itemMap["copies"],
                  "totalPages": itemMap["totalPages"],
                  "itemCost": itemMap["cost"],
                };
              }).toList();

              allOrder.add(orderData);
            }
          }
        }
      }
    } catch (e) {
      if (e is! TimeoutException) {
        debugPrint("Error: $e");
      }
    }

    final merged = <String, Map<String, dynamic>>{};
    for (final o in [...localOngoing, ...allOrder]) {
      final id = (o["orderId"] ?? o["_Id"] ?? o["orderDate"] ?? "").toString();
      if (id.isEmpty) continue;
      merged[id] = o;
    }

    final mergedList = merged.values.toList();
    mergedList.sort((a, b) {
      final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return mergedList;
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
    final source = listOrders
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final filtered = source.where((order) {
      final status = _asText(order["status"]).toLowerCase();
      final queryMatch = normalizedQuery.isEmpty ||
          _asText(order["orderId"]).toLowerCase().contains(normalizedQuery) ||
          _asText(order["storeName"]).toLowerCase().contains(normalizedQuery) ||
          status.contains(normalizedQuery);
      final statusMatch = _statusFilter == "all" || status == _statusFilter;
      return queryMatch && statusMatch;
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
        case "amount_high":
          return bAmount.compareTo(aAmount);
        case "amount_low":
          return aAmount.compareTo(bAmount);
        case "status":
          return _asText(a["status"]).compareTo(_asText(b["status"]));
        case "newest":
        default:
          return bDate.compareTo(aDate);
      }
    });
    return filtered;
  }

  double get _visibleTotalAmount {
    return _visibleOrders.fold<double>(0, (sum, order) {
      return sum + _asDouble(order["totalCost"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    _cachedPaddingV ??= calculateDynamicFontSize(
      totalScreenHeight: size.height,
      totalScreenWidth: size.width,
      currentFontSize: 30,
    );
    _cachedPaddingH ??= calculateDynamicFontSize(
      totalScreenHeight: size.height,
      totalScreenWidth: size.width,
      currentFontSize: 6,
    );

    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Orders',
          icon: Icons.receipt_long_rounded,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrdersWithRetry,
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: _cachedPaddingV!, horizontal: _cachedPaddingH!),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : listOrders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 88),
                      children: const [
                        SizedBox(height: 180),
                        Center(child: NoOrders())
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 88),
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Showing: ${_visibleOrders.length} order(s)",
                                        style: const TextStyle(
                                          color: ColorPallets.swiggyOrange,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "Rs ${_visibleTotalAmount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: ColorPallets.swiggyOrange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                  onSubmitted: _rememberSearch,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Search by order id, shop, or status",
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
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        final recent = _recentSearches[index];
                                        return ActionChip(
                                          avatar: const Icon(Icons.history,
                                              size: 16),
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
                                SizedBox(
                                  height: 38,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _statusFilters.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final filter = _statusFilters[index];
                                      return ChoiceChip(
                                        label: Text(filter.toUpperCase()),
                                        selected: _statusFilter == filter,
                                        onSelected: (_) => setState(
                                          () => _statusFilter = filter,
                                        ),
                                      );
                                    },
                                  ),
                                ),
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
                                          child:
                                              Text(mode.replaceAll("_", " ")),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _sortMode = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_visibleOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 70),
                            child: Center(
                              child: NoOrders.custom(
                                title: "No Matching Orders",
                                subtitle:
                                    "Try changing search text or selected status.",
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _visibleOrders.length,
                            itemBuilder: (context, index) {
                              final order = _visibleOrders[index];
                              final orderId = _asText(order["orderId"]);
                              final status = _asText(order["status"]);
                              return Dismissible(
                                key: ValueKey("$orderId:$status"),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  await _cancelOrderWithReason(order);
                                  return false;
                                },
                                onDismissed: (direction) {
                                  setState(() {
                                    listOrders.removeWhere((o) =>
                                        _asText(o["orderId"]) == orderId);
                                  });
                                },
                                child: GestureDetector(
                                  onLongPress: () =>
                                      _showOrderQuickActions(order),
                                  child: CarrOnGoingItem(
                                    onGoingXeroxItem: order,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}
