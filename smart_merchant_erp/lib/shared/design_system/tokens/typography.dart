import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), // For Buttons
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    );
  }
}
