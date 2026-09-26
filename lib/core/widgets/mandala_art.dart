import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Faint Vedic mandala line art used as a decorative footer on auth screens.
class MandalaArt extends StatelessWidget {
  const MandalaArt({
    super.key,
    this.size = 260,
    this.color,
    this.opacity = 0.5,
  });

  final double size;
  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size(size, size * 0.6),
          painter: MandalaPainter(color: color ?? AppColors.primary),
        ),
      ),
    );
  }
}

class MandalaPainter extends CustomPainter {
  MandalaPainter({this.color = AppColors.primary});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 1.35);
    final double radius = size.height * 1.2;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Petal rings
    for (int ring = 0; ring < 3; ring++) {
      final double r = radius * (0.42 + ring * 0.22);
      final int petals = 12 + ring * 6;
      for (int i = 0; i < petals; i++) {
        final double angle = (i / petals) * 2 * math.pi;
        final Offset tip = center +
            Offset(math.cos(angle), math.sin(angle) * 0.75) * r;
        final Offset left = center +
            Offset(math.cos(angle - 0.12), math.sin(angle - 0.12) * 0.75) *
                r *
                0.72;
        final Offset right = center +
            Offset(math.cos(angle + 0.12), math.sin(angle + 0.12) * 0.75) *
                r *
                0.72;
        final Path petal = Path()
          ..moveTo(center.dx, center.dy)
          ..quadraticBezierTo(left.dx, left.dy, tip.dx, tip.dy)
          ..quadraticBezierTo(right.dx, right.dy, center.dx, center.dy);
        canvas.drawPath(petal, paint);
      }
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2, height: r * 1.5),
        paint,
      );
    }

    // Temple skyline underneath the mandala
    final Paint skyline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _skyline(canvas, size, skyline);
  }

  void _skyline(Canvas canvas, Size size, Paint paint) {
    double x = 0;
    final double base = size.height - 2;
    while (x < size.width) {
      final double w = 26 + (x % 18);
      final double h = 18 + ((x * 7) % 26);
      final Path tower = Path()
        ..moveTo(x, base)
        ..lineTo(x, base - h)
        ..quadraticBezierTo(x + w / 2, base - h - 18, x + w, base - h)
        ..lineTo(x + w, base);
      canvas.drawPath(tower, paint);
      x += w + 6;
    }
    canvas.drawLine(Offset(0, base), Offset(size.width, base), paint);
  }

  @override
  bool shouldRepaint(covariant MandalaPainter oldDelegate) =>
      oldDelegate.color != color;
}
