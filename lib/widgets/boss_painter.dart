import 'package:flutter/material.dart';

/// Unique pixel-art style boss painters for each zone.
/// All drawn with Flutter's Canvas — zero external assets needed.

// ─────────────────────────────────────────────
// Factory — returns the right painter by boss name
// ─────────────────────────────────────────────
Widget buildBossArt(String bossName, Color zoneColor, {double size = 140}) {
  CustomPainter painter;
  final name = bossName.toLowerCase();

  if (name.contains('slime')) {
    painter = SlimePainter(color: zoneColor);
  } else if (name.contains('goblin')) {
    painter = GoblinPainter(color: zoneColor);
  } else if (name.contains('skeleton')) {
    painter = SkeletonPainter(color: zoneColor);
  } else if (name.contains('dragon')) {
    painter = DragonPainter(color: zoneColor);
  } else {
    painter = DefaultBossPainter(color: zoneColor);
  }

  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: painter),
  );
}

// ─────────────────────────────────────────────
// 1. Giant Slime — bubbly blob with eyes
// ─────────────────────────────────────────────
class SlimePainter extends CustomPainter {
  final Color color;
  SlimePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // Body
    final bodyPaint = Paint()..color = color.withValues(alpha: 0.9);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 70),
        glowPaint);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 88, height: 68),
        bodyPaint);

    // Shine
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 18, cy - 16), width: 20, height: 14),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1A1A1A);
    final pupilPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - 16, cy - 5), 10, eyePaint);
    canvas.drawCircle(Offset(cx + 16, cy - 5), 10, eyePaint);
    canvas.drawCircle(Offset(cx - 18, cy - 7), 3, pupilPaint);
    canvas.drawCircle(Offset(cx + 14, cy - 7), 3, pupilPaint);

    // Angry brow
    final browPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx - 24, cy - 18), Offset(cx - 8, cy - 14), browPaint);
    canvas.drawLine(
        Offset(cx + 24, cy - 18), Offset(cx + 8, cy - 14), browPaint);

    // Teeth
    final teethPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cx - 20 + (i * 10), cy + 18, 7, 10),
        teethPaint,
      );
    }

    // Bubbles
    final bubblePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx + 38, cy - 20), 8, bubblePaint);
    canvas.drawCircle(Offset(cx + 48, cy - 35), 5, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// 2. Goblin King — pointy ears, crown, grin
// ─────────────────────────────────────────────
class GoblinPainter extends CustomPainter {
  final Color color;
  GoblinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    const skinColor = Color(0xFF6B8C42);

    // Crown
    final crownPaint = Paint()..color = const Color(0xFFFFD700);
    final crownPath = Path()
      ..moveTo(cx - 28, cy - 48)
      ..lineTo(cx - 28, cy - 64)
      ..lineTo(cx - 16, cy - 54)
      ..lineTo(cx, cy - 68)
      ..lineTo(cx + 16, cy - 54)
      ..lineTo(cx + 28, cy - 64)
      ..lineTo(cx + 28, cy - 48)
      ..close();
    canvas.drawPath(crownPath, crownPaint);
    // Crown gems
    canvas.drawCircle(
        Offset(cx, cy - 62), 5, Paint()..color = Colors.red.shade700);
    canvas.drawCircle(
        Offset(cx - 22, cy - 57), 3, Paint()..color = Colors.blue.shade400);
    canvas.drawCircle(
        Offset(cx + 22, cy - 57), 3, Paint()..color = Colors.blue.shade400);

    // Head
    final headPaint = Paint()..color = skinColor;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 20), width: 70, height: 75),
      headPaint,
    );

    // Pointy ears
    final earPath = Path()
      ..moveTo(cx - 35, cy - 20)
      ..lineTo(cx - 55, cy - 40)
      ..lineTo(cx - 28, cy - 5)
      ..close();
    canvas.drawPath(earPath, headPaint);
    final earPath2 = Path()
      ..moveTo(cx + 35, cy - 20)
      ..lineTo(cx + 55, cy - 40)
      ..lineTo(cx + 28, cy - 5)
      ..close();
    canvas.drawPath(earPath2, headPaint);

    // Eyes — yellow glowing
    canvas.drawCircle(
        Offset(cx - 14, cy - 22), 10, Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx + 14, cy - 22), 10, Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx - 14, cy - 22), 6, Paint()..color = const Color(0xFFFFE000));
    canvas.drawCircle(
        Offset(cx + 14, cy - 22), 6, Paint()..color = const Color(0xFFFFE000));
    canvas.drawCircle(
        Offset(cx - 14, cy - 22), 3, Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx + 14, cy - 22), 3, Paint()..color = Colors.black);

    // Big nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 10), width: 22, height: 14),
      Paint()..color = skinColor.withRed(100),
    );
    canvas.drawCircle(Offset(cx - 6, cy - 8), 4,
        Paint()..color = Colors.black.withValues(alpha: 0.4));
    canvas.drawCircle(Offset(cx + 6, cy - 8), 4,
        Paint()..color = Colors.black.withValues(alpha: 0.4));

    // Menacing grin
    final mouthPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 36, height: 20),
      0.2,
      2.7,
      false,
      mouthPaint,
    );
    // Tusk
    canvas.drawRect(
        Rect.fromLTWH(cx - 20, cy + 8, 6, 12), Paint()..color = Colors.white);
    canvas.drawRect(
        Rect.fromLTWH(cx + 14, cy + 8, 6, 12), Paint()..color = Colors.white);

    // Body
    final bodyPaint = Paint()..color = color.withValues(alpha: 0.8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 38), width: 60, height: 40),
        const Radius.circular(6),
      ),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// 3. Skeleton Lord — skull with glowing eyes
