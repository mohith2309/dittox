import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import "../../utils/color_pallets.dart";

class BackGroundPainter extends CustomPainter {
  BackGroundPainter({required Animation<double> animation})
      : firstPaint = Paint()
          ..color = ColorPallets.lightPurple
          ..style = PaintingStyle.fill,
        secoundPaint = Paint()
          ..color = ColorPallets.deepBlue
          ..style = PaintingStyle.fill,
        thirdPaint = Paint()
          ..color = ColorPallets.pinkinshShadedPurple
          ..style = PaintingStyle.fill,
        liquidAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
          reverseCurve: Curves.easeInBack,
        ),
        thirdAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(
            0,
            0.7,
            curve: Interval(0, 0.8, curve: SpringCurve()),
          ),
          reverseCurve: Curves.linear,
        ),
        secoundAnimation = CurvedAnimation(
          parent: animation,
          curve: const Interval(
            0,
            0.8,
            curve: Interval(0, 0.9, curve: SpringCurve()),
          ),
          reverseCurve: Curves.easeInCirc,
        ),
        firstAnimation = CurvedAnimation(
          parent: animation,
          curve: const SpringCurve(),
          reverseCurve: Curves.easeInCirc,
        ),
        super(repaint: animation);

  final Paint firstPaint;
  final Paint secoundPaint;
  final Paint thirdPaint;

  final Animation<double> liquidAnimation;
  final Animation<double> secoundAnimation;
  final Animation<double> thirdAnimation;
  final Animation<double> firstAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    _paintPrimary(canvas, size);
    _paintSecoundary(canvas, size);
    _paintThird(canvas, size);
  }

  void _paintPrimary(Canvas canvas, Size size) {
    final primaryPath = Path();
    primaryPath.moveTo(size.width, size.height / 2);
    primaryPath.lineTo(size.width, 0);
    primaryPath.lineTo(0, 0);
    primaryPath.lineTo(
        0, lerpDouble(0, size.height, firstAnimation.value) as double);

    _addPointsToPath(primaryPath, [
      Point(
        x: lerpDouble(0, size.width / 3, firstAnimation.value) as double,
        y: lerpDouble(0, size.height, firstAnimation.value) as double,
      ),
      Point(
        x: lerpDouble(size.width / 2, size.width / 4 * 3, liquidAnimation.value)
            as double,
        y: lerpDouble(
                size.height / 2, size.height / 4 * 3, liquidAnimation.value)
            as double,
      ),
      Point(
        x: size.width,
        y: lerpDouble(
                size.height / 2, size.height * 3 / 4, liquidAnimation.value)
            as double,
      ),
    ]);
    // purplePath.quadraticBezierTo(
    //     size.width / 2, size.height / 2, size.width, size.height / 2);
    primaryPath.close();

    canvas.drawPath(primaryPath, firstPaint);
  }

  void _paintSecoundary(Canvas canvas, Size size) {
    final secoundaryPath = Path();
    secoundaryPath.moveTo(size.width, 300);
    secoundaryPath.lineTo(size.width, 0);
    secoundaryPath.lineTo(0, 0);
    secoundaryPath.lineTo(
      0,
      lerpDouble(
        size.height / 4,
        size.height / 2,
        secoundAnimation.value,
      ) as double,
    );

    _addPointsToPath(secoundaryPath, [
      Point(
        x: size.width / 4,
        y: lerpDouble(
          size.height / 2,
          size.height * 3 / 4,
          liquidAnimation.value,
        ) as double,
      ),
      Point(
        x: size.width * 3 / 5,
        y: lerpDouble(
          size.height / 4,
          size.height / 2,
          liquidAnimation.value,
        ) as double,
      ),
      Point(
        x: size.width * 4 / 5,
        y: lerpDouble(
          size.height / 6,
          size.height / 3,
          secoundAnimation.value,
        ) as double,
      ),
      Point(
        x: size.width,
        y: lerpDouble(
          size.height / 5,
          size.height / 4,
          secoundAnimation.value,
        ) as double,
      ),
    ]);

    canvas.drawPath(secoundaryPath, secoundPaint);
  }

  void _paintThird(Canvas canvas, Size size) {
    if (thirdAnimation.value > 0) {
      final thirdPath = Path();

      thirdPath.moveTo(size.width * 3 / 4, 0);
      thirdPath.lineTo(0, 0);
      thirdPath.lineTo(
        0,
        lerpDouble(
          0,
          size.height / 12,
          thirdAnimation.value,
        ) as double,
      );

      _addPointsToPath(thirdPath, [
        Point(
          x: size.width / 7,
          y: lerpDouble(
            0,
            size.height / 6,
            liquidAnimation.value,
          ) as double,
        ),
        Point(
          x: size.width / 3,
          y: lerpDouble(
            0,
            size.height / 10,
            liquidAnimation.value,
          ) as double,
        ),
        Point(
          x: size.width / 3 * 2,
          y: lerpDouble(
            0,
            size.height / 8,
            liquidAnimation.value,
          ) as double,
        ),
        Point(
          x: size.width * 3 / 4,
          y: 0,
        ),
      ]);

      canvas.drawPath(thirdPath, thirdPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void _addPointsToPath(Path path, List<Point> points) {
    if (points.length < 3) {
      throw UnsupportedError("need three or more points to create a path");
    }

    for (var i = 0; i < points.length - 2; i++) {
      final xController = (points[i].x + points[i + 1].x) / 2;
      final yController = (points[i].y + points[i + 1].y) / 2;
      path.quadraticBezierTo(
          points[i].x, points[i].y, xController, yController);
    }

    path.quadraticBezierTo(
        points[points.length - 2].x,
        points[points.length - 2].y,
        points[points.length - 1].x,
        points[points.length - 1].y);
  }
}

class Point {
  final double x;
  final double y;
  Point({required this.x, required this.y});
}

class SpringCurve extends Curve {
  const SpringCurve({
    this.a = 0.15,
    this.w = 19.4,
  });

  final double a;
  final double w;

  @override
  double transformInternal(double t) {
    return (-(pow(e, -t / a) * cos(t * w)) + 1).toDouble();
  }
}
