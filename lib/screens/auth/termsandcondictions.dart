import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';

class TermsAndCond extends StatelessWidget {
  static const routeName = "/tersmandcond";
  const TermsAndCond({super.key});
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
            currentFontSize: 20,
            // heightSpecific: true,
          ),
          horizontal: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 35,
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
                    currentFontSize: 50,
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
              currentFontSize: 10,
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
                currentFontSize: 18,
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
              currentFontSize: 20,
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
                    currentFontSize: 20,
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

  Widget keyValueLong(
    String key,
    String value,
    double totalScreenHeight,
    double totalScreenWidth,
  ) {
    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 5),
      margin: EdgeInsets.symmetric(
        vertical: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 5,
          // heightSpecific: true,
        ),
      ),
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
                maxLines: 2,
                key,
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    // fontSize: 18,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 40,
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
                  currentFontSize: 15,
                  // heightSpecific: false,
                ),
              ),
              Text(":",
                  style: TextStyle(
                    // fontSize: 18,
                    fontSize: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 40,
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
              currentFontSize: 10,
              // heightSpecific: true,
            ),
          ),
          Text(
            value,
            maxLines: 10,
            style: TextStyle(
                fontWeight: FontWeight.w400,
                // fontSize: 18,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 30,
                  // heightSpecific: true,
                ),
                color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
        appBar: AppBar(
          title: const Text("Terms & Conditions"),
          foregroundColor: ColorPallets.white,
        ),
        body: Padding(
          // padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          padding: EdgeInsets.symmetric(
              vertical: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 15,
                // heightSpecific: true,
              ),
              horizontal: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 30,
                // heightSpecific: false,
              )),
          child: ListView(
            children: [
              keyValueLong(
                "Acceptance of Terms",
                "By accessing and using Dittox, you acknowledge and agree to the following terms and conditions, which constitute a legally binding agreement between you and I2N Technologies. If you do not agree to these terms, please refrain from using our services.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Service Ordering:",
                "Through our app, users can avail online printing services by uploading documents, configuring print options, and viewing pricing from various partnering stores listed on the app.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Payment:",
                "Users are responsible for making prompt and accurate payments for their orders using the payment methods provided within the app",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Order Pickup:",
                "Users must ensure timely pickup of their orders from the designated store location after receiving a notification confirming the completion of the printing job.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "User Responsibilities:",
                "Users are obligated to provide accurate and complete information when uploading documents and configuring print options. Users must also adhere to the policies and guidelines of the chosen store and acknowledge that any violation of these policies may affect their order.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Intellectual Property:",
                "Users retain ownership of the content they upload through the app for printing purposes. Users understand and agree that they are solely responsible for the content they submit.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Limitation of Liability:",
                "I2N Technologies shall not be held liable for any direct, indirect, incidental, special, or consequential damages arising out of or in connection with the use or inability to use our services.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Governing Law and Dispute Resolution:",
                "These terms and conditions shall be governed by and construed in accordance with the laws of India. Any dispute arising under or in connection with these terms shall be subject to the exclusive jurisdiction of the courts located in laws of India.",
                totalScreenHeight,
                totalScreenWidth,
              ),
              keyValueLong(
                "Changes to Terms and Conditions",
                "I2N Technologies reserves the right to update, modify, or change these terms and conditions at any time. Users will be notified of such changes and the revised terms will be accessible within the app.",
                totalScreenHeight,
                totalScreenWidth,
              ),
            ],
          ),
        ));
  }
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //       body: Column(
  //     children: [
  //       SizedBox(
  //         height: 90,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(
  //             vertical: 10,
  //             horizontal: 20,
  //           ),
  //           child: Row(
  //               mainAxisAlignment: MainAxisAlignment.start,
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 CustomIconButton(
  //                   onPressed: () {
  //                     Navigator.of(context).pop();
  //                     ScaffoldMessenger.of(context).clearSnackBars();
  //                   },
  //                   icon: FontAwesomeIcons.chevronLeft,
  //                   iconColor: ColorPallets.white,
  //                   backGroundColor: ColorPallets.deepBlue,
  //                   size: 40,
  //                   iconSize: 16,
  //                 ),
  //                 const Text("Terms and Conditions"),
  //               ]),
  //         ),
  //       ),
  //       Expanded(
  //           child: ListView(
  //         children: [
  //           CustomTandCText(
  //             title: "Acceptance of Terms",
  //             text:
  //                 "By accessing and using Dittox, you acknowledge and agree to the following terms and conditions, which constitute a legally binding agreement between you and I2N Technologies. If you do not agree to these terms, please refrain from using our services.",
  //           ),
  //           CustomTandCText(
  //             title: "Service Ordering:",
  //             text:
  //                 "Through our app, users can avail online printing services by uploading documents, configuring print options, and viewing pricing from various partnering stores listed on the app.",
  //           ),
  //           CustomTandCText(
  //               title: "Payment:",
  //               text:
  //                   "Users are responsible for making prompt and accurate payments for their orders using the payment methods provided within the app"),
  //           CustomTandCText(
  //               title: "Order Pickup:",
  //               text:
  //                   "Users must ensure timely pickup of their orders from the designated store location after receiving a notification confirming the completion of the printing job."),
  //           CustomTandCText(
  //             title: "User Responsibilities:",
  //             text:
  //                 "Users are obligated to provide accurate and complete information when uploading documents and configuring print options. Users must also adhere to the policies and guidelines of the chosen store and acknowledge that any violation of these policies may affect their order.",
  //           ),
  //           CustomTandCText(
  //             title: "Intellectual Property:",
  //             text:
  //                 "Users retain ownership of the content they upload through the app for printing purposes. Users understand and agree that they are solely responsible for the content they submit.",
  //           ),
  //           CustomTandCText(
  //               title: "Limitation of Liability:",
  //               text:
  //                   "I2N Technologies shall not be held liable for any direct, indirect, incidental, special, or consequential damages arising out of or in connection with the use or inability to use our services."),
  //           CustomTandCText(
  //             title: "Governing Law and Dispute Resolution:",
  //             text:
  //                 "These terms and conditions shall be governed by and construed in accordance with the laws of India. Any dispute arising under or in connection with these terms shall be subject to the exclusive jurisdiction of the courts located in laws of India.",
  //           ),
  //           CustomTandCText(
  //               title: "Changes to Terms and Conditions",
  //               text:
  //                   "I2N Technologies reserves the right to update, modify, or change these terms and conditions at any time. Users will be notified of such changes and the revised terms will be accessible within the app."),
  //         ],
  //       ))
  //     ],
  //   ));
  // }
}
