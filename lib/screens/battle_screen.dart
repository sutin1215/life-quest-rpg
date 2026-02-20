import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart'; // <--- NEW
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
    with TickerProviderStateMixin {
  final AiService _ai = AiService();
  final DatabaseService _db = DatabaseService();

  // Battle State
  late int _maxHeroHp;
  late int _currentHeroHp;
  late int _maxBossHp;
  late int _currentBossHp;

  bool _isPlayerTurn = true;
  bool _battleOver = false;
  bool _didWin = false; // <--- NEW: Tracks if the player won
  bool _isLoading = true;
  String _narrative = "The enemy draws near...";

  // "Juice" Controls
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _bossPulseController;
  late AnimationController _fadeController; // <--- NEW: For victory screen
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController; // <--- NEW

  final List<String> _battleLog = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeBattle();

    _shakeController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _shakeAnimation =
        Tween<double>(begin: 0, end: 1.0).animate(_shakeController);

    _bossPulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
        lowerBound: 0.95,
        upperBound: 1.05)
      ..repeat(reverse: true);

    _fadeController = AnimationController(
        duration: const Duration(seconds: 1), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _bossPulseController.dispose();
    _fadeController.dispose();
    _confettiController.dispose(); // <--- NEW
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeBattle() async {
    _maxHeroHp = 50 + (widget.userLvl * 10);
    _currentHeroHp = _maxHeroHp;

    // Fix: Zone level is inside the map, not the map itself
    int bossLvl = widget.zone['reqLvl'] ?? 1;
    _maxBossHp = 80 + (bossLvl * 15);
    _currentBossHp = _maxBossHp;

    // Fixed AI call to match your actual Service method
    final taunt = await _ai.generateBattleNarration(
      heroClass: widget.userClass,
      heroLevel: widget.userLvl,
      bossName: widget.zone['boss'],
      bossLevel: bossLvl,
      didWin: true, // Placeholder for start
      intensity: "Beginning",
    );

    if (mounted) {
      setState(() {
        _log("BOSS: $taunt");
        _log("Battle Start! Player turn.");
        _isLoading = false;
      });
    }
  }

  void _playerAction(String action) {
    if (!_isPlayerTurn || _battleOver) return;

    setState(() => _isPlayerTurn = false);

    int dmg = 0;
    String logMsg = "";

    if (action == "ATTACK") {
      dmg = (10 + widget.userLvl * 2) + Random().nextInt(5);
      logMsg = "You attacked for $dmg damage!";
    } else if (action == "HEAL") {
      int heal = (15 + widget.userLvl * 2);
      setState(() {
        _currentHeroHp = (_currentHeroHp + heal).clamp(0, _maxHeroHp);
      });
      logMsg = "You healed for $heal HP!";
    } else if (action == "ULTIMATE") {
      if (Random().nextBool()) {
        dmg = (25 + widget.userLvl * 3);
        logMsg = "CRITICAL HIT! Ultimate deals $dmg damage!";
      } else {
        logMsg = "You missed your Ultimate!";
      }
    }

    if (dmg > 0) {
      setState(() {
        _currentBossHp = (_currentBossHp - dmg).clamp(0, _maxBossHp);
      });
    }
    _log(logMsg);

    if (_currentBossHp <= 0) {
      _endBattle(true);
    } else {
      Future.delayed(const Duration(milliseconds: 1500), _bossTurn);
    }
  }

  void _bossTurn() {
    if (_battleOver) return;

    int bossLevel = widget.zone['reqLvl'] ?? 1;
    int dmg = (8 + bossLevel * 2) + Random().nextInt(5);

    setState(() {
      _currentHeroHp = (_currentHeroHp - dmg).clamp(0, _maxHeroHp);
      _log("${widget.zone['boss']} attacks for $dmg damage!");
      _shakeController.forward(from: 0);
    });

    if (_currentHeroHp <= 0) {
      _endBattle(false);
    } else {
      setState(() => _isPlayerTurn = true);
    }
  }

  Future<void> _endBattle(bool won) async {
    setState(() {
      _battleOver = true;
      _didWin = won; // Set the win status
    });

    final resultText = await _ai.generateBattleNarration(
      heroClass: widget.userClass,
      heroLevel: widget.userLvl,
      bossName: widget.zone['boss'],
      bossLevel: widget.zone['reqLvl'],
      didWin: won,
      intensity: won ? "Victorious" : "Crushing",
    );

    _log(resultText);

    if (won) {
      await _db.defeatBoss(widget.zone['id']);
      _fadeController.forward(); // Trigger the victory screen animation
      _confettiController.play(); // <--- NEW: Play confetti
    }
  }

  void _log(String msg) {
    setState(() {
      _battleLog.add(msg);
      _narrative = msg;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color zoneColor = widget.zone['color'] ?? Colors.red;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        double dx = sin(_shakeAnimation.value * pi * 10) * 8;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Scaffold(
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
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(flex: 4, child: _buildBossDisplay(zoneColor)),
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.amber))
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: _battleLog.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "> ${_battleLog[index]}",
                                      style: GoogleFonts.vt323(
                                          color: Colors.white70,
                                          fontSize: 18),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Expanded(flex: 3, child: _buildPlayerControls()),
                    ],
                  ),
                ),
                if (_didWin) _buildVictoryOverlay(), // <--- NEW

                // --- Confetti for Victory ---
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // <--- NEW: Boss Display Area
  Widget _buildBossDisplay(Color zoneColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.zone['boss'].toString().toUpperCase(),
            style: GoogleFonts.vt323(
              fontSize: 32,
              color: Colors.white,
              shadows: [const Shadow(blurRadius: 10, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 10),
          _buildHealthBar(_currentBossHp, _maxBossHp, Colors.red),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _bossPulseController,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: zoneColor,
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  Icon(Icons.adb, size: 80, color: zoneColor.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  // <--- NEW: Player Controls Area
  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "HERO HP",
                style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
              ),
              Text(
                "$_currentHeroHp / $_maxHeroHp",
                style: GoogleFonts.vt323(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _buildHealthBar(_currentHeroHp, _maxHeroHp, Colors.green),
          const SizedBox(height: 20),
          if (!_battleOver)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton("ATTACK", Colors.redAccent, "ATTACK"),
                _buildActionButton("HEAL", Colors.greenAccent, "HEAL"),
                _buildActionButton("ULTI", Colors.purpleAccent, "ULTIMATE"),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "RETURN TO MAP",
                  style: GoogleFonts.vt323(fontSize: 24, color: Colors.black),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildHealthBar(int current, int max, Color color) {
    double percentage = (current / max).clamp(0.0, 1.0);
    return Container(
      height: 15,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white30),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 300),
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, String actionType) {
    bool disabled = !_isPlayerTurn || _battleOver;
    return GestureDetector(
      onTap: disabled ? null : () => _playerAction(actionType),
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: 90,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.vt323(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
  // <--- NEW: Victory Screen Overlay
  Widget _buildVictoryOverlay() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "VICTORY!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: 60,
                    color: Colors.amber,
                    shadows: [
                      const Shadow(blurRadius: 20, color: Colors.amber)
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    _narrative, // Show the final AI story
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                      fontSize: 20,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "SPOILS",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(fontSize: 28, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                _buildSpoils(),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "RETURN TO MAP",
                    style: GoogleFonts.vt323(fontSize: 24, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpoils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _spoilItem(Icons.star, "+200 XP", Colors.lightBlueAccent),
          _spoilItem(Icons.monetization_on, "+100 G", Colors.yellow),
        ],
      ),
    );
  }

  Widget _spoilItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.vt323(fontSize: 22, color: Colors.white),
        ),
      ],
    );
  }
}

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
        colors: [color.withOpacity(0.3), Colors.transparent],
        radius: 1.0,
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);

    final linePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, size.height),
          Offset(size.width / 2, size.height * 0.4), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
