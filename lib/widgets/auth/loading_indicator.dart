import 'package:flutter/material.dart';

import "../../utils/color_pallets.dart";

class LoadingProgressIndicator extends StatelessWidget {
  final bool isLoading;
  const LoadingProgressIndicator({
    super.key,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 100),
      child: Visibility(
        visible: isLoading,
        child: const LinearProgressIndicator(
          backgroundColor: ColorPallets.pinkinshShadedPurple,
        ),
      ),
    );
  }
}
