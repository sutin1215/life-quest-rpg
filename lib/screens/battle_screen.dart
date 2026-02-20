import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import 'dart:math';

class BattleScreen extends StatefulWidget {
  final Map<String, dynamic> zone;
  final int userLvl;
  final String userClass;

  const BattleScreen({
    super.key,
    required this.zone,
    required this.userLvl,
    required this.userClass,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  final AiService _ai = AiService();
  final DatabaseService _db = DatabaseService();

  String _narrative = "The enemy draws near...";
  bool _isFighting = false;
  bool _hasFought = false;
  bool _didWin = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
        lowerBound: 0.95,
        upperBound: 1.05)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startBattle() async {
    setState(() {
      _isFighting = true;
      _narrative = "Clashing with the ${widget.zone['boss']}...";
    });

    final winChance =
        (50 + (widget.userLvl - widget.zone['reqLvl']) * 10).clamp(5, 95);
    final roll = Random().nextInt(100);
    final didWin = roll < winChance;

    String intensity = didWin
        ? (winChance - roll > 30 ? 'Flawless' : 'Clutch')
        : (roll - winChance > 30 ? 'Overwhelming' : 'Solid');

    final narrative = await _ai.generateBattleNarration(
      heroClass: widget.userClass,
      heroLevel: widget.userLvl,
      bossName: widget.zone['boss'],
      bossLevel: widget.zone['reqLvl'],
      didWin: didWin,
      intensity: intensity,
    );

    if (didWin) await _db.defeatBoss(widget.zone['id']);

    if (mounted) {
      setState(() {
        _narrative = narrative;
        _isFighting = false;
        _hasFought = true;
        _didWin = didWin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color zoneColor = widget.zone['color'] ?? Colors.red;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          CustomPaint(
            painter: BattleBackgroundPainter(color: zoneColor),
            size: Size.infinite,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _controller,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withAlpha((255 * 0.5).round()),
                        boxShadow: [
                          BoxShadow(
                              color: zoneColor, blurRadius: 40, spreadRadius: 5)
                        ],
                        border: Border.all(color: Colors.white, width: 2)),
                    child: Icon(Icons.adb,
                        size: 100, color: zoneColor.withAlpha((255 * 0.9).round())),
                  ),
                ),
                const SizedBox(height: 20),
                Text(widget.zone['boss'].toUpperCase(),
                    style: GoogleFonts.vt323(
                        fontSize: 40,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(2, 2))
                        ])),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  tween: Tween<double>(
                      begin: 1.0, end: _hasFought && _didWin ? 0.0 : 1.0),
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: const Size(200, 20),
                      painter: HealthBarPainter(
                          percentage: value, color: Colors.red),
                    );
                  },
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((255 * 0.8).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: _isFighting
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : SingleChildScrollView(
                          child: Text(
                            _narrative,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.vt323(
                                fontSize: 22, color: Colors.white70),
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                if (!_hasFought)
                  _buildActionButton(
                      "FIGHT BOSS", Colors.redAccent, _startBattle)
                else
                  _buildActionButton(
                      _didWin ? "CLAIM VICTORY" : "RETREAT",
                      _didWin ? Colors.amber : Colors.grey,
                      () => Navigator.pop(context)),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: color.withAlpha((255 * 0.5).round()),
                  blurRadius: 15,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: Colors.white, width: 2)),
        child: Text(label,
            style: GoogleFonts.vt323(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- CUSTOM PAINTERS ---

class BattleBackgroundPainter extends CustomPainter {
  final Color color;
  BattleBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..color = const Color(0xFF121212);
    canvas.drawRect(rect, paint);

    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withAlpha((255 * 0.25).round()), Colors.transparent],
        radius: 1.0,
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    final linePaint = Paint()
      ..color = color.withAlpha((255 * 0.1).round())
      ..strokeWidth = 1.5;

    // Floor Grid Effect
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, size.height),
          Offset(size.width / 2, size.height / 2), linePaint);
    }

    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = color.withAlpha((255 * 0.3).round())
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HealthBarPainter extends CustomPainter {
  final double percentage;
  final Color color;

  HealthBarPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.grey.shade900;
    final fillPaint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, bgPaint);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * percentage, size.height), fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant HealthBarPainter oldDelegate) => true;
}
