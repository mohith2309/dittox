import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/current_user.dart';
import '../../screens/nav_drawers/navBar.dart';
import '../../utils/color_pallets.dart';
import '../../screens/Orders/order_tracking_screen.dart';
import '../../utils/dynamicSizing.dart';

class CarrOnGoingItem extends StatefulWidget {
  final Map<String, dynamic> onGoingXeroxItem;
  const CarrOnGoingItem({super.key, required this.onGoingXeroxItem});

  @override
  State<CarrOnGoingItem> createState() => _CarrOnGoingItemState();
}

class _CarrOnGoingItemState extends State<CarrOnGoingItem> {
  // String getDate(String data) {
  //   String dateTimeString = data;
  //   DateFormat dateFormat = DateFormat.yMMMMd();
  //   DateTime dateTime =
  //       DateFormat('EEEE, MMMM d, y - h:mm:ss a').parse(dateTimeString);
  //   String dateString = dateFormat.format(dateTime);
  //   return dateString;
  // }

  String getDate(String data) {
    String dateTimeString = data;
    DateTime dateTime = DateTime.parse(dateTimeString);
    DateFormat dateFormat = DateFormat.yMMMMd();
    String dateString = dateFormat.format(dateTime.toLocal());
    return dateString;
  }

  String _statusOfOrder() {
    return (widget.onGoingXeroxItem["status"] ?? "")
        .toString()
        .trim()
        .toLowerCase();
  }

  String _etaForStatus(String status) {
    if (status == "pending") return "ETA: Store review in 2-5 mins";
    if (status == "accepted") return "ETA: Printing starts in 5-10 mins";
    if (status == "printing") return "ETA: Ready in 10-20 mins";
    if (status == "ready") return "ETA: Ready for pickup now";
    if (status == "collected") return "Completed";
    if (status == "rejected" || status == "failed") return "Order closed";
    return "ETA unavailable";
  }

