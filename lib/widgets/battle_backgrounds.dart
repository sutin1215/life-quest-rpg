import 'dart:math';
import 'package:flutter/material.dart';

/// Returns the correct background painter for each zone.
CustomPainter getBattleBackground(String zoneName) {
  final name = zoneName.toLowerCase();
  if (name.contains('slime') || name.contains('forest')) {
    return ForestBattlePainter();
  } else if (name.contains('goblin') || name.contains('cave')) {
    return CaveBattlePainter();
  } else if (name.contains('haunted') || name.contains('keep')) {
    return HauntedBattlePainter();
  } else if (name.contains('dragon') || name.contains('peak')) {
    return DragonPeakBattlePainter();
  }
  return ForestBattlePainter();
}

// ─────────────────────────────────────────────
// 1. Slime Forest — green trees, fog, fireflies
// ─────────────────────────────────────────────
class ForestBattlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0A1A0A), const Color(0xFF1B3A1B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Moon
    canvas.drawCircle(
      Offset(w * 0.8, h * 0.12),
      28,
      Paint()..color = const Color(0xFFEEE8C0).withOpacity(0.85),
    );
    canvas.drawCircle(
      Offset(w * 0.82, h * 0.10),
      22,
      Paint()..color = const Color(0xFF1B3A1B),
    );

    // Background tree silhouettes (dark)
    _drawTree(canvas, w * 0.05, h * 0.75, h * 0.4, const Color(0xFF0A1A0A));
    _drawTree(canvas, w * 0.15, h * 0.72, h * 0.45, const Color(0xFF0A1A0A));
    _drawTree(canvas, w * 0.75, h * 0.70, h * 0.48, const Color(0xFF0A1A0A));
    _drawTree(canvas, w * 0.88, h * 0.73, h * 0.42, const Color(0xFF0A1A0A));

    // Mid trees (slightly lighter)
    _drawTree(canvas, w * 0.25, h * 0.78, h * 0.35, const Color(0xFF122212));
    _drawTree(canvas, w * 0.60, h * 0.76, h * 0.38, const Color(0xFF122212));

    // Ground
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF1A3320), const Color(0xFF0D1A10)],
      ).createShader(Rect.fromLTWH(0, h * 0.82, w, h * 0.18));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18), groundPaint);

    // Fog layer
    final fogPaint = Paint()
      ..color = const Color(0xFF4CAF50).withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w / 2, h * 0.85), width: w * 1.2, height: 60),
        fogPaint);

    // Fireflies
    final rng = Random(42);
    final ffPaint = Paint()
      ..color = const Color(0xFFAAFF44).withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (int i = 0; i < 12; i++) {
      canvas.drawCircle(
          Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.75),
          2,
          ffPaint);
    }
  }

  void _drawTree(Canvas c, double x, double baseY, double height, Color color) {
    final p = Paint()..color = color;
    c.drawPath(
      Path()
        ..moveTo(x, baseY - height)
        ..lineTo(x - height * 0.18, baseY)
        ..lineTo(x + height * 0.18, baseY)
        ..close(),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(x, baseY - height * 0.75)
        ..lineTo(x - height * 0.24, baseY - height * 0.2)
        ..lineTo(x + height * 0.24, baseY - height * 0.2)
        ..close(),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// 2. Goblin Cave — stalactites, torches, rock
// ─────────────────────────────────────────────
class CaveBattlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark cave background
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [const Color(0xFF2A1A0A), const Color(0xFF0A0805)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Torch glow left
    _drawTorchGlow(canvas, w * 0.12, h * 0.4);
    // Torch glow right
    _drawTorchGlow(canvas, w * 0.88, h * 0.4);

    // Stalactites from ceiling
    final rockPaint = Paint()..color = const Color(0xFF3A2A1A);
    final rng = Random(7);
    for (int i = 0; i < 9; i++) {
      final x = w * 0.05 + (i * w * 0.105);
      final stalHeight = 30.0 + rng.nextDouble() * 55;
      canvas.drawPath(
        Path()
          ..moveTo(x - 12, 0)
          ..lineTo(x, stalHeight)
          ..lineTo(x + 12, 0)
          ..close(),
        rockPaint,
      );
    }

    // Stalagmites from floor
    final rng2 = Random(13);
    for (int i = 0; i < 7; i++) {
      final x = w * 0.07 + (i * w * 0.13);
      final stagHeight = 20.0 + rng2.nextDouble() * 35;
      canvas.drawPath(
        Path()
          ..moveTo(x - 10, h)
          ..lineTo(x, h - stagHeight)
          ..lineTo(x + 10, h)
          ..close(),
        rockPaint,
      );
    }

    // Ground with rock texture
    final groundPaint = Paint()..color = const Color(0xFF2A1A0A);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.84, w, h * 0.16), groundPaint);

    // Cracks in wall
    final crackPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(w * 0.3, h * 0.2), Offset(w * 0.25, h * 0.45), crackPaint);
    canvas.drawLine(
        Offset(w * 0.7, h * 0.15), Offset(w * 0.75, h * 0.38), crackPaint);
  }

  void _drawTorchGlow(Canvas c, double x, double y) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 35);
    c.drawCircle(Offset(x, y), 50, glowPaint);

    // Torch stick
    c.drawRect(Rect.fromCenter(center: Offset(x, y + 20), width: 8, height: 30),
        Paint()..color = const Color(0xFF5D4037));
    // Flame
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y - 5), width: 16, height: 22),
      Paint()..color = const Color(0xFFFF6B00),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y - 8), width: 8, height: 12),
      Paint()..color = const Color(0xFFFFE000),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// 3. Haunted Keep — crumbling walls, moon, bats
