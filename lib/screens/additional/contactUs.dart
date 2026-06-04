import 'package:dittox/utils/color_pallets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/dynamicSizing.dart';

class ContactUs extends StatelessWidget {
  static const routeName = "/contactUs";
  const ContactUs({super.key});

  void launchWebsite() async {
    Uri uri = Uri.https("dittox.in/login");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void launchMail() async {
    Uri uri = Uri(
      scheme: "mailto",
      path: "manjunathdr.cse@bmsce.ac.in",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void launchSms() async {
    final uri = Uri(
      scheme: "sms",
      path: "+919986537604",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void launchPhoneCall() async {
    final uri = Uri(
      scheme: "tel",
      path: "+919986537604",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void lauchWhatsApp() async {
    var phone = "+919986537604";
    var message = "hi";
    final uri =
        Uri.parse("whatsapp://send?phone=$phone&text=${Uri.parse(message)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: ColorPallets.white,
        title: const Text("Contact Us"),
      ),
      body: Container(
        // padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        padding: EdgeInsets.symmetric(
            vertical: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 30,
              // heightSpecific: true,
            ),
            horizontal: calculateDynamicFontSize(
              totalScreenHeight: totalScreenHeight,
              totalScreenWidth: totalScreenWidth,
              currentFontSize: 40,
              // heightSpecific: false,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DITTOX PRIVATE LIMITED",
              textAlign: TextAlign.start,
              style: TextStyle(
                color: ColorPallets.deepBlue,
                // fontSize: 24,
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
            Divider(
              color: ColorPallets.deepBlue,
              // thickness: 1.5,
              thickness: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 3,
                // heightSpecific: true,
              ),
            ),
            SizedBox(
              // height: 10,
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 15,
                // heightSpecific: true,
              ),
            ),
            Text(
              "Office Address",
              style: TextStyle(
                // fontSize: 20,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 35,
                  // heightSpecific: true,
                ),
                color: ColorPallets.deepBlue,
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
            const Text(
              "Webspruce ,1,3rd Floor, LVR ONE, 17th Cross Rd, near Orion Mall, A Block, Milk Colony, 2nd Stage, Rajajinagar, Bengaluru, Karnataka 560010 ",
              maxLines: 5,
            ),
            TextButton.icon(
                onPressed: () {
                  MapsLauncher.launchCoordinates(13.008033, 77.554924);
                },
                icon: const FaIcon(
                  FontAwesomeIcons.locationArrow,
                  color: ColorPallets.deepBlue,
                ),
                label: const Text(
                  "Visit Our Office",
                  style: TextStyle(color: ColorPallets.deepBlue),
                )),
            SizedBox(
              // height: 20,
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
            ),
            Text(
              "Social Media",
              style: TextStyle(
                // fontSize: 20,
                fontSize: calculateDynamicFontSize(
                  totalScreenHeight: totalScreenHeight,
                  totalScreenWidth: totalScreenWidth,
                  currentFontSize: 35,
                  // heightSpecific: true,
                ),
                color: ColorPallets.deepBlue,
              ),
            ),
            SizedBox(
              // height: 20,
              height: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 20,
                // heightSpecific: true,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: launchMail,
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    // height: 30,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: true,
                    ),
                    // width: 30,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: false,
                    ),
                    child: Image.asset(
                      "assets/image/mail.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: launchPhoneCall,
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    // height: 30,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: true,
                    ),
                    // width: 30,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: false,
                    ),
                    child: Image.asset(
                      "assets/image/phone.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: launchSms,
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    // height: 30,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: true,
                    ),
                    // width: 30,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 50,
                      // heightSpecific: false,
                    ),
                    child: Image.asset(
                      "assets/image/text_msg.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: lauchWhatsApp,
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    // height: 40,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 60,
                      // heightSpecific: true,
                    ),
                    // width: 40,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 60,
                      // heightSpecific: false,
                    ),
                    child: Image.asset(
                      "assets/image/whatsapp.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: launchWebsite,
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    // height: 40,
                    height: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 60,
                      // heightSpecific: true,
                    ),
                    // width: 40,
                    width: calculateDynamicFontSize(
                      totalScreenHeight: totalScreenHeight,
                      totalScreenWidth: totalScreenWidth,
                      currentFontSize: 60,
                      // heightSpecific: false,
                    ),
                    child: Image.asset(
                      "assets/image/chrome.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
