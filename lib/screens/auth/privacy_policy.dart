import 'package:dittox/utils/dynamicSizing.dart';
import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';

class PrivacyPolicy extends StatelessWidget {
  static const routeName = "/privacy policy";

  const PrivacyPolicy({super.key});

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
                    currentFontSize: 18,
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
        foregroundColor: ColorPallets.white,
        title: const Text("Privacy Policy"),
      ),
      body: Padding(
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
                  "Introduction:",
                  "Welcome to Dittox, the online printing service app. This policy explains how we collect, use, and protect your personal information.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Information We Collect:",
                  "When you use our app, we collect personal information such as your name, email, phone number, uploaded documents, printing preferences, payment details, and location for delivery purposes.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "How We Use Your Information:",
                  "We use your information to process your orders, calculate printing prices, facilitate communication between you and vendors, handle payments, and enhance app performance.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Sharing Information with Vendors:",
                  "To fulfil your printing orders, we share specific details like document content, printing preferences, and delivery location with our vendors. We do not share sensitive payment information with vendors.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Data Security Measures:",
                  "Your data's security is a priority. We employ encryption, secure servers, access controls, and regular security assessments to safeguard your personal information.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Vendor Payments:",
                  "Your payment information is securely processed and stored only for financial transactions related to the app's services.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Your Control Over Information:",
                  "You can access, modify, or delete your personal information through your account settings. You can also opt out of promotional communications.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Cookies and Analytics:",
                  "We use cookies and tracking technologies for analytics and app performance optimization. You can manage your cookie preferences through your device settings",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Third-Party Services:",
                  "We integrate third-party services such as payment processors for seamless transactions. Refer to their privacy policies for information on their data handling practices.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Changes to Our Policy:",
                  "We may update this policy as our services evolve. You'll be notified of any changes through app notifications or email.",
                  totalScreenHeight,
                  totalScreenWidth),
              keyValueLong(
                  "Contact Us:",
                  "If you have questions or concerns about your privacy, please contact us at I2N Technologies, 1869, 38th A cross, 11th Main, Jayanagar, Bangalore-560041. Ph.No : 9986537604.",
                  totalScreenHeight,
                  totalScreenWidth)
            ],
          )),
    );
  }
}
