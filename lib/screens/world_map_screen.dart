import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../theme/rpg_theme.dart';
import 'battle_screen.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    final List<Map<String, dynamic>> zones = [
      {
        'id': 1,
        'name': 'Slime Forest',
        'boss': 'Giant Slime',
        'reqLvl': 2,
        'color': const Color(0xFF4CAF50),
        'x': 200.0,
        'y': 550.0,
      },
      {
        'id': 2,
        'name': 'Goblin Cave',
        'boss': 'Goblin King',
        'reqLvl': 5,
        'color': const Color(0xFF8D6E63),
        'x': 450.0,
        'y': 400.0,
      },
      {
        'id': 3,
        'name': 'Haunted Keep',
        'boss': 'Skeleton Lord',
        'reqLvl': 8,
        'color': const Color(0xFF607D8B),
        'x': 650.0,
        'y': 550.0,
      },
      {
        'id': 4,
        'name': 'Dragon Peak',
        'boss': 'Red Dragon',
        'reqLvl': 12,
        'color': const Color(0xFFFF5722),
        'x': 900.0,
        'y': 250.0,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: Text('THE FORBIDDEN LANDS',
            style: GoogleFonts.vt323(
                fontSize: 30,
                color: RpgTheme.goldPrimary,
                shadows: [
                  const Shadow(blurRadius: 10, color: RpgTheme.goldPrimary)
                ])),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: RpgTheme.goldPrimary.withOpacity(0.3)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: db.getUserStats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load map data.',
                  style:
                      GoogleFonts.vt323(fontSize: 22, color: Colors.redAccent)),
            );
          }

          int userLvl = 1;
          String userClass = 'Hero';
          int userStr = 5, userInt = 5, userDex = 5, currentZone = 1;

          if (snapshot.hasData && snapshot.data!.exists) {
            final user = snapshot.data!.data() as Map<String, dynamic>;
            userLvl = user['level'] ?? 1;
            userClass = user['className'] ?? 'Hero';
            userStr = user['str'] ?? 5;
            userInt = user['int'] ?? 5;
            userDex = user['dex'] ?? 5;
            currentZone = user['currentZone'] ?? 1;
          }

          return InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(400),
            minScale: 0.4,
            maxScale: 2.5,
            child: Stack(
              children: [
                // Map background
                CustomPaint(
                  size: const Size(1400, 900),
                  painter: RpgMapPainter(zones: zones),
                ),
                // IMPROVEMENT #10: Fog of war painter over locked zones
                CustomPaint(
                  size: const Size(1400, 900),
                  painter: FogOfWarPainter(
                      zones: zones, currentZone: currentZone, userLvl: userLvl),
                ),
                ...zones.map((zone) {
                  final bool isLocked = userLvl < (zone['reqLvl'] as int);
                  final bool isDefeated = (zone['id'] as int) < currentZone;
                  final bool isNext = !isLocked &&
                      !isDefeated &&
                      zones
                              .where((z) =>
                                  !(userLvl < (z['reqLvl'] as int)) &&
                                  (z['id'] as int) >= currentZone)
                              .map((z) => z['reqLvl'] as int)
                              .fold(999, (a, b) => a < b ? a : b) ==
                          (zone['reqLvl'] as int);

                  return Positioned(
                    left: (zone['x'] as double) - 35,
                    top: (zone['y'] as double) - 80,
                    child: _AnimatedMapMarker(
                      zone: zone,
                      isLocked: isLocked,
                      isNext: isNext,
                      isDefeated: isDefeated,
                      onTap: () => _handleTap(context, zone, userLvl, userClass,
                          isLocked, userStr, userInt, userDex),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // IMPROVEMENT #11: Zone entry transition (expanding circle)
  void _handleTap(BuildContext context, Map zone, int userLvl, String userClass,
      bool isLocked, int str, int int_, int dex) {
    if (isLocked) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: RpgTheme.cardDecoration(borderColor: Colors.redAccent),
          child: Text(
            'Danger! Reach Level ${zone['reqLvl']} to enter.',
            style: GoogleFonts.vt323(fontSize: 20, color: Colors.white),
          ),
        ),
      ));
    } else {
      HapticFeedback.heavyImpact();
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => BattleScreen(
            zone: zone as Map<String, dynamic>,
            userLvl: userLvl,
            userClass: userClass,
            userStr: str,
            userInt: int_,
            userDex: dex,
          ),
          transitionsBuilder: (_, animation, __, child) {
            // Expanding circle wipe transition
            return ClipPath(
              clipper: _CircleRevealClipper(animation.value),
              child: child,
            );
          },
        ),
      );
    }
  }
}

