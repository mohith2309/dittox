import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/color_pallets.dart';
import '../../utils/ui_sounds.dart';
import '../nav_drawers/navBar.dart';
import 'order_tracking_screen.dart';

/// Shown immediately after a successful order placement.
/// Displays a confirmation with the order ID, store info, and two CTAs.
class OrderConfirmationScreen extends StatefulWidget {
  static const routeName = '/orderConfirmation';

  final Map<String, dynamic> order;
  final String accessToken;
  final bool isPayLater;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    required this.accessToken,
    this.isPayLater = false,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    // Small delay so the screen has settled before animating
    Timer(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
    // Fire after a tiny delay so the screen has fully rendered
    Timer(const Duration(milliseconds: 200), () => UiSounds.orderPlaced());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _orderId => (widget.order['orderId'] ?? '').toString();

  String get _storeName =>
      (widget.order['storeName'] ?? 'Your Print Shop').toString();

  String get _storeAddress => (widget.order['storeAddress'] ?? '').toString();

  double get _totalCost => (widget.order['totalCost'] as num?)?.toDouble() ?? 0;

  int get _totalPages => (widget.order['totalPages'] as num?)?.toInt() ?? 0;

  String get _fulfillmentMode =>
      (widget.order['fulfillmentMode'] ?? 'Pickup').toString();

  String get _estimatedTime {
    if (widget.isPayLater) return 'Payment pending';
    if (_fulfillmentMode == 'Delivery') return '30–60 mins delivery';
    return '10–20 mins for pickup';
  }

  Future<void> _copyOrderId() async {
    await Clipboard.setData(ClipboardData(text: _orderId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order ID copied to clipboard')),
    );
  }

  void _goTrack() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(order: widget.order),
      ),
    );
  }

  void _goOrders() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ButtonNavigationBar(
          accessToken: widget.accessToken,
          initialIndex: 1,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent back navigation — user must use the explicit buttons
      canPop: false,
      child: Scaffold(
        backgroundColor: ColorPallets.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(),
                // ── Animated checkmark ──────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: widget.isPayLater
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isPayLater
                          ? Icons.schedule_rounded
                          : Icons.check_circle_rounded,
                      size: 64,
                      color: widget.isPayLater
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Title ──────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Text(
                        widget.isPayLater
                            ? 'Pay Later Order Placed!'
                            : 'Order Placed Successfully!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: ColorPallets.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isPayLater
                            ? 'Settle the payment later to start printing.'
                            : 'Your documents are on their way to being printed.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ColorPallets.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // ── Order ID card ───────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _InfoCard(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded,
                              color: ColorPallets.deepBlue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Order ID',
                            style: TextStyle(
                              color: ColorPallets.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _copyOrderId,
                            child: Row(
                              children: [
                                Text(
                                  _orderId.length > 20
                                      ? '${_orderId.substring(0, 18)}…'
                                      : _orderId,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: ColorPallets.deepBlue,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.copy_rounded,
                                    size: 16,
                                    color: ColorPallets.textSecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // ── Store card ──────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _InfoCard(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  ColorPallets.deepBlue.withValues(alpha: 0.1),
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
                                Text(
                                  _storeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: ColorPallets.textPrimary,
                                  ),
                                ),
                                if (_storeAddress.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _storeAddress,
                                    style: const TextStyle(
                                      color: ColorPallets.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Stat(
                            icon: Icons.description_rounded,
                            label: '$_totalPages page(s)',
                          ),
                          const SizedBox(width: 16),
                          _Stat(
                            icon: Icons.payments_rounded,
                            label: '₹${_totalCost.toStringAsFixed(2)}',
                          ),
                          const SizedBox(width: 16),
                          _Stat(
                            icon: Icons.schedule_rounded,
                            label: _estimatedTime,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // ── CTA buttons ─────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _goTrack,
                          icon: const Icon(Icons.route_rounded),
                          label: const Text('Track Order'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _goOrders,
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('View All Orders'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorPallets.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ColorPallets.deepBlue),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorPallets.textPrimary,
          ),
        ),
      ],
    );
  }
}
