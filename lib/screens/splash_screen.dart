import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rpg_theme.dart';

/// Animated RPG title splash screen shown on first app launch.
/// Automatically navigates to [nextScreen] after [duration].
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(milliseconds: 3200),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleCtrl;
  late AnimationController _starsCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _fadeOutCtrl;

  late Animation<double> _titleScale;
  late Animation<double> _titleFade;
  late Animation<double> _glowPulse;
  late Animation<double> _fadeOut;

  final List<_Star> _stars = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // Generate random stars
    for (int i = 0; i < 60; i++) {
      _stars.add(_Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2.5 + 0.5,
        opacity: _rng.nextDouble() * 0.6 + 0.2,
      ));
    }

    _titleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _titleScale = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.elasticOut));
    _titleFade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeIn));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _glowPulse = Tween(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _starsCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    _fadeOutCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(_fadeOutCtrl);

    // Sequence: wait → title in → hold → fade out → navigate
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _titleCtrl.forward();
    });

    Future.delayed(widget.duration - const Duration(milliseconds: 500), () {
      if (mounted) {
        _fadeOutCtrl.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => widget.nextScreen,
                transitionDuration: Duration.zero,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _starsCtrl.dispose();
    _glowCtrl.dispose();
    _fadeOutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeOut,
      builder: (_, __) => Opacity(
        opacity: _fadeOut.value,
        child: Scaffold(
          backgroundColor: RpgTheme.backgroundDark,
          body: Stack(
            children: [
              // Starfield background
              AnimatedBuilder(
                animation: _starsCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _StarfieldPainter(
                      stars: _stars, twinkle: _starsCtrl.value),
                  size: Size.infinite,
                ),
              ),

              // Central content
              Center(
                child: AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _titleFade,
                    child: ScaleTransition(
                      scale: _titleScale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon with glow
                          AnimatedBuilder(
                            animation: _glowPulse,
                            builder: (_, __) => Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: RpgTheme.goldPrimary.withValues(
                                        alpha: _glowPulse.value * 0.6),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 80,
                                color: RpgTheme.goldPrimary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // LIFE QUEST title
                          AnimatedBuilder(
                            animation: _glowPulse,
                            builder: (_, __) => Text(
                              'LIFE QUEST',
                              style: GoogleFonts.vt323(
                                fontSize: 56,
                                color: RpgTheme.goldPrimary,
                                shadows: [
                                  Shadow(
                                    color: RpgTheme.goldPrimary
                                        .withValues(alpha: _glowPulse.value),
                                    blurRadius: 20,
                                  ),
                                ],
                                letterSpacing: 4,
                              ),
                            ),
                          ),

                          Text(
                            'R P G',
                            style: GoogleFonts.vt323(
                              fontSize: 32,
                              color: RpgTheme.textPrimary,
                              letterSpacing: 16,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Decorative divider
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  width: 60,
                                  height: 1,
                                  color: RpgTheme.goldPrimary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 12),
                              const Icon(Icons.shield,
                                  color: RpgTheme.goldPrimary, size: 16),
                              const SizedBox(width: 12),
                              Container(
                                  width: 60,
                                  height: 1,
                                  color: RpgTheme.goldPrimary
                                      .withValues(alpha: 0.5)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Tagline
                          Text(
                            'YOUR LIFE. YOUR QUEST.',
                            style: GoogleFonts.vt323(
                              fontSize: 18,
                              color: RpgTheme.textMuted,
                              letterSpacing: 3,
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Blinking "loading" text
                          _BlinkingText('LOADING...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlinkingText extends StatefulWidget {
  final String text;
  const _BlinkingText(this.text);

  @override
  State<_BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<_BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value,
        child: Text(
          widget.text,
          style: GoogleFonts.vt323(
              fontSize: 16, color: RpgTheme.textMuted, letterSpacing: 4),
        ),
      ),
    );
  }
}

class _Star {
  final double x, y, size, opacity;
  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double twinkle;
  _StarfieldPainter({required this.stars, required this.twinkle});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = (s.opacity + twinkle * 0.3).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.twinkle != twinkle;
}
