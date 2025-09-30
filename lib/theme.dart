import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === MATERIAL DESIGN 3 - COULEURS PRINCIPALES (BASÉES SUR VOTRE LOGO) ===
  
  /// Primary Color - Rouge croix (#860505) du logo
  static const Color primaryColor = Color(0xFF860505); // Rouge croix principal
  static const Color onPrimaryColor = Color(0xFFFFFFFF); // Blanc sur primary
  static const Color primaryContainer = Color(0xFFFFDAD4); // Container primary clair
  static const Color onPrimaryContainer = Color(0xFF2E0100); // Texte foncé sur container
  
  /// Secondary Color - Dérivé harmonieux du rouge principal
  static const Color secondaryColor = Color(0xFF775651); // Brun-rouge complémentaire
  static const Color onSecondaryColor = Color(0xFFFFFFFF); // Blanc sur secondary
  static const Color secondaryContainer = Color(0xFFFFDAD4); // Container secondary
  static const Color onSecondaryContainer = Color(0xFF2C1512); // Texte sur container secondary
  
  /// Tertiary Color - Couleur d'accent spirituelle
  static const Color tertiaryColor = Color(0xFF715B2E); // Brun doré spirituel
  static const Color onTertiaryColor = Color(0xFFFFFFFF); // Blanc sur tertiary
  static const Color tertiaryContainer = Color(0xFFFCDFA6); // Container tertiary
  static const Color onTertiaryContainer = Color(0xFF251A00); // Texte sur container tertiary
  
  // === MATERIAL DESIGN 3 - COULEURS DE SURFACE ===
  
  /// Surface Colors
  static const Color surface = Color(0xFFFFF8F6); // Surface principale
  static const Color onSurface = Color(0xFF201A19); // Texte principal (noir du logo)
  static const Color surfaceVariant = Color(0xFFF5DDD8); // Surface variante
  static const Color onSurfaceVariant = Color(0xFF534340); // Texte sur surface variante
  static const Color surfaceTint = primaryColor; // Tint = primary color
  
  /// Background Colors
  static const Color background = Color(0xFFFFF8F6); // Background principal
  static const Color onBackground = Color(0xFF201A19); // Texte sur background (noir du logo)
  
  /// Outline Colors
  static const Color outline = Color(0xFF857370); // Outline standard
  static const Color outlineVariant = Color(0xFFD8C2BC); // Outline variant
  
  // === MATERIAL DESIGN 3 - COULEURS UTILITAIRES ===
  
  /// Error Colors
  static const Color error = Color(0xFFBA1A1A); // Rouge erreur MD3
  static const Color onError = Color(0xFFFFFFFF); // Blanc sur erreur
  static const Color errorContainer = Color(0xFFFFDAD6); // Container erreur
  static const Color onErrorContainer = Color(0xFF410002); // Texte sur container erreur
  
  /// Success Colors (extension MD3)
  static const Color success = Color(0xFF006E1C); // Vert succès
  static const Color onSuccess = Color(0xFFFFFFFF); // Blanc sur succès
  static const Color successContainer = Color(0xFF6FFF81); // Container succès
  static const Color onSuccessContainer = Color(0xFF002106); // Texte sur container succès
  
  /// Warning Colors (extension MD3)
  static const Color warning = Color(0xFF8C5000); // Orange warning
  static const Color onWarning = Color(0xFFFFFFFF); // Blanc sur warning
  static const Color warningContainer = Color(0xFFFFDCC2); // Container warning
  static const Color onWarningContainer = Color(0xFF2E1500); // Texte sur container warning
  
  /// Info Colors (extension MD3)
  static const Color info = Color(0xFF0061A4); // Bleu info
  static const Color onInfo = Color(0xFFFFFFFF); // Blanc sur info
  static const Color infoContainer = Color(0xFFD1E4FF); // Container info
  static const Color onInfoContainer = Color(0xFF001D36); // Texte sur container info
  
  // === COULEURS NEUTRES (GREYS SCALE) ===
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // === COULEURS D'ÉTAT INTERACTIF ===
  
  static const Color primaryHover = Color(0xFFA50808); // Primary hover state
  static const Color primaryActive = Color(0xFF5C0404); // Primary active state
  static const Color primaryDisabled = Color(0xFF9E9E9E); // Primary disabled
  
  // === ALIAS DE COMPATIBILITÉ ===
  
  static const Color textPrimaryColor = onSurface; // Noir du logo
  static const Color textSecondaryColor = onSurfaceVariant; // Texte secondaire
  static const Color textTertiaryColor = onSurfaceVariant; // Texte tertiaire
  static const Color backgroundColor = surface; // Background principal
  static const Color surfaceColor = surfaceVariant; // Surface variante
  static const Color errorColor = error; // Couleur d'erreur
  static const Color successColor = success; // Couleur de succès
  static const Color warningColor = warning; // Couleur d'avertissement
  static const Color infoColor = info; // Couleur d'information
  static const Color redStandard = error; // Rouge standard
  static const Color greenStandard = success; // Vert standard
  static const Color blueStandard = info; // Bleu standard
  static const Color orangeStandard = warning; // Orange standard
  static const Color pinkStandard = Color(0xFFE91E63); // Rose standard
  static const Color white100 = grey100; // Blanc 100 (legacy)
  static const Color black100 = grey900; // Noir 100 (legacy)
  static const Color primaryDark = Color(0xFF5C0404); // Primary dark
  static const Color primaryDarker = Color(0xFF2E0101); // Primary darker
  
  // === CONSTANTES DE DESIGN ===
  
  /// Border Radius (conformes MD3)
  static const double radiusXSmall = 4.0;   // Extra small radius
  static const double radiusSmall = 8.0;    // Small radius  
  static const double radiusMedium = 12.0;  // Medium radius
  static const double radiusLarge = 16.0;   // Large radius
  static const double radiusXLarge = 20.0;  // Extra large radius
  static const double radiusXXLarge = 24.0; // Extra extra large radius
  static const double radiusRound = 32.0;   // Round radius
  static const double radiusCircular = 42.0; // Circular radius
  
  /// Spacing (conformes MD3)
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  static const double spaceXXLarge = 48.0;
  static const double spaceHuge = 64.0;
  
  /// Elevations (conformes MD3)
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 3.0;
  static const double elevation3 = 6.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 12.0;
  
  /// Typography weights
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontRegular = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemiBold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
  static const FontWeight fontExtraBold = FontWeight.w800;
  
  // === MÉTHODES UTILITAIRES ===
  
  /// BorderRadius communs
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusRound => BorderRadius.circular(radiusRound);
  
  /// Obtenir une couleur avec opacité
  static Color colorWithOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  // === MATERIAL DESIGN 3 THEME ===
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // ColorScheme MD3 complet
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondaryColor,
        onSecondary: onSecondaryColor,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiaryColor,
        onTertiary: onTertiaryColor,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        background: background,
        onBackground: onBackground,
        surface: surface,
        onSurface: onSurface,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceTint: surfaceTint,
      ),
      
      // Typography (Google Fonts - Inter)
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 57,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 45,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: fontRegular,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: fontMedium,
          color: onSurfaceVariant,
        ),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor, // #860505 - Rouge croix du logo
        foregroundColor: onPrimaryColor, // Blanc sur rouge
        elevation: elevation0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: fontMedium,
          color: onPrimaryColor, // Blanc sur rouge
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: elevation1,
          padding: const EdgeInsets.symmetric(horizontal: spaceLarge, vertical: spaceMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: fontMedium,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: outline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: spaceLarge, vertical: spaceMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: fontMedium,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: spaceMedium, vertical: spaceSmall),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: fontMedium,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        color: surface,
        elevation: elevation1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
        ),
        margin: EdgeInsets.all(spaceSmall),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceMedium,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: elevation3,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primaryColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: fontMedium,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: fontRegular,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryContainer,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: fontMedium,
          color: onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: spaceSmall),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
    );
  }
  
  // === THÈME SOMBRE (OPTIONNEL) ===
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFB4A9),
        onPrimary: Color(0xFF570100),
        primaryContainer: Color(0xFF6E0200),
        onPrimaryContainer: Color(0xFFFFDAD4),
        secondary: Color(0xFFE7BDB6),
        onSecondary: Color(0xFF442926),
        secondaryContainer: Color(0xFF5D3F3B),
        onSecondaryContainer: Color(0xFFFFDAD4),
        tertiary: Color(0xFFDFC38C),
        onTertiary: Color(0xFF3E2E04),
        tertiaryContainer: Color(0xFF564419),
        onTertiaryContainer: Color(0xFFFCDFA6),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        background: Color(0xFF1A110F),
        onBackground: Color(0xFFF1DDD9),
        surface: Color(0xFF1A110F),
        onSurface: Color(0xFFF1DDD9),
        surfaceVariant: Color(0xFF534340),
        onSurfaceVariant: Color(0xFFD8C2BC),
        outline: Color(0xFFA08C87),
        outlineVariant: Color(0xFF534340),
        surfaceTint: Color(0xFFFFB4A9),
      ),
      
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );
  }
  
  /// Méthode pour obtenir une couleur de statut
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'active':
        return success;
      case 'error':
      case 'failed':
      case 'cancelled':
        return error;
      case 'warning':
      case 'pending':
      case 'in_progress':
        return warning;
      case 'info':
      case 'draft':
        return info;
      default:
        return grey500;
    }
  }
}