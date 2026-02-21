import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../theme/rpg_theme.dart';
import '../widgets/boss_painter.dart';
import '../widgets/battle_backgrounds.dart';
import '../widgets/rpg_dialogue_box.dart';

class BattleScreen extends StatefulWidget {
  final Map<String, dynamic> zone;
  final int userLvl;
  final String userClass;
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

  late int _maxHeroHp;
  late int _currentHeroHp;
  late int _maxBossHp;
  late int _currentBossHp;

  bool _isPlayerTurn = true;
  bool _battleOver = false;
  bool _didWin = false;
  bool _isLoading = true;
  bool _spoilsSaved = false;
  String _narrative = '';
  int _turnCount = 0;
  bool _midBattleTauntShown = false;

  // Attack flash animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _bossPulseController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  // Boss HP flash on hit
  late AnimationController _bossHitController;
  late Animation<double> _bossHitAnim;

  // Hero HP flash on hit
  late AnimationController _heroHitController;
  late Animation<double> _heroHitAnim;

  // Attack lunge animation
  late AnimationController _attackController;
  late Animation<double> _attackAnim;

  @override
  void initState() {
    super.initState();

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

    // Boss flash red on hit
    _bossHitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _bossHitAnim = Tween(begin: 0.0, end: 1.0).animate(_bossHitController);

    // Hero flash on damage received
    _heroHitController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _heroHitAnim = Tween(begin: 0.0, end: 1.0).animate(_heroHitController);

    // Attack lunge
    _attackController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _attackAnim = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _attackController, curve: Curves.easeOut));

    _initializeBattle();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _bossPulseController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    _bossHitController.dispose();
    _heroHitController.dispose();
    _attackController.dispose();
    super.dispose();
  }

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
        _narrative = taunt;
        _isLoading = false;
      });
    }
  }

  void _playerAction(String action) {
    if (!_isPlayerTurn || _battleOver) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPlayerTurn = false);

    int dmg = 0;
    String logMsg = '';

    if (action == 'ATTACK') {
      dmg = (10 + widget.userLvl * 2 + widget.userStr) + Random().nextInt(5);
      logMsg = 'You strike for $dmg damage!';
      // Lunge animation then boss flash
      _attackController.forward(from: 0).then((_) {
        _attackController.reverse();
        if (dmg > 0) {
          _bossHitController
              .forward(from: 0)
              .then((_) => _bossHitController.reverse());
        }
      });
    } else if (action == 'HEAL') {
      HapticFeedback.lightImpact();
      int heal = (15 + widget.userLvl * 2 + widget.userInt);
      setState(() {
        _currentHeroHp = (_currentHeroHp + heal).clamp(0, _maxHeroHp);
      });
      logMsg = 'You channel energy and heal $heal HP!';
    } else if (action == 'ULTIMATE') {
      double critChance = 0.4 + (widget.userDex * 0.02);
      if (Random().nextDouble() < critChance) {
        dmg = (25 + widget.userLvl * 3 + widget.userStr * 2);
        logMsg = '⚡ CRITICAL! Ultimate deals $dmg damage!';
        HapticFeedback.heavyImpact();
        _bossHitController
            .forward(from: 0)
            .then((_) => _bossHitController.reverse());
      } else {
        logMsg = 'Your Ultimate missed!';
      }
    }

    if (dmg > 0) {
      setState(() {
        _currentBossHp = (_currentBossHp - dmg).clamp(0, _maxBossHp);
      });
    }

    setState(() => _narrative = logMsg);

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
        intensity: 'MidBattle',
      )
          .then((taunt) {
        if (mounted) setState(() => _narrative = taunt);
      });
    }
  }

  void _bossTurn() {
    if (_battleOver) return;
    int dmg = (8 + _bossLevel * 2) + Random().nextInt(5);

    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0);
    _heroHitController
        .forward(from: 0)
        .then((_) => _heroHitController.reverse());

    setState(() {
      _currentHeroHp = (_currentHeroHp - dmg).clamp(0, _maxHeroHp);
      _narrative = '${widget.zone['boss']} attacks for $dmg damage!';
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
      bossLevel: _bossLevel,
      didWin: won,
      intensity: won ? 'Victorious' : 'Crushing',
    );

    setState(() => _narrative = resultText);

    if (won) {
      final saved = await _db.defeatBoss(widget.zone['id'] as int? ?? 0);
      if (mounted) {
        setState(() => _spoilsSaved = saved);
        _fadeController.forward();
        _confettiController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color zoneColor = widget.zone['color'] as Color? ?? Colors.red;
    final String bossName = widget.zone['boss'] as String? ?? 'Boss';
    final String zoneName = widget.zone['name'] as String? ?? '';

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
                // IMPROVEMENT #7: Zone-specific painted background
                CustomPaint(
                  painter: getBattleBackground(zoneName),
                  size: Size.infinite,
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                          flex: 5, child: _buildBossArea(zoneColor, bossName)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _isLoading
                            ? Container(
                                height: 90,
                                decoration: RpgTheme.parchmentDecoration(),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      color: RpgTheme.goldPrimary),
                                ),
                              )
                            // IMPROVEMENT #5: Typewriter dialogue box
                            : RpgDialogueBox(
                                text: _narrative,
                                speakerName: _isPlayerTurn || _narrative.isEmpty
                                    ? null
                                    : bossName,
                                accentColor: zoneColor,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(flex: 3, child: _buildPlayerControls(zoneColor)),
                    ],
                  ),
                ),
                if (_didWin) _buildVictoryOverlay(bossName),
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

  Widget _buildBossArea(Color zoneColor, String bossName) {
    return Stack(
      children: [
        // IMPROVEMENT #6: Hero avatar bottom-left
        Positioned(
          bottom: 16,
          left: 16,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black45,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    'https://api.dicebear.com/9.x/pixel-art/png?seed=${widget.userClass}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('YOU',
                  style:
                      GoogleFonts.vt323(fontSize: 14, color: Colors.white70)),
            ],
          ),
        ),
        // Boss display center
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bossName.toUpperCase(),
                style: GoogleFonts.vt323(
                  fontSize: 28,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 12, color: zoneColor)],
                ),
              ),
              const SizedBox(height: 8),
              _buildHealthBar(_currentBossHp, _maxBossHp, Colors.red),
              const SizedBox(height: 20),
              // IMPROVEMENT #3: Attack flash on boss
              AnimatedBuilder(
                animation: _bossHitAnim,
                builder: (_, child) => ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.red.withOpacity(_bossHitAnim.value * 0.6),
                    BlendMode.srcATop,
                  ),
                  child: child,
                ),
                child: ScaleTransition(
                  scale: _bossPulseController,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: zoneColor.withOpacity(0.5),
                          blurRadius: 35,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    // IMPROVEMENT #2: Unique pixel boss art
                    child: buildBossArt(bossName, zoneColor, size: 130),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerControls(Color zoneColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Hero HP bar with flash
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HERO HP',
                  style: GoogleFonts.vt323(
                      color: RpgTheme.textPrimary, fontSize: 16)),
              Text('$_currentHeroHp / $_maxHeroHp',
                  style: GoogleFonts.vt323(
                      color: RpgTheme.textMuted, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          // IMPROVEMENT #3: Hero HP bar flashes on damage
          AnimatedBuilder(
            animation: _heroHitAnim,
            builder: (_, __) => Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                boxShadow: _heroHitAnim.value > 0
                    ? [
                        BoxShadow(
                          color:
                              Colors.red.withOpacity(_heroHitAnim.value * 0.8),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: _buildHealthBar(_currentHeroHp, _maxHeroHp, Colors.green),
            ),
          ),
          const SizedBox(height: 16),
          if (!_battleOver)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // IMPROVEMENT #3: Attack button lunges forward
                AnimatedBuilder(
                  animation: _attackAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_attackAnim.value * 12, 0),
                    child: child,
                  ),
                  child: _buildActionButton(
                      'ATTACK', Colors.redAccent, 'ATTACK',
                      hint: 'STR +${widget.userStr}'),
                ),
                _buildActionButton('HEAL', Colors.greenAccent, 'HEAL',
                    hint: 'INT +${widget.userInt}'),
                _buildActionButton('ULTI', Colors.purpleAccent, 'ULTIMATE',
                    hint: 'DEX ${(40 + widget.userDex * 2)}%'),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RpgTheme.goldPrimary,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('RETURN TO MAP',
                    style:
                        GoogleFonts.vt323(fontSize: 24, color: Colors.black)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(int current, int max, Color color) {
    double pct = (current / max).clamp(0.0, 1.0);
    // Color shifts to red as HP drops
    final barColor = pct > 0.5
        ? color
        : pct > 0.25
            ? Colors.orange
            : Colors.red;

    return Container(
      height: 12,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 300),
        widthFactor: pct,
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(color: barColor.withOpacity(0.5), blurRadius: 6),
            ],
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
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 92,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white54, width: 1.5),
            boxShadow: disabled
                ? []
                : [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: GoogleFonts.vt323(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
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

  Widget _buildVictoryOverlay(String bossName) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'VICTORY!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(
                    fontSize: 64,
                    color: RpgTheme.goldPrimary,
                    shadows: [
                      const Shadow(blurRadius: 24, color: RpgTheme.goldPrimary)
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Typewriter narration on victory
                RpgDialogueBox(
                  text: _narrative,
                  speakerName: 'NARRATOR',
                  accentColor: RpgTheme.goldPrimary,
                ),
                const SizedBox(height: 24),
                Text('SPOILS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                        fontSize: 26, color: RpgTheme.textMuted)),
                const SizedBox(height: 10),
                _spoilsSaved
                    ? _buildSpoils()
                    : Center(
                        child: Text(
                          'Could not save rewards. Check connection.',
                          style: GoogleFonts.vt323(
                              fontSize: 18, color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpgTheme.goldPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('RETURN TO MAP',
                      style:
                          GoogleFonts.vt323(fontSize: 24, color: Colors.black)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: RpgTheme.cardDecoration(borderColor: RpgTheme.goldPrimary),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _spoilItem(Icons.star, '+200 XP', Colors.lightBlueAccent),
          _spoilItem(Icons.monetization_on, '+100 G', Colors.amber),
        ],
      ),
    );
  }

  Widget _spoilItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.vt323(
                fontSize: 22,
                color: Colors.white,
                shadows: [Shadow(color: color, blurRadius: 8)])),
      ],
    );
  }
}
