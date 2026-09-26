import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Painted Google "G" so no third-party icon package is required.
class GoogleGIcon extends StatelessWidget {
  const GoogleGIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGPainter(),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const Color blue = Color(0xFF4285F4);
  static const Color red = Color(0xFFEA4335);
  static const Color yellow = Color(0xFFFBBC05);
  static const Color green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius * 0.86);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3
      ..strokeCap = StrokeCap.round;

    double deg(double value) => value * math.pi / 180;

    paint.color = blue;
    canvas.drawArc(rect, deg(188), deg(72), false, paint);
    paint.color = red;
    canvas.drawArc(rect, deg(276), deg(64), false, paint);
    paint.color = yellow;
    canvas.drawArc(rect, deg(20), deg(66), false, paint);
    paint.color = green;
    canvas.drawArc(rect, deg(96), deg(74), false, paint);

    // The "G" cross bar.
    final Paint bar = Paint()..color = blue;
    final RRect barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx - radius * 0.05,
        center.dy - radius * 0.16,
        radius * 0.95,
        radius * 0.32,
      ),
      Radius.circular(radius * 0.16),
    );
    canvas.drawRRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Apple mark using the Material icon font (available offline).
class AppleIcon extends StatelessWidget {
  const AppleIcon({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.apple, size: size, color: color ?? const Color(0xFF111111));
  }
}
