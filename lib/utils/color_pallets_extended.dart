import 'package:flutter/material.dart';
import 'color_pallets.dart';

/// Extended color palette with additional colors needed by optimized components
/// This extends the original ColorPallets without modifying it
class ColorPalletsExtended {
  static const Color deepBlue = ColorPallets.deepBlue;
  static const Color lightBlue = ColorPallets.lightBlue;
  static const Color darkPurple = ColorPallets.darkPurple;
  static const Color lightPurple = ColorPallets.lightPurple;
  static const Color white = ColorPallets.white;
  static const Color black = ColorPallets.black;
  
  /// Grey colors for UI elements
  static const Color textFieldBorderGrey = Color(0xFFE0E0E0);
  static const Color hintTextGrey = Color(0xFF9E9E9E);
  static const Color dividerGrey = Color(0xFFBDBDBD);
  static const Color backgroundGrey = Color(0xFFF5F5F5);
}
