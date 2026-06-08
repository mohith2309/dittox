import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/orders_cache_store.dart';
import '../../utils/pill_notifications.dart';
import '../../utils/security_utils.dart';
import '../../widgets/Cart/no_items.dart';
import '../../widgets/Cart/payLater.dart';
import '../../widgets/common/pill_appbar_title.dart';

class PayLater extends StatefulWidget {
  static const routeName = "/paylaterOrders";
  final String accessToken;

  const PayLater({super.key, required this.accessToken});

  @override
  State<PayLater> createState() => _PayLaterState();
}

class _PayLaterState extends State<PayLater> {
  List<dynamic> listOrders = [];
  bool isLoading = false;
  bool _isFetching = false;
  String _query = "";
  DateTime? _lastSyncAt;

  String _asText(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == "null") return fallback;
    return text;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_asText(value)) ?? fallback;
  }

  double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(_asText(value)) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _warmStartAndFetch();
  }

  Future<void> _warmStartAndFetch() async {
    final localPayLaterOrders = await DemoOrdersStore.getPayLaterOrders();
    if (mounted && localPayLaterOrders.isNotEmpty) {
      setState(() {
        listOrders = localPayLaterOrders;
      });
    }
    await _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (_isFetching) return;
    _isFetching = true;
    if (mounted && listOrders.isEmpty) setState(() => isLoading = true);

    try {
      final result = await _collectPayLaterOrders();
      if (!mounted) return;
      setState(() {
        listOrders = result;
        _lastSyncAt = DateTime.now();
      });
      await OrdersCacheStore.save(
        accessToken: widget.accessToken,
        scope: "paylater",
        orders: result,
      );
    } catch (error) {
      debugPrint("Error fetching pay-later orders: $error");
      if (mounted) {
        PillNotifications.show(
          context,
          message: "PayLater sync issue. Showing saved local orders.",
          type: PillType.warning,
        );
      }
    } finally {
      _isFetching = false;
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _getColorPartialRange(dynamic pageNumbers) {
    if (pageNumbers is List) return pageNumbers.join(", ");
    return "";
  }

  String _getColor(String color) {
    if (color == "bw") return "Black & White";
    if (color == "multi") return "Color Print";
    return "Partial Color";
  }

  Future<List<dynamic>> _collectPayLaterOrders() async {
    final localPayLaterOrders = await DemoOrdersStore.getPayLaterOrders();

    if (widget.accessToken.trim().isEmpty ||
        widget.accessToken == "demo_token") {
      return localPayLaterOrders;
    }

    late final http.Response response;
    try {
      final uri =
          SecurityUtils.safeWebUri('${ApiEndPoiunts.baseUrl}/orders/list');
      if (uri == null) return localPayLaterOrders;
      response = await http
          .get(
            uri,
            headers: SecurityUtils.authHeaders(widget.accessToken),
          )
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      return localPayLaterOrders;
    } catch (_) {
      return localPayLaterOrders;
    }

    if (response.statusCode != 200) {
      return localPayLaterOrders;
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return localPayLaterOrders;
    }
    if (decoded['responseCode'] != 'OK') {
      return localPayLaterOrders;
    }

    final result = decoded["result"];
    final orderList = result is Map<String, dynamic>
        ? ((result["data"] as List?) ?? <dynamic>[])
        : <dynamic>[];
    final allOrder = <Map<String, dynamic>>[];

    for (final eachOrder in orderList) {
      if (eachOrder is! Map) continue;
      final orderMap = Map<String, dynamic>.from(eachOrder);
      if (orderMap["orderLater"] == true) {
        final order = <String, dynamic>{};
        order["_id"] = _asText(orderMap["_id"]);
        order["orderId"] = _asText(orderMap["orderId"]);
        order["orderDate"] = _asText(
          orderMap["createdAt"],
          fallback: DateTime.now().toIso8601String(),
        );
        order["totalPages"] = _asInt(orderMap["totalPages"]);
        order["totalCost"] = _asDouble(orderMap["totalCost"]);
        order["status"] = _asText(orderMap["status"], fallback: "pending");
        order["storeId"] = _asText(orderMap["storeId"]);

        // Avoid slow store/details fan-out call; use list payload if present.
        order["storeName"] = _asText(orderMap["storeName"], fallback: "Store");
        order["storeAddress"] = _asText(orderMap["storeAddress"]);
        order["storeLocationX"] = _asDouble(orderMap["storeLocationX"]);
        order["storeLocationY"] = _asDouble(orderMap["storeLocationY"]);
        order["storeEmail"] = _asText(orderMap["storeEmail"]);
        order["storeContactNumber"] = _asText(orderMap["storeContactNumber"]);
        order["storeOpeningTime"] = _asText(orderMap["storeOpeningTime"]);
        order["storeClosingTime"] = _asText(orderMap["storeClosingTime"]);

        final itemsList = (orderMap["items"] as List?) ?? <dynamic>[];
        order["itemsCount"] = itemsList.length;
        final wantedItems = <Map<String, dynamic>>[];
        for (final eachItem in itemsList) {
          if (eachItem is! Map) continue;
          final itemMap = Map<String, dynamic>.from(eachItem);
          final colors = itemMap["colors"];
          final colorsMap =
              colors is Map ? Map<String, dynamic>.from(colors) : const {};
          final colorPar = itemMap["colorPar"];
          final colorParMap =
              colorPar is Map ? Map<String, dynamic>.from(colorPar) : const {};
          final bondPage = itemMap["bondPage"];
          final bondPageMap =
              bondPage is Map ? Map<String, dynamic>.from(bondPage) : const {};
          final sideRaw =
              _asText(itemMap["sides"], fallback: _asText(itemMap["side"]));
          wantedItems.add({
            "downloadUrl": _asText(itemMap["documents"]),
            "copies": _asInt(itemMap["copies"]),
            "totalPages": _asInt(itemMap["totalPages"]),
            "itemCost": _asDouble(itemMap["cost"]),
            "itemColor": _getColor(colorsMap["color"]),
            "colorPartialPagesList":
                _getColorPartialRange(colorParMap["pageNumbers"]),
            "bondPage":
                bondPageMap["selected"] ?? bondPageMap["seleted"] ?? "no",
            "paperSize": _asText(itemMap["paperSize"], fallback: "A4"),
            "printLayout":
                _asText(itemMap["printLayout"], fallback: "Portrait"),
            "binding": _asText(itemMap["binding"], fallback: "No Binding"),
            "side": sideRaw == "one" ? "single-side Print" : "Both-side Print",
          });
        }
        order["items"] = wantedItems;
        allOrder.add(order);
      }
    }

    final localOrderIds =
        allOrder.map((order) => (order["orderId"] ?? "").toString()).toSet();
    for (final localOrder in localPayLaterOrders) {
      final localId = (localOrder["orderId"] ?? "").toString();
      if (localId.isNotEmpty && !localOrderIds.contains(localId)) {
        allOrder.add(localOrder);
      }
    }

    allOrder.sort((a, b) {
      final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return allOrder;
  }

  List<Map<String, dynamic>> get _visibleOrders {
    final normalizedQuery = _query.trim().toLowerCase();
    final source = listOrders
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (normalizedQuery.isEmpty) return source;
    return source.where((order) {
      final orderId = _asText(order["orderId"]).toLowerCase();
      final storeName = _asText(order["storeName"]).toLowerCase();
      final status = _asText(order["status"]).toLowerCase();
      return orderId.contains(normalizedQuery) ||
          storeName.contains(normalizedQuery) ||
          status.contains(normalizedQuery);
    }).toList();
  }

  double get _visibleTotalDue {
    return _visibleOrders.fold<double>(0, (sum, order) {
      return sum + _asDouble(order["totalCost"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Pay-Later Orders',
          icon: Icons.account_balance_wallet_rounded,
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 30,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 6,
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : listOrders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: NoOrders.custom(
                            title: "No Pay-Later Orders",
                            subtitle:
                                "You have no pending pay-later orders right now.",
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _visibleOrders.isEmpty ? 2 : _visibleOrders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                              "Orders: ${_visibleOrders.length}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: ColorPallets.swiggyOrange,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "Due: Rs ${_visibleTotalDue.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: ColorPallets.swiggyOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        onChanged: (value) =>
                                            setState(() => _query = value),
                                        decoration: InputDecoration(
                                          hintText:
                                              "Search by order id, store, or status",
                                          prefixIcon: const Icon(Icons.search),
                                          suffixIcon: _query.trim().isEmpty
                                              ? null
                                              : IconButton(
                                                  onPressed: () =>
                                                      setState(() => _query = ""),
                                                  icon: const Icon(Icons.clear),
                                                ),
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                      ),
                                      if (_lastSyncAt != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          "Last sync: ${_lastSyncAt!.hour.toString().padLeft(2, '0')}:${_lastSyncAt!.minute.toString().padLeft(2, '0')}:${_lastSyncAt!.second.toString().padLeft(2, '0')}",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          );
                        }

                        if (_visibleOrders.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(
                              child: NoOrders.custom(
                                title: "No Matching Pay-Later Orders",
                                subtitle:
                                    "Try a different search term or clear search.",
                              ),
                            ),
                          );
                        }

                        return PayLaterCard(
                          payLaterXeroxItem: _visibleOrders[index - 1],
                          accessToken: widget.accessToken,
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
