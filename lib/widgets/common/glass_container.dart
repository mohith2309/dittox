import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_settings.dart';
import '../../utils/color_pallets.dart';

/// A liquid-glass container that adapts to dark mode, light mode, and
/// potato mode (no blur, for low-end devices).
///
/// Usage:
/// ```dart
/// GlassContainer(
///   borderRadius: 24,
///   padding: const EdgeInsets.all(16),
///   child: Text('Hello'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final Color? tintColor;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blurStrength = 14,
    this.tintColor,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final potatoMode = context.select((AppSettings s) => s.potatoMode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = BorderRadius.circular(borderRadius);

    final Widget content;

    if (potatoMode) {
      // Potato mode: no blur, flat solid card
      content = Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A2526)
              : (tintColor ?? Colors.white).withValues(alpha: 0.97),
          borderRadius: br,
          border: Border.all(
            color: isDark ? const Color(0xFF2D3E40) : ColorPallets.cardBorder,
          ),
        ),
        child: child,
      );
    } else {
      // Glass mode: frosted blur + translucent tint
      content = ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: tintColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.white.withValues(alpha: 0.62)),
              borderRadius: br,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.60),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    if (margin != null || onTap != null) {
      return Container(
        margin: margin,
        child: onTap != null
            ? GestureDetector(onTap: onTap, child: content)
            : content,
      );
    }

    return onTap != null
        ? GestureDetector(onTap: onTap, child: content)
        : content;
  }
}

/// A glass-styled Card replacement. Wraps [GlassContainer] with default
/// card-like padding and margin.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}
