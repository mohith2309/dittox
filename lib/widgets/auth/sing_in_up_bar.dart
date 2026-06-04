import "package:flutter/material.dart";

import "../../utils/color_pallets.dart";

import "../../utils/dynamicSizing.dart";
import "./loading_indicator.dart";
import "./circular_press_button.dart";

class SignInBar extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const SignInBar({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Padding(
      padding: EdgeInsets.symmetric(
          // vertical: 8,
          vertical: calculateDynamicFontSize(
        totalScreenHeight: totalScreenHeight,
        totalScreenWidth: totalScreenWidth,
        currentFontSize: 8,
        // heightSpecific: true,
      )),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorPallets.deepBlue,
                  // fontSize: 24,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 55,
                    // heightSpecific: true,
                  )),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: LoadingProgressIndicator(
                isLoading: isLoading,
              ),
            ),
          ),
          Expanded(
              flex: 1,
              child: RoundContinueButton(
                onPressed: onPressed,
              ))
        ],
      ),
    );
  }
}

class SignUpBar extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const SignUpBar({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final mqsz = MediaQuery.sizeOf(context);
    final double totalScreenHeight = mqsz.height;
    final double totalScreenWidth = mqsz.width;
    return Padding(
      padding: EdgeInsets.symmetric(
        // vertical: 8,
        vertical: calculateDynamicFontSize(
          totalScreenHeight: totalScreenHeight,
          totalScreenWidth: totalScreenWidth,
          currentFontSize: 25,
          // heightSpecific: true,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ColorPallets.deepBlue,
                  // fontSize: 24,
                  fontSize: calculateDynamicFontSize(
                    totalScreenHeight: totalScreenHeight,
                    totalScreenWidth: totalScreenWidth,
                    currentFontSize: 60,
                    // heightSpecific: true,
                  )),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: LoadingProgressIndicator(
                isLoading: isLoading,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: RoundContinueButton(
              onPressed: onPressed,
            ),
          )
        ],
      ),
    );
  }
}