// ─────────────────────────────────────────────
class SkeletonPainter extends CustomPainter {
  final Color color;
  SkeletonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 5;
    final bonePaint = Paint()..color = const Color(0xFFE8E0C8);
    final shadowPaint = Paint()..color = const Color(0xFF9E9880);

    // Ribcage
    for (int i = 0; i < 4; i++) {
      final y = cy + 20 + (i * 10);
      // Left rib
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx - 10, y), width: 44, height: 14),
        3.14,
        3.14,
        false,
        Paint()
          ..color = bonePaint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      // Right rib
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 10, y), width: 44, height: 14),
        0,
        3.14,
        false,
        Paint()
          ..color = bonePaint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    // Spine
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(Offset(cx, cy + 18 + (i * 8)), 4, bonePaint);
    }

    // Skull
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 22), width: 72, height: 75),
      bonePaint,
    );
    // Shadow on skull
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 8, cy - 16), width: 30, height: 35),
      Paint()..color = shadowPaint.color.withValues(alpha: 0.3),
    );
    // Jaw
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 8), width: 54, height: 20),
        const Radius.circular(4),
      ),
      bonePaint,
    );

    // Glowing eye sockets
    final eyeGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx - 16, cy - 20), 12, eyeGlowPaint);
    canvas.drawCircle(Offset(cx + 16, cy - 20), 12, eyeGlowPaint);
    canvas.drawCircle(
        Offset(cx - 16, cy - 20), 8, Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx + 16, cy - 20), 8, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx - 16, cy - 20), 5,
        Paint()..color = color.withValues(alpha: 0.95));
    canvas.drawCircle(Offset(cx + 16, cy - 20), 5,
        Paint()..color = color.withValues(alpha: 0.95));

    // Nasal cavity
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - 4)
        ..lineTo(cx - 5, cy + 3)
        ..lineTo(cx + 5, cy + 3)
        ..close(),
      Paint()..color = Colors.black54,
    );

    // Teeth
    final darkPaint = Paint()..color = const Color(0xFF1A1A1A);
    for (int i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(cx - 18 + (i * 7), cy + 1, 5, 9),
        bonePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - 18 + (i * 7) + 5, cy + 1, 2, 9),
        darkPaint,
      );
    }

    // Dark crown / hood wisps
    final wispPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 58), width: 80, height: 30),
      wispPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// 4. Red Dragon — fierce dragon head
