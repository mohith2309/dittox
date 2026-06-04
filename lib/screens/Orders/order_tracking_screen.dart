import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/color_pallets.dart';
import '../../widgets/common/pill_appbar_title.dart';

/// Full-detail order tracking screen.
/// Accepts the complete order map so all data is real — no hardcoding.
class OrderTrackingScreen extends StatefulWidget {
  static const routeName = '/orderTracking';

  /// Pass the full order map from DemoOrdersStore / cart list.
  final Map<String, dynamic> order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  // ── Helpers ────────────────────────────────────────────────────────────────

  String _text(String key, {String fallback = ''}) {
    final v = widget.order[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return (s.isEmpty || s.toLowerCase() == 'null') ? fallback : s;
  }

  double _num(String key) => (widget.order[key] as num?)?.toDouble() ?? 0;

  String get _orderId => _text('orderId', fallback: 'N/A');
  String get _status => _text('status', fallback: 'pending').toLowerCase();
  String get _storeName => _text('storeName', fallback: 'Print Shop');
  String get _storeAddress => _text('storeAddress');
  String get _storeContact => _text('storeContactNumber');
  String get _storeEmail => _text('storeEmail');
  String get _orderDate => _text('orderDate');
  double get _totalCost => _num('totalCost');
  int get _totalPages => (widget.order['totalPages'] as num?)?.toInt() ?? 0;
  double get _storeLocationX => _num('storeLocationX');
  double get _storeLocationY => _num('storeLocationY');
  String get _fulfillmentMode => _text('fulfillmentMode', fallback: 'Pickup');
  String get _cancelReason => _text('cancelReason');

  bool get _isTerminal =>
      _status == 'collected' || _status == 'rejected' || _status == 'failed';

  // ── Status → progress index ────────────────────────────────────────────────
  // pending=0, accepted=1, printing=2, ready=3, collected=4
  static const _statusIndex = {
    'pending': 0,
    'accepted': 1,
    'printing': 2,
    'ready': 3,
    'collected': 4,
  };

  int get _currentStepIndex => _statusIndex[_status] ?? 0;

  // ── Timeline steps ─────────────────────────────────────────────────────────
  static const _steps = [
    _Step('Order Placed', 'Your request has been received',
        Icons.receipt_long_rounded),
    _Step('Accepted', 'The shop has accepted your order',
        Icons.storefront_rounded),
    _Step('Printing', 'Documents are being printed now', Icons.print_rounded),
    _Step('Ready for Pickup', 'Head to the shop to collect',
        Icons.inventory_2_rounded),
    _Step('Completed', 'Order collected successfully', Icons.done_all_rounded),
  ];

  // ── ETA ────────────────────────────────────────────────────────────────────
  String get _eta {
    switch (_status) {
      case 'pending':
        return 'ETA: Shop review in 2–5 mins';
      case 'accepted':
        return 'ETA: Printing starts in 5–10 mins';
      case 'printing':
        return 'ETA: Ready in 10–20 mins';
      case 'ready':
        return 'Ready for pickup now!';
      case 'collected':
        return 'Order completed';
      case 'rejected':
        return _cancelReason.isNotEmpty
            ? 'Cancelled: $_cancelReason'
            : 'Order was cancelled';
      default:
        return '';
    }
  }

  // ── Status colour ──────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (_status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF3B82F6);
      case 'printing':
        return const Color(0xFF8B5CF6);
      case 'ready':
        return const Color(0xFF10B981);
      case 'collected':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'printing':
        return 'Printing…';
      case 'ready':
        return 'Ready ✓';
      case 'collected':
        return 'Collected ✓';
      case 'rejected':
        return 'Cancelled';
      default:
        return _status;
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _callShop() async {
    if (_storeContact.isEmpty) return;
    final uri = Uri.parse('tel:$_storeContact');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _emailShop() async {
    if (_storeEmail.isEmpty) return;
    final uri = Uri.parse('mailto:$_storeEmail');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps() async {
    if (_storeLocationX == 0 && _storeLocationY == 0) return;
    final uri = Uri.parse(
        'https://maps.google.com/?q=$_storeLocationX,$_storeLocationY');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _shareOrder() async {
    final text = [
      'Order ID: $_orderId',
      'Store: $_storeName',
      if (_storeAddress.isNotEmpty) 'Address: $_storeAddress',
      'Status: $_statusLabel',
      'Pages: $_totalPages',
      'Cost: ₹${_totalCost.toStringAsFixed(2)}',
      if (_orderDate.isNotEmpty) 'Placed: $_orderDate',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order details copied to clipboard')),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: PillAppBarTitle(
          title:
              'Order #${_orderId.length > 14 ? _orderId.substring(_orderId.length - 10) : _orderId}',
          icon: Icons.route_rounded,
        ),
        actions: [
          IconButton(
            tooltip: 'Share / Copy',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _shareOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 16),
            _buildStoreCard(),
            const SizedBox(height: 16),
            _buildOrderDetailsCard(),
            if (!_isTerminal) ...[
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header gradient card ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ColorPallets.deepBlue, ColorPallets.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ColorPallets.deepBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fulfillmentMode == 'Delivery'
                      ? 'Delivery Order'
                      : 'Pickup Order',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _eta,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    if (_status == 'rejected' || _status == 'failed') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.cancel_rounded, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Cancelled',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (_cancelReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _cancelReason,
                          style: const TextStyle(
                              color: ColorPallets.textSecondary, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Progress',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 16),
            ...List.generate(_steps.length, (i) {
              final isCompleted = i < _currentStepIndex;
              final isCurrent = i == _currentStepIndex;
              final isLast = i == _steps.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + vertical line
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isCurrent
                              ? (isCompleted
                                  ? ColorPallets.deepBlue
                                  : _statusColor)
                              : Colors.grey.shade200,
                          border: isCurrent
                              ? Border.all(
                                  color: _statusColor.withValues(alpha: 0.4),
                                  width: 3)
                              : null,
                        ),
                        child: Icon(
                          _steps[i].icon,
                          size: 18,
                          color: isCompleted || isCurrent
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 32,
                          color: isCompleted
                              ? ColorPallets.deepBlue
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _steps[i].title,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14,
                              color: isCompleted || isCurrent
                                  ? ColorPallets.textPrimary
                                  : ColorPallets.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _steps[i].subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted || isCurrent
                                  ? ColorPallets.textSecondary
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Store card ─────────────────────────────────────────────────────────────

  Widget _buildStoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Print Shop',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorPallets.deepBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: ColorPallets.deepBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_storeName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (_storeAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_storeAddress,
                            style: const TextStyle(
                                color: ColorPallets.textSecondary,
                                fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_storeContact.isNotEmpty)
                  _ActionChip(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    onTap: _callShop,
                  ),
                if (_storeContact.isNotEmpty) const SizedBox(width: 8),
                if (_storeEmail.isNotEmpty)
                  _ActionChip(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    onTap: _emailShop,
                  ),
                if (_storeEmail.isNotEmpty) const SizedBox(width: 8),
                if (_storeLocationX != 0 || _storeLocationY != 0)
                  _ActionChip(
                    icon: Icons.directions_rounded,
                    label: 'Directions',
                    onTap: _openMaps,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Order details card ─────────────────────────────────────────────────────

  Widget _buildOrderDetailsCard() {
    final items = (widget.order['items'] as List?) ?? const <dynamic>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Details',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            _DetailRow('Pages', '$_totalPages'),
            _DetailRow('Cost', '₹${_totalCost.toStringAsFixed(2)}', bold: true),
            _DetailRow('Mode', _fulfillmentMode),
            if (_orderDate.isNotEmpty)
              _DetailRow(
                  'Placed',
                  _orderDate.length > 10
                      ? _orderDate.substring(0, 10)
                      : _orderDate),
            if (items.isNotEmpty) ...[
              const Divider(height: 20),
              Text('${items.length} document(s)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ColorPallets.textSecondary,
                      fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Action buttons (only for non-terminal statuses) ───────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_status == 'pending' || _status == 'accepted')
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (_status == 'pending' || _status == 'accepted')
          const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/supportCenter'),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Help'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small reusable widgets ──────────────────────────────────────────────────

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Step(this.title, this.subtitle, this.icon);
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _DetailRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: ColorPallets.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ColorPallets.deepBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: ColorPallets.deepBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ColorPallets.deepBlue),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: ColorPallets.deepBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
