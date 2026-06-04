import 'package:dittox/widgets/Cart/review.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../model/pdfFile.dart';
import '../../providers/ListOfPdfFiles.dart';
import '../../screens/pdf/pdfFilter.dart';
import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';

class HistoryCard extends StatefulWidget {
  final Map<String, dynamic> historyXeroxItem;
  final String accesstoken;
  const HistoryCard({
    super.key,
    required this.historyXeroxItem,
    required this.accesstoken,
  });

  @override
  State<HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<HistoryCard> {
  Future<void> launchWebsite(String downloadUrl) async {
    final uri = Uri.tryParse(downloadUrl.trim());
    if (uri == null || !uri.hasScheme) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document link is unavailable.')),
      );
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open document link.')),
    );
  }

  void _reorderSimilar() {
    final rawItems = widget.historyXeroxItem["items"];
    final items = rawItems is List ? rawItems : const <dynamic>[];
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This order has no reusable document data.')),
      );
      return;
    }

    final pdfList = context.read<ListOfPDFFiles>();
    pdfList.emptyPDFfile();
    for (var i = 0; i < items.length; i++) {
      final item = items[i] is Map
          ? Map<String, dynamic>.from(items[i] as Map)
          : <String, dynamic>{};
      final doc = _safeText(item["downloadUrl"], fallback: "");
      if (doc.isEmpty) continue;
      final pages =
          int.tryParse(_safeText(item["totalPages"], fallback: "1")) ?? 1;
      final copies =
          int.tryParse(_safeText(item["copies"], fallback: "1")) ?? 1;
      pdfList.addPDFFile(
        PdfData(
          name: 'Reorder file ${i + 1}.pdf',
          size: '-',
          totalPages: pages,
          copies: copies,
          binding: _safeText(item["binding"], fallback: 'No binding'),
          paperSize: _safeText(item["paperSize"], fallback: 'A4'),
          pdfSides: _safeText(item["side"], fallback: 'Single side'),
          pdfPrintLayout: _safeText(item["printLayout"], fallback: 'Portrait'),
          color: _safeText(item["itemColor"], fallback: 'Black & White'),
          pageRange: _safeText(item["pageRange"], fallback: '1-$pages'),
          colorParDesciption: '',
          colorParPageNumbers: '',
          colorParTotal: 0,
          additionDesciption: _safeText(item["notes"], fallback: ''),
          documents: doc,
          bondPages: item["bondPage"] == true,
          collateCopies: item["collateCopies"] == true,
          numberCopies: item["numberCopies"] == true,
        ),
      );
    }

    if (pdfList.allPdfList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid documents found for reorder.')),
      );
      return;
    }
    Navigator.of(context).pushNamed(PDFFilters.routeName);
  }

  String _safeText(dynamic value, {String fallback = "-"}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == "null") return fallback;
    return text;
  }

  String getDate(dynamic data) {
    final dateTimeString = _safeText(data, fallback: "");
    if (dateTimeString.isEmpty) return "-";
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final dateFormat = DateFormat.yMMMMd();
      return dateFormat.format(dateTime.toLocal());
    } catch (_) {
      return dateTimeString;
    }
  }

  Widget keyValueLong(
    String key,
    dynamic value,
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
                  // heightSpecific: false,
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
            _safeText(value),
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
          currentFontSize: 32,
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
                  _safeText(widget.historyXeroxItem["orderId"],
                      fallback: _safeText(widget.historyXeroxItem["_Id"],
                          fallback: "Order")),
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
                  _safeText(widget.historyXeroxItem["storeName"],
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
                  getDate(
                    widget.historyXeroxItem["orderDate"],
                  ),
                  style: TextStyle(
                    // fontSize: 13,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 26,
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
    dynamic value,
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
              _safeText(value),
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
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              // heightSpecific: false,
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
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;

    final rawItems = widget.historyXeroxItem["items"];
    final List<dynamic> itemsList =
        rawItems is List ? rawItems : const <dynamic>[];

    List<Widget> itemWidgets = [];

    for (int index = 0; index < itemsList.length; index++) {
      // print(itemsList[index]);
      // print(
      //     'take Review ----------------------->>>>>>.${itemsList[index]["takeReview"]}');
      final item = itemsList[index] is Map
          ? Map<String, dynamic>.from(itemsList[index] as Map)
          : <String, dynamic>{};
      itemWidgets.add(
        Column(
          children: [
            keyValueOfFeatureDownload(
              index + 1,
              _safeText(item["downloadUrl"], fallback: ""),
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Copies ",
              item["copies"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Total Pages ",
              item["totalPages"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Page Range ",
              item["pageRange"] ?? "All pages",
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Cost ",
              item["itemCost"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Color ",
              item["itemColor"] ?? "Standard",
              totalScreenHeight,
              totalScreenWidth,
            ),
            item["colorPartialPagesList"] != null &&
                    item["colorPartialPagesList"].toString().trim().isNotEmpty
                ? keyValueOfFeature(
                    "Color Partials  ",
                    item["colorPartialPagesList"],
                    totalScreenHeight,
                    totalScreenWidth,
                  )
                : const SizedBox(),
            item["bondPage"] != null
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
              item["paperSize"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Print Layout ",
              item["printLayout"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Binding Formate ",
              item["binding"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Print Side Formate ",
              item["side"],
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Collate Copies ",
              item["collateCopies"] == true ? "Yes" : "No",
              totalScreenHeight,
              totalScreenWidth,
            ),
            keyValueOfFeature(
              "Number Copies ",
              item["numberCopies"] == true ? "Yes" : "No",
              totalScreenHeight,
              totalScreenWidth,
            ),
            if (_safeText(item["notes"], fallback: "").isNotEmpty)
              keyValueOfFeature(
                "Notes ",
                item["notes"],
                totalScreenHeight,
                totalScreenWidth,
              ),

            index == itemsList.length - 1
                ? const SizedBox()
                : Padding(
                    padding: EdgeInsets.only(
                      // left: 12,
                      left: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 24,
                        // heightSpecific: false,
                      ),
                      // right: 12,
                      right: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 24,
                        // heightSpecific: false,
                      ),
                    ),
                    child: Divider(
                      color: Colors.black54.withValues(alpha: 0.2),
                      // thickness: 1,
                      thickness: calculateDynamicFontSize(
                        totalScreenHeight: totalScreenHeight,
                        totalScreenWidth: totalScreenWidth,
                        currentFontSize: 2,
                        // heightSpecific: false,
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
          )),
          decoration: BoxDecoration(
              border: Border.all(
                color: ColorPallets.deepBlue,
                // width: 1,
                width: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 2,
                  // heightSpecific: false,
                ),
              ),
              borderRadius: BorderRadius.circular(
                // 8,
                calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 16,
                  // heightSpecific: true,
                ),
              )),
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
              widget.historyXeroxItem['takeReview'] == true &&
                      _safeText(widget.historyXeroxItem['_Id'], fallback: "")
                          .isNotEmpty &&
                      _safeText(widget.historyXeroxItem['storeId'],
                              fallback: "")
                          .isNotEmpty
                  ? ReviewWidget(
                      id: _safeText(widget.historyXeroxItem['_Id']),
                      accessToken: widget.accesstoken,
                      shopId: _safeText(widget.historyXeroxItem['storeId']))
                  : const SizedBox(),
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
                  // heightSpecific: true,
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reorderSimilar,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Reorder Similar'),
                  ),
                ),
              ),

              // ListView.builder(
              //   shrinkWrap: true,
              //   itemCount: itemsList.length,
              //   itemBuilder: (context, index) {
              //     return Column(
              //       children: [
              //         keyValueOfFeatureDownload(
              //             index + 1, itemsList[index]["downloadUrl"]),
              //         keyValueOfFeature(
              //             "Copies ", itemsList[index]["copies"].toString()),
              //         keyValueOfFeature("Total Pages ",
              //             itemsList[index]["totalPages"].toString()),
              //         keyValueOfFeature(
              //             "Cost ", itemsList[index]["itemCost"].toString()),
              //         keyValueOfFeature(
              //             "Color ", itemsList[index]["itemColor"]),
              //         if (itemsList[index]["colorPartialPagesList"] != null)
              //           keyValueOfFeature("Color Partials  ",
              //               itemsList[index]["colorPartialPagesList"]),
              //         if (itemsList[index]["bondPage"] != null)
              //           keyValueOfFeature("Bond Papers  ", "YES"),
              //         keyValueOfFeature(
              //             "Paper Size ", itemsList[index]["paperSize"]),
              //         keyValueOfFeature(
              //             "Print Layout ", itemsList[index]["printLayout"]),
              //         keyValueOfFeature(
              //             "Binding Formate ", itemsList[index]["binding"]),
              //         keyValueOfFeature(
              //             "Print Side Formate ", itemsList[index]["side"]),
              //         const SizedBox(
              //             height: 10), // Adjust the spacing as needed
              //       ],
              //     );
              //   },
              // ),
              // keyValueOfFeatureDownload(1, itemsList[0]["downloadUrl"]),
              // keyValueOfFeature("Copies ", itemsList[0]["copies"].toString()),
              // keyValueOfFeature(
              //     "Total Pages ", itemsList[0]["totalPages"].toString()),
              // keyValueOfFeature("Cost ", itemsList[0]["itemCost"].toString()),
              // keyValueOfFeature("Color ", itemsList[0]["itemColor"]),
              // itemsList[0]["colorPartialPagesList"] != null
              //     ? keyValueOfFeature(
              //         "Color Partials  ", itemsList[0]["colorPartialPagesList"])
              //     : const SizedBox(),
              // itemsList[0]["bondPage"] != null
              //     ? keyValueOfFeature("Bond Papers  ", "YES")
              //     : const SizedBox(),
              // keyValueOfFeature("Paper Size ", itemsList[0]["paperSize"]),
              // keyValueOfFeature("Print Layout ", itemsList[0]["printLayout"]),
              // keyValueOfFeature("Binding Formate ", itemsList[0]["binding"]),
              // keyValueOfFeature("Print Side Formate ", itemsList[0]["side"]),

              // keyValueOfFeature(
              //     "No of Copies", widget.historyXeroxItem["noOfCopies"]),
              // keyValueOfFeature("Total No.of Pages",
              //     "${widget.historyXeroxItem["noOfPages"]} Pages X ${widget.historyXeroxItem["noOfCopies"]} Copies  "),
              // keyValueOfFeature(
              //     "Page Orientation ", widget.historyXeroxItem["pageOrient"]),
              // keyValueOfFeature(
              //     "Page Types", widget.historyXeroxItem["pageSize"]),
              // keyValueOfFeature(
              //     "Print Type", widget.historyXeroxItem["pagePrintSide"]),
              // keyValueOfFeature(
              //     "Color ", widget.historyXeroxItem["printJobType"]),
              // widget.historyXeroxItem["printJobType"] == "Partial Color"
              //     ? keyValueOfFeature("Color Pages",
              //         "${widget.historyXeroxItem['colorPagesCount']} ( ${widget.historyXeroxItem['colorPagesRange']} )")
              //     : const SizedBox(),
              // widget.historyXeroxItem['bindingType'] != "NoBound"
              //     ? keyValueOfFeature(
              //         "Binding Type", widget.historyXeroxItem['bindingType'])
              //     : const SizedBox(),
              // widget.historyXeroxItem['isBondPaperNeeded'] == "true"
              //     ? keyValueOfFeature(
              //         "Bond Pages", widget.historyXeroxItem['bondPaperRange'])
              //     : const SizedBox(),
              // widget.historyXeroxItem['isTransparentSheetNeed'] == "true"
              //     ? keyValueOfFeature("Transparent Color",
              //         widget.historyXeroxItem['transparentSheetColor'])
              //     : const SizedBox(),
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
                  // heightSpecific: true,
                )),
                child: Divider(
                  color: ColorPallets.deepBlue,
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
                widget.historyXeroxItem['storeName'],
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueOfFeature(
                "Contact-Number",
                widget.historyXeroxItem['storeContactNumber'],
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueOfFeature(
                "Shop Email",
                widget.historyXeroxItem['storeEmail'],
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Shop Addres",
                widget.historyXeroxItem['storeAddress'],
                totalScreenHeight,
                totalScreenWidth,
              ),

              SizedBox(
                // height: 10
                // ,
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
              // keyValueOfFeature("OrderId",dget.historyXeroxItem['orderId']),

              keyValueLong(
                "OrderId",
                widget.historyXeroxItem['orderId'],
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueOfFeature(
                "Date Of Order",
                getDate(widget.historyXeroxItem['orderDate']),
                totalScreenHeight,
                totalScreenWidth,
              ),
              // keyValueLong("Date Of Order",
              //     getDate(widget.historyXeroxItem['orderDate'])),
              keyValueOfFeature(
                "Total Cost",
                widget.historyXeroxItem['totalCost'].toString(),
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
            ],
          ),
        ));
  }
}
