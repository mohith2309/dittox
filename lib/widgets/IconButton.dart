import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:flutter/material.dart";

class CustomIconButton extends StatelessWidget {
  final FaIconData icon;
  final Color iconColor;
  final Color backGroundColor;
  final int iconSize;
  final int size;
  final VoidCallback onPressed;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backGroundColor,
    required this.size,
    required this.iconSize,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Palette: Replaced Container with Ink/InkWell for ripple effect and added Tooltip for accessibility
    Widget button = Ink(
      decoration: BoxDecoration(
          color: backGroundColor,
          borderRadius: BorderRadius.circular(size / 2)),
      height: size.toDouble(),
      width: size.toDouble(),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Center(
          child: FaIcon(
            icon,
            color: iconColor,
            size: iconSize.toDouble(),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
