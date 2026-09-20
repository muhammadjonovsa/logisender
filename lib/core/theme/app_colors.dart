import 'package:flutter/material.dart';

/// Color palette for LogiSender Pro — modern dark theme with vivid accents.
abstract final class AppColors {
  // ── Base surfaces ──
  static const Color background = Color(0xFF07090F);
  static const Color surface = Color(0xFF0E1118);
  static const Color surfaceVariant = Color(0xFF151A25);
  static const Color surfaceElevated = Color(0xFF1C2230);
  static const Color card = Color(0xFF12161F);
  static const Color cardAlt = Color(0xFF181D29);
  static const Color border = Color(0xFF242B3A);
  static const Color borderSoft = Color(0xFF1C2230);

  // ── Text ──
  static const Color textPrimary = Color(0xFFF2F5FA);
  static const Color textSecondary = Color(0xFF9AA7B9);
  static const Color textTertiary = Color(0xFF647085);

  // ── Brand ──
  static const Color primary = Color(0xFF6C8CFF);
  static const Color primaryDark = Color(0xFF4A5FE0);
  static const Color accent = Color(0xFF23D3A0);
  static const Color brandViolet = Color(0xFFA78BFA);
  static const Color brandCyan = Color(0xFF38BDF8);

  // ── Status ──
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF97066);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF38BDF8);

  // ── Glassmorphism ──
  static Color glassBg = Colors.white.withValues(alpha: 0.06);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.14);

  // ── Gradients ──
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0F1C), Color(0xFF07090F)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A5FE0), Color(0xFF6C8CFF)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38BDF8), Color(0xFF6C8CFF), Color(0xFFA78BFA)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFF04438), Color(0xFFF97066)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.09),
      Colors.white.withValues(alpha: 0.02),
    ],
  );

  // ── Shadows ──
  static List<BoxShadow> softShadow(Color color, [double opacity = 0.35]) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}