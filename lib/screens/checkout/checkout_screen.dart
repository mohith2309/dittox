import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../providers/ListOfPdfFiles.dart';
import '../../providers/app_notifications.dart';
import '../../providers/seletedShop.dart';
import '../../utils/api_endpoints.dart';
import '../../utils/color_pallets.dart';
import '../../utils/coupon_codes.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/operational_order_service.dart';
import '../../utils/payment_preferences_store.dart';
import '../../utils/pill_notifications.dart';
import '../../utils/user_stats_store.dart';
import '../../utils/user_preferences_store.dart';
import '../../utils/wallet_store.dart';
import '../../widgets/common/pill_appbar_title.dart';
import '../nav_drawers/navBar.dart';
import '../Orders/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = "/checkout";

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const String _merchantName = ApiEndPoiunts.merchantName;
  static const String _razorpayCreateOrderUrl =
      ApiEndPoiunts.razorpayCreateOrderUrl;
  static const String _razorpayVerifyUrl =
      ApiEndPoiunts.razorpayVerifyPaymentUrl;
  static const String _razorpayKeyId = String.fromEnvironment(
    'DITTOX_RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_ScE9I9VKKUwVWA',
  );

  String _accessToken = "";
  double _walletBalance = 0.0;
  bool _isWalletReady = false;
  bool _isRazorpayLoading = false;
  bool _isTopUpInProgress = false;
  String? _pendingRazorpayFlow;
  double _pendingRazorpayAmount = 0;
  double _pendingDiscountApplied = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isProSubscriber = false;
  double _discountSaved = 0;
  double _topupBonusSaved = 0;
  String _fulfillmentMode = 'Pickup';
  String _pickupSlot = '';
  bool _rushOrder = false;
  List<String> _savedAddresses = const <String>[];
  String _selectedAddress = '';
  String _defaultPaymentMethod = 'Wallet';
  String _selectedPaymentMethod = 'Wallet';
  List<String> _savedCards = const <String>[];
  final TextEditingController _couponController = TextEditingController();
  String _appliedCouponCode = '';
  String _couponMessage = '';
  double _couponDiscount = 0;
  double _lastFailedPaymentAmount = 0;
  double _lastFailedPaymentDiscount = 0;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
    _loadCheckoutPreferences();
  }

  Future<void> _loadCheckoutPreferences() async {
    final addresses = await UserPreferencesStore.getSavedAddresses();
    final defaultPayment = await UserPreferencesStore.getDefaultPayment();
    final savedCards = await PaymentPreferencesStore.getSavedCards();
    if (!mounted) return;
    setState(() {
      _savedAddresses = addresses;
      _selectedAddress = addresses.isNotEmpty ? addresses.first : '';
      _defaultPaymentMethod = defaultPayment;
      _selectedPaymentMethod = defaultPayment;
      _savedCards = savedCards;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeToken =
        ModalRoute.of(context)?.settings.arguments as String? ?? "demo_token";
    if (_accessToken != routeToken) {
      _accessToken = routeToken;
      _loadWallet();
      _loadUserStats();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    try {
      final stored = await WalletStore.getBalance(_accessToken);
      final txns = await WalletStore.getTransactions(_accessToken);
      if (!mounted) return;
      setState(() {
        _walletBalance = stored;
        _transactions = txns;
        _isWalletReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletBalance = 0;
        _transactions = [];
        _isWalletReady = true;
      });
    }
  }

  Future<void> _saveWallet(double value) async {
    await WalletStore.setBalance(_accessToken, value);
  }

  Future<void> _loadUserStats() async {
    final isPro = await UserStatsStore.isProSubscriber();
    final saved = await UserStatsStore.getDiscountSaved();
    final bonusSaved = await UserStatsStore.getTopupBonusSaved();
    if (!mounted) return;
    setState(() {
      _isProSubscriber = isPro;
      _discountSaved = saved;
      _topupBonusSaved = bonusSaved;
    });
  }

  Future<bool> _canPlaceOrderOrShowDuesBlock() async {
    if (_fulfillmentMode == 'Delivery' && _selectedAddress.trim().isEmpty) {
      PillNotifications.show(
        context,
        message: "Add/select a delivery address first.",
        type: PillType.error,
      );
      return false;
    }
    final unpaidPayLaterCount = await DemoOrdersStore.getUnpaidPayLaterCount();

    if (unpaidPayLaterCount >= ApiEndPoiunts.maxUnpaidPayLaterOrders) {
      return _showPayLaterLimitDialog(unpaidPayLaterCount);
    }
    return true;
  }

  Future<bool> _showPayLaterLimitDialog(int unpaidPayLaterCount) async {
    if (!mounted) return false;
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("PayLater dues found"),
        content: Text(
          "This test device has $unpaidPayLaterCount unpaid PayLater orders saved locally. "
          "Settle dues first, or open PayLater to review pending orders.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop("cancel"),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop("open"),
            child: const Text("Open PayLater"),
          ),
        ],
      ),
    );

    if (action == "open") {
      if (!mounted) return false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ButtonNavigationBar(
            accessToken: _accessToken,
            initialIndex: 2,
          ),
        ),
        (route) => false,
      );
    }

    return false;
  }

  Future<void> _topUpWalletAfterRazorpay(double amount) async {
    final double bonus = _isProSubscriber ? (amount * 0.10) : 0;
    final credited = amount + bonus;
    final next = _walletBalance + credited;
    await _saveWallet(next);
    await WalletStore.addTransaction(
      _accessToken,
      type: "credit",
      amount: credited,
      note:
          _isProSubscriber ? "Wallet top-up (+10% Pro bonus)" : "Wallet top-up",
    );
    if (bonus > 0) {
      await UserStatsStore.addTopupBonusSaved(bonus);
    }
    final txns = await WalletStore.getTransactions(_accessToken);
    if (!mounted) return;
    setState(() {
      _walletBalance = next;
      _transactions = txns;
      if (bonus > 0) _topupBonusSaved += bonus;
    });
    PillNotifications.show(
      context,
      message: bonus > 0
          ? "Wallet topped up by Rs ${amount.toInt()} (+Rs ${bonus.toStringAsFixed(0)} Pro bonus)"
          : "Wallet topped up by Rs ${amount.toInt()}",
      type: PillType.success,
    );
  }

  Future<void> _payWithWallet(
    double amount,
    String accessToken, {
    double discountApplied = 0,
  }) async {
    final allowed = await _canPlaceOrderOrShowDuesBlock();
    if (!allowed) return;
    if (!mounted) return;
    if (_walletBalance < amount) {
      context.read<AppNotifications>().addWarning(
            title: 'Low wallet balance',
            body: 'Please top up wallet or use Razorpay to continue.',
          );
      PillNotifications.show(
        context,
        message: "Insufficient test wallet balance",
        type: PillType.error,
      );
      return;
    }

    final next = _walletBalance - amount;
    await _saveWallet(next);
    await WalletStore.addTransaction(
      _accessToken,
      type: "debit",
      amount: amount,
      note: "Order payment",
    );
    if (discountApplied > 0) {
      await UserStatsStore.addDiscountSaved(discountApplied);
    }
    final txns = await WalletStore.getTransactions(_accessToken);
    if (!mounted) return;
    setState(() {
      _walletBalance = next;
      _transactions = txns;
      if (discountApplied > 0) _discountSaved += discountApplied;
    });

    PillNotifications.show(
      context,
      message:
          "Test payment successful (Wallet). Rs ${amount.toStringAsFixed(2)}",
      type: PillType.success,
    );

    await _createOrderAndGoToOrdersTab(accessToken);
  }

  Future<void> _createOrderAndGoToOrdersTab(String accessToken) async {
    final shop =
        Provider.of<seletedShop>(context, listen: false).getSeletedShop();
    final pdfs = Provider.of<ListOfPDFFiles>(context, listen: false).allPdfList;
    String orderId = '';
    try {
      final int totalPages = pdfs.fold<int>(
          0, (sum, pdf) => sum + pdf.selectedPagesCount * pdf.copies);
      final double totalCost = pdfs.fold<double>(
          0.0, (sum, pdf) => sum + pdf.selectedPagesCount * pdf.copies * 2.0);
      orderId = await DemoOrdersStore.addOrder(
        shop: shop,
        pdfs: pdfs,
        payLater: false,
        fulfillmentMode: _fulfillmentMode,
        pickupSlot: _pickupSlot,
        rushOrder: _rushOrder,
        deliveryAddress: _selectedAddress,
        defaultPaymentMethod: _selectedPaymentMethod,
      ).timeout(const Duration(seconds: 2), onTimeout: () => '');
      if (_appliedCouponCode.isNotEmpty) {
        await CouponSystem.markCouponUsed(_appliedCouponCode);
      }
      if (!mounted) return;
      final confirmOrder = <String, dynamic>{
        'orderId': orderId,
        'storeName': shop.storeName,
        'storeAddress': shop.address,
        'storeContactNumber': shop.contactNumber,
        'storeLocationX': shop.locationX,
        'storeLocationY': shop.locationY,
        'totalCost': totalCost,
        'totalPages': totalPages,
        'fulfillmentMode': _fulfillmentMode,
        'status': 'accepted',
      };
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            order: confirmOrder,
            accessToken: accessToken,
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ButtonNavigationBar(
            accessToken: accessToken,
            initialIndex: 1,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _createPayLaterOrderAndGoToOrdersTab(String accessToken) async {
    final allowed = await _canPlaceOrderOrShowDuesBlock();
    if (!allowed) return;
    if (!mounted) return;
    final shop =
        Provider.of<seletedShop>(context, listen: false).getSeletedShop();
    final pdfs = Provider.of<ListOfPDFFiles>(context, listen: false).allPdfList;
    var orderId = '';
    try {
      orderId = await DemoOrdersStore.addOrder(
        shop: shop,
        pdfs: pdfs,
        payLater: true,
        fulfillmentMode: _fulfillmentMode,
        pickupSlot: _pickupSlot,
        rushOrder: _rushOrder,
        deliveryAddress: _selectedAddress,
        defaultPaymentMethod: _selectedPaymentMethod,
      ).timeout(const Duration(seconds: 2), onTimeout: () => '');
      if (_appliedCouponCode.isNotEmpty) {
        await CouponSystem.markCouponUsed(_appliedCouponCode);
      }
    } catch (_) {}
    if (!mounted) return;
    // Build confirmation data from available state
    final shop2 =
        Provider.of<seletedShop>(context, listen: false).getSeletedShop();
    final pdfs2 =
        Provider.of<ListOfPDFFiles>(context, listen: false).allPdfList;
    final int totalPages2 = pdfs2.fold<int>(
        0, (sum, pdf) => sum + pdf.selectedPagesCount * pdf.copies);
    final double totalCost2 = pdfs2.fold<double>(
        0.0, (sum, pdf) => sum + pdf.selectedPagesCount * pdf.copies * 2.0);
    final confirmOrder2 = <String, dynamic>{
      'orderId': orderId.isEmpty ? 'Pay Later Order' : orderId,
      'storeName': shop2.storeName,
      'storeAddress': shop2.address,
      'totalCost': totalCost2,
      'totalPages': totalPages2,
      'fulfillmentMode': _fulfillmentMode,
      'status': 'pending',
    };
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          order: confirmOrder2,
          accessToken: accessToken,
          isPayLater: true,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    final flow = _pendingRazorpayFlow;
    if (flow == "wallet_topup") {
      await _topUpWalletAfterRazorpay(_pendingRazorpayAmount);
      _pendingRazorpayFlow = null;
      _pendingRazorpayAmount = 0;
      if (mounted) {
        setState(() {
          _isTopUpInProgress = false;
          _isRazorpayLoading = false;
        });
      }
      return;
    }

    var verificationStatus = 'received';
    if (_razorpayVerifyUrl.isNotEmpty) {
      final isVerified = await _verifyRazorpayPayment(response);
      verificationStatus = isVerified ? 'verified' : 'received_unverified';
      if (!isVerified && mounted) {
        PillNotifications.show(
          context,
          message:
              "Payment success received. Creating a local order while server verification is unavailable.",
          type: PillType.warning,
          duration: const Duration(seconds: 4),
        );
      }
    }
    final paymentId = (response.paymentId ?? response.orderId ?? '').trim();
    if (paymentId.isNotEmpty) {
      unawaited(
        OperationalOrderService.recordPaymentConfirmation(
          paymentId: paymentId,
          orderId: response.orderId,
          amount: _pendingRazorpayAmount,
          method: 'razorpay',
          status: verificationStatus,
        ),
      );
    }
    if (_pendingDiscountApplied > 0) {
      await UserStatsStore.addDiscountSaved(_pendingDiscountApplied);
      if (mounted) {
        setState(() {
          _discountSaved += _pendingDiscountApplied;
        });
      }
    }
    _pendingRazorpayFlow = null;
    _pendingRazorpayAmount = 0;
    _pendingDiscountApplied = 0;
    if (mounted) setState(() => _isRazorpayLoading = false);
    await _createOrderAndGoToOrdersTab(_accessToken);
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    final failedAmount = _pendingRazorpayAmount;
    final failedDiscount = _pendingDiscountApplied;
    final reason = response.message?.isNotEmpty == true
        ? response.message!
        : "Razorpay payment failed.";
    unawaited(
      OperationalOrderService.scheduleFailedPaymentRetry(
        reason: reason,
        amount: failedAmount,
      ),
    );
    _pendingRazorpayFlow = null;
    _pendingRazorpayAmount = 0;
    _pendingDiscountApplied = 0;
    if (mounted) {
      setState(() {
        _isTopUpInProgress = false;
        _isRazorpayLoading = false;
        _lastFailedPaymentAmount = failedAmount;
        _lastFailedPaymentDiscount = failedDiscount;
      });
    }
    if (!mounted) return;
    PillNotifications.show(
      context,
      message: response.message?.isNotEmpty == true
          ? "Razorpay failed: ${response.message}"
          : "Razorpay payment failed.",
      type: PillType.error,
    );
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isRazorpayLoading = false);
    PillNotifications.show(
      context,
      message: "External wallet selected: ${response.walletName ?? 'Wallet'}",
      type: PillType.info,
    );
  }

  Future<String?> _createRazorpayOrder(double amount,
      {required String receiptTag}) async {
    if (_razorpayCreateOrderUrl.isEmpty) return null;
    try {
      final response = await http
          .post(
            Uri.parse(_razorpayCreateOrderUrl),
            headers: {
              'Content-Type': 'application/json',
              if (_accessToken.trim().isNotEmpty &&
                  _accessToken != "demo_token")
                'X-auth-token': 'bearer $_accessToken',
            },
            body: jsonEncode({
              "amount": (amount * 100).round(),
              "currency": "INR",
              "receipt":
                  "${receiptTag}_${DateTime.now().millisecondsSinceEpoch}",
            }),
          )
          .timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final result = body is Map<String, dynamic> ? body["result"] : null;
      final orderId = (body["order_id"] ??
              body["id"] ??
              result?["order_id"] ??
              result?["id"])
          ?.toString();
      if (orderId == null || orderId.trim().isEmpty) return null;
      return orderId;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _verifyRazorpayPayment(PaymentSuccessResponse response) async {
    try {
      final verifyPayload = {
        "razorpay_payment_id": response.paymentId,
        "razorpay_order_id": response.orderId,
        "razorpay_signature": response.signature,
      };
      final verifyResponse = await http
          .post(
            Uri.parse(_razorpayVerifyUrl),
            headers: {
              'Content-Type': 'application/json',
              if (_accessToken.trim().isNotEmpty &&
                  _accessToken != "demo_token")
                'X-auth-token': 'bearer $_accessToken',
            },
            body: jsonEncode(verifyPayload),
          )
          .timeout(const Duration(seconds: 8));

      if (verifyResponse.statusCode < 200 || verifyResponse.statusCode >= 300) {
        return false;
      }
      final body = jsonDecode(verifyResponse.body);
      if (body is Map<String, dynamic>) {
        if (body["verified"] == true ||
            body["status"] == "verified" ||
            body["responseCode"] == "OK") {
          return true;
        }
      }
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _payOrderWithRazorpay(
    double amount, {
    double discountApplied = 0,
  }) async {
    final allowed = await _canPlaceOrderOrShowDuesBlock();
    if (!allowed) return;
    if (_isRazorpayLoading) return;
    setState(() => _isRazorpayLoading = true);
    _pendingRazorpayFlow = "order_payment";
    _pendingRazorpayAmount = amount;
    _pendingDiscountApplied = discountApplied;
    final backendOrderId =
        await _createRazorpayOrder(amount, receiptTag: "dittox_order");
    final options = {
      'key': _razorpayKeyId,
      'amount': (amount * 100).round(),
      'name': _merchantName,
      'description': 'Dittox order payment',
      'currency': 'INR',
      if (backendOrderId != null) 'order_id': backendOrderId,
      'prefill': {
        'contact': '',
        'email': '',
      },
      'retry': {'enabled': true, 'max_count': 2}
    };
    try {
      if (backendOrderId == null &&
          mounted &&
          _razorpayCreateOrderUrl.isNotEmpty) {
        PillNotifications.show(
          context,
          message:
              "Could not create payment order on server. Opening direct Razorpay checkout.",
          type: PillType.warning,
          duration: const Duration(seconds: 4),
        );
      }
      _razorpay.open(options);
    } catch (e) {
      _pendingRazorpayFlow = null;
      _pendingRazorpayAmount = 0;
      _pendingDiscountApplied = 0;
      if (!mounted) return;
      setState(() => _isRazorpayLoading = false);
      PillNotifications.show(
        context,
        message: "Unable to open Razorpay: $e",
        type: PillType.error,
      );
    }
  }

  Future<void> _topUpWalletWithRazorpay(double amount) async {
    if (_isTopUpInProgress || _isRazorpayLoading) return;
    setState(() {
      _isTopUpInProgress = true;
      _isRazorpayLoading = true;
    });
    _pendingRazorpayFlow = "wallet_topup";
    _pendingRazorpayAmount = amount;
    final options = {
      'key': _razorpayKeyId,
      'amount': (amount * 100).round(),
      'name': _merchantName,
      'description': 'Dittox wallet top-up',
      'currency': 'INR',
      'prefill': {'contact': '', 'email': ''},
      'retry': {'enabled': true, 'max_count': 2}
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      _pendingRazorpayFlow = null;
      _pendingRazorpayAmount = 0;
      if (!mounted) return;
      setState(() {
        _isTopUpInProgress = false;
        _isRazorpayLoading = false;
      });
      PillNotifications.show(
        context,
        message: "Unable to open Razorpay: $e",
        type: PillType.error,
      );
    }
  }

  List<String> _pickupSlots() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final slot = now.add(Duration(minutes: 30 * (index + 1)));
      final hour = slot.hour % 12 == 0 ? 12 : slot.hour % 12;
      final minute = slot.minute.toString().padLeft(2, '0');
      final suffix = slot.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    });
  }

  Future<void> _applyCoupon(double amount) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    final result = await CouponSystem.validateCoupon(code, amount);
    if (!mounted) return;
    setState(() {
      _couponMessage = result.easterEggMessage ?? result.message;
      if (result.isValid) {
        _appliedCouponCode = code.toUpperCase();
        _couponDiscount = result.discountAmount;
      } else {
        _appliedCouponCode = '';
        _couponDiscount = 0;
      }
    });
    PillNotifications.show(
      context,
      message: _couponMessage,
      type: result.isValid ? PillType.success : PillType.error,
    );
  }

  void _clearAppliedCouponForPriceChange() {
    if (_appliedCouponCode.isEmpty && _couponDiscount == 0) return;
    _appliedCouponCode = '';
    _couponDiscount = 0;
    _couponMessage = 'Coupon cleared. Apply again for the updated total.';
  }

  Future<void> _addSavedCard() async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Card Label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Example: HDFC card ending 4242',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label == null || label.isEmpty) return;
    await PaymentPreferencesStore.addSavedCard(label);
    await _loadCheckoutPreferences();
  }

  Future<void> _downloadReceiptPdf({
    required double amount,
    required double discount,
    required int totalPages,
    required int totalCopies,
    required String shopName,
  }) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final graphics = page.graphics;
    final titleFont =
        PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    var y = 24.0;
    void line(String text) {
      graphics.drawString(text, bodyFont,
          bounds: Rect.fromLTWH(24, y, 480, 20));
      y += 24;
    }

    graphics.drawString('Dittox Estimate', titleFont,
        bounds: Rect.fromLTWH(24, y, 480, 28));
    y += 42;
    line('Shop: $shopName');
    line('Documents: $totalPages page(s), $totalCopies copy/copies');
    line(
        'Fulfillment: $_fulfillmentMode${_pickupSlot.isEmpty ? '' : ' at $_pickupSlot'}');
    if (_selectedAddress.isNotEmpty) line('Address: $_selectedAddress');
    if (_appliedCouponCode.isNotEmpty) line('Coupon: $_appliedCouponCode');
    line('Discount: Rs ${discount.toStringAsFixed(2)}');
    line('Payable: Rs ${amount.toStringAsFixed(2)}');
    line('Generated: ${DateTime.now().toLocal()}');

    final bytes = await document.save();
    document.dispose();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/dittox_receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path, type: 'application/pdf');
  }

  @override
  Widget build(BuildContext context) {
    final selectedShopProvider = Provider.of<seletedShop>(context);
    final pdfFilesProvider = Provider.of<ListOfPDFFiles>(context);

    final selectedShop = selectedShopProvider.getSeletedShop();
    final documents = pdfFilesProvider.allPdfList;
    final totalPages =
        documents.fold<int>(0, (sum, pdf) => sum + pdf.selectedPagesCount);
    final totalCopies = documents.fold<int>(0, (sum, pdf) => sum + pdf.copies);
    final rushFee = _rushOrder ? 20.0 : 0.0;
    final estimatedAmount =
        (selectedShop.cost <= 0 ? 1.0 : selectedShop.cost) + rushFee;
    final couponDiscount =
        _couponDiscount > estimatedAmount ? estimatedAmount : _couponDiscount;
    final afterCoupon = estimatedAmount - couponDiscount;
    final discountedAmount =
        _isProSubscriber ? (afterCoupon * 0.9) : afterCoupon;
    final effectiveAmount = discountedAmount < 1 ? 1.0 : discountedAmount;
    final proDiscount = _isProSubscriber ? afterCoupon - discountedAmount : 0.0;
    final discountApplied = estimatedAmount - effectiveAmount;
    final accessToken = _accessToken;

    return Scaffold(
      appBar: AppBar(
        title: const PillAppBarTitle(
          title: 'Checkout',
          icon: Icons.shopping_bag_rounded,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(selectedShop.storeName),
              subtitle: Text(selectedShop.address),
              trailing: Text(
                "Rs ${selectedShop.cost.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorPallets.swiggyOrange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Summary",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Documents: ${documents.length}"),
                  Text("Total pages: $totalPages"),
                  Text("Total copies: $totalCopies"),
                  Text("Distance: ${selectedShop.distance}"),
                  Text("ETA: ${selectedShop.duration}"),
                  Text("Fulfillment: $_fulfillmentMode"),
                  if (_pickupSlot.isNotEmpty) Text("Pickup slot: $_pickupSlot"),
                  if (_rushOrder) const Text("Rush fee: Rs 20.00"),
                  if (couponDiscount > 0)
                    Text(
                        "Coupon discount: -Rs ${couponDiscount.toStringAsFixed(2)}"),
                  const SizedBox(height: 8),
                  Text(
                    "Estimated total: Rs ${estimatedAmount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorPallets.swiggyOrange,
                    ),
                  ),
                  if (_isProSubscriber) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Dittox Pro discount (10%): -Rs ${proDiscount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: ColorPallets.deepBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Payable now: Rs ${effectiveAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorPallets.swiggyOrange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Promo Code",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'DITTOX10',
                            prefixIcon: Icon(Icons.local_offer_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _applyCoupon(estimatedAmount),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  if (_couponMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _couponMessage,
                      style: TextStyle(
                        color: couponDiscount > 0
                            ? ColorPallets.deepBlue
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Delivery Options",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Pickup',
                        label: Text('Pickup'),
                        icon: Icon(Icons.storefront_rounded),
                      ),
                      ButtonSegment(
                        value: 'Delivery',
                        label: Text('Delivery'),
                        icon: Icon(Icons.delivery_dining_rounded),
                      ),
                    ],
                    selected: {_fulfillmentMode},
                    onSelectionChanged: (value) {
                      setState(() => _fulfillmentMode = value.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _pickupSlot.isEmpty ? null : _pickupSlot,
                    decoration: const InputDecoration(
                      labelText: 'Scheduled pickup slot',
                      prefixIcon: Icon(Icons.schedule_rounded),
                    ),
                    items: _pickupSlots()
                        .map(
                          (slot) => DropdownMenuItem(
                            value: slot,
                            child: Text(slot),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _pickupSlot = value ?? ''),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rush order'),
                    subtitle:
                        const Text('Prioritize this order for Rs 20 extra'),
                    value: _rushOrder,
                    onChanged: (value) => setState(() {
                      _rushOrder = value;
                      _clearAppliedCouponForPriceChange();
                    }),
                  ),
                  if (_fulfillmentMode == 'Delivery') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAddress.isEmpty ? null : _selectedAddress,
                      decoration: const InputDecoration(
                        labelText: 'Delivery address',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      items: _savedAddresses
                          .map(
                            (address) => DropdownMenuItem(
                              value: address,
                              child: Text(
                                address,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedAddress = value ?? ''),
                    ),
                    if (_savedAddresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Add saved addresses from Settings before using delivery.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text('Preferred payment: $_defaultPaymentMethod'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "This checkout uses Razorpay for online payments.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment Options",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final method in const [
                        'Wallet',
                        'UPI',
                        'Saved Card',
                        'Google Pay',
                        'Paytm',
                        'Net Banking',
                        'COD',
                        'Razorpay'
                      ])
                        ChoiceChip(
                          label: Text(method),
                          selected: _selectedPaymentMethod == method,
                          onSelected: (_) =>
                              setState(() => _selectedPaymentMethod = method),
                        ),
                    ],
                  ),
                  if (_selectedPaymentMethod == 'Saved Card') ...[
                    const SizedBox(height: 10),
                    if (_savedCards.isEmpty) const Text('No saved cards yet.'),
                    for (final card in _savedCards)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.credit_card_rounded),
                        title: Text(card),
                      ),
                    OutlinedButton.icon(
                      onPressed: _addSavedCard,
                      icon: const Icon(Icons.add_card_rounded),
                      label: const Text('Save card label'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    _selectedPaymentMethod == 'COD'
                        ? 'COD creates a Pay Later style order for store collection.'
                        : 'Selected method will use the safest available local/Razorpay flow.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (_lastFailedPaymentAmount > 0) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _payOrderWithRazorpay(
                          _lastFailedPaymentAmount,
                          discountApplied: _lastFailedPaymentDiscount,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry Failed Payment'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isWalletReady
                          ? () {
                              if (_selectedPaymentMethod == 'Wallet') {
                                _payWithWallet(
                                  effectiveAmount,
                                  accessToken,
                                  discountApplied: discountApplied,
                                );
                              } else if (_selectedPaymentMethod == 'COD') {
                                _createPayLaterOrderAndGoToOrdersTab(
                                    accessToken);
                              } else {
                                _payOrderWithRazorpay(
                                  effectiveAmount,
                                  discountApplied: discountApplied,
                                );
                              }
                            }
                          : null,
                      icon: const Icon(Icons.lock_rounded),
                      label: Text('Pay with $_selectedPaymentMethod'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadReceiptPdf(
                        amount: effectiveAmount,
                        discount: discountApplied,
                        totalPages: totalPages,
                        totalCopies: totalCopies,
                        shopName: selectedShop.storeName,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Download Estimate PDF'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Wallet",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isWalletReady
                        ? "Balance: Rs ${_walletBalance.toStringAsFixed(2)}"
                        : "Loading wallet...",
                    style: const TextStyle(color: Colors.black87),
                  ),
                  if (_isProSubscriber) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Pro top-up bonus saved: Rs ${_topupBonusSaved.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: ColorPallets.deepBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isWalletReady
                              ? () => _topUpWalletWithRazorpay(100)
                              : null,
                          child: Text(_isProSubscriber
                              ? "Add Rs 100 (+10%)"
                              : "Add Rs 100 (Razorpay)"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isWalletReady
                              ? () => _topUpWalletWithRazorpay(500)
                              : null,
                          child: Text(_isProSubscriber
                              ? "Add Rs 500 (+10%)"
                              : "Add Rs 500 (Razorpay)"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isWalletReady
                          ? () => _payWithWallet(
                                effectiveAmount,
                                accessToken,
                                discountApplied: discountApplied,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPallets.deepBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Pay with Test Wallet"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Text(
                      "No transactions yet",
                      style: TextStyle(color: Colors.black54),
                    ),
                  for (final txn in _transactions.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              txn["note"]?.toString() ?? "Transaction",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${txn["type"] == "credit" ? "+" : "-"}Rs ${(txn["amount"] as num?)?.toStringAsFixed(2) ?? "0.00"}",
                            style: TextStyle(
                              color: txn["type"] == "credit"
                                  ? ColorPallets.deepBlue
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Razorpay Payment",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Amount: Rs ${effectiveAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRazorpayLoading
                          ? null
                          : () => _payOrderWithRazorpay(
                                effectiveAmount,
                                discountApplied: discountApplied,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPallets.deepBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isRazorpayLoading
                            ? "Preparing Razorpay..."
                            : "Pay with Razorpay",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _createPayLaterOrderAndGoToOrdersTab(accessToken),
                      child: const Text("Place as Pay Later"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProSubscriber)
            Text(
              "Total saved with Dittox Pro: Rs ${(_discountSaved + _topupBonusSaved).toStringAsFixed(2)}",
              style: const TextStyle(
                color: ColorPallets.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
