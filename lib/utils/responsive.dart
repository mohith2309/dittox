import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Responsive sizing utility for Flutter apps
///
/// Usage:
/// ```dart
/// final responsive = Responsive.of(context);
/// final fontSize = responsive.fontSize(16);
/// ```
class Responsive {
  final BuildContext context;
  late final Size _size;
  late final double _width;
  late final double _height;
  late final double _diagonal;
  late final bool _isTablet;
  late final bool _isPhone;
  late final bool _isDesktop;

  Responsive._(this.context) {
    _size = MediaQuery.sizeOf(context);
    _width = _size.width;
    _height = _size.height;
    _diagonal = math.sqrt(_width * _width + _height * _height);
    _isPhone = _width < 600;
    _isTablet = _width >= 600 && _width < 1200;
    _isDesktop = _width >= 1200;
  }

  /// Factory constructor that caches the instance
  static Responsive of(BuildContext context) {
    return Responsive._(context);
  }

  // Size getters
  Size get size => _size;
  double get width => _width;
  double get height => _height;
  double get diagonal => _diagonal;

  // Device type
  bool get isPhone => _isPhone;
  bool get isTablet => _isTablet;
  bool get isDesktop => _isDesktop;
  bool get isLandscape => _width > _height;

  /// Calculate responsive font size
  /// Base size is designed for a 375px wide screen (iPhone X)
  double fontSize(double baseSize) {
    return (baseSize * _width / 375).clamp(baseSize * 0.8, baseSize * 1.3);
  }

  /// Calculate responsive width (percentage of screen)
  double wp(double percent) => _width * (percent / 100);

  /// Calculate responsive height (percentage of screen)
  double hp(double percent) => _height * (percent / 100);

  /// Responsive padding
  EdgeInsets padding({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
    double horizontal = 0,
    double vertical = 0,
    double all = 0,
  }) {
    if (all > 0) {
      return EdgeInsets.all(wp(all));
    }
    return EdgeInsets.only(
      left: wp(left + horizontal),
      right: wp(right + horizontal),
      top: hp(top + vertical),
      bottom: hp(bottom + vertical),
    );
  }

  /// Responsive symmetric padding
  EdgeInsets symmetricPadding({double vertical = 0, double horizontal = 0}) {
    return EdgeInsets.symmetric(
      vertical: hp(vertical),
      horizontal: wp(horizontal),
    );
  }

  /// Responsive sized box
  SizedBox verticalSpace(double percent) => SizedBox(height: hp(percent));
  SizedBox horizontalSpace(double percent) => SizedBox(width: wp(percent));

  /// Icon size
  double iconSize(double baseSize) => fontSize(baseSize * 1.5);

  /// Border radius
  double radius(double baseRadius) => wp(baseRadius);
}

/// Extension for easier access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive.of(this);
}

/// Widget that provides responsive sizing via builder pattern
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.of(context));
  }
}
