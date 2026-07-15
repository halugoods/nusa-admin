import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class NusaTheme {
  static const primaryColor = Color(0xFFE63946);
  static const primaryDark = Color(0xFFC1121F);
  static const primarySoft = Color(0xFFFDE8EA);
  static const bgColor = Color(0xFFF7F7F9);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const dividerColor = Color(0xFFE5E7EB);
  static const borderColor = Color(0xFFF3F4F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentGold = Color(0xFFF59E0B);
  static const accentOrange = Color(0xFFF97316);
  static const accentBlue = Color(0xFF3B82F6);

  // Semantic status tokens
  static const statusGenerated = accentBlue;
  static const statusTrial = accentGold;
  static const statusActive = accentGreen;
  static const statusCancelled = primaryColor;
  static const statusExpired = textTertiary;
  static const statusSuspended = accentOrange;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor: bgColor,
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceColor,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
      );
}
