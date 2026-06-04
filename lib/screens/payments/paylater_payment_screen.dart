import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/wallet_store.dart';
import '../nav_drawers/navBar.dart';

class PayLaterPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final String accessToken;
  const PayLaterPaymentScreen({
    super.key,
    required this.order,
    required this.accessToken,
  });

  @override
  State<PayLaterPaymentScreen> createState() => _PayLaterPaymentScreenState();
}

class _PayLaterPaymentScreenState extends State<PayLaterPaymentScreen> {
  static const String _razorpayKeyId = String.fromEnvironment(
    'DITTOX_RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_ScE9I9VKKUwVWA',
  );

  late Razorpay _razorpay;
  bool _isLoading = false;

  String get _orderId {
    final primary = (widget.order["orderId"] ?? "").toString().trim();
    if (primary.isNotEmpty && primary.toLowerCase() != "null") return primary;
    final secondary = (widget.order["_id"] ?? "").toString().trim();
    if (secondary.isNotEmpty && secondary.toLowerCase() != "null") {
      return secondary;
    }
    return "";
  }

  double get _amount => ((widget.order["totalCost"] as num?) ?? 0).toDouble();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (_) => _onSuccess("Razorpay"));
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (_) => _onFailure());
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _finishAndGoOrders() async {
    if (!mounted) return;
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

  Future<void> _onSuccess(String method) async {
    if (_orderId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Missing order id. Please refresh orders.")),
      );
      return;
    }
    final ok = await DemoOrdersStore.markPayLaterPaid(
      orderId: _orderId,
      method: method,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not mark order as paid.")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment successful via $method")),
    );
    await _finishAndGoOrders();
  }

  void _onFailure() {
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment failed. Try again.")),
    );
  }

  Future<void> _payWithWallet() async {
    if (_amount <= 0) return;
    final current = await WalletStore.getBalance(widget.accessToken);
    if (current < _amount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient wallet balance")),
      );
      return;
    }
    await WalletStore.setBalance(widget.accessToken, current - _amount);
    await WalletStore.addTransaction(
      widget.accessToken,
      type: 'debit',
      amount: _amount,
      note: "PayLater settled",
      orderId: _orderId,
      method: 'Wallet',
    );
    await _onSuccess("Wallet");
  }

  Future<void> _payWithRazorpay() async {
    if (_amount <= 0 || _isLoading) return;
    setState(() => _isLoading = true);
    final options = {
      "key": _razorpayKeyId,
      "amount": (_amount * 100).round(),
      "currency": "INR",
      "name": ApiEndPoiunts.merchantName,
      "description": "PayLater order payment",
      "prefill": {"contact": "", "email": ""},
      "retry": {"enabled": true, "max_count": 2},
      "notes": {"order_id": _orderId},
    };
    // _razorpay.open is fire-and-forget; the result arrives via the success/
    // error event handlers, which own resetting _isLoading. Resetting it here
    // would defeat the double-tap guard above while the sheet is open.
    try {
      _razorpay.open(options);
    } catch (_) {
      _onFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColorPallets.white,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 20),
            SizedBox(width: 8),
            Text("PayLater Payment"),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: $_orderId"),
                  const SizedBox(height: 8),
                  Text(
                    "Amount: ₹${_amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ColorPallets.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _payWithRazorpay,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPallets.deepBlue,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_rounded, size: 18),
                const SizedBox(width: 8),
                Text(_isLoading ? "Opening Razorpay..." : "Pay with Razorpay"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _payWithWallet,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wallet_rounded, size: 18),
                SizedBox(width: 8),
                Text("Pay with Wallet"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
