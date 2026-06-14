import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Renders the mascot for the currently active theme (Gundam RX-78-2 head or
/// Hello Kitty face).
class ThemeMascot extends StatelessWidget {
  final double size;

  /// Outline color; defaults to the theme outline.
  final Color? outline;

  const ThemeMascot({super.key, required this.size, this.outline});

  @override
  Widget build(BuildContext context) {
    final type = context.watch<ThemeProvider>().current;
    final line = outline ?? PixelColors.of(context).outline;
    switch (type) {
      case PixelThemeType.gundam:
        return GundamMascot(size: size, outline: line);
      case PixelThemeType.helloKitty:
        return HelloKittyMascot(size: size, outline: line);
      case PixelThemeType.original:
        // No mascot for the classic theme — use a neutral wallet emblem.
        return Icon(Icons.account_balance_wallet_rounded,
            size: size * 0.86, color: line);
      case PixelThemeType.luxury:
        // Old-money laurel crest.
        return LuxuryMascot(size: size, outline: line);
    }
  }
}

// ---------------------------------------------------------------------------
// Gundam RX-78-2 head
// ---------------------------------------------------------------------------
class GundamMascot extends StatelessWidget {
  final double size;
  final Color outline;
  const GundamMascot({super.key, required this.size, required this.outline});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GundamPainter(outline),
    );
  }
}

class _GundamPainter extends CustomPainter {
  final Color outline;
  _GundamPainter(this.outline);

  static const _white = Color(0xFFF4F6FB);
  static const _blue = Color(0xFF2B4C9B);
  static const _red = Color(0xFFE03A2F);
  static const _yellow = Color(0xFFFFE34D);
  static const _visor = Color(0xFF12223B);
  static const _eye = Color(0xFFFFF867); // federation neon yellow

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeJoin = StrokeJoin.miter;
    Paint fill(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.fill;

    void poly(List<Offset> pts, Color c, {bool line = true}) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, fill(c));
      if (line) canvas.drawPath(path, stroke);
    }

    // Side helmet guards (blue "ears").
    poly([p(0.14, 0.42), p(0.28, 0.40), p(0.30, 0.66), p(0.16, 0.64)], _blue);
    poly([p(0.86, 0.42), p(0.72, 0.40), p(0.70, 0.66), p(0.84, 0.64)], _blue);
    // yellow vents on the guards
    canvas.drawRect(
        Rect.fromLTWH(0.18 * s, 0.46 * s, 0.07 * s, 0.04 * s), fill(_yellow));
    canvas.drawRect(
        Rect.fromLTWH(0.75 * s, 0.46 * s, 0.07 * s, 0.04 * s), fill(_yellow));

    // Face / helmet base (white).
    poly([
      p(0.50, 0.16),
      p(0.30, 0.30),
      p(0.27, 0.55),
      p(0.38, 0.74),
      p(0.50, 0.82),
      p(0.62, 0.74),
      p(0.73, 0.55),
      p(0.70, 0.30),
    ], _white);

    // Visor band (dark).
    poly([
      p(0.32, 0.46),
      p(0.68, 0.46),
      p(0.64, 0.60),
      p(0.36, 0.60),
    ], _visor);
    // Eyes (neon).
    poly([p(0.37, 0.49), p(0.46, 0.49), p(0.44, 0.57), p(0.38, 0.57)], _eye,
        line: false);
    poly([p(0.63, 0.49), p(0.54, 0.49), p(0.56, 0.57), p(0.62, 0.57)], _eye,
        line: false);

    // Mouth / chin vent (red).
    poly([p(0.42, 0.66), p(0.58, 0.66), p(0.55, 0.74), p(0.45, 0.74)], _red);

    // V-fin antenna (yellow chevron + red center nub).
    poly([
      p(0.50, 0.30),
      p(0.32, 0.10),
      p(0.39, 0.09),
      p(0.50, 0.24),
      p(0.61, 0.09),
      p(0.68, 0.10),
    ], _yellow);
    canvas.drawRect(
        Rect.fromLTWH(0.47 * s, 0.05 * s, 0.06 * s, 0.20 * s), fill(_red));
    canvas.drawRect(
        Rect.fromLTWH(0.47 * s, 0.05 * s, 0.06 * s, 0.20 * s), stroke);
  }

  @override
  bool shouldRepaint(covariant _GundamPainter old) => old.outline != outline;
}

// ---------------------------------------------------------------------------
// Hello Kitty face
// ---------------------------------------------------------------------------
class HelloKittyMascot extends StatelessWidget {
  final double size;
  final Color outline;
  const HelloKittyMascot(
      {super.key, required this.size, required this.outline});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _KittyPainter(outline),
    );
  }
}

class _KittyPainter extends CustomPainter {
  final Color outline;
  _KittyPainter(this.outline);

