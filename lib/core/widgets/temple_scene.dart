import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Painted dusk temple used behind the splash screen.
///
/// Stands in for `assets/images/splash/splash_bg.png`; when the real artwork
/// is added, screens can swap to `Image.asset` + this painter as overlay.
class TempleScenePainter extends CustomPainter {
  TempleScenePainter({this.progress = 1});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Sky
    final Paint sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF07131F),
          Color(0xFF0D2739),
          Color(0xFF17405A),
          Color(0xFF0E2E42),
        ],
        stops: <double>[0, 0.35, 0.7, 1],
      ).createShader(rect);
    canvas.drawRect(rect, sky);

    _paintStars(canvas, size);

    // Warm horizon glow behind the temple
    final Offset glowCenter = Offset(size.width * 0.5, size.height * 0.62);
    final Paint glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.gold.withValues(alpha: 0.55),
          AppColors.primary.withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: size.width));
    canvas.drawRect(rect, glow);

    // Water
    final double horizon = size.height * 0.74;
    final Paint water = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFF0A1D2C).withValues(alpha: 0.95),
          const Color(0xFF050F1A),
        ],
      ).createShader(Rect.fromLTRB(0, horizon, size.width, size.height));
    canvas.drawRect(Rect.fromLTRB(0, horizon, size.width, size.height), water);

    // Temple silhouette
    final Paint temple = Paint()..color = const Color(0xFF04101B);
    final Paint templeLit = Paint()..color = AppColors.gold.withValues(alpha: 0.9);

    // Main shikhara
    _tower(
      canvas,
      center: Offset(size.width * 0.5, horizon),
      width: size.width * 0.26,
      height: size.height * 0.3,
      paint: temple,
      lit: templeLit,
      litWindows: 5,
    );
    // Side towers
    _tower(
      canvas,
      center: Offset(size.width * 0.25, horizon),
      width: size.width * 0.17,
      height: size.height * 0.2,
      paint: temple,
      lit: templeLit,
      litWindows: 3,
    );
    _tower(
      canvas,
      center: Offset(size.width * 0.76, horizon),
      width: size.width * 0.17,
      height: size.height * 0.21,
      paint: temple,
      lit: templeLit,
      litWindows: 3,
    );

    // Base platform
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          size.width * 0.08,
          horizon - size.height * 0.045,
          size.width * 0.92,
          horizon + size.height * 0.012,
        ),
        const Radius.circular(6),
      ),
      temple,
    );

    // Reflection
    final Paint reflection = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.18);
    for (int i = 0; i < 26; i++) {
      final double y = horizon + i * (size.height * 0.01);
      final double w = (size.width * 0.34) * (1 - i / 34);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, y),
          width: w,
          height: 1.6,
        ),
        reflection,
      );
    }

    // Ripple lines
    final Paint ripple = Paint()
      ..color = AppColors.onDark.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 8; i++) {
      final double y = horizon + size.height * 0.04 * i + 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ripple);
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final Paint star = Paint()..color = AppColors.onDark.withValues(alpha: 0.6);
    int seed = 7;
    for (int i = 0; i < 60; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final double x = (seed % 1000) / 1000 * size.width;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final double y = ((seed % 1000) / 1000) * size.height * 0.55;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final double r = 0.6 + (seed % 100) / 100 * 1.1;
      canvas.drawCircle(Offset(x, y), r, star);
    }
  }

  void _tower(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required Paint paint,
    required Paint lit,
    required int litWindows,
  }) {
    final double baseY = center.dy;
    final double topY = baseY - height;

    // Body
    final Path body = Path()
      ..moveTo(center.dx - width / 2, baseY)
      ..lineTo(center.dx - width / 2, topY + height * 0.35)
      ..lineTo(center.dx + width / 2, topY + height * 0.35)
      ..lineTo(center.dx + width / 2, baseY)
      ..close();
    canvas.drawPath(body, paint);

    // Curved shikhara
    final Path spire = Path()
      ..moveTo(center.dx - width * 0.46, topY + height * 0.38)
      ..cubicTo(
        center.dx - width * 0.42,
        topY + height * 0.1,
        center.dx - width * 0.16,
        topY + height * 0.04,
        center.dx,
        topY,
      )
      ..cubicTo(
        center.dx + width * 0.16,
        topY + height * 0.04,
        center.dx + width * 0.42,
        topY + height * 0.1,
        center.dx + width * 0.46,
        topY + height * 0.38,
      )
      ..close();
    canvas.drawPath(spire, paint);

    // Finial
    canvas.drawCircle(Offset(center.dx, topY), width * 0.05, paint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, topY - width * 0.1),
        width: 2,
        height: width * 0.16,
      ),
      lit,
    );

    // Lit windows
    for (int i = 0; i < litWindows; i++) {
      final double t = (i + 1) / (litWindows + 1);
      final double y = baseY - height * 0.12 - t * height * 0.2;
      final double w = width * 0.14;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx, y), width: w, height: w * 1.5),
          Radius.circular(w / 2),
        ),
        lit,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TempleScenePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
