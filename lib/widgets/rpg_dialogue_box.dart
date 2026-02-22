import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/rpg_theme.dart';

/// Classic RPG dialogue box with typewriter letter-by-letter animation.
/// Drop this anywhere you want to display AI-generated text dramatically.
class RpgDialogueBox extends StatefulWidget {
  final String text;
  final String? speakerName;
  final Duration charDelay;
  final VoidCallback? onComplete;
  final Color? accentColor;

  const RpgDialogueBox({
    super.key,
    required this.text,
    this.speakerName,
    this.charDelay = const Duration(milliseconds: 30),
    this.onComplete,
    this.accentColor,
  });

  @override
  State<RpgDialogueBox> createState() => _RpgDialogueBoxState();
}

class _RpgDialogueBoxState extends State<RpgDialogueBox>
    with SingleTickerProviderStateMixin {
  String _displayed = '';
  int _charIndex = 0;
  Timer? _timer;
  bool _complete = false;

  // Blinking cursor
  late AnimationController _cursorController;
  late Animation<double> _cursorAnim;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _cursorAnim = Tween(begin: 0.0, end: 1.0).animate(_cursorController);

    _startTypewriter();
  }

  @override
  void didUpdateWidget(RpgDialogueBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      setState(() {
        _displayed = '';
        _charIndex = 0;
        _complete = false;
      });
      _startTypewriter();
    }
  }

  void _startTypewriter() {
    _timer = Timer.periodic(widget.charDelay, (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayed = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() => _complete = true);
        widget.onComplete?.call();
      }
    });
  }

  /// Tap to skip — instantly show full text
  void _skipToEnd() {
    _timer?.cancel();
    setState(() {
      _displayed = widget.text;
      _charIndex = widget.text.length;
      _complete = true;
    });
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? RpgTheme.goldPrimary;

    return GestureDetector(
      onTap: _complete ? null : _skipToEnd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1409), Color(0xFF0F0B05)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.7), width: 2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker name tag
            if (widget.speakerName != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.speakerName!.toUpperCase(),
                  style: GoogleFonts.vt323(
                    fontSize: 14,
                    color: accent,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Dialogue text with cursor
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _displayed,
                    style: GoogleFonts.vt323(
                      fontSize: 18,
                      color: RpgTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  if (!_complete)
                    WidgetSpan(
                      child: AnimatedBuilder(
                        animation: _cursorAnim,
                        builder: (_, __) => Opacity(
                          opacity: _cursorAnim.value,
                          child: Text(
                            '▋',
                            style: GoogleFonts.vt323(
                              fontSize: 18,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // "tap to skip" hint while typing
            if (!_complete) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'TAP TO SKIP ▶',
                  style: GoogleFonts.vt323(
                    fontSize: 12,
                    color: accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