  static const _white = Color(0xFFFFFFFF);
  static const _eye = Color(0xFF2A2233);
  static const _nose = Color(0xFFF4B73E);
  static const _bow = Color(0xFFE5556B);
  static const _bowHi = Color(0xFFFFB3C7);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    Paint fill(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.fill;

    void poly(List<Offset> pts, Color c, {bool line = true}) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, fill(c));
      if (line) canvas.drawPath(path, stroke);
    }

    // Ears (triangles).
    poly([p(0.16, 0.06), p(0.06, 0.34), p(0.40, 0.28)], _white);
    poly([p(0.84, 0.06), p(0.94, 0.34), p(0.60, 0.28)], _white);

    // Head (rounded blob via oval).
    final head = Rect.fromCenter(
        center: p(0.5, 0.58), width: 0.86 * s, height: 0.64 * s);
    canvas.drawOval(head, fill(_white));
    canvas.drawOval(head, stroke);

    // Whiskers.
    final wp = Paint()
      ..color = outline
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;
    for (final dy in [0.50, 0.58, 0.66]) {
      canvas.drawLine(p(0.18, dy), p(0.01, dy - 0.04), wp);
      canvas.drawLine(p(0.82, dy), p(0.99, dy - 0.04), wp);
    }

    // Eyes.
    for (final cx in [0.36, 0.64]) {
      final e = Rect.fromCenter(
          center: p(cx, 0.56), width: 0.07 * s, height: 0.12 * s);
      canvas.drawOval(e, fill(_eye));
    }

    // Nose.
    final nose = Rect.fromCenter(
        center: p(0.5, 0.66), width: 0.10 * s, height: 0.06 * s);
    canvas.drawOval(nose, fill(_nose));
    canvas.drawOval(nose, stroke);

    // Bow on the (viewer's) left ear.
    poly([p(0.30, 0.16), p(0.12, 0.06), p(0.12, 0.30)], _bow);
    poly([p(0.30, 0.16), p(0.48, 0.06), p(0.48, 0.30)], _bow);
    final knot = Rect.fromCenter(
        center: p(0.30, 0.17), width: 0.10 * s, height: 0.12 * s);
    canvas.drawOval(knot, fill(_bow));
    canvas.drawOval(knot, stroke);
    // bow highlights
    canvas.drawCircle(p(0.20, 0.14), s * 0.022, fill(_bowHi));
    canvas.drawCircle(p(0.40, 0.14), s * 0.022, fill(_bowHi));
  }

  @override
  bool shouldRepaint(covariant _KittyPainter old) => old.outline != outline;
}

// ---------------------------------------------------------------------------
// Luxury — old-money laurel crest
// ---------------------------------------------------------------------------
class LuxuryMascot extends StatelessWidget {
  final double size;
  final Color outline;
  const LuxuryMascot({super.key, required this.size, required this.outline});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LuxuryPainter(outline),
    );
  }
}

class _LuxuryPainter extends CustomPainter {
  final Color color;
  _LuxuryPainter(this.color);

  Offset _bezier(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * b.dx + t * t * c.dx,
      u * u * a.dy + 2 * u * t * b.dy + t * t * c.dy,
    );
  }

  double _angle(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    final dx = 2 * u * (b.dx - a.dx) + 2 * t * (c.dx - b.dx);
    final dy = 2 * u * (b.dy - a.dy) + 2 * t * (c.dy - b.dy);
    return math.atan2(dy, dx);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset pt(double x, double y) => Offset(x * s, y * s);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Two symmetric laurel branches forming an open wreath.
    for (var side = 0; side < 2; side++) {
      double fx(double x) => side == 0 ? x : 1 - x;
      final p0 = pt(fx(0.50), 0.88);
      final p1 = pt(fx(0.06), 0.58);
      final p2 = pt(fx(0.40), 0.14);
      final stem = Path()
        ..moveTo(p0.dx, p0.dy)
        ..quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
      canvas.drawPath(stem, stroke);

      for (final t in const [0.30, 0.48, 0.66, 0.82]) {
        final leafAt = _bezier(p0, p1, p2, t);
        final a = _angle(p0, p1, p2, t);
        canvas.save();
        canvas.translate(leafAt.dx, leafAt.dy);
        canvas.rotate(a + (side == 0 ? -0.85 : 0.85));
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: s * 0.17, height: s * 0.075),
          fill,
        );
        canvas.restore();
      }
    }

    // Crest gem at the top of the wreath.
    final cx = 0.5 * s, cy = 0.13 * s, r = s * 0.075;
    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.7, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.7, cy)
      ..close();
    canvas.drawPath(diamond, fill);
  }

  @override
  bool shouldRepaint(covariant _LuxuryPainter old) => old.color != color;
}
