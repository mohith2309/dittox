import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/user_stats_store.dart';

class PlayBillingScreen extends StatefulWidget {
  static const routeName = "/playBilling";
  const PlayBillingScreen({super.key});

  @override
  State<PlayBillingScreen> createState() => _PlayBillingScreenState();
}

class _PlayBillingScreenState extends State<PlayBillingScreen> {
  static const String _merchantName = ApiEndPoiunts.merchantName;
  static const String _razorpayCreateOrderUrl = ApiEndPoiunts.razorpayCreateOrderUrl;
  static const String _razorpayVerifyUrl = ApiEndPoiunts.razorpayVerifyPaymentUrl;
  static const String _razorpayKeyId = String.fromEnvironment(
    'DITTOX_RAZORPAY_KEY_ID',
    defaultValue: '',
  );
  static const int _proAmountPaise = int.fromEnvironment(
    'DITTOX_PRO_AMOUNT_PAISE',
    defaultValue: 46900,
  );
  static const String _proPlanId = String.fromEnvironment(
    'DITTOX_PRO_SUB_ID',
    defaultValue: 'pro_monthly',
  );

  late Razorpay _razorpay;
  bool _isPurchasing = false;
  String _status = "Ready";

  Map<String, dynamic> _releaseShareMeta(int amountPaise) {
    if (!kReleaseMode) return {};
    final pct = ApiEndPoiunts.releaseSharePercent;
    final beneficiary = ApiEndPoiunts.releaseShareBeneficiary.trim();
    if (pct <= 0 || beneficiary.isEmpty) return {};
    final sharePaise = ((amountPaise * pct) / 100).round();
    return {
      "platformShare": {
        "percent": pct,
        "beneficiary": beneficiary,
        "amount_paise": sharePaise,
      }
    };
  }

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<String?> _createRazorpayOrder() async {
    if (_razorpayCreateOrderUrl.isEmpty) return null;
    try {
      final response = await http
          .post(
            Uri.parse(_razorpayCreateOrderUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "amount": _proAmountPaise,
              "currency": "INR",
              "receipt": "dittox_pro_${DateTime.now().millisecondsSinceEpoch}",
              "plan_id": _proPlanId,
              ..._releaseShareMeta(_proAmountPaise),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final body = jsonDecode(response.body);
      final result = body is Map<String, dynamic> ? body["result"] : null;
      final orderId = (body["order_id"] ?? body["id"] ?? result?["order_id"] ?? result?["id"])?.toString();
      if (orderId == null || orderId.trim().isEmpty) return null;
      return orderId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _verifyPayment(PaymentSuccessResponse response) async {
    final hasPaymentId = (response.paymentId ?? '').trim().isNotEmpty;
    // Without a backend verifier the signature can't be checked here, so only
    // accept when Razorpay actually returned a payment id (a real charge)
    // rather than trusting every success callback.
    if (_razorpayVerifyUrl.isEmpty) return hasPaymentId;
    if (!hasPaymentId) return false;
    try {
      final verifyResponse = await http
          .post(
            Uri.parse(_razorpayVerifyUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "razorpay_payment_id": response.paymentId,
              "razorpay_order_id": response.orderId,
              "razorpay_signature": response.signature,
              "plan_id": _proPlanId,
              ..._releaseShareMeta(_proAmountPaise),
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (verifyResponse.statusCode < 200 || verifyResponse.statusCode >= 300) {
        return false;
      }
      final body = jsonDecode(verifyResponse.body);
      if (body is Map<String, dynamic>) {
        return body["verified"] == true ||
            body["status"] == "verified" ||
            body["responseCode"] == "OK";
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _buyProWithRazorpay() async {
    if (_isPurchasing) return;
    setState(() {
      _isPurchasing = true;
      _status = "Opening Razorpay...";
    });

    final orderId = await _createRazorpayOrder();
    final options = <String, dynamic>{
      "key": _razorpayKeyId,
      "amount": _proAmountPaise,
      "currency": "INR",
      "name": _merchantName,
      "description": "Dittox Pro ($_proPlanId)",
      if (orderId != null) "order_id": orderId,
      "retry": {"enabled": true, "max_count": 2},
      "prefill": {"contact": "", "email": ""},
      "theme": {"color": "#1B3A8A"},
      "notes": {
        "plan_id": _proPlanId,
        ..._releaseShareMeta(_proAmountPaise),
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _status = "Unable to open payment: $e";
      });
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final verified = await _verifyPayment(response);
    if (verified) {
      await UserStatsStore.markProSubscribed(planId: _proPlanId);
    }
    if (!mounted) return;
    setState(() {
      _isPurchasing = false;
      if (!verified) {
        _status =
            "Payment received, verification pending. Please contact support if Pro is not activated.";
      } else if (_razorpayVerifyUrl.isEmpty) {
        _status =
            "Dittox Pro activated (test mode — server verification not configured).";
      } else {
        _status = "Dittox Pro activated successfully.";
      }
    });
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() {
      _isPurchasing = false;
      _status = response.message?.isNotEmpty == true
          ? "Payment failed: ${response.message}"
          : "Payment failed. Please try again.";
    });
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() {
      _status = "External wallet selected: ${response.walletName ?? "Wallet"}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColorPallets.white,
        title: const Text("Dittox Pro"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dittox Pro (Razorpay)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text("Plan ID: $_proPlanId"),
                const SizedBox(height: 10),
                Text(
                  "Price: ₹${(_proAmountPaise / 100).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: ColorPallets.deepBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Pro Benefits",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text("• Priority order processing"),
                const Text("• Faster upload & checkout flow"),
                const Text("• Premium support on order issues"),
                const Text("• Early access to new Dittox features"),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPurchasing ? null : _buyProWithRazorpay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPallets.deepBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isPurchasing ? "Processing..." : "Subscribe with Razorpay"),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
