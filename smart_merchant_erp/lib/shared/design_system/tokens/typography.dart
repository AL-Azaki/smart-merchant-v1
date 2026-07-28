import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        textStyle: const TextStyle(fontFamilyFallback: ['sans-serif']),
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        textStyle: const TextStyle(fontFamilyFallback: ['sans-serif']),
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        textStyle: const TextStyle(fontFamilyFallback: ['sans-serif']),
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        textStyle: const TextStyle(fontFamilyFallback: ['sans-serif']),
      ),
      titleLarge: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600, textStyle: const TextStyle(fontFamilyFallback: ['sans-serif'])),
      titleMedium: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600, textStyle: const TextStyle(fontFamilyFallback: ['sans-serif'])),
      bodyLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, textStyle: const TextStyle(fontFamilyFallback: ['sans-serif'])),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, textStyle: const TextStyle(fontFamilyFallback: ['sans-serif'])),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        textStyle: const TextStyle(fontFamilyFallback: ['sans-serif']),
      ), // For Buttons
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        textStyle: const TextStyle(fontFamilyFallback: ['sans-serif']),
      ),
    );
  }
}
