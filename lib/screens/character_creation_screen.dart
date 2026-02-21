import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../theme/rpg_theme.dart';
import 'profile_screen.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen>
    with TickerProviderStateMixin {
  final _bioController = TextEditingController();
  final _mainQuestController = TextEditingController();
  final _ai = AiService();
  final _db = DatabaseService();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  late AnimationController _starsCtrl;

  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _glowCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _glow = Tween(begin: 0.3, end: 1.0).animate(_glowCtrl);

    _starsCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    // Spawn background particles
    final rng = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(seed: rng + i));
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _mainQuestController.dispose();
    _glowCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  void _awakenHero() async {
    if (_bioController.text.trim().isEmpty ||
        _mainQuestController.text.trim().isEmpty) {
      setState(
          () => _errorMessage = 'Fill in both fields to awaken your hero!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _ai.generateCharacter(
          _bioController.text, _mainQuestController.text);
      result['mainQuest'] = _mainQuestController.text;
      result['bio'] = _bioController.text;
      await _db.initializeUser(result);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'The Fate Weaver is unreachable. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RpgTheme.backgroundDark,
      body: Stack(
        children: [
          // Animated particle background
          AnimatedBuilder(
            animation: _starsCtrl,
            builder: (_, __) => CustomPaint(
              painter:
                  _ParticlePainter(particles: _particles, t: _starsCtrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Title icon with glow
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: RpgTheme.goldPrimary
                                .withOpacity(_glow.value * 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome,
                          size: 72, color: RpgTheme.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('FATE WEAVER',
                      style: GoogleFonts.vt323(
                          fontSize: 14,
                          color: RpgTheme.textMuted,
                          letterSpacing: 6)),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (_, __) => Text(
                      'WHO ARE YOU?',
                      style: GoogleFonts.vt323(
                        fontSize: 42,
                        color: RpgTheme.goldPrimary,
                        shadows: [
                          Shadow(
                            blurRadius: 16,
                            color:
                                RpgTheme.goldPrimary.withOpacity(_glow.value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell the Fate Weaver about your life,\nyour strengths, and your passions...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                        fontSize: 18, color: RpgTheme.textMuted),
                  ),

                  const SizedBox(height: 28),
                  _buildSectionDivider('YOUR STORY'),
                  const SizedBox(height: 12),

                  // Bio field
                  _buildTextField(
                    controller: _bioController,
                    hint:
                        'e.g., I am a Computer Science student. I love lifting weights, drinking coffee, and solving puzzles.',
                    maxLines: 5,
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionDivider('YOUR MAIN QUEST'),
                  const SizedBox(height: 4),
                  Text(
                    'What is the primary goal you wish to achieve?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vt323(
                        fontSize: 17, color: RpgTheme.textMuted),
                  ),
                  const SizedBox(height: 12),

                  // Main quest field
                  _buildTextField(
                    controller: _mainQuestController,
                    hint: 'e.g., Get in shape and run a 5K',
                    maxLines: 2,
                    enabled: !_isLoading,
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: RpgTheme.cardDecoration(
                          borderColor: Colors.redAccent),
                      child: Row(children: [
                        const Icon(Icons.warning_amber,
                            color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: GoogleFonts.vt323(
                                  fontSize: 17,
                                  color: Colors.redAccent,
                                  height: 1.3)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Loading or button
                  _isLoading
                      ? Column(children: [
                          const CircularProgressIndicator(
                              color: RpgTheme.goldPrimary),
                          const SizedBox(height: 16),
                          Text('Weaving your destiny...',
                              style: GoogleFonts.vt323(
                                  fontSize: 22, color: RpgTheme.goldPrimary)),
                          const SizedBox(height: 4),
                          Text('The Fate Weaver judges your soul...',
                              style: GoogleFonts.vt323(
                                  fontSize: 16, color: RpgTheme.textMuted)),
                        ])
                      : GestureDetector(
                          onTap: _awakenHero,
                          child: AnimatedBuilder(
                            animation: _glow,
                            builder: (_, __) => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    RpgTheme.goldPrimary,
                                    Color(0xFFE8A838)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: RpgTheme.goldPrimary
                                        .withOpacity(_glow.value * 0.6),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text('AWAKEN',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.vt323(
                                      fontSize: 28,
                                      color: Colors.black,
                                      letterSpacing: 3)),
                            ),
                          ),
                        ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String text) {
    return Row(children: [
      Expanded(
          child: Container(
              height: 1, color: RpgTheme.goldPrimary.withOpacity(0.3))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text,
            style: GoogleFonts.vt323(
                fontSize: 14, color: RpgTheme.goldPrimary, letterSpacing: 3)),
      ),
      Expanded(
          child: Container(
              height: 1, color: RpgTheme.goldPrimary.withOpacity(0.3))),
    ]);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      style: GoogleFonts.vt323(
          color: RpgTheme.textPrimary, fontSize: 17, height: 1.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: RpgTheme.backgroundCard,
        hintText: hint,
        hintStyle: GoogleFonts.vt323(
            color: RpgTheme.textMuted, fontSize: 15, height: 1.4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: RpgTheme.goldPrimary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: RpgTheme.goldPrimary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: RpgTheme.textMuted.withOpacity(0.2)),
        ),
      ),
    );
  }
}

class _Particle {
  final double x, y, size, speed;
  _Particle({required int seed})
      : x = (seed % 1000) / 1000.0,
        y = ((seed * 7) % 1000) / 1000.0,
        size = ((seed * 3) % 20) / 10.0 + 0.5,
        speed = ((seed * 11) % 100) / 200.0 + 0.2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (0.15 + t * p.speed * 0.3).clamp(0.05, 0.4);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        Paint()..color = RpgTheme.goldPrimary.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
