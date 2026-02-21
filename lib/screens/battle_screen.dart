import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import 'dart:math';

class BattleScreen extends StatefulWidget {
  final Map<String, dynamic> zone;
  final int userLvl;
  final String userClass;
  // IMPROVEMENT: Accept player stats so combat uses them
  final int userStr;
  final int userInt;
  final int userDex;

  const BattleScreen({
    super.key,
    required this.zone,
    required this.userLvl,
    required this.userClass,
    this.userStr = 5,
    this.userInt = 5,
    this.userDex = 5,
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
  bool _didWin = false;
  bool _isLoading = true;
  // IMPROVEMENT: Track whether spoils were actually saved
  bool _spoilsSaved = false;
  String _narrative = "The enemy draws near...";
  // IMPROVEMENT: Track battle turns for mid-battle taunt trigger
  int _turnCount = 0;
  bool _midBattleTauntShown = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _bossPulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

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

    _fadeController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
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
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // FIX #4: bossLevel uses null-safe fallback `?? 1`
  int get _bossLevel => widget.zone['reqLvl'] as int? ?? 1;

  Future<void> _initializeBattle() async {
    _maxHeroHp = 50 + (widget.userLvl * 10);
    _currentHeroHp = _maxHeroHp;

    _maxBossHp = 80 + (_bossLevel * 15);
    _currentBossHp = _maxBossHp;

    final taunt = await _ai.generateBattleNarration(
      heroClass: widget.userClass,
      heroLevel: widget.userLvl,
      bossName: widget.zone['boss'] as String? ?? 'Boss',
      bossLevel: _bossLevel,
      didWin: true,
      intensity: "Beginning",
    );

    if (mounted) {
      setState(() {
        _log("BOSS: $taunt");
        _log("Battle Start! Your turn.");
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
      // IMPROVEMENT: STR now affects attack damage
      dmg = (10 + widget.userLvl * 2 + widget.userStr) + Random().nextInt(5);
      logMsg = "You attacked for $dmg damage!";
    } else if (action == "HEAL") {
      // IMPROVEMENT: INT now affects heal power
      int heal = (15 + widget.userLvl * 2 + widget.userInt);
      setState(() {
        _currentHeroHp = (_currentHeroHp + heal).clamp(0, _maxHeroHp);
      });
      logMsg = "You healed for $heal HP!";
    } else if (action == "ULTIMATE") {
      // IMPROVEMENT: DEX affects crit chance
      double critChance =
          0.4 + (widget.userDex * 0.02); // base 40% + 2% per DEX
      if (Random().nextDouble() < critChance) {
        dmg = (25 + widget.userLvl * 3 + widget.userStr * 2);
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

    // IMPROVEMENT: Mid-battle taunt when boss drops below 50% HP
    _checkMidBattleTaunt();

    _turnCount++;

    if (_currentBossHp <= 0) {
      _endBattle(true);
    } else {
      Future.delayed(const Duration(milliseconds: 1500), _bossTurn);
    }
  }

  void _checkMidBattleTaunt() {
    if (!_midBattleTauntShown &&
        _currentBossHp < _maxBossHp * 0.5 &&
        !_battleOver) {
      _midBattleTauntShown = true;
      _ai
          .generateBattleNarration(
        heroClass: widget.userClass,
        heroLevel: widget.userLvl,
        bossName: widget.zone['boss'] as String? ?? 'Boss',
        bossLevel: _bossLevel,
        didWin: false,
        intensity: "MidBattle",
      )
          .then((taunt) {
        if (mounted) _log("BOSS: $taunt");
      });
    }
  }

  void _bossTurn() {
    if (_battleOver) return;

    int dmg = (8 + _bossLevel * 2) + Random().nextInt(5);

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
      _didWin = won;
    });

    final resultText = await _ai.generateBattleNarration(
      heroClass: widget.userClass,
      heroLevel: widget.userLvl,
      bossName: widget.zone['boss'] as String? ?? 'Boss',
      bossLevel: _bossLevel, // FIX #4: uses null-safe getter
      didWin: won,
      intensity: won ? "Victorious" : "Crushing",
    );

    _log(resultText);

    if (won) {
      // FIX #3: Only show spoils if defeatBoss actually succeeded
      final saved = await _db.defeatBoss(widget.zone['id'] as int? ?? 0);
      if (mounted) {
        setState(() => _spoilsSaved = saved);
        _fadeController.forward();
        _confettiController.play();
      }
    }
  }

  void _log(String msg) {
    if (!mounted) return;
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
    Color zoneColor = widget.zone['color'] as Color? ?? Colors.red;

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
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "> ${_battleLog[index]}",
                                      style: GoogleFonts.vt323(
                                          color: Colors.white70, fontSize: 18),
                                    ),
                                  );
                                },
                              ),
                      ),
                      Expanded(flex: 3, child: _buildPlayerControls()),
                    ],
                  ),
                ),
                if (_didWin) _buildVictoryOverlay(),
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
                      Colors.purple,
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

  Widget _buildBossDisplay(Color zoneColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            (widget.zone['boss'] as String? ?? 'BOSS').toUpperCase(),
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

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("HERO HP",
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 18)),
              Text("$_currentHeroHp / $_maxHeroHp",
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 5),
          _buildHealthBar(_currentHeroHp, _maxHeroHp, Colors.green),
          const SizedBox(height: 20),
          if (!_battleOver)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton("ATTACK", Colors.redAccent, "ATTACK",
                    hint: "STR +${widget.userStr}"),
                _buildActionButton("HEAL", Colors.greenAccent, "HEAL",
                    hint: "INT +${widget.userInt}"),
                _buildActionButton("ULTI", Colors.purpleAccent, "ULTIMATE",
                    hint: "DEX ${(40 + widget.userDex * 2)}%"),
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
            ),
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

  Widget _buildActionButton(String label, Color color, String actionType,
      {String hint = ''}) {
    bool disabled = !_isPlayerTurn || _battleOver;
    return GestureDetector(
      onTap: disabled ? null : () => _playerAction(actionType),
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          width: 90,
          height: 65,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: GoogleFonts.vt323(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              // IMPROVEMENT: Show stat influence hint on each button
              if (hint.isNotEmpty)
                Text(hint,
                    style:
                        GoogleFonts.vt323(fontSize: 13, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

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
                    _narrative,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                        fontSize: 20, color: Colors.white, height: 1.4),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "SPOILS",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(fontSize: 28, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                // FIX #3: Show spoils only if actually saved, otherwise show error
                _spoilsSaved
                    ? _buildSpoils()
                    : Center(
                        child: Text(
                          "Could not save rewards. Check connection.",
                          style: GoogleFonts.vt323(
                              fontSize: 18, color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
        Text(text, style: GoogleFonts.vt323(fontSize: 22, color: Colors.white)),
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
