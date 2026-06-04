import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../screens/nav_drawers/navBar.dart';
import '../../screens/payments/paylater_payment_screen.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';
import '../../utils/wallet_store.dart';

class PayLaterCard extends StatefulWidget {
  final Map<String, dynamic> payLaterXeroxItem;
  final String accessToken;
  const PayLaterCard({
    super.key,
    required this.payLaterXeroxItem,
    required this.accessToken,
  });

  @override
  State<PayLaterCard> createState() => _PayLaterCardState();
}

class _PayLaterCardState extends State<PayLaterCard> {
  late Razorpay _razorPay;

  String _asText(dynamic value, {String fallback = ""}) {
    if (value == null) return fallback;
    final text = value.toString();
    if (text.trim().isEmpty || text.toLowerCase() == "null") return fallback;
    return text;
  }

  void _handlePaymentSuccess(
      BuildContext ctx, PaymentSuccessResponse response) {
    if (!mounted) return;
    final amount =
        (widget.payLaterXeroxItem['totalCost'] as num?)?.toDouble() ?? 0;
    WalletStore.getBalance(widget.accessToken).then((value) async {
      await WalletStore.setBalance(widget.accessToken, value + amount);
      await WalletStore.addTransaction(
        widget.accessToken,
        type: 'credit',
        amount: amount,
        note: "PayLater payment received",
        orderId: widget.payLaterXeroxItem['_id']?.toString(),
        method: 'Razorpay',
      );
    });
    if (!mounted) return;
    Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (ctx) => ButtonNavigationBar(
            accessToken: widget.accessToken,
          ),
        ),
        (route) => false);
  }

  void _handlePaymentError(BuildContext ctx, PaymentFailureResponse response) {
    if (!mounted) return;
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Status'),
          content: const Text('Payment is failed. Please try again once.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                // showFailedAlertDialog(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    _razorPay.clear();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // no-op
  }

  @override
  void initState() {
    super.initState();
    _razorPay = Razorpay();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      _handlePaymentSuccess(context, response);
    });
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      _handlePaymentError(context, response);
    });
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorPay.clear();
    super.dispose();
  }

  void fetchData(String downloadUrl) async {
    final response = await http.get(Uri.parse(downloadUrl)
        // Uri.parse('http://xerox-bucket.s3.ap-south-1.amazonaws.com/users/654b38f06fbd53e8ae895492-1705153162465-form%2011.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIA2S5BGTLKY4PRAOMX%2F20240113%2Fap-south-1%2Fs3%2Faws4_request&X-Amz-Date=20240113T133923Z&X-Amz-Expires=604800&X-Amz-Signature=c98ad7cef56ca3975d387bc01714fe8288b97e2f2a715cec2ecc44915d2ad588&X-Amz-SignedHeaders=host'),
        );

    if (response.statusCode == 200) {
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception('Failed to load data');
    }
  }

  void launchWebsite(String downloadUrl) async {
    if (downloadUrl.trim().isEmpty) return;
    final uri = Uri.tryParse(downloadUrl.trim());
    if (uri != null && uri.hasScheme && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document link is unavailable.')),
    );
  }

  String getDate(dynamic data) {
    final dateTimeString = _asText(data);
    if (dateTimeString.isEmpty) return "N/A";
    final dateTime = DateTime.tryParse(dateTimeString);
    if (dateTime == null) return "N/A";
    final dateFormat = DateFormat.yMMMMd();
    return dateFormat.format(dateTime.toLocal());
  }

  Widget keyValueLong(
    String key,
    String value,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 14,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 24,
            // heightSpecific: false,
          )),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                maxLines: 2,
                key,
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    // fontSize: 18,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 36,
                      // heightSpecific: true,
                    ),
                    color: ColorPallets.deepBlue),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                // width: 10,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              Text(":",
                  style: TextStyle(
                    // fontSize: 18,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 36,
                      // heightSpecific: true,
                    ),
                    color: ColorPallets.deepBlue,
                    fontWeight: FontWeight.w600,
                  ))
            ],
          ),
          SizedBox(
            // height: 10,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: true,
            ),
          ),
          Text(
            value,
            maxLines: 3,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                // fontSize: 18,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 36,
                  // heightSpecific: true,
                ),
                color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget expandedTitle(
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        // vertical: 16,
        vertical: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 20,
          // heightSpecific: true,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Image.asset(
              "assets/image/xerox_sample.png",
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            // width: 20,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _asText(widget.payLaterXeroxItem["orderId"], fallback: "N/A"),
                  style: TextStyle(
                    color: ColorPallets.deepBlue,
                    // fontSize: 22,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 44,
                      // heightSpecific: true,
                    ),
                    // fontWeight: FontWeight.,
                    fontStyle: FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  // height: 3,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 6,
                    // heightSpecific: true,
                  ),
                ),
                Text(
                  _asText(widget.payLaterXeroxItem["storeName"],
                      fallback: "Store"),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // fontSize: 18,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 36,
                      // heightSpecific: true,
                    ),
                  ),
                ),
                SizedBox(
                  // height: 3,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 6,
                    // heightSpecific: true,
                  ),
                ),
                Text(
                  getDate(widget.payLaterXeroxItem["orderDate"]),
                  style: TextStyle(
                    // fontSize: 13,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 26,
                      // heightSpecific true,
                    ),
                  ),
                ),
                SizedBox(
                  // height: 3,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 6,
                    // heightSpecific: true,
                  ),
                ),
                // Row(
                //   children: [
                //     const Text(
                //       "Order-Id :    ",
                //       style: TextStyle(fontSize: 13),
                //     ),
                //     Text(
                //       widget.historyXeroxItem["orderId"]
                //           .toString()
                //           .substring(0, 6)
                //           .toString(),
                //       style: const TextStyle(fontSize: 13),
                //     )
                //   ],
                // ),
                // Chip(
                //   backgroundColor: ColorPallets.deepBlue,
                //   label: Padding(
                //       padding: const EdgeInsets.symmetric(
                //           horizontal: 7, vertical: 10),
                //       child: FittedBox(
                //         child: Text(
                //           // ignore: unnecessary_brace_in_string_interps
                //           "${widget.onGoingXeroxItem["priceOfOrder"]} Rs",
                //           overflow: TextOverflow.ellipsis,
                //           style: const TextStyle(
                //               fontSize: 20, color: ColorPallets.white),
                //         ),
                //       )),
                // ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget keyValueOfFeature(
    String key,
    String value,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 14,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 24,
            // heightSpecific: false,
          )),
      child: Row(
        children: [
          Expanded(
            child: Text(
              maxLines: 2,
              key,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 36,
                    // heightSpecific: true,
                  ),
                  color: ColorPallets.deepBlue),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            // width: 10,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: false,
            ),
          ),
          Text(
            ":",
            style: TextStyle(
              // fontSize: 18,
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 36,
                // heightSpecific: true,
              ),
              color: ColorPallets.deepBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            // width: 20,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            ),
          ),
          Expanded(
            child: Text(
              maxLines: 8,
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 36,
                    // heightSpecific: true,
                  ),
                  color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget keyValueOfFeatureDownload(
    int fileNumber,
    String downloadUrl,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      // padding: const EdgeInsets.only(top: 5, left: 12, right: 12),
      padding: EdgeInsets.only(
          top: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 10,
            // heightSpecific: true,
          ),
          left: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 24,
            // heightSpecific: false,
          ),
          right: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 24,
            // heightSpecific: false,
          )),
      child: Row(
        children: [
          Expanded(
            child: Text(
              maxLines: 2,
              "File $fileNumber ",
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 36,
                    // heightSpecific: true,
                  ),
                  color: ColorPallets.deepBlue),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            // width: 10,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
              // heightSpecific: false,
            ),
          ),
          Text(
            ":",
            style: TextStyle(
              // fontSize: 18,
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 36,
                // heightSpecific: true,
              ),
              color: ColorPallets.deepBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            // width: 20,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: true,
            ),
          ),
          Expanded(
              child: TextButton(
            child: Text(
              maxLines: 8,
              "download file",
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 36,
                    // heightSpecific: true,
                  ),
                  color: ColorPallets.darkPurple),
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => launchWebsite(downloadUrl),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawItems = widget.payLaterXeroxItem["items"];
    final List<Map<String, dynamic>> itemsList = rawItems is List
        ? rawItems
            .map((e) => e is Map<String, dynamic>
                ? e
                : e is Map
                    ? Map<String, dynamic>.from(e)
                    : <String, dynamic>{})
            .toList()
        : <Map<String, dynamic>>[];
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;

    List<Widget> itemWidgets = [];

    for (int index = 0; index < itemsList.length; index++) {
      itemWidgets.add(
        Column(
          children: [
            keyValueOfFeatureDownload(
              index + 1,
              _asText(itemsList[index]["downloadUrl"]),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Copies ",
              itemsList[index]["copies"].toString(),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Total Pages ",
              itemsList[index]["totalPages"].toString(),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Cost ",
              itemsList[index]["itemCost"].toString(),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Color ",
              _asText(itemsList[index]["itemColor"], fallback: "N/A"),
              totalScreenHeight,
              totalScreenWidth,
            ),
            _asText(itemsList[index]["colorPartialPagesList"]).isNotEmpty
                ? keyValueOfFeature(
                    "Color Partials  ",
                    _asText(itemsList[index]["colorPartialPagesList"]),
                    totalScreenHeight,
                    totalScreenWidth,
                  )
                : const SizedBox(),
            itemsList[index]["bondPage"] != null
                ? keyValueOfFeature(
                    "Bond Papers  ",
                    "Yes",
                    totalScreenHeight,
                    totalScreenWidth,
                  )
                : keyValueOfFeature(
                    "Bond Papers  ",
                    "No",
                    totalScreenHeight,
                    totalScreenWidth,
                  ),
            keyValueOfFeature(
              "Paper Size ",
              _asText(itemsList[index]["paperSize"], fallback: "A4"),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Print Layout ",
              _asText(itemsList[index]["printLayout"], fallback: "Portrait"),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Binding Formate ",
              _asText(itemsList[index]["binding"], fallback: "No Binding"),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Print Side Formate ",
              _asText(itemsList[index]["side"], fallback: "single-side Print"),
              totalScreenHeight,
              totalScreenWidth,
            ),

            index == itemsList.length - 1
                ? const SizedBox()
                : Padding(
                    // padding: const EdgeInsets.only(left: 12, right: 12),
                    padding: EdgeInsets.symmetric(
                        vertical: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 24,
                          // heightSpecific: true,
                        ),
                        horizontal: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 24,
                          // heightSpecific: false,
                        )),
                    child: Divider(
                      color: Colors.black54.withValues(alpha: 0.2),
                      // thickness: 1,
                      thickness: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 2,
                        // heightSpecific: true,
                      ),
                    ),
                  ),

            SizedBox(
              // height: 10,
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
            ), // Adjust the spacing as needed
          ],
        ),
      );
    }

    Future<void> deleteOrder(String? idCandidate, BuildContext ctx) async {
      final internalOrderId = _asText(
        idCandidate,
        fallback: _asText(widget.payLaterXeroxItem["orderId"]),
      );
      if (widget.accessToken == "demo_token") {
        Navigator.of(ctx).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (ctx) => ButtonNavigationBar(
                accessToken: widget.accessToken,
              ),
            ),
            (route) => false);
        return;
      }
      if (internalOrderId.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ColorPallets.deepBlue,
            content: Text("Could not identify this order. Please refresh."),
          ),
        );
        return;
      }
      try {
        final String url =
            'https://dittox.in/xerox/v1/orders/delete/$internalOrderId';
        final response = await http.put(Uri.parse(url),
            headers: {'X-auth-token': 'bearer ${widget.accessToken}'});

        if (response.statusCode == 200) {
          // Check if response code is OK
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['responseCode'] == 'OK') {
            // Response code is OK, handle success
            if (!ctx.mounted) return;
            Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (ctx) => ButtonNavigationBar(
                    accessToken: widget.accessToken,
                  ),
                ),
                (route) => false);
          } else {
            // Response code is not OK, handle error
            throw Exception(
                'Failed to delete order: ${jsonResponse['message']}');
          }
        } else {
          // Handle non-200 status code
          throw Exception('Failed to delete order: ${response.statusCode}');
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorPallets.deepBlue,
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.red,
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      e.toString(),
                      style: TextStyle(
                        // fontSize: 18,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        ),
                        fontStyle: FontStyle.normal,
                        color: ColorPallets.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Padding(
        padding: EdgeInsets.symmetric(
          // horizontal: 20,
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 40,
            // heightSpecific: false,
          ),
          vertical: 0,
        ),
        child: Container(
          margin: EdgeInsets.symmetric(
            // vertical: 15,
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 30,
              // heightSpecific: true,
            ),
          ),
          decoration: BoxDecoration(
              border: Border.all(
                color: ColorPallets.deepBlue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            iconColor: ColorPallets.deepBlue,
            title: expandedTitle(
              totalScreenHeight,
              totalScreenWidth,
            ),
            backgroundColor:
                const Color.fromARGB(255, 178, 239, 240).withValues(alpha: 0.1),
            children: <Widget>[
              // progressOrderTracker(widget.historyXeroxItem["orderStatus"]),
              SizedBox(
                // height: 20,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: true,
                ),
              ),
              Text(
                "Document Details",
                style: TextStyle(
                    color: ColorPallets.deepBlue,
                    // fontSize: 22,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 44,
                      // heightSpecific: true,
                    ),
                    fontStyle: FontStyle.italic),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    // horizontal: 20,
                    horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: false,
                )),
                child: Divider(
                  color: ColorPallets.deepBlue,
                  // thickness: 2,
                  thickness: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 4,
                    // heightSpecific: true,
                  ),
                ),
              ),

              Column(
                children: itemWidgets,
              ),

              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              Text(
                "Shop Detials",
                style: TextStyle(
                    color: ColorPallets.deepBlue,
                    // fontSize: 22,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 44,
                      // heightSpecific: true,
                    ),
                    fontStyle: FontStyle.italic),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    // horizontal: 20,
                    horizontal: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: false,
                )),
                child: Divider(
                  color: ColorPallets.deepBlue,
                  // thickness: 2,
                  thickness: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 4,
                    // heightSpecific: true,
                  ),
                ),
              ),
              keyValueOfFeature(
                "Shope Name",
                _asText(widget.payLaterXeroxItem['storeName'],
                    fallback: "Store"),
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueOfFeature(
                "Contact-Number",
                _asText(widget.payLaterXeroxItem['storeContactNumber'],
                    fallback: "N/A"),
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueOfFeature(
                "Shop Email",
                _asText(widget.payLaterXeroxItem['storeEmail'],
                    fallback: "N/A"),
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Shop Addres",
                _asText(widget.payLaterXeroxItem['storeAddress'],
                    fallback: "N/A"),
                totalScreenHeight,
                totalScreenWidth,
              ),

              SizedBox(
                // height: 10,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 20,
                  // heightSpecific: true,
                ),
              ),
              Text(
                "Order Detials",
                style: TextStyle(
                    color: ColorPallets.deepBlue,
                    // fontSize: 22,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 44,
                      // heightSpecific: true,
                    ),
                    fontStyle: FontStyle.italic),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  // horizontal: 20,
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: false,
                  ),
                ),
                child: Divider(
                  color: ColorPallets.deepBlue,
                  // thickness: 2,
                  thickness: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 4,
                    // heightSpecific: true,
                  ),
                ),
              ),
              // keyValueOfFeature("OrderId", widget.historyXeroxItem['orderId']),

              keyValueLong(
                "OrderId",
                _asText(widget.payLaterXeroxItem['orderId'], fallback: "N/A"),
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueOfFeature(
                "Date Of Order",
                getDate(widget.payLaterXeroxItem['orderDate']),
                totalScreenHeight,
                totalScreenWidth,
              ),
              // keyValueLong("Date Of Order",
              //     getDate(widget.historyXeroxItem['orderDate'])),
              keyValueOfFeature(
                "Total Cost",
                _asText(widget.payLaterXeroxItem['totalCost'], fallback: "0"),
                totalScreenHeight,
                totalScreenWidth,
              ),
              SizedBox(
                // height: 20,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 40,
                  // heightSpecific: true,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 30,
                    // heightSpecific: true,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          await deleteOrder(
                            _asText(
                              widget.payLaterXeroxItem['_id'],
                              fallback:
                                  _asText(widget.payLaterXeroxItem["orderId"]),
                            ),
                            context,
                          );
                        },
                        child: Container(
                          // width: MediaQuery.of(context).size.width * 0.3,
                          // Make the container fill the entire width
                          padding: EdgeInsets.symmetric(
                            // vertical: 10,
                            vertical: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 20,
                              // heightSpecific: true,
                            ),
                            // horizontal: 8,
                            horizontal: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 16,
                              // heightSpecific: false,
                            ),
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.redAccent,
                              width: calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 2,
                                // heightSpecific: true,
                              ),
                            ),
                            // color: ColorPallets
                            //     .deepBlue, // Set the background color to green
                            borderRadius: BorderRadius.circular(
                              // 10,
                              calculateDynamicFontSize(
                                totalScreenHeight: totalScreenHeight,
                                totalScreenWidth: totalScreenWidth,
                                currentFontSize: 20,
                                // heightSpecific: true,
                              ),
                            ), // Set round borders
                          ),
                          child: Center(
                            child: Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors
                                    .redAccent, // Assuming ColorPallets.white is equivalent to Colors.white
                                // fontSize: 22,
                                fontSize: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 44,
                                  // heightSpecific: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 40,
                        // heightSpecific: true,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PayLaterPaymentScreen(
                                order: widget.payLaterXeroxItem,
                                accessToken: widget.accessToken,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          // width: MediaQuery.of(context).size.width * 0.3,
                          // Make the container fill the entire width
                          padding: EdgeInsets.symmetric(
                            // vertical: 10,
                            vertical: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 20,
                              // heightSpecific: true,
                            ),
                            // horizontal: 8,
                            horizontal: calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 16,
                              // heightSpecific: false,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: ColorPallets
                                .deepBlue, // Set the background color to green
                            borderRadius: BorderRadius.circular(
                                // 10,
                                calculateDynamicFontSize(
                              totalScreenHeight: totalScreenHeight,
                              totalScreenWidth: totalScreenWidth,
                              currentFontSize: 20,
                              // heightSpecific: true,
                            )), // Set round borders
                          ),
                          child: Center(
                            child: Text(
                              "Pay Now",
                              style: TextStyle(
                                color: Colors
                                    .white, // Assuming ColorPallets.white is equivalent to Colors.white
                                // fontSize: 22,
                                fontSize: calculateDynamicFontSize(
                                  totalScreenHeight: totalScreenHeight,
                                  totalScreenWidth: totalScreenWidth,
                                  currentFontSize: 44,
                                  // heightSpecific: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                // height: 15,
                height: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 30,
                  // heightSpecific: true,
                ),
              )
            ],
          ),
        ));
  }
}