// ─────────────────────────────────────────────
class DragonPainter extends CustomPainter {
  final Color color;
  DragonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    // Fire breath glow behind
    final fireGlow = Paint()
      ..color = Colors.orange.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 30, cy + 20), width: 60, height: 30),
      fireGlow,
    );

    // Neck/body
    final scalePaint = Paint()..color = color;
    final darkScale = Paint()..color = color.withRed((color.red * 0.6).toInt());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx + 10, cy + 30), width: 50, height: 45),
        const Radius.circular(8),
      ),
      scalePaint,
    );

    // Wing hints
    final wingPaint = Paint()..color = color.withValues(alpha: 0.7);
    final wingL = Path()
      ..moveTo(cx - 10, cy)
      ..lineTo(cx - 60, cy - 35)
      ..lineTo(cx - 50, cy + 10)
      ..lineTo(cx - 15, cy + 15)
      ..close();
    canvas.drawPath(wingL, wingPaint);
    final wingR = Path()
      ..moveTo(cx + 30, cy)
      ..lineTo(cx + 70, cy - 30)
      ..lineTo(cx + 60, cy + 15)
      ..lineTo(cx + 35, cy + 15)
      ..close();
    canvas.drawPath(wingR, wingPaint);

    // Head
    final headPath = Path()
      ..moveTo(cx - 30, cy - 10)
      ..lineTo(cx - 40, cy - 40)
      ..lineTo(cx - 15, cy - 55)
      ..lineTo(cx + 20, cy - 50)
      ..lineTo(cx + 35, cy - 30)
      ..lineTo(cx + 25, cy)
      ..close();
    canvas.drawPath(headPath, scalePaint);

    // Snout
    final snoutPath = Path()
      ..moveTo(cx - 38, cy - 18)
      ..lineTo(cx - 60, cy - 8)
      ..lineTo(cx - 55, cy + 5)
      ..lineTo(cx - 25, cy + 2)
      ..close();
    canvas.drawPath(snoutPath, darkScale);

    // Nostril flame
    canvas.drawCircle(
      Offset(cx - 48, cy - 5),
      5,
      Paint()
        ..color = Colors.orange
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Horns
    final hornPaint = Paint()..color = const Color(0xFF3E2723);
    final horn1 = Path()
      ..moveTo(cx - 10, cy - 52)
      ..lineTo(cx - 20, cy - 78)
      ..lineTo(cx + 2, cy - 50)
      ..close();
    canvas.drawPath(horn1, hornPaint);
    final horn2 = Path()
      ..moveTo(cx + 14, cy - 48)
      ..lineTo(cx + 24, cy - 72)
      ..lineTo(cx + 30, cy - 46)
      ..close();
    canvas.drawPath(horn2, hornPaint);

    // Eye — slit pupil
    canvas.drawCircle(
        Offset(cx + 10, cy - 32), 12, Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx + 10, cy - 32), 9, Paint()..color = const Color(0xFFFFE000));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx + 10, cy - 32), width: 4, height: 14),
      Paint()..color = Colors.black,
    );

    // Scale texture lines
    final linePaint = Paint()
      ..color = darkScale.color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx + 10 + (i * 4), cy - 20 + (i * 6)),
            width: 18,
            height: 12),
        0,
        3.14,
        false,
        linePaint,
      );
    }

    // Teeth
    final teethPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 4; i++) {
      final tx = cx - 55 + (i * 8);
      canvas.drawPath(
        Path()
          ..moveTo(tx, cy + 2)
          ..lineTo(tx + 4, cy + 12)
          ..lineTo(tx + 8, cy + 2)
          ..close(),
        teethPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// Default boss for unknown names
// ─────────────────────────────────────────────
class DefaultBossPainter extends CustomPainter {
  final Color color;
  DefaultBossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), 50, glow);
    canvas.drawCircle(Offset(cx, cy), 44, Paint()..color = color);
    canvas.drawCircle(Offset(cx, cy), 44,
        Paint()..color = Colors.black.withValues(alpha: 0.3));
    canvas.drawCircle(
        Offset(cx - 12, cy - 8), 10, Paint()..color = Colors.black);
    canvas.drawCircle(
        Offset(cx + 12, cy - 8), 10, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(cx - 12, cy - 8), 5, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(cx + 12, cy - 8), 5, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
