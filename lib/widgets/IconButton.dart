import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:flutter/material.dart";

class CustomIconButton extends StatelessWidget {
  final FaIconData icon;
  final Color iconColor;
  final Color backGroundColor;
  final int iconSize;
  final int size;
  final VoidCallback onPressed;
  final String? semanticLabel;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backGroundColor,
    required this.size,
    required this.iconSize,
    required this.onPressed,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed,
        child: Container(
            decoration: BoxDecoration(
                color: backGroundColor,
                borderRadius: BorderRadius.circular(size / 2)),
            height: size.toDouble(),
            width: size.toDouble(),
            child: FaIcon(
              icon,
              color: iconColor,
              size: iconSize.toDouble(),
              semanticLabel: semanticLabel,
            )),
      ),
    );
  }
}
