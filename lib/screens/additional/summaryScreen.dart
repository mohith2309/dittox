import 'dart:async';
import 'dart:convert';

import 'package:dittox/utils/color_pallets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../providers/ListOfPdfFiles.dart';
import '../../providers/current_user.dart';
import '../../providers/seletedShop.dart';
import '../../utils/api_endpoints.dart';
import '../../utils/demo_orders_store.dart';
import '../../utils/dynamicSizing.dart';
import '../nav_drawers/navBar.dart';

class SummaryScreen extends StatefulWidget {
  static const routeName = "/summary";
  final String accessToken;

  const SummaryScreen({super.key, required this.accessToken});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const String _razorpayKeyId = String.fromEnvironment(
    'DITTOX_RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_ScE9I9VKKUwVWA',
  );

  late Razorpay _razorPay;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _razorPay = Razorpay();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorPay.clear();
    super.dispose();
  }

  void _goToOrdersHome() {
    Provider.of<ListOfPDFFiles>(context, listen: false).emptyPDFfile();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx) => ButtonNavigationBar(
          accessToken: widget.accessToken,
          initialIndex: 1,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _createDemoOrder({required bool payLater}) async {
    final shop =
        Provider.of<seletedShop>(context, listen: false).getSeletedShop();
    final pdfs = Provider.of<ListOfPDFFiles>(context, listen: false).allPdfList;
    await DemoOrdersStore.addOrder(shop: shop, pdfs: pdfs, payLater: payLater);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment successful. Order placed.")),
    );
    _goToOrdersHome();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.message?.isNotEmpty == true
              ? "Payment failed: ${response.message}"
              : "Payment failed. Please try again.",
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("External wallet: ${response.walletName ?? "Wallet"}")),
    );
  }

  List<int> _extractRangeValues(String rangeString) {
    final values = rangeString
        .split('-')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .toList();
    return values.length == 2 ? values : const [1, 1];
  }

  String _getColorCode(String input) {
    switch (input.toLowerCase()) {
      case 'black & white':
        return 'bw';
      case 'all color':
        return 'multi';
      case 'partial color':
        return 'colpar';
      default:
        return '';
    }
  }

  List<int> _generateColorPageList(String input) {
    if (input.trim().isEmpty) return <int>[];
    final result = <int>[];
    for (final range in input.split(',')) {
      if (range.contains('-')) {
        final rangeParts = range.split('-');
        final start = int.tryParse(rangeParts[0].trim()) ?? 0;
        final end = int.tryParse(rangeParts[1].trim()) ?? 0;
        for (int i = start; i <= end; i++) {
          result.add(i);
        }
      } else {
        final value = int.tryParse(range.trim());
        if (value != null) result.add(value);
      }
    }
    return result;
  }

  String _getPaperSize(String input) {
    switch (input.toUpperCase()) {
      case 'A4':
        return 'a4';
      case 'A5':
        return 'a5';
      case 'LEGAL':
        return 'legal';
      case 'LETTER':
        return 'letter';
      case 'B5':
        return 'b5';
      case 'A6':
        return 'a6';
      case 'POST CARD':
        return 'postCard';
      case '5*7':
        return '5*7';
      case '4*6':
        return '4*6';
      case '3.5*5':
        return '3.5*5';
      default:
        return '';
    }
  }

  String _getBindingType(String input) {
    switch (input.toLowerCase()) {
      case 'no binding':
        return 'noBinding';
      case 'staples':
        return 'Staples';
      case 'spiral':
        return 'Spiral';
      case 'stick file':
        return 'Stick File';
      default:
        return '';
    }
  }

  Map<String, dynamic> _releaseShareMeta() {
    if (!kReleaseMode) return {};
    final pct = ApiEndPoiunts.releaseSharePercent;
    final beneficiary = ApiEndPoiunts.releaseShareBeneficiary.trim();
    if (pct <= 0 || beneficiary.isEmpty) return {};
    return {
      "platformShare": {
        "percent": pct,
        "beneficiary": beneficiary,
      }
    };
  }

  Map<String, dynamic> _preparePayloadForOrder() {
    final finalShop = Provider.of<seletedShop>(context, listen: false);
    final listfinalPdfs = Provider.of<ListOfPDFFiles>(context, listen: false);
    final payload = <String, dynamic>{
      "items": [],
      "storeId": finalShop.getSeletedShop().id
    };

    for (final eachPdf in listfinalPdfs.allPdfList) {
      final colorCode = _getColorCode(eachPdf.color);
      final eachPDFPayload = <String, dynamic>{
        "copies": eachPdf.copies.toString(),
        "pageRange": _extractRangeValues(eachPdf.pageRange),
        "sides": eachPdf.pdfSides == "Single Side" ? "one" : "both",
        "printLayout": eachPdf.pdfPrintLayout,
        "colors": {"color": colorCode},
        "colorPar": {
          "description": "",
          "total": 0,
          "pageNumbers": colorCode == "colpar"
              ? _generateColorPageList(eachPdf.colorParPageNumbers)
              : <int>[],
        },
        "paperSize": _getPaperSize(eachPdf.paperSize),
        "bondPage": {
          "selected": eachPdf.bondPages ? "yes" : "no",
          "description": "",
          "total": 0
        },
        "binding": _getBindingType(eachPdf.binding),
        "instructions": eachPdf.additionDesciption,
        "fileName": eachPdf.name,
        "totalPages": eachPdf.totalPages,
        "document": eachPdf.documents,
      };
      (payload["items"] as List).add(eachPDFPayload);
    }
    payload.addAll(_releaseShareMeta());
    return payload;
  }

  Future<void> _payLater() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    if (widget.accessToken.trim().isEmpty ||
        widget.accessToken == "demo_token") {
      await _createDemoOrder(payLater: true);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _goToOrdersHome();
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiEndPoiunts.baseUrl}/orders/create'),
            headers: {
              "Content-Type": "application/json",
              "X-auth-token": "bearer ${widget.accessToken}",
            },
            body:
                json.encode({..._preparePayloadForOrder(), "orderLater": true}),
          )
          .timeout(const Duration(seconds: 15));

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body["responseCode"] == "OK") {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _goToOrdersHome();
      } else {
        throw Exception(body["message"] ?? "Could not create order");
      }
    } on TimeoutException {
      await _createDemoOrder(payLater: true);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Server slow. Pay-later order saved locally.")),
      );
      _goToOrdersHome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pay-later failed: $e")),
      );
    }
  }

  Future<void> _makePayment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    if (widget.accessToken.trim().isEmpty ||
        widget.accessToken == "demo_token") {
      await _createDemoOrder(payLater: false);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _goToOrdersHome();
      return;
    }

    final currentUser = Provider.of<CurrentUser>(context, listen: false);

    try {
      final response = await http
          .post(
            Uri.parse('${ApiEndPoiunts.baseUrl}/orders/create'),
            headers: {
              "Content-Type": "application/json",
              "X-auth-token": "bearer ${widget.accessToken}",
            },
            body: json.encode(_preparePayloadForOrder()),
          )
          .timeout(const Duration(seconds: 15));

      final body = json.decode(response.body);
      if (response.statusCode == 200 && body["responseCode"] == "OK") {
        final result = (body["result"] as Map?) ?? <String, dynamic>{};
        final totalCostNum = (result["totalCost"] is num)
            ? (result["totalCost"] as num)
            : num.tryParse("${result["totalCost"]}") ?? 0;
        final amountPaise = (totalCostNum * 100).round();
        final razorpayOrderId =
            (result["razorpayOrderId"] ?? result["orderId"] ?? "").toString();

        final options = <String, dynamic>{
          "key": _razorpayKeyId,
          "amount": amountPaise > 0 ? amountPaise : 100,
          "currency": "INR",
          "name": "Dittox",
          "description": "Order Payment",
          if (razorpayOrderId.isNotEmpty) "order_id": razorpayOrderId,
          "prefill": {
            "name": currentUser.getUserName,
            "email": currentUser.getUserEmail,
            "contact": currentUser.getUserPhoneNumber,
          },
          "theme": {"color": "#3399cc"},
        };

        _razorPay.open(options);
        return;
      }
      throw Exception(body["message"] ?? "Could not create order");
    } on TimeoutException {
      await _createDemoOrder(payLater: false);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server slow. Order saved locally.")),
      );
      _goToOrdersHome();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final totalScreenHeight = mqsz.height;
    final totalScreenWidth = mqsz.width;

    final finalShop = Provider.of<seletedShop>(context);
    final listfinalPdfs = Provider.of<ListOfPDFFiles>(context);
    final shopDetails = finalShop.shopOrderPreview();

    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColorPallets.white,
        backgroundColor: ColorPallets.deepBlue,
        title: const Text("Order Preview"),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 40,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 30,
          ),
        ),
        child: ListView(
          children: [
            Text(
              "Document Details",
              style: TextStyle(
                color: ColorPallets.deepBlue,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 44,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(
              color: ColorPallets.deepBlue,
              thickness: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 4,
              ),
            ),
            for (final eachPdf in listfinalPdfs.allPdfList)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _keyValueOfFeature(
                      "Pdf File Name",
                      eachPdf.name.split(".")[0],
                      totalScreenHeight,
                      totalScreenWidth),
                  _keyValueOfFeature("Price", "Rs ${shopDetails["price"]}",
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature("No of Copies", eachPdf.copies.toString(),
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature(
                      "Total Pages",
                      "${eachPdf.totalPages} X ${eachPdf.copies}",
                      totalScreenHeight,
                      totalScreenWidth),
                  _keyValueOfFeature("Page Range", eachPdf.pageRange,
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature("Orientation", eachPdf.pdfPrintLayout,
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature("Sides", eachPdf.pdfSides,
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature("Print Type", eachPdf.color,
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature("Binding", eachPdf.binding,
                      totalScreenHeight, totalScreenWidth),
                  _keyValueOfFeature(
                      "Bond Pages",
                      eachPdf.bondPages ? "Yes" : "No",
                      totalScreenHeight,
                      totalScreenWidth),
                  if (eachPdf.color == "Partial Color")
                    _keyValueOfFeature(
                        "Color Range",
                        eachPdf.colorParPageNumbers,
                        totalScreenHeight,
                        totalScreenWidth),
                  if (eachPdf.additionDesciption.trim().isNotEmpty)
                    _keyValueLong("Instructions", eachPdf.additionDesciption,
                        totalScreenHeight, totalScreenWidth),
                  Divider(
                      color: Colors.black54.withValues(alpha: 0.2),
                      thickness: 2),
                ],
              ),
            Text(
              "Shop Details",
              style: TextStyle(
                color: ColorPallets.deepBlue,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 44,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: ColorPallets.deepBlue, thickness: 4),
            _keyValueOfFeature("Shop Name", shopDetails["shopName"]!,
                totalScreenHeight, totalScreenWidth),
            _keyValueOfFeature("Contact", shopDetails["contactNumber"]!,
                totalScreenHeight, totalScreenWidth),
            _keyValueOfFeature("Email", shopDetails["shopEmail"]!,
                totalScreenHeight, totalScreenWidth),
            _keyValueOfFeature("Distance", shopDetails["distance"]!,
                totalScreenHeight, totalScreenWidth),
            _keyValueOfFeature("Time", shopDetails["duration"]!,
                totalScreenHeight, totalScreenWidth),
            _keyValueLong("Address", shopDetails["shopAddress"]!,
                totalScreenHeight, totalScreenWidth),
          ],
        ),
      ),
      bottomSheet: Container(
        height: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 180,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        decoration:
            BoxDecoration(color: ColorPallets.lightBlue.withValues(alpha: 0.1)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Chip(
              label: Text(
                "Rs ${shopDetails["price"]}",
                style: const TextStyle(fontSize: 44, color: ColorPallets.white),
              ),
              backgroundColor: ColorPallets.deepBlue,
            ),
            InkWell(
              onTap: _isSubmitting
                  ? null
                  : () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Payment method'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _makePayment();
                              },
                              child: const Text('Pay Now'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _payLater();
                              },
                              child: const Text('Pay Later'),
                            ),
                          ],
                        ),
                      ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Row(
                  children: [
                    Text(
                      _isSubmitting ? "Processing..." : "Pay",
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: ColorPallets.deepBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const FaIcon(FontAwesomeIcons.arrowRight,
                        color: ColorPallets.deepBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyValueLong(String key, String value, double totalScreenHeight,
      double totalScreenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key,
              style:
                  const TextStyle(color: ColorPallets.deepBlue, fontSize: 36)),
          Text(value,
              style: const TextStyle(color: Colors.black54, fontSize: 36)),
        ],
      ),
    );
  }

  Widget _keyValueOfFeature(String key, String value, double totalScreenHeight,
      double totalScreenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(key,
                  style: const TextStyle(
                      color: ColorPallets.deepBlue, fontSize: 36))),
          const Text(": ",
              style: TextStyle(color: ColorPallets.deepBlue, fontSize: 36)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.black54, fontSize: 36))),
        ],
      ),
    );
  }
}
