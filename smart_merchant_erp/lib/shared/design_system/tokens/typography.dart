import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ), // For Buttons
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
