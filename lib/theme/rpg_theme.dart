import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central RPG color palette and text styles used across all screens.
/// Import this file wherever you need consistent RPG styling.
class RpgTheme {
  // --- Color Palette ---
  static const Color backgroundDark = Color(0xFF0D1B2A); // deep navy
  static const Color backgroundMid = Color(0xFF1B2838); // slightly lighter navy
  static const Color backgroundCard = Color(0xFF1C1409); // warm dark parchment
  static const Color goldPrimary = Color(0xFFC9A84C); // aged gold
  static const Color goldLight = Color(0xFFFFD700); // bright gold
  static const Color bloodRed = Color(0xFF8B1A1A); // danger red
  static const Color forestGreen = Color(0xFF2D6A4F); // nature green
  static const Color arcaneBlue = Color(0xFF1A3A5C); // magic blue
  static const Color parchment = Color(0xFFD4A373); // scroll tan
  static const Color textPrimary = Color(0xFFE8D5B7); // warm white
  static const Color textMuted = Color(0xFF8A7560); // muted parchment

  // Stat colors
  static const Color strColor = Color(0xFFE57373); // red
  static const Color intColor = Color(0xFF64B5F6); // blue
  static const Color dexColor = Color(0xFF81C784); // green

  // --- Text Styles ---
  static TextStyle title({double size = 40, Color color = goldPrimary}) =>
      GoogleFonts.vt323(fontSize: size, color: color, letterSpacing: 1.2);

  static TextStyle body({double size = 18, Color color = textPrimary}) =>
      GoogleFonts.vt323(fontSize: size, color: color, height: 1.4);

  static TextStyle label({double size = 14, Color color = textMuted}) =>
      GoogleFonts.vt323(fontSize: size, color: color);

  // --- Decorations ---
  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? goldPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? goldPrimary).withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      );

  static BoxDecoration parchmentDecoration() => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1409), Color(0xFF0F0B05)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldPrimary.withValues(alpha: 0.4), width: 1),
      );

  static BoxDecoration glowDecoration(Color glowColor) => BoxDecoration(
        color: backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: glowColor.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      );
}
