import "package:flutter/material.dart";
// import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';

class AboutUs extends StatelessWidget {
  static const routeName = "/abouUs";
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Scaffold(
      appBar:
          AppBar(foregroundColor: ColorPallets.white, title: const Text("About Us")),
      body: SingleChildScrollView(
        child: Container(
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
                    )),
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
              const Text(
                  '''Welcome to Dittox!\n\nAt Dittox, we're passionate about making the lives of students easier. We understand the hustle and bustle of academic life, and that's why we've created a seamless platform that connects students with their nearest xerox shops. Say goodbye to the hassle of finding a xerox shop and waiting in long queues. With Dittox, you can place your photocopy orders conveniently from your phone or computer and pick them up at your convenience.\n\nOur journey began with a simple idea: to streamline the process of getting course materials and documents copied for students. We noticed the frustration students faced when they needed copies of their study materials or assignments, especially during peak times. That's when we envisioned Dittox—a platform that bridges the gap between students and xerox shops, making photocopying quick, easy, and hassle-free.
        \nOur mission is to empower students by providing them with a convenient solution for their photocopying needs. Whether you're rushing to meet a deadline or simply need to make copies of important documents, Dittox is here to help you every step of the way.
        \nWhat sets us apart is our commitment to quality, convenience, and reliability. We work closely with trusted xerox shops in your area to ensure that your copies are made with precision and delivered to you in a timely manner. With Dittox, you can trust that your photocopying needs are in good hands.
        \nJoin the Dittox community today and experience the convenience of effortless photocopying. We're here to make your academic journey smoother, one copy at a time.
        \n\nThank you for choosing Dittox!'''),
            ],
          ),
        ),
      ),
    );
  }
}
