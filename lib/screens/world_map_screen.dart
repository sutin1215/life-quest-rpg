import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'battle_screen.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    // The core RPG regions with their specific coordinates
    final List<Map<String, dynamic>> zones = [
      {
        "id": 1,
        "name": "Slime Forest",
        "boss": "Giant Slime",
        "reqLvl": 2,
        "color": const Color(0xFF4CAF50),
        "x": 200.0,
        "y": 550.0
      },
      {
        "id": 2,
        "name": "Goblin Cave",
        "boss": "Goblin King",
        "reqLvl": 5,
        "color": const Color(0xFF8D6E63),
        "x": 450.0,
        "y": 400.0
      },
      {
        "id": 3,
        "name": "Haunted Keep",
        "boss": "Skeleton Lord",
        "reqLvl": 8,
        "color": const Color(0xFF607D8B),
        "x": 650.0,
        "y": 550.0
      },
      {
        "id": 4,
        "name": "Dragon Peak",
        "boss": "Red Dragon",
        "reqLvl": 12,
        "color": const Color(0xFFFF5722),
        "x": 900.0,
        "y": 250.0
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: Text("THE FORBIDDEN LANDS",
            style: GoogleFonts.vt323(
                fontSize: 32, color: const Color(0xFFFFD700))),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: db.getUserStats(),
        builder: (context, snapshot) {
          int userLvl = 1;
          String userClass = "Hero";

          if (snapshot.hasData && snapshot.data!.exists) {
            final user = snapshot.data!.data() as Map<String, dynamic>;
            userLvl = user['level'] ?? 1;
            userClass = user['className'] ?? "Hero";
          }

          return InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(400),
            minScale: 0.4,
            maxScale: 2.5,
            child: Stack(
              children: [
                // 1. THE PROCEDURAL MAP
                CustomPaint(
                  size: const Size(1400, 900),
                  painter: RpgMapPainter(zones: zones),
                ),

                // 2. INTERACTIVE ZONE MARKERS
                ...zones.map((zone) {
                  bool isLocked = userLvl < zone['reqLvl'];
                  // Glow logic: If the user is currently qualified for this zone but hasn't reached the next one
                  bool isNext = !isLocked && (zone['reqLvl'] > userLvl - 3);

                  return Positioned(
                    left: zone['x'] - 35,
                    top: zone['y'] - 80,
                    child: GestureDetector(
                      onTap: () => _handleTap(
                          context, zone, userLvl, userClass, isLocked),
                      child: _buildFantasyMarker(zone, isLocked, isNext),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleTap(BuildContext context, Map zone, int userLvl, String userClass,
      bool isLocked) {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Danger! Reach Level ${zone['reqLvl']} to enter.",
            style: GoogleFonts.vt323(fontSize: 20)),
        backgroundColor: Colors.red.withOpacity(0.9),
      ));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BattleScreen(
                    zone: zone as Map<String, dynamic>,
                    userLvl: userLvl,
                    userClass: userClass,
                  )));
    }
  }

  Widget _buildFantasyMarker(Map zone, bool isLocked, bool isNext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: isNext ? 70 : 60,
          height: isNext ? 70 : 60,
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey.shade900 : zone['color'],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isLocked ? Colors.black : zone['color'].withOpacity(0.6),
                blurRadius: isNext ? 25 : 10,
                spreadRadius: isNext ? 5 : 2,
              )
            ],
            border: Border.all(
                color: const Color(0xFFFFD700), width: isLocked ? 1 : 3),
          ),
          child: Icon(isLocked ? Icons.lock_outline : Icons.shield,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12)),
          child: Text(zone['name'],
              style: GoogleFonts.vt323(
                  color: isLocked ? Colors.grey : const Color(0xFFFFD700),
                  fontSize: 18)),
        ),
      ],
    );
  }
}

class RpgMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> zones;
  RpgMapPainter({required this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Water Background (Ocean Gradient)
    final Rect bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F2027),
          Color(0xFF203A43),
          Color(0xFF2C5364),
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, waterPaint);

    // 2. Main Continent Path
    final landPaint = Paint()..color = const Color(0xFF1B4332);
    final shorePaint = Paint()
      ..color = const Color(0xFFD4A373)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    var continentPath = Path()
      ..moveTo(100, 500)
      ..quadraticBezierTo(200, 200, 500, 250)
      ..quadraticBezierTo(800, 100, 1100, 300)
      ..quadraticBezierTo(1300, 600, 1000, 800)
      ..quadraticBezierTo(600, 950, 200, 800)
      ..close();

    canvas.drawPath(continentPath, landPaint);
    canvas.drawPath(continentPath, shorePaint);

    // 3. Decorations (Mountains & Malaysian Palm Trees)
    _drawMountain(canvas, 850, 220);
    _drawMountain(canvas, 910, 250);

    _drawPalmTree(canvas, 250, 580);
    _drawPalmTree(canvas, 600, 600);
    _drawPalmTree(canvas, 400, 450);

    // 4. Connect Zones with Dashed Travel Lines
    _drawDashedTravelLines(canvas);
  }

  void _drawDashedTravelLines(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < zones.length - 1; i++) {
      final start = Offset(zones[i]['x'], zones[i]['y']);
      final end = Offset(zones[i + 1]['x'], zones[i + 1]['y']);

      double distance = 0;
      final totalDist = (end - start).distance;
      while (distance < totalDist) {
        final lerpedOffset = Offset.lerp(start, end, distance / totalDist);
        if (lerpedOffset != null) {
          canvas.drawCircle(lerpedOffset, 1.5, paint);
        }
        distance += 15;
      }
    }
  }

  void _drawMountain(Canvas canvas, double x, double y) {
    final mountainPaint = Paint()..color = const Color(0xFF3E2723);
    final path = Path()
      ..moveTo(x, y)
      ..lineTo(x + 35, y - 70)
      ..lineTo(x + 70, y)
      ..close();
    canvas.drawPath(path, mountainPaint);
    // Snow Cap
    canvas.drawPath(
        Path()
          ..moveTo(x + 25, y - 50)
          ..lineTo(x + 35, y - 70)
          ..lineTo(x + 45, y - 50)
          ..close(),
        Paint()..color = Colors.white);
  }

  void _drawPalmTree(Canvas canvas, double x, double y) {
    // Trunk
    canvas.drawLine(
        Offset(x, y),
        Offset(x, y - 25),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 4);
    // Leaves (Tropical RPG Style)
    final leafPaint = Paint()..color = const Color(0xFF2D6A4F);
    canvas.drawCircle(Offset(x - 10, y - 28), 12, leafPaint);
    canvas.drawCircle(Offset(x + 10, y - 28), 12, leafPaint);
    canvas.drawCircle(Offset(x, y - 35), 12, leafPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