// ─────────────────────────────────────────────
class HauntedBattlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stormy sky
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0A0A1A), const Color(0xFF1A1A2E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Eerie moon
    final moonGlow = Paint()
      ..color = const Color(0xFF607D8B).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(w * 0.5, h * 0.1), 45, moonGlow);
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.1), 28, Paint()..color = const Color(0xFFB0BEC5));

    // Storm clouds
    final cloudPaint = Paint()
      ..color = const Color(0xFF263238).withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.3, h * 0.08), width: 120, height: 40),
        cloudPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.72, h * 0.07), width: 100, height: 35),
        cloudPaint);

    // Castle wall left
    _drawWallSection(canvas, 0, h * 0.5, w * 0.2, h);
    // Castle wall right
    _drawWallSection(canvas, w * 0.8, h * 0.5, w, h);

    // Battlements (merlons)
    final stonePaint = Paint()..color = const Color(0xFF37474F);
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * w * 0.045, h * 0.5 - 20, w * 0.03, 20),
        stonePaint,
      );
    }
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
            w - (i + 1) * w * 0.045 - w * 0.03, h * 0.5 - 20, w * 0.03, 20),
        stonePaint,
      );
    }

    // Ground — cracked stone
    canvas.drawRect(Rect.fromLTWH(0, h * 0.84, w, h * 0.16),
        Paint()..color = const Color(0xFF263238));

    // Crack lines on ground
    final crackPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.2, h * 0.84), Offset(w * 0.35, h), crackPaint);
    canvas.drawLine(Offset(w * 0.6, h * 0.84), Offset(w * 0.5, h), crackPaint);

    // Bats
    _drawBat(canvas, w * 0.2, h * 0.25);
    _drawBat(canvas, w * 0.75, h * 0.32);
    _drawBat(canvas, w * 0.45, h * 0.18);

    // Purple mist
    final mistPaint = Paint()
      ..color = const Color(0xFF7B1FA2).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w / 2, h * 0.86), width: w, height: 80),
        mistPaint);
  }

  void _drawWallSection(Canvas c, double x1, double y1, double x2, double y2) {
    final p = Paint()..color = const Color(0xFF37474F);
    c.drawRect(Rect.fromLTRB(x1, y1, x2, y2), p);
    // Stone texture lines
    final lp = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1;
    for (double y = y1; y < y2; y += 18) {
      c.drawLine(Offset(x1, y), Offset(x2, y), lp);
    }
    for (double y = y1; y < y2; y += 36) {
      c.drawLine(Offset(x1 + (x2 - x1) / 2, y),
          Offset(x1 + (x2 - x1) / 2, y + 18), lp);
    }
  }

  void _drawBat(Canvas c, double x, double y) {
    final p = Paint()..color = const Color(0xFF1A1A2E);
    // Left wing
    c.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x - 18, y - 8)
        ..lineTo(x - 12, y + 5)
        ..close(),
      p,
    );
    // Right wing
    c.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x + 18, y - 8)
        ..lineTo(x + 12, y + 5)
        ..close(),
      p,
    );
    // Body
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 10, height: 8), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// 4. Dragon Peak — lava, volcanic mountains
// ─────────────────────────────────────────────
class DragonPeakBattlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fiery sky
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A0500),
          const Color(0xFF3D0C00),
          const Color(0xFF8B1A1A),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Volcanic ash clouds
    final ashPaint = Paint()
      ..color = const Color(0xFF4A2000).withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.25, h * 0.1), width: 160, height: 50),
        ashPaint);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.72, h * 0.08), width: 130, height: 45),
        ashPaint);

    // Volcano mountains (background)
    _drawVolcano(canvas, w * 0.1, h * 0.85, h * 0.55);
    _drawVolcano(canvas, w * 0.85, h * 0.85, h * 0.60);

    // Lava river at ground level
    final lavaPaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFFFF6B00), const Color(0xFFFF3D00)],
      ).createShader(Rect.fromLTWH(0, h * 0.83, w, h * 0.08));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.83, w, h * 0.08), lavaPaint);

    // Lava glow
    final lavaGlow = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, 40), lavaGlow);

    // Dark rock ground
    canvas.drawRect(Rect.fromLTWH(0, h * 0.88, w, h * 0.12),
        Paint()..color = const Color(0xFF1A0A00));

    // Lava bubbles
    final rng = Random(5);
    final bubblePaint = Paint()
      ..color = const Color(0xFFFF4500).withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
          Offset(rng.nextDouble() * w, h * 0.84 + rng.nextDouble() * 20),
          3 + rng.nextDouble() * 4,
          bubblePaint);
    }

    // Ember particles rising
    final emberPaint = Paint()
      ..color = const Color(0xFFFF6B00).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final rng2 = Random(99);
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(
          Offset(rng2.nextDouble() * w, rng2.nextDouble() * h * 0.8),
          1 + rng2.nextDouble() * 2,
          emberPaint);
    }
  }

  void _drawVolcano(Canvas c, double cx, double baseY, double height) {
    final p = Paint()..color = const Color(0xFF1A0500);
    c.drawPath(
      Path()
        ..moveTo(cx, baseY - height)
        ..lineTo(cx - height * 0.4, baseY)
        ..lineTo(cx + height * 0.4, baseY)
        ..close(),
      p,
    );
    // Lava at top
    final lavaTip = Paint()
      ..color = const Color(0xFFFF4500).withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    c.drawCircle(Offset(cx, baseY - height + 10), 15, lavaTip);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
