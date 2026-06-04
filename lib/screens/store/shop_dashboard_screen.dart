import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';
import '../../utils/formatters.dart';

class ShopDashboardScreen extends StatefulWidget {
  static const routeName = "/shopDashboard";
  final String shopId;
  final String shopName;

  const ShopDashboardScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: ColorPallets.deepBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.shopName,
                style: const TextStyle(fontSize: 16),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ColorPallets.deepBlue,
                      ColorPallets.lightBlue,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            _buildStatCard(
                              'Today',
                              '₹1,250',
                              '+12%',
                              Colors.green,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Orders',
                              '28',
                              '+5',
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                Tab(icon: Icon(Icons.people), text: 'Customers'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildOrdersTab(),
            _buildAnalyticsTab(),
            _buildCustomersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              change,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionsGrid(),
          const SizedBox(height: 20),
          _buildRevenueChart(),
          const SizedBox(height: 20),
          _buildRecentOrdersList(),
          const SizedBox(height: 20),
          _buildTopProducts(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildQuickAction(Icons.qr_code_scanner, 'Scan', Colors.blue),
            _buildQuickAction(Icons.print, 'Print', Colors.green),
            _buildQuickAction(Icons.receipt_long, 'Orders', Colors.orange),
            _buildQuickAction(Icons.inventory, 'Stock', Colors.purple),
            _buildQuickAction(Icons.inventory_2, 'Supplies', Colors.teal),
            _buildQuickAction(Icons.people, 'Customers', Colors.pink),
            _buildQuickAction(Icons.analytics, 'Reports', Colors.indigo),
            _buildQuickAction(Icons.settings, 'Settings', Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<String>(
                  value: 'week',
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Today')),
                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                    DropdownMenuItem(value: 'month', child: Text('This Month')),
                  ],
                  onChanged: (v) {},
                  underline: const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: CustomPaint(
                size: const Size(double.infinity, 150),
                painter: _ChartPainter(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegend('Mon', Colors.blue),
                _buildChartLegend('Tue', Colors.blue),
                _buildChartLegend('Wed', Colors.blue),
                _buildChartLegend('Thu', Colors.blue),
                _buildChartLegend('Fri', Colors.blue),
                _buildChartLegend('Sat', Colors.green),
                _buildChartLegend('Sun', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String day, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersList() {
    final orders = [
      {'id': 'DTX001', 'customer': 'John D.', 'amount': 45, 'status': 'Ready'},
      {'id': 'DTX002', 'customer': 'Sarah M.', 'amount': 120, 'status': 'Printing'},
      {'id': 'DTX003', 'customer': 'Mike R.', 'amount': 35, 'status': 'Pending'},
    ];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...orders.map((order) {
            final orderMap = order as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: ColorPallets.deepBlue.withValues(alpha: 0.1),
                child: Text(
                  orderMap['customer'].toString()[0],
                  style: const TextStyle(color: ColorPallets.deepBlue),
                ),
              ),
              title: Text(orderMap['id'].toString()),
              subtitle: Text(orderMap['customer'].toString()),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format((orderMap['amount'] as num).toDouble()),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderMap['status'].toString()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      orderMap['status'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = [
      {'name': 'A4 Black & White', 'count': 150, 'revenue': 4500},
      {'name': 'A4 Color', 'count': 80, 'revenue': 3200},
      {'name': 'A3 Black & White', 'count': 45, 'revenue': 2700},
      {'name': 'Spiral Binding', 'count': 25, 'revenue': 750},
    ];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Top Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...products.map((product) {
            final productMap = product as Map<String, dynamic>;
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description,
                  color: ColorPallets.deepBlue,
                  size: 20,
                ),
              ),
              title: Text(productMap['name'].toString()),
              subtitle: Text('${productMap['count']} orders'),
              trailing: Text(
                CurrencyFormatter.format((productMap['revenue'] as num).toDouble()),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return const Center(
      child: Text('Orders Tab - Add order list here'),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Text('Analytics Tab - Add charts here'),
    );
  }

  Widget _buildCustomersTab() {
    return const Center(
      child: Text('Customers Tab - Add customer list here'),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return Colors.green;
      case 'printing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColorPallets.deepBlue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = ColorPallets.deepBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final heights = [60.0, 80.0, 45.0, 90.0, 70.0, 100.0, 85.0];
    final spacing = size.width / (heights.length - 1);

    path.moveTo(0, size.height - heights[0]);
    for (int i = 1; i < heights.length; i++) {
      path.lineTo(i * spacing, size.height - heights[i]);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = ColorPallets.deepBlue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < heights.length; i++) {
      canvas.drawCircle(
        Offset(i * spacing, size.height - heights[i]),
        4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