  Color _statusBadgeColor(String status) {
    switch (status) {
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
      case 'rejected':
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _statusBadgeLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'printing':
        return 'Printing…';
      case 'ready':
        return '✓ Ready';
      case 'collected':
        return '✓ Collected';
      case 'rejected':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
    } catch (_) {
      return raw;
    }
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
            currentFontSize: 7,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 12,
            // heightSpecific: false,
          )),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                maxLines: 1,
                key,
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    // fontSize: 12,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 12,
                      // heightSpecific: true,
                    ),
                    color: ColorPallets.deepBlue),
                overflow: TextOverflow.ellipsis,
              ),
              // const SizedBox(
              //   width: 5,
              // ),
              Text(":",
                  style: TextStyle(
                    // fontSize: 12,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 12,
                      // heightSpecific: true,
                    ),
                    color: ColorPallets.deepBlue,
                    fontWeight: FontWeight.w600,
                  ))
            ],
          ),
          // const SizedBox(
          //   height: 5,
          // ),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                // fontSize: 12,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 12,
                  // heightSpecific: true,
                ),
                color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget keyValueOfFeature(
    String key,
    String value,
    double size,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 2,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 12,
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
                  fontSize: size,
                  color: ColorPallets.deepBlue),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            // width: 5,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 12,
              // heightSpecific: false,
            ),
          ),
          Text(
            ":",
            style: TextStyle(
              fontSize: size,
              color: ColorPallets.deepBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            // width: 10,
            width: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 10,
              // heightSpecific: false,
            ),
          ),
          Expanded(
            child: Text(
              maxLines: 8,
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: size,
                  color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget expandedTitle(
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    final status = _statusOfOrder();
    return Container(
      margin: EdgeInsets.symmetric(
        // vertical: 16,
        vertical: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 30,
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
              currentFontSize: 35,
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
                  widget.onGoingXeroxItem["orderId"].toString(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorPallets.deepBlue,
                    // fontSize: 18,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 38,
                      // heightSpecific: true,
                    ),
                    // fontWeight: FontWeight.,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBadgeColor(status).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _statusBadgeLabel(status),
                    style: TextStyle(
                      color: _statusBadgeColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  // height: 3,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 8,
                    // heightSpecific: true,
                  ),
                ),
                Text(
                  widget.onGoingXeroxItem["storeName"],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    // fontSize: 16,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 30,
                      // heightSpecific: true,
                    ),
                  ),
                ),
                SizedBox(
                  // height: 3,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 8,
                    // heightSpecific: true,
                  ),
                ),

                Text(
                  "Created: ${_formatDateTime(widget.onGoingXeroxItem["orderDate"].toString())}",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 24,
                    ),
                    color: Colors.black54,
                  ),
                ),
                Text(
                  _etaForStatus(status),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 24,
                    ),
                    color: ColorPallets.deepBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  // height: 3,
                  height: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 8,
                    // heightSpecific: true,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(
                          order: widget.onGoingXeroxItem,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Track Order',
                        style: TextStyle(
                          color: ColorPallets.deepBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: ColorPallets.deepBlue,
                        size: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                // Row(
                //   children: [
                //     const Text(
                //       "Order-Id :    ",
                //       style: TextStyle(fontSize: 13),
                //     ),
                //     Text(
                //       widget.onGoingXeroxItem["orderId"].toString(),
                //       style: const TextStyle(fontSize: 13),
                //       overflow: TextOverflow.ellipsis,
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

  Widget progressOrderTracker(
    String orderStatus,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    final status = orderStatus.toLowerCase();
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 20,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 10,
            // heightSpecific: false,
          )),
      child: Column(
        children: [
          Text(
            orderStatus,
            style: TextStyle(
                // fontSize: 22,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 60,
                  // heightSpecific: true,
                ),
                color: (status == "rejected" || status == "failed")
                    ? Colors.red
                    : ColorPallets.deepBlue),
          ),
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.manual,
            lineXY: 0.15,
            isFirst: true,
            endChild: Container(
              // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              padding: EdgeInsets.symmetric(
                  vertical: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: false,
                  )),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order accepted",
                      style: TextStyle(
                        // fontSize: 22,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        ),
                        color: (status == "rejected" || status == "failed")
                            ? Colors.red
                            : ColorPallets.deepBlue,
                      ),
                    ),
                    SizedBox(
                      // height: 5,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 5,
                        // heightSpecific: true,
                      ),
                    ),
                    Text(
                        "your order has been accepted by ${widget.onGoingXeroxItem["storeName"]}")
                  ]),
            ),
            afterLineStyle: LineStyle(
                color: (status == "rejected" || status == "failed")
                    ? Colors.red
                    : (status == "pending"
                        ? ColorPallets.lightBlue
                        : ColorPallets.deepBlue),
                thickness: (status == "rejected" || status == "failed")
                    ? 2
                    // : (status == "pending" ? 2 : 5),
                    : (status == "pending"
                        ? calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 5,
                            // heightSpecific: false,
                          )
                        : calculateDynamicFontSize(
                            totalScreenHeight: totalScreenHeight,
                            totalScreenWidth: totalScreenWidth,
                            currentFontSize: 10,
                            // heightSpecific: false,
                          ))),
            indicatorStyle: (status == "rejected" || status == "failed")
                ? IndicatorStyle(
                    color: Colors.red,
                    // height: 10,
                    // width: 10,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 30,
                      // heightSpecific: true,
                    ),
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 30,
                      // heightSpecific: false,
                    ),
                  )
                : (status == "pending"
                    ? IndicatorStyle(
                        color: ColorPallets.lightBlue,
                        // height: 10,
                        // width: 10,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 15,
                          // heightSpecific: true,
                        ),
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 15,
                          // heightSpecific: false,
                        ),
                      )
                    : IndicatorStyle(
                        color: ColorPallets.deepBlue,
                        // height: 20,
                        // width: 20,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 30,
                          // heightSpecific: true,
                        ),
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 30,
                          // heightSpecific: false,
                        ),
                      )),
          ),
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.manual,
            lineXY: 0.15,
            endChild: Container(
              // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              padding: EdgeInsets.symmetric(
                  vertical: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: false,
                  )),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Printing",
                      style: TextStyle(
                        // fontSize: 22,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        ),
                        color: (status == "rejected" || status == "failed")
                            ? Colors.red
                            : ColorPallets.deepBlue,
                      ),
                    ),
                    SizedBox(
                      // height: 5,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 5,
                        // heightSpecific: true,
                      ),
                    ),
                    Text(
                        "${widget.onGoingXeroxItem["storeName"]} has start priting your order")
                  ]),
            ),
            beforeLineStyle: (status == "rejected" || status == "failed")
                ? LineStyle(
                    color: Colors.red,
                    // thickness: 2,
                    thickness: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 5,
                      // heightSpecific: false,
                    ))
                : ((status == "accepted" ||
                        status == "printing" ||
                        status == "ready" ||
                        status == "collected")
                    ? LineStyle(
                        color: ColorPallets.deepBlue,
                        // thickness: 5,
                        thickness: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 10,
                          // heightSpecific: true,
                        ))
                    : LineStyle(
                        color: ColorPallets.lightBlue,
                        // thickness: 2,
                        thickness: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 5,
                          // heightSpecific: true,
                        ),
                      )),
            afterLineStyle: (status == "rejected" || status == "failed")
                ? const LineStyle(color: Colors.red, thickness: 2)
                : ((status == "printing" ||
                        status == "ready" ||
                        status == "collected")
                    ? LineStyle(
                        color: ColorPallets.deepBlue,
                        // thickness: 5,
                        thickness: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 10,
                          // heightSpecific: true,
                        ))
                    : LineStyle(
                        color: ColorPallets.lightBlue,
                        // thickness: 2,
                        thickness: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 5,
                          // heightSpecific: true,
                        ))),
            indicatorStyle: (status == "rejected" || status == "failed")
                ? IndicatorStyle(
                    color: Colors.red,
                    // height: 10,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 15,
                      // heightSpecific: true,
                    ),
                    // width: 10,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 15,
                      // heightSpecific: false,
                    ))
                : ((status != "pending" && status != "accepted")
                    ? IndicatorStyle(
                        color: ColorPallets.deepBlue,
                        // height: 20,
                        // width: 20,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 30,
                          // heightSpecific: true,
                        ),
                        // width: 10,
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 30,
                          // heightSpecific: false,
                        ))
                    : IndicatorStyle(
                        color: ColorPallets.lightBlue,
                        // height: 10,
                        // width: 10,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 15,
                          // heightSpecific: true,
                        ),
                        // width: 10,
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 15,
                          // heightSpecific: false,
                        ))),
          ),
          TimelineTile(
            axis: TimelineAxis.vertical,
            alignment: TimelineAlign.manual,
            lineXY: 0.15,
            isLast: true,
            endChild: Container(
              // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              padding: EdgeInsets.symmetric(
                  vertical: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  horizontal: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: false,
                  )),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ready To Pick",
                      style: TextStyle(
                        // fontSize: 22,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        ),
                        color: (status == "rejected" || status == "failed")
                            ? Colors.red
                            : ColorPallets.deepBlue,
                      ),
                    ),
                    SizedBox(
                      // height: 5,
                      height: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 5,
                        // heightSpecific: true,
                      ),
                    ),
                    const Text("you can come or colleted your copies"),
                    const Text("Tap on our Navigation Icon for Google maps "),
                  ]),
            ),
            beforeLineStyle: (status == "rejected" || status == "failed")
                ? const LineStyle(color: Colors.red, thickness: 2)
                : ((status == "printing" ||
                        status == "ready" ||
                        status == "collected")
                    ? LineStyle(
                        color: ColorPallets.deepBlue,
                        // thickness: 5,
                        thickness: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 10,
                          // heightSpecific: true,
                        ),
                      )
                    : LineStyle(
                        color: ColorPallets.lightBlue,
                        // thickness: 2,
                        thickness: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 5,
                          // heightSpecific: true,
                        ),
                      )),
            indicatorStyle: (status == "rejected" || status == "failed")
                ? IndicatorStyle(
                    color: Colors.red,
                    // height: 10,
                    // width: 10,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 15,
                      // heightSpecific: true,
                    ),
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 15,
                      // heightSpecific: false,
                    ))
                : ((status == "ready" || status == "collected")
                    ? IndicatorStyle(
                        color: ColorPallets.deepBlue,
                        // height: 20,
                        // width: 20,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 30,
                          // heightSpecific: true,
                        ),
                        // width: 10,
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 30,
                          // heightSpecific: false,
                        ))
                    : IndicatorStyle(
                        color: ColorPallets.lightBlue,
                        // height: 10,
                        // width: 10,
                        height: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 15,
                          // heightSpecific: true,
                        ),
                        width: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 15,
                          // heightSpecific: false,
                        ))),
          ),
        ],
      ),
    );
  }

  Widget aditionalOrderDetails(
    CurrentUser curUSer,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      padding: EdgeInsets.symmetric(
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 5,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 50,
            // heightSpecific: false,
          )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shop Address",
            style: TextStyle(
              color: ColorPallets.deepBlue,
              // fontSize: 22,
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 40,
                // heightSpecific: true,
              ),
            ),
          ),
          SizedBox(
            // height: 5,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 5,
              // heightSpecific: true,
            ),
          ),
          Text(widget.onGoingXeroxItem["storeAddress"]),
          SizedBox(
            // height: 10,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: true,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                  child: Text(
                "Total Pages - ${widget.onGoingXeroxItem["totalPages"]}",
                style: TextStyle(
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                ),
              )),
              Expanded(
                  child: Text("Rs ${widget.onGoingXeroxItem["totalCost"]}",
                      style: TextStyle(
                        // fontSize: 24,
                        fontSize: calculateDynamicFontSize(
                          totalScreenHeight: totalScreenHeight,
                          totalScreenWidth: totalScreenWidth,
                          currentFontSize: 40,
                          // heightSpecific: true,
                        ),
                        color: ColorPallets.deepBlue,
                      ))),
            ],
          ),
          SizedBox(
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 20,
            ),
          ),
          Text(
            "Fulfillment: ${widget.onGoingXeroxItem["fulfillmentMode"] ?? "Pickup"}",
            style: TextStyle(
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 34,
              ),
              color: ColorPallets.deepBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((widget.onGoingXeroxItem["pickupSlot"] ?? "")
              .toString()
              .trim()
              .isNotEmpty)
            Text("Pickup slot: ${widget.onGoingXeroxItem["pickupSlot"]}"),
          if (widget.onGoingXeroxItem["rushOrder"] == true)
            const Text("Rush order: Yes"),
          if ((widget.onGoingXeroxItem["deliveryAddress"] ?? "")
              .toString()
              .trim()
              .isNotEmpty)
            Text("Delivery: ${widget.onGoingXeroxItem["deliveryAddress"]}"),
          if ((widget.onGoingXeroxItem["cancelReason"] ?? "")
              .toString()
              .trim()
              .isNotEmpty) ...[
            SizedBox(
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
              ),
            ),
            Text(
              "Cancel reason: ${widget.onGoingXeroxItem["cancelReason"]}",
              style: TextStyle(
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 34,
                ),
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          SizedBox(
            // height: 10,
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 30,
              // heightSpecific: true,
            ),
          ),
          // Text(
          //   "Takes ${widget.onGoingXeroxItem["durationFromCurrentLocation"]} to reach ${widget.onGoingXeroxItem["shopName"]} Shop which is ${widget.onGoingXeroxItem["shopDistanceFromCurrentLocation"]} far",
          //   style: TextStyle(),
          //   maxLines: 4,
          // ),
          // const SizedBox(
          //   height: 10,
          // ),
          TextButton.icon(
              onPressed: () {
                // openMapsNavigation(
                //     curUSer.getUsetLatitude,
                //     curUSer.getUserLongitude,
                //     double.parse(widget.onGoingXeroxItem["shopLatitude"]),
                //     double.parse(widget.onGoingXeroxItem["shopLongitude"]));
                mapLauncher(
                    widget.onGoingXeroxItem["storeAddress"].toString(),
                    widget.onGoingXeroxItem["storeLocationX"].toString(),
                    widget.onGoingXeroxItem["storeLocationY"].toString());
                // launchGoogleMaps(
                //   double.parse(widget.onGoingXeroxItem["shopLatitude"]),
                //   double.parse(widget.onGoingXeroxItem["shopLongitude"]),
                // );
              },
              icon: const FaIcon(
                FontAwesomeIcons.locationArrow,
                color: ColorPallets.deepBlue,
              ),
              label: Text(
                "Tap here to open Google Maps",
                style: TextStyle(
                  // fontSize: 18,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 40,
                    // heightSpecific: true,
                  ),
                  color: ColorPallets.deepBlue,
                ),
              )),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                ButtonNavigationBar.routeName,
              );
            },
            icon:
                const Icon(Icons.replay_outlined, color: ColorPallets.deepBlue),
            label: Text(
              "Reorder Similar",
              style: TextStyle(
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 34,
                ),
                color: ColorPallets.deepBlue,
              ),
            ),
          ),
          SizedBox(
            height: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: true,
            ),
          )
        ],
      ),
    );
  }

  void mapLauncher(String mapAddress, String latitude, String longitude) {
    MapsLauncher.launchCoordinates(
        double.parse(latitude), double.parse(longitude));
    // MapsLauncher.launchQuery(mapAddress);
  }

  void openMapsNavigation(double startLatitude, double startLongitude,
      double destinationLatitude, double destinationLongitude) async {
    // String googleMapsUrl =
    //     'https://www.google.com/maps/dir/?api=1&origin=$startLatitude,$startLongitude&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
    String url =
        'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude&travelmode=driving';
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open map navigation.')),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final mqSize = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqSize.height;
    final double totalScreenWidth = mqSize.width;
    final curUser = Provider.of<CurrentUser>(context, listen: false);
    return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 20,
            // heightSpecific: true,
          ),
          vertical: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 20,
            // heightSpecific: true,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
                color: ColorPallets.deepBlue,
                width: 1,
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
            // trailing: SizedBox(),
            // trailing: Icon(Icons.arrow_drop_down),
            // subtitle: const Text(
            //   'view more',
            //   style: TextStyle(
            //     color: ColorPallets.deepBlue,
            //     fontStyle: FontStyle.italic,
            //   ),
            // ),
            children: <Widget>[
              progressOrderTracker(
                widget.onGoingXeroxItem["status"],
                totalScreenHeight,
                totalScreenWidth,
              ),
              // const SizedBox(
              //   height: 20,
              // ),
              aditionalOrderDetails(
                curUser,
                totalScreenHeight,
                totalScreenWidth,
              ),
            ],
          ),
        ));
  }
}
