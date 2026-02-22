import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rpg_theme.dart';

/// Animated glowing stat badge that pulses gently.
/// Use for STR/INT/DEX anywhere in the app.
class GlowingStatBadge extends StatefulWidget {
  final String label;
  final int value;
  final Color color;
  final bool animate;

  const GlowingStatBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.animate = true,
  });

  @override
  State<GlowingStatBadge> createState() => _GlowingStatBadgeState();
}

class _GlowingStatBadgeState extends State<GlowingStatBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: RpgTheme.backgroundCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: widget.color.withValues(alpha: 0.7), width: 1.5),
          boxShadow: widget.animate
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _glow.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label,
                style: GoogleFonts.vt323(
                    color: widget.color, fontSize: 16, letterSpacing: 1.5)),
            Text('${widget.value}',
                style: GoogleFonts.vt323(color: Colors.white, fontSize: 26)),
          ],
        ),
      ),
    );
  }
}

/// Animated counter that counts up from [from] to [to].
class AnimatedStatCounter extends StatefulWidget {
  final int from;
  final int to;
  final Color color;
  final double fontSize;

  const AnimatedStatCounter({
    super.key,
    required this.from,
    required this.to,
    required this.color,
    this.fontSize = 26,
  });

  @override
  State<AnimatedStatCounter> createState() => _AnimatedStatCounterState();
}

class _AnimatedStatCounterState extends State<AnimatedStatCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _count;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _count = IntTween(begin: widget.from, end: widget.to)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _count,
      builder: (_, __) => Text(
        '${_count.value}',
        style:
            GoogleFonts.vt323(color: widget.color, fontSize: widget.fontSize),
      ),
    );
  }
}
