import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlays a floating "+XP" / "+Gold" reward that rises and fades.
/// Wrap your screen's Stack with this and call [FloatingRewardOverlay.show].
class FloatingRewardOverlay extends StatefulWidget {
  const FloatingRewardOverlay({super.key});

  /// Call this static method to trigger the animation from anywhere.
  static void show(BuildContext context, {required int xp, required int gold}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _FloatingRewardEntry(
        xp: xp,
        gold: gold,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<FloatingRewardOverlay> createState() => _FloatingRewardOverlayState();
}

class _FloatingRewardOverlayState extends State<FloatingRewardOverlay> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _FloatingRewardEntry extends StatefulWidget {
  final int xp;
  final int gold;
  final VoidCallback onDone;

  const _FloatingRewardEntry({
    required this.xp,
    required this.gold,
    required this.onDone,
  });

  @override
  State<_FloatingRewardEntry> createState() => _FloatingRewardEntryState();
}

class _FloatingRewardEntryState extends State<_FloatingRewardEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rise;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rise = Tween(begin: 0.0, end: -120.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _fade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Position in lower-center of screen
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        left: size.width / 2 - 70,
        top: size.height * 0.6 + _rise.value,
        child: Opacity(
          opacity: _fade.value,
          child: Column(
            children: [
              _chip('+${widget.xp} XP', Colors.lightBlueAccent, Icons.star),
              const SizedBox(height: 6),
              _chip('+${widget.gold} G', Colors.amber, Icons.monetization_on),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text,
              style: GoogleFonts.vt323(
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [Shadow(color: color, blurRadius: 6)])),
        ],
      ),
    );
  }
}
