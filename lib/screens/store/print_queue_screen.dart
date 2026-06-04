import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/formatters.dart';
import '../../utils/store_auth_store.dart';
import '../../widgets/common/pill_appbar_title.dart';

class PrintQueueScreen extends StatefulWidget {
  static const routeName = "/printQueue";

  final List<Map<String, dynamic>> initialOrders;

  const PrintQueueScreen({
    super.key,
    this.initialOrders = const <Map<String, dynamic>>[],
  });

  @override
  State<PrintQueueScreen> createState() => _PrintQueueScreenState();
}

class _PrintQueueScreenState extends State<PrintQueueScreen> {
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _orders = _queueOnly(widget.initialOrders);
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    if (mounted && _orders.isEmpty) setState(() => _loading = true);
    final activeStore = await StoreAuthStore.getActiveStore();
    final storeId =
        (activeStore?["linkedStoreId"] ?? activeStore?["id"] ?? "").toString();
    final orders = await DemoOrdersStore.getStoreOrders(storeId: storeId);
    if (!mounted) return;
    setState(() {
      _orders = _queueOnly(orders);
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _queueOnly(List<Map<String, dynamic>> source) {
    final queue = source.where((order) {
      final status = (order["status"] ?? "").toString().toLowerCase();
      return status == "accepted" || status == "printing" || status == "ready";
    }).toList();
    queue.sort((a, b) {
      final aStatus = (a["status"] ?? "").toString();
      final bStatus = (b["status"] ?? "").toString();
      if (aStatus != bStatus) return aStatus.compareTo(bStatus);
      final aDate = DateTime.tryParse((a["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse((b["orderDate"] ?? "").toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return queue;
  }

  int get _totalPages => _orders.fold<int>(0, (sum, order) {
        final pages = int.tryParse((order["totalPages"] ?? 0).toString()) ?? 0;
        return sum + pages;
      });

  double get _totalAmount => _orders.fold<double>(0, (sum, order) {
        final amount =
            double.tryParse((order["totalCost"] ?? 0).toString()) ?? 0;
        return sum + amount;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Print Queue',
          icon: Icons.local_printshop_rounded,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh queue',
            onPressed: _loadQueue,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Icon(Icons.print_disabled_rounded,
                          size: 72, color: ColorPallets.textSecondary),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No jobs waiting to print',
                          style: TextStyle(
                            color: ColorPallets.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildSummaryCard();
                      return _buildOrderCard(_orders[index - 1], index);
                    },
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPallets.deepBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _buildSummaryTile('Jobs', _orders.length.toString()),
          _buildSummaryTile('Pages', _totalPages.toString()),
          _buildSummaryTile(
              'Value', CurrencyFormatter.formatCompact(_totalAmount)),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int position) {
    final status = (order["status"] ?? "accepted").toString().toLowerCase();
    final orderId = (order["orderId"] ?? "-").toString();
    final pages = (order["totalPages"] ?? 0).toString();
    final amount = double.tryParse((order["totalCost"] ?? 0).toString()) ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ColorPallets.deepBlue.withValues(alpha: 0.1),
          foregroundColor: ColorPallets.deepBlue,
          child: Text(position.toString()),
        ),
        title: Text(orderId, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$pages pages • ${CurrencyFormatter.format(amount)}'),
        trailing: Chip(
          label: Text(status.toUpperCase()),
          backgroundColor: status == 'printing'
              ? ColorPallets.lightBlue.withValues(alpha: 0.16)
              : ColorPallets.lightPurplishWhile.withValues(alpha: 0.32),
        ),
      ),
    );
  }
}