// IMPROVEMENT #11: Circular reveal clipper for zone entry
class _CircleRevealClipper extends CustomClipper<Path> {
  final double progress;
  _CircleRevealClipper(this.progress);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = sqrt(size.width * size.width + size.height * size.height);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: maxRadius * progress));
  }

  @override
  bool shouldReclip(_CircleRevealClipper old) => old.progress != progress;
}

// IMPROVEMENT #9: Animated map marker with floating bob and rotation on lock
class _AnimatedMapMarker extends StatefulWidget {
  final Map zone;
  final bool isLocked, isNext, isDefeated;
  final VoidCallback onTap;

  const _AnimatedMapMarker({
    required this.zone,
    required this.isLocked,
    required this.isNext,
    required this.isDefeated,
    required this.onTap,
  });

  @override
  State<_AnimatedMapMarker> createState() => _AnimatedMapMarkerState();
}

class _AnimatedMapMarkerState extends State<_AnimatedMapMarker>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _lockSpinCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();

    // IMPROVEMENT #9: Float bob for NEXT zone
    _floatCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _floatAnim = Tween(begin: -6.0, end: 6.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // IMPROVEMENT #9: Slow rotation for locked zones
    _lockSpinCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _spinAnim = Tween(begin: 0.0, end: 2 * pi).animate(_lockSpinCtrl);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _lockSpinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color zoneColor = widget.zone['color'] as Color;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatAnim, _spinAnim]),
        builder: (_, __) {
          final floatOffset = widget.isNext ? _floatAnim.value : 0.0;
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main marker circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: widget.isNext ? 72 : 60,
                      height: widget.isNext ? 72 : 60,
                      decoration: BoxDecoration(
                        color: widget.isLocked
                            ? Colors.grey.shade900
                            : widget.isDefeated
                                ? Colors.grey.shade700
                                : zoneColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.isLocked
                                ? Colors.black
                                : widget.isDefeated
                                    ? Colors.black45
                                    : zoneColor.withOpacity(0.6),
                            blurRadius: widget.isNext ? 28 : 10,
                            spreadRadius: widget.isNext ? 6 : 2,
                          ),
                        ],
                        border: Border.all(
                            color: widget.isLocked
                                ? Colors.grey.shade700
                                : RpgTheme.goldPrimary,
                            width: widget.isLocked ? 1 : 2.5),
                      ),
                      child: widget.isLocked
                          ? Transform.rotate(
                              angle: _spinAnim.value * 0.08,
                              child: const Icon(Icons.lock_outline,
                                  color: Colors.grey, size: 28),
                            )
                          : Icon(
                              widget.isDefeated
                                  ? Icons.check_circle
                                  : Icons.shield,
                              color: Colors.white,
                              size: 30,
                            ),
                    ),
                    // NEXT badge
                    if (widget.isNext)
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: RpgTheme.goldPrimary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: RpgTheme.goldPrimary.withOpacity(0.6),
                                  blurRadius: 6)
                            ],
                          ),
                          child: Text('NEXT',
                              style: GoogleFonts.vt323(
                                  fontSize: 12, color: Colors.black)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: widget.isDefeated
                            ? Colors.grey.withOpacity(0.3)
                            : widget.isLocked
                                ? Colors.grey.withOpacity(0.2)
                                : RpgTheme.goldPrimary.withOpacity(0.5)),
                  ),
                  child: Text(
                    widget.zone['name'] as String,
                    style: GoogleFonts.vt323(
                      color: widget.isDefeated || widget.isLocked
                          ? Colors.grey
                          : RpgTheme.goldLight,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (widget.isLocked)
                  Text('Req. Lvl ${widget.zone['reqLvl']}',
                      style: GoogleFonts.vt323(
                          fontSize: 14, color: Colors.red[300])),
                if (widget.isDefeated)
                  Text('CLEARED',
                      style: GoogleFonts.vt323(
                          fontSize: 14, color: Colors.greenAccent)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// IMPROVEMENT #10: Fog of war over locked areas
class FogOfWarPainter extends CustomPainter {
  final List<Map<String, dynamic>> zones;
  final int currentZone;
  final int userLvl;

  FogOfWarPainter({
    required this.zones,
    required this.currentZone,
    required this.userLvl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final zone in zones) {
      final bool isLocked = userLvl < (zone['reqLvl'] as int);
      if (!isLocked) continue;

      final double x = zone['x'] as double;
      final double y = zone['y'] as double;

      final fogPaint = Paint()
        ..color = const Color(0xFF0D1B2A).withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(Offset(x, y), 90, fogPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FogOfWarPainter old) =>
      old.userLvl != userLvl || old.currentZone != currentZone;
}

// ── Map Painter (unchanged visual, just cleaned up) ──────────────────────────
class RpgMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> zones;
  RpgMapPainter({required this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, waterPaint);

    final landPaint = Paint()..color = const Color(0xFF1B4332);
    final shorePaint = Paint()
      ..color = RpgTheme.parchment
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final continentPath = Path()
      ..moveTo(100, 500)
      ..quadraticBezierTo(200, 200, 500, 250)
      ..quadraticBezierTo(800, 100, 1100, 300)
      ..quadraticBezierTo(1300, 600, 1000, 800)
      ..quadraticBezierTo(600, 950, 200, 800)
      ..close();

    canvas.drawPath(continentPath, landPaint);
    canvas.drawPath(continentPath, shorePaint);

    _drawMountain(canvas, 850, 220);
    _drawMountain(canvas, 910, 250);
    _drawPalmTree(canvas, 250, 580);
    _drawPalmTree(canvas, 600, 600);
    _drawPalmTree(canvas, 400, 450);
    _drawDashedLines(canvas);
  }

  void _drawDashedLines(Canvas canvas) {
    final paint = Paint()
      ..color = RpgTheme.goldPrimary.withOpacity(0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < zones.length - 1; i++) {
      final start = Offset(zones[i]['x'] as double, zones[i]['y'] as double);
      final end =
          Offset(zones[i + 1]['x'] as double, zones[i + 1]['y'] as double);
      double dist = 0;
      final total = (end - start).distance;
      while (dist < total) {
        final p = Offset.lerp(start, end, dist / total);
        if (p != null) canvas.drawCircle(p, 2, paint);
        dist += 16;
      }
    }
  }

  void _drawMountain(Canvas canvas, double x, double y) {
    final p = Paint()..color = const Color(0xFF3E2723);
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x + 35, y - 70)
        ..lineTo(x + 70, y)
        ..close(),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + 25, y - 50)
        ..lineTo(x + 35, y - 70)
        ..lineTo(x + 45, y - 50)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  void _drawPalmTree(Canvas canvas, double x, double y) {
    canvas.drawLine(
        Offset(x, y),
        Offset(x, y - 25),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 4);
    final leaf = Paint()..color = RpgTheme.forestGreen;
    canvas.drawCircle(Offset(x - 10, y - 28), 12, leaf);
    canvas.drawCircle(Offset(x + 10, y - 28), 12, leaf);
    canvas.drawCircle(Offset(x, y - 35), 12, leaf);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
