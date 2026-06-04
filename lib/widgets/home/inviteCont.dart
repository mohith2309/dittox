import 'package:flutter/material.dart';

import '../../utils/color_pallets.dart';

class InviteCont extends StatelessWidget {
  const InviteCont({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Container(
          padding: EdgeInsets.all(wide ? 22 : 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7ED), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColorPallets.cardBorder),
          ),
          child: SizedBox(
            height: wide ? 260 : 150,
            child: Row(
              children: [
                Expanded(
                  flex: wide ? 4 : 5,
                  child: Image.asset(
                    "assets/image/referFriend.png",
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                SizedBox(width: wide ? 28 : 10),
                Expanded(
                  flex: wide ? 5 : 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorPallets.swiggyOrangeLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "DITTOX PRO BONUS",
                          style: TextStyle(
                            color: ColorPallets.swiggyOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Invite your friend",
                        style: TextStyle(
                          color: ColorPallets.textPrimary,
                          fontSize: wide ? 24 : 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Get reward up to Rs 50",
                        style: TextStyle(
                          color: ColorPallets.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: ColorPallets.swiggyOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "INVITE NOW",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
