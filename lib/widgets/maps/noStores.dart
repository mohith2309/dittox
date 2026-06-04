import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';
import '../../utils/dynamicSizing.dart';

class NoStoresOrders extends StatelessWidget {
  const NoStoresOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: totalScreenHeight * .6,
          width: double.infinity,
          child: Image.asset(
            "assets/image/no_order.png",
            fit: BoxFit.cover,
          ),
        ),
        Text(
          "Sorry , we are not providing service here",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: ColorPallets.deepBlue,
              // fontSize: 26,
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 50,
                // heightSpecific: true,
              )),
        ),
        SizedBox(
          // height: 5,
          height: calculateDynamicFontSize(
            totalScreenHeight: totalScreenHeight,
            totalScreenWidth: totalScreenWidth,
            currentFontSize: 10,
            // heightSpecific: true,
          ),
        ),
        Text(
          "Try any other location where our servcie avilable ",
          style: TextStyle(
              color: ColorPallets.lightBlue,
              // fontSize: 16,
              fontSize: calculateDynamicFontSize(
                totalScreenHeight: totalScreenHeight,
                totalScreenWidth: totalScreenWidth,
                currentFontSize: 35,
                // heightSpecific: true,
              )),
        ),
      ],
    );
  }
}
