import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette Raffinée : Rouge bordeaux avec états interactifs
  static const Color primaryColor = Color(0xFF860505); // Rouge bordeaux #860505
  static const Color primaryHover = Color(0xFFA60606); // Hover/Focus
  static const Color primaryActive = Color(0xFF5D0404); // Active/Pressed
  
  // Couleurs de compatibilité (mappées sur la nouvelle palette)
  static const Color secondaryColor = Color(0xFF6C757D); // Text secondary
  static const Color tertiaryColor = Color(0xFF5C0404); // Primary active
  
  // Couleurs neutres modernes
  static const Color backgroundColor = Color(0xFFF8F9FA); // Background
  static const Color surfaceColor = Color(0xFFE9ECEF); // Surface
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);
  static const Color warningColor = Color(0xFFD69E2E);
  
  // Couleurs de texte adaptées à la palette
  static const Color textPrimaryColor = Color(0xFF212529); // Texte principal
  static const Color textSecondaryColor = Color(0xFF6C757D); // Text secondary
  static const Color textTertiaryColor = Color(0xFF6C757D); // Text tertiary

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Schéma de couleurs
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: primaryHover,
        tertiary: primaryActive,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      
      // Police
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          displaySmall: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
          titleSmall: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondaryColor,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
          labelMedium: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondaryColor,
          ),
        ),
      ),
      
      // App Bar
      appBarTheme: AppBarTheme(
        toolbarHeight: 44, // Hauteur encore plus réduite
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: primaryColor, // Rouge bordeaux #860505
        foregroundColor: Colors.white, // Texte blanc sur fond rouge
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white, // Titre en blanc
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Icônes en blanc
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Rouge bordeaux
          foregroundColor: Colors.white, // Blanc pur
          elevation: 2,
          shadowColor: primaryActive.withOpacity(0.3), // Ombre active
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.pressed)) return primaryActive;
            if (states.contains(MaterialState.hovered)) return primaryHover;
            return primaryColor;
          }),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor, // Rouge bordeaux
          side: BorderSide(color: textSecondaryColor, width: 1.5), // Bordure text secondary
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered)) return primaryHover.withOpacity(0.1);
            if (states.contains(MaterialState.pressed)) return primaryActive.withOpacity(0.1);
            return null;
          }),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor, // Background F8F9FA
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: surfaceColor), // Surface E9ECEF
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondaryColor), // Text secondary 6C757D
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryHover, width: 2), // Hover A50707
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textTertiaryColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        elevation: 4,
        shadowColor: Color(0x1A6C757D), // Ombre text secondary
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: AppTheme.surfaceColor, // Surface E9ECEF
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor, // Surface E9ECEF
        selectedColor: Color(0x33850606), // Rouge bordeaux transparent
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        side: BorderSide(color: textSecondaryColor), // Bordure text secondary
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: textSecondaryColor, // Text secondary 6C757D
        foregroundColor: Colors.white, // Blanc
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor, // Surface E9ECEF
        selectedItemColor: primaryColor, // Rouge bordeaux
        unselectedItemColor: textSecondaryColor, // Text secondary 6C757D
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // TabBar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textTertiaryColor,
        indicatorColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      
      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor, // Gris très foncé
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white, // Blanc pur
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Thème sombre harmonieux avec la palette raffinée
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Schéma de couleurs pour le mode sombre
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: textSecondaryColor, // Text secondary en primaire pour le mode sombre
        secondary: primaryColor, // Rouge bordeaux en secondaire
        tertiary: primaryActive, // Active 5C0404
        surface: Color(0xFF212529), // Couleur similaire au text primary inversée
        background: Color(0xFF1A1D20), // Fond très sombre
        error: errorColor,
      ),
      
      // Police adaptée au mode sombre
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            color: Colors.white, // Blanc pur
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFFF5F5F5), // Blanc cassé
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFFF5F5F5),
          ),
        ),
      ),
      
      // AppBar pour le mode sombre
      appBarTheme: AppBarTheme(
        toolbarHeight: 44, // Hauteur encore plus réduite
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: primaryColor, // Rouge bordeaux #860505
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Icônes blanches
        ),
      ),
    );
  }

  // Couleurs utilitaires harmonisées avec la palette raffinée
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'member':
        return textSecondaryColor; // Text secondary 6C757D
      case 'leader':
        return primaryHover; // Hover A50707
      case 'pastor':
        return primaryColor; // Rouge bordeaux
      default:
        return textTertiaryColor;
    }
  }
  
  static Color getGroupTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'petit groupe':
        return textSecondaryColor; // Text secondary 6C757D
      case 'prière':
        return primaryColor; // Rouge bordeaux
      case 'jeunesse':
        return primaryHover; // Hover A50707
      case 'étude biblique':
        return textPrimaryColor; // Text primary 212529
      case 'louange':
        return primaryColor; // Rouge bordeaux
      case 'leadership':
        return primaryActive; // Active 5C0404
      default:
        return textTertiaryColor;
    }
  }
  
  static Color getServiceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'brouillon':
        return textSecondaryColor; // Text secondary 6C757D
      case 'publie':
        return successColor;
      case 'archive':
        return textSecondaryColor;
      case 'annule':
        return errorColor;
      default:
        return textTertiaryColor;
    }
  }
}