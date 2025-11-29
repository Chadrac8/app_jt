import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'; // Pour defaultTargetPlatform
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === MATERIAL DESIGN 3 - COULEURS PRINCIPALES (BASÉES SUR NOTRE LOGO) ===
  
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
  static const double spaceXXXLarge = 64.0;
  static const double spaceHuge = 80.0;
  
  /// Elevations (conformes MD3)
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 3.0;
  static const double elevation3 = 6.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 12.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;
  
  /// Opacity levels
  static const double opacityVeryLow = 0.1;
  static const double opacityLow = 0.3;
  static const double opacityMedium = 0.5;
  static const double opacityHigh = 0.7;
  static const double opacityVeryHigh = 0.9;
  
  /// Border widths
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;
  static const double borderWidthThicker = 3.0;
  
  /// Typography weights
  static const FontWeight fontLight = FontWeight.w300;
  static const FontWeight fontRegular = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontSemiBold = FontWeight.w600;
  static const FontWeight fontBold = FontWeight.w700;
  
  // === CONSTANTES SUPPLÉMENTAIRES POUR HARDCODED CLEANUP ===
  
  /// Espacements spécialisés supplémentaires
  static const double space1 = 1.0;
  static const double space2 = 2.0;
  static const double space3 = 3.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space18 = 18.0;
  static const double space20 = 20.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  
  /// Border radius spécialisés
  static const double radius2 = 2.0;
  static const double radius6 = 6.0;
  static const double radius10 = 10.0;
  static const double radius15 = 15.0;
  static const double radius25 = 25.0;
  static const double radiusNone = 0.0;
  
  /// Tailles de police spécialisées
  static const double fontSize10 = 10.0;
  static const double fontSize11 = 11.0;
  static const double fontSize12 = 12.0;
  static const double fontSize13 = 13.0;
  static const double fontSize14 = 14.0;
  static const double fontSize15 = 15.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize22 = 22.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  static const double fontSize36 = 36.0;
  static const double fontSize45 = 45.0;
  static const double fontSize57 = 57.0;
  
  /// Couleurs spécialisées pour passages thématiques Bible
  static const Color passageColor1 = Color(0xFFFFCDD2); // Rouge clair
  static const Color passageColor2 = Color(0xFFBBDEFB); // Bleu clair  
  static const Color passageColor3 = Color(0xFFC8E6C9); // Vert clair
  static const Color passageColor4 = Color(0xFFFFE0B2); // Orange clair
  static const Color passageColor5 = Color(0xFFE1BEE7); // Violet clair
  
  /// Couleurs spéciales
  static const Color goldColor = Color(0xFFFFD700); // Or
  static const Color darkModeBackground = Color(0xFF121212); // Dark mode
  static const Color successColorBright = Color(0xFF00E676); // Vert succès vif
  
  /// Opacités spécialisées  
  static const double opacity15 = 0.15;
  static const double opacity25 = 0.25;
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
  
  // === STYLES DE TEXTE ACCESSIBLES DIRECTEMENT ===
  
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: AppTheme.fontSize12,
    fontWeight: fontRegular,
    color: onSurfaceVariant,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: AppTheme.fontSize14,
    fontWeight: fontRegular,
    color: onSurface,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: AppTheme.fontSize16,
    fontWeight: fontRegular,
    color: onSurface,
  );
  
  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: AppTheme.fontSize14,
    fontWeight: fontMedium,
    color: onSurface,
  );
  
  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: AppTheme.fontSize16,
    fontWeight: fontMedium,
    color: onSurface,
  );
  
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: AppTheme.fontSize22,
    fontWeight: fontMedium,
    color: onSurface,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: AppTheme.fontSize24,
    fontWeight: fontRegular,
    color: onSurface,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: AppTheme.fontSize28,
    fontWeight: fontRegular,
    color: onSurface,
  );
  
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: AppTheme.fontSize32,
    fontWeight: fontRegular,
    color: onSurface,
  );
  
  // === MATERIAL DESIGN 3 THEME ===
  // === CONFIGURATION MULTIPLATEFORME ADAPTATIVE ===
  
  /// Détermine si la plateforme actuelle suit les conventions iOS/macOS
  static bool get isApplePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  
  // === HELPERS POUR TEXTES ADAPTATIFS ===
  
  /// Crée un Tab adaptatif qui ne coupe pas le texte sur Android
  static Tab adaptiveTab({
    required String text,
    IconData? icon,
  }) {
    return Tab(
      icon: icon != null ? Icon(icon) : null,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: isApplePlatform ? 14 : 12,
          height: 1.2,
        ),
      ),
    );
  }

  /// Crée un FilterChip adaptatif avec gestion automatique du débordement
  static FilterChip adaptiveFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
    Color? selectedColor,
    Color? checkmarkColor,
  }) {
    return FilterChip(
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        // ✅ Style hérité du ChipTheme (WidgetStateTextStyle)
      ),
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor,
      checkmarkColor: checkmarkColor,
    );
  }

  /// Crée un ChoiceChip adaptatif avec gestion automatique du débordement
  static ChoiceChip adaptiveChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    Widget? avatar,
    Color? selectedColor,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        // ✅ Style hérité du ChipTheme (WidgetStateTextStyle)
      ),
      avatar: avatar,
      selected: selected,
      onSelected: onSelected,
      selectedColor: selectedColor,
    );
  }

  /// Crée un Row adaptatif avec icône et texte pour les boutons
  /// Gère automatiquement le débordement avec Flexible
  static Widget adaptiveButtonContent({
    required String label,
    IconData? icon,
    bool iconAfterText = false,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final textWidget = Flexible(
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize ?? (isApplePlatform ? 14 : 13),
          fontWeight: fontWeight ?? fontMedium,
          color: color,
          height: 1.2,
          letterSpacing: isApplePlatform ? -0.1 : -0.2,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );

    if (icon == null) {
      return textWidget;
    }

    final iconWidget = Icon(icon, size: 18);
    const spacing = SizedBox(width: 6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAfterText
          ? [textWidget, spacing, iconWidget]
          : [iconWidget, spacing, textWidget],
    );
  }

  /// Crée un Text avec overflow handling automatique pour les labels
  /// À utiliser dans Chip, FilterChip, ChoiceChip, etc.
  static Text adaptiveChipLabel(
    String text, {
    TextStyle? style,
  }) {
    return Text(
      text,
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      // Style hérité du ChipTheme si non spécifié
    );
  }
  
  /// Taille de police adaptative pour les labels
  static double get adaptiveLabelFontSize => isApplePlatform ? 14 : 12;
  
  /// Taille de police adaptative pour les chips
  static double get adaptiveChipFontSize => isApplePlatform ? 13 : 11.5;
  
  /// Style de texte adaptatif pour éviter les textes coupés
  static TextStyle adaptiveTextStyle({
    required double iosFontSize,
    double? androidFontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: isApplePlatform ? iosFontSize : (androidFontSize ?? iosFontSize - 1.5),
      fontWeight: fontWeight ?? fontRegular,
      color: color,
      letterSpacing: letterSpacing ?? (isApplePlatform ? -0.1 : -0.2),
      height: 1.2,
    );
  }
  
  /// Détermine si la plateforme actuelle est un desktop
  static bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
  
  /// Détermine si la plateforme actuelle est mobile
  static bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
  
  /// Détermine si la plateforme actuelle est web
  static bool get isWeb => kIsWeb;
  
  // === DESIGN TOKENS ADAPTATIFS ===
  
  /// Padding adaptatif selon la plateforme
  static double get adaptivePadding => isDesktop ? 24.0 : 16.0;
  
  /// Largeur maximale du contenu (plus large sur desktop)
  static double get maxContentWidth => isDesktop ? 1200.0 : 800.0;
  
  /// Taille des icônes adaptative
  static double get adaptiveIconSize => isDesktop ? 24.0 : 20.0;
  
  /// Espacement des éléments de navigation
  static double get navigationSpacing => isDesktop ? 48.0 : 32.0;
  
  /// Rayon de bordure adaptatif (iOS préfère plus arrondi)
  static double get adaptiveBorderRadius => isApplePlatform ? 12.0 : 8.0;
  
  // === DESIGN TOKENS POUR CARTES D'ACTION ===
  
  /// Rayon pour cartes d'action (12dp iOS, 16dp Android/Material)
  static double get actionCardRadius => isApplePlatform ? 12.0 : radiusLarge;
  
  /// Épaisseur de bordure pour cartes (0.5px iOS, 1px Android)
  static double get actionCardBorderWidth => isApplePlatform ? 0.5 : 1.0;
  
  /// Padding interne des cartes d'action
  static double get actionCardPadding => isDesktop ? 20.0 : 16.0;
  
  /// Nombre de colonnes pour grille responsive
  static int getGridColumns(double screenWidth) {
    if (isDesktop && screenWidth >= 1200) return 4;
    if (isDesktop || screenWidth >= 600) return 3;
    return 2; // Mobile par défaut
  }
  
  /// Espacement entre cartes dans la grille
  static double get gridSpacing => isDesktop ? 16.0 : 12.0;
  
  /// Opacité pour interaction tactile (plus subtile sur iOS)
  static double get interactionOpacity => isApplePlatform ? 0.08 : 0.12;
  
  // === TAILLES DE POLICE ADAPTATIVES ===
  
  /// Typography Scale - Conforme Material Design 3 (2024)
  /// Base = Standard MD3 officiel | Desktop = Base + 2sp (bonus lisibilité)
  /// iOS/macOS = Base × 1.05 (conventions Apple)
  
  // Display (Titres très grands)
  static double get adaptiveDisplayLarge => isDesktop ? 59.0 : 57.0;   // MD3: 57sp
  static double get adaptiveDisplayMedium => isDesktop ? 47.0 : 45.0;  // MD3: 45sp
  static double get adaptiveDisplaySmall => isDesktop ? 38.0 : 36.0;   // MD3: 36sp
  
  // Headline (Titres)
  static double get adaptiveHeadlineLarge => isDesktop ? 34.0 : 32.0;   // MD3: 32sp
  static double get adaptiveHeadlineMedium => isDesktop ? 30.0 : 28.0;  // MD3: 28sp
  static double get adaptiveHeadlineSmall => isDesktop ? 26.0 : 24.0;   // MD3: 24sp
  
  // Title (Sous-titres)
  static double get adaptiveTitleLarge => isDesktop ? 24.0 : 22.0;   // MD3: 22sp
  static double get adaptiveTitleMedium => isDesktop ? 18.0 : 16.0;  // MD3: 16sp
  static double get adaptiveTitleSmall => isDesktop ? 16.0 : 14.0;   // MD3: 14sp
  
  // Body (Texte principal)
  static double get adaptiveBodyLarge => isDesktop ? 18.0 : 16.0;  // MD3: 16sp
  static double get adaptiveBodyMedium => isDesktop ? 16.0 : 14.0; // MD3: 14sp ⚠️ CORRIGÉ
  static double get adaptiveBodySmall => isDesktop ? 14.0 : 12.0;  // MD3: 12sp
  
  // Label (Labels de boutons, etc.)
  // Adapté iOS vs Android : Android légèrement plus petit pour éviter les textes coupés
  static double get adaptiveLabelLarge => isDesktop ? 16.0 : (isApplePlatform ? 14.0 : 13.0);  // MD3: 14sp (iOS 14, Android 13)
  static double get adaptiveLabelMedium => isDesktop ? 14.0 : (isApplePlatform ? 12.0 : 11.0); // MD3: 12sp (iOS 12, Android 11)
  static double get adaptiveLabelSmall => isDesktop ? 13.0 : (isApplePlatform ? 11.0 : 10.0);  // MD3: 11sp (iOS 11, Android 10)
  
  /// Multiplicateur de taille pour iOS/macOS (conventions Apple)
  /// Body iOS: 14sp × 1.05 = 14.7sp (proche recommandation Apple ~17pt)
  /// Usage: fontSize * fontSizeMultiplier
  static double get fontSizeMultiplier => isApplePlatform ? 1.05 : 1.0;
  
  // === MATERIAL DESIGN 3 - COULEURS PRINCIPALES (BASÉES SUR NOTRE LOGO) ===
  
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
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceTint: surfaceTint,
      ),
      
      // Typography (Google Fonts - Inter) - Adaptatif multiplateforme
      // Desktop: tailles légèrement plus grandes (+2sp)
      // iOS/macOS: multiplicateur 1.05x pour meilleure lisibilité
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveDisplayLarge * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveDisplayMedium * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveDisplaySmall * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveHeadlineLarge * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveHeadlineMedium * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveHeadlineSmall * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveTitleLarge * AppTheme.fontSizeMultiplier,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveTitleMedium * AppTheme.fontSizeMultiplier,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveTitleSmall * AppTheme.fontSizeMultiplier,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveBodyLarge * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveBodyMedium * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveBodySmall * AppTheme.fontSizeMultiplier,
          fontWeight: fontRegular,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveLabelLarge * AppTheme.fontSizeMultiplier,
          fontWeight: fontMedium,
          color: onSurface,
          height: 1.2, // Meilleure lisibilité sur Android
          letterSpacing: isApplePlatform ? -0.1 : -0.2,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveLabelMedium * AppTheme.fontSizeMultiplier,
          fontWeight: fontMedium,
          color: onSurface,
          height: 1.2,
          letterSpacing: isApplePlatform ? -0.1 : -0.2,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: AppTheme.adaptiveLabelSmall * AppTheme.fontSizeMultiplier,
          fontWeight: fontMedium,
          color: onSurfaceVariant,
          height: 1.2,
          letterSpacing: isApplePlatform ? -0.1 : -0.2,
        ),
      ),
      
      // AppBar Theme - Material Design 3 (2024) - Surface Style
      appBarTheme: AppBarTheme(
        backgroundColor: surface, // MD3: Surface claire (blanc/gris clair)
        foregroundColor: onSurface, // Texte foncé sur fond clair
        surfaceTintColor: primaryColor, // MD3: Teinte rouge subtile pour cohérence
        elevation: elevation0, // MD3 standard: pas d'élévation
        scrolledUnderElevation: elevation2, // MD3: élévation au scroll pour profondeur
        shadowColor: Colors.black.withOpacity(0.1), // MD3: ombre subtile si scrolled
        // MD3 Multiplateforme: Adaptatif selon la plateforme
        // iOS/macOS: centré (convention Apple) | Android/Web: à gauche (MD3)
        centerTitle: defaultTargetPlatform == TargetPlatform.iOS || 
                     defaultTargetPlatform == TargetPlatform.macOS,
        titleSpacing: spaceMedium, // MD3: 16dp spacing standard
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // MD3: status bar transparente
          statusBarIconBrightness: Brightness.dark, // Icônes foncées sur fond clair
          statusBarBrightness: Brightness.light, // Fond clair
          systemNavigationBarColor: Colors.white, // MD3: navigation bar claire
          systemNavigationBarIconBrightness: Brightness.dark, // Icônes foncées
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize22, // MD3 headlineSmall (22sp)
          fontWeight: fontMedium, // MD3: Medium weight (500)
          color: onSurface, // Texte foncé sur fond clair
          height: 1.27, // MD3 line height pour headlineSmall
          letterSpacing: 0, // MD3 letter spacing
        ),
        toolbarTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14, // MD3 bodyMedium
          fontWeight: fontRegular,
          color: onSurface, // Texte foncé sur fond clair
        ),
        iconTheme: IconThemeData(
          color: onSurfaceVariant, // MD3: Icônes en onSurfaceVariant (gris foncé)
          size: 24, // MD3 standard icon size
          opacity: 1.0,
        ),
        actionsIconTheme: IconThemeData(
          color: onSurfaceVariant, // MD3: Icônes actions en onSurfaceVariant
          size: 24,
          opacity: 1.0,
        ),
      ),
      
      // Icon Button Theme - MD3 Style
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: onSurfaceVariant, // MD3: Couleur foncée pour icônes
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.all(spaceSmall),
          // MD3: Hover et pressed states
        ).copyWith(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryColor; // Rouge au clic
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryColor; // Rouge au survol
            }
            return onSurfaceVariant; // Gris foncé par défaut
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return primaryColor.withOpacity(0.12); // MD3: 12% overlay
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryColor.withOpacity(0.08); // MD3: 8% overlay
            }
            return null;
          }),
        ),
      ),
      
      // Elevated Button Theme - Adaptatif
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          // Elevation adaptative: plus prononcée sur Android, subtile sur iOS
          elevation: isApplePlatform ? 0 : elevation1,
          padding: EdgeInsets.symmetric(
            // Plus de padding horizontal sur Android pour éviter les textes coupés
            horizontal: isDesktop ? spaceLarge + 8 : (isApplePlatform ? spaceLarge : spaceLarge + 4),
            vertical: isDesktop ? spaceMedium + 4 : spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isApplePlatform ? 12.0 : radiusMedium, // iOS plus arrondi
            ),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
            fontWeight: fontMedium,
            // Hauteur de ligne plus généreuse pour Android
            height: isApplePlatform ? 1.2 : 1.3,
          ),
          // Permet au texte de respirer sur Android
          minimumSize: const Size(64, 42),
        ),
      ),
      
      // Outlined Button Theme - Adaptatif
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: outline,
            width: isApplePlatform ? 1.5 : 1.0, // iOS lignes plus épaisses
          ),
          padding: EdgeInsets.symmetric(
            // Plus de padding horizontal sur Android
            horizontal: isDesktop ? spaceLarge + 8 : (isApplePlatform ? spaceLarge : spaceLarge + 4),
            vertical: isDesktop ? spaceMedium + 4 : spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isApplePlatform ? 12.0 : radiusMedium,
            ),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
            fontWeight: fontMedium,
            height: isApplePlatform ? 1.2 : 1.3,
          ),
          minimumSize: const Size(64, 42),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          // Plus de padding horizontal sur Android
          padding: EdgeInsets.symmetric(
            horizontal: isApplePlatform ? spaceMedium : spaceMedium + 4,
            vertical: spaceSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: fontMedium,
            height: isApplePlatform ? 1.2 : 1.3,
          ),
          minimumSize: const Size(48, 36),
        ),
      ),
      
      // Card Theme - Adaptatif
      cardTheme: CardThemeData(
        color: surface,
        // Elevation adaptative: iOS préfère flat, Android/Desktop préfère subtle shadow
        elevation: isApplePlatform ? 0 : elevation1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(isApplePlatform ? 16.0 : radiusMedium),
          ),
          // iOS ajoute une bordure subtile quand pas d'élévation
          side: isApplePlatform
              ? BorderSide(color: outline.withOpacity(0.2), width: 0.5)
              : BorderSide.none,
        ),
        margin: EdgeInsets.all(isDesktop ? spaceMedium : spaceSmall),
      ),
      
      // Input Decoration Theme - Adaptatif
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isApplePlatform ? grey50 : surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
          borderSide: BorderSide(
            color: outline,
            width: isApplePlatform ? 0.5 : 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
          borderSide: BorderSide(
            color: outline,
            width: isApplePlatform ? 0.5 : 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
          borderSide: BorderSide(
            color: primaryColor,
            width: isApplePlatform ? 1.5 : 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
          borderSide: BorderSide(color: error, width: isApplePlatform ? 1.5 : 1.0),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceLarge : spaceMedium,
          vertical: isDesktop ? spaceMedium + 4 : spaceMedium,
        ),
      ),
      
      // Floating Action Button Theme - Adaptatif
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        // iOS préfère moins d'élévation
        elevation: isApplePlatform ? elevation1 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 16.0 : radiusMedium,
          ),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        // Tailles de police adaptatives pour éviter les textes coupés sur Android
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 12 : 11,
          fontWeight: fontSemiBold,
          height: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 12 : 11,
          fontWeight: fontRegular,
          height: 1.2,
        ),
        // Permet d'afficher toujours les labels
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Tab Bar Theme - Material Design 3 (Primary Tabs)
      tabBarTheme: TabBarThemeData(
        // MD3: Primary tabs intégrées à l'AppBar Surface
        labelColor: primaryColor, // MD3: Texte rouge (primary) pour tab active
        unselectedLabelColor: onSurfaceVariant, // MD3: Texte gris pour tabs inactives
        
        // Styles de texte adaptatifs pour Android
        labelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 14 : 12,
          fontWeight: fontSemiBold,
          height: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 14 : 12,
          fontWeight: fontMedium,
          height: 1.2,
        ),
        
        // MD3: Indicateur de sélection style YouTube Studio (arrondi en haut, 3dp hauteur)
        indicator: const UnderlineTabIndicator(
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
          borderSide: BorderSide(
            color: primaryColor,
            width: 3.0, // MD3: 3dp d'épaisseur
          ),
          insets: EdgeInsets.symmetric(horizontal: 16.0), // Padding horizontal
        ),
        indicatorSize: TabBarIndicatorSize.tab, // Largeur du tab (avec padding)
        
        dividerColor: Colors.transparent, // MD3: Pas de divider visible
        dividerHeight: 0, // MD3: Hauteur du divider à 0
        overlayColor: WidgetStateProperty.resolveWith((states) {
          // MD3: États interactifs
          if (states.contains(WidgetState.pressed)) {
            return primaryColor.withOpacity(0.12); // 12% overlay au press
          }
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.08); // 8% overlay au hover
          }
          return null;
        }),
        // MD3: Padding et spacing
        labelPadding: const EdgeInsets.symmetric(horizontal: 16), // MD3: 16dp horizontal
        splashFactory: InkRipple.splashFactory, // MD3: Ripple effect
      ),
      
      // Chip Theme - Adaptatif (FilterChip, ChoiceChip, etc.)
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryColor,
        disabledColor: surfaceVariant.withOpacity(0.5),
        // Couleur du label avec Material State (selected/unselected)
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: isApplePlatform ? 13 : 11.5,
            fontWeight: isSelected ? fontSemiBold : fontMedium,
            color: isSelected ? onPrimaryColor : onSurfaceVariant,
            letterSpacing: isApplePlatform ? -0.1 : -0.2,
            height: 1.2,
          );
        }),
        // Padding réduit sur mobile pour économiser l'espace
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceMedium : (isApplePlatform ? spaceSmall : 6),
          vertical: isApplePlatform ? spaceSmall : 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusMedium : radiusSmall,
          ),
        ),
        // Style alternatif pour chip sélectionné (fallback)
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 13 : 11.5,
          fontWeight: fontSemiBold,
          color: onPrimaryContainer,
          letterSpacing: isApplePlatform ? -0.1 : -0.2,
          height: 1.2,
        ),
        // Espacement entre icône et label
        labelPadding: EdgeInsets.symmetric(horizontal: isApplePlatform ? 8 : 6),
        // Couleur de l'icône avec Material State
        iconTheme: IconThemeData(
          color: onSurfaceVariant,
          size: 16,
        ),
      ),
      
      // Dialog Theme - Adaptatif
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation2 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 20.0 : radiusMedium,
          ),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize20,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: fontRegular,
          color: onSurface,
        ),
      ),
      
      // Bottom Sheet Theme - Adaptatif
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation2 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isApplePlatform ? 20.0 : radiusMedium),
          ),
        ),
        modalBackgroundColor: surface,
        modalElevation: isApplePlatform ? elevation2 : elevation3,
      ),
      
      // Snackbar Theme - Adaptatif
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          color: surface,
        ),
        behavior: isDesktop ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        elevation: isApplePlatform ? elevation1 : elevation2,
        shape: isDesktop
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusSmall),
              )
            : null,
      ),
      
      // Scrollbar Theme - Visible sur desktop, auto-hidden sur mobile
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(isDesktop),
        thickness: WidgetStateProperty.all(isDesktop ? 8.0 : 4.0),
        radius: const Radius.circular(4.0),
        thumbColor: WidgetStateProperty.all(
          onSurfaceVariant.withOpacity(isDesktop ? 0.3 : 0.2),
        ),
      ),
      
      // ListTile Theme - Adaptatif
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceLarge : spaceMedium,
          vertical: isDesktop ? spaceSmall : space4,
        ),
        minLeadingWidth: isDesktop ? 40 : 32,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusMedium : radiusSmall,
          ),
        ),
      ),
      
      // Switch Theme - Adaptatif
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onPrimaryColor;
          }
          return isApplePlatform ? grey300 : surfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return isApplePlatform ? grey400 : outline;
        }),
        // iOS switch est plus large
        splashRadius: isApplePlatform ? 20.0 : 16.0,
      ),
      
      // Checkbox Theme - Adaptatif
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimaryColor),
        side: BorderSide(
          color: outline,
          width: isApplePlatform ? 1.5 : 2.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 4.0 : 2.0,
          ),
        ),
      ),
      
      // Radio Theme - Adaptatif
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return outline;
        }),
        splashRadius: isDesktop ? 20.0 : 16.0,
      ),
      
      // Slider Theme - Adaptatif
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: isApplePlatform ? grey300 : primaryColor.withOpacity(0.24),
        thumbColor: isApplePlatform ? white : primaryColor,
        overlayColor: primaryColor.withOpacity(0.12),
        // iOS slider a un thumb plus grand
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: isApplePlatform ? 14.0 : 10.0,
        ),
        trackHeight: isApplePlatform ? 4.0 : 4.0,
        overlayShape: RoundSliderOverlayShape(
          overlayRadius: isDesktop ? 24.0 : 20.0,
        ),
      ),
      
      // Progress Indicator Theme - Adaptatif
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: isApplePlatform ? grey200 : primaryColor.withOpacity(0.24),
        circularTrackColor: isApplePlatform ? grey200 : primaryColor.withOpacity(0.24),
        linearMinHeight: isApplePlatform ? 3.0 : 4.0,
      ),
      
      // Divider Theme - Adaptatif
      dividerTheme: DividerThemeData(
        color: isApplePlatform ? grey300 : outline.withOpacity(0.2),
        thickness: isApplePlatform ? 0.5 : 1.0,
        space: isDesktop ? spaceLarge : spaceMedium,
      ),
      
      // Drawer Theme - Adaptatif
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation1 : elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(isApplePlatform ? 16.0 : 0.0),
            bottomRight: Radius.circular(isApplePlatform ? 16.0 : 0.0),
          ),
        ),
        width: isDesktop ? 304.0 : 280.0, // Desktop drawer plus large
      ),
      
      // Navigation Drawer Theme - Adaptatif
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation1 : elevation2,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusMedium : radiusSmall,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(
            fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
            fontWeight: fontMedium,
          ),
        ),
      ),
      
      // Navigation Rail Theme - Pour desktop
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation1 : elevation2,
        selectedIconTheme: IconThemeData(
          color: primaryColor,
          size: isDesktop ? 28 : 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: onSurfaceVariant,
          size: isDesktop ? 28 : 24,
        ),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: fontMedium,
          color: primaryColor,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          fontWeight: fontRegular,
          color: onSurfaceVariant,
        ),
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Badge Theme - Adaptatif
      badgeTheme: BadgeThemeData(
        backgroundColor: error,
        textColor: onError,
        smallSize: isDesktop ? 8 : 6,
        largeSize: isDesktop ? 20 : 16,
        textStyle: GoogleFonts.inter(
          fontSize: isDesktop ? 11 : 10,
          fontWeight: fontMedium,
        ),
      ),
      
      // Tooltip Theme - Adaptatif
      tooltipTheme: TooltipThemeData(
        constraints: BoxConstraints(minHeight: isDesktop ? 32 : 24), padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceMedium : spaceSmall,
          vertical: isDesktop ? spaceSmall : space4,
        ),
        margin: EdgeInsets.all(isDesktop ? spaceSmall : space4),
        decoration: BoxDecoration(
          color: onSurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 8.0 : 4.0,
          ),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: isDesktop ? 13 : 12,
          fontWeight: fontRegular,
          color: surface,
        ),
        waitDuration: isDesktop
            ? const Duration(milliseconds: 500)
            : const Duration(milliseconds: 700),
      ),
      
      // Popup Menu Theme - Adaptatif
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: isApplePlatform ? elevation2 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
          fontWeight: fontRegular,
          color: onSurface,
        ),
      ),
      
      // Menu Theme - Adaptatif (pour MenuBar, MenuAnchor)
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          elevation: WidgetStateProperty.all(
            isApplePlatform ? elevation2 : elevation3,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                isApplePlatform ? 12.0 : radiusSmall,
              ),
            ),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.all(isDesktop ? spaceSmall : space4),
          ),
        ),
      ),
      
      // Banner Theme - Adaptatif
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: GoogleFonts.inter(
          fontSize: AppTheme.fontSize14,
          color: onSurface,
        ),
        padding: EdgeInsets.all(isDesktop ? spaceLarge : spaceMedium),
        elevation: isApplePlatform ? elevation1 : elevation2,
      ),
      
      // Data Table Theme - Optimisé pour desktop
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceVariant),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryContainer.withOpacity(0.12);
          }
          return null;
        }),
        headingTextStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
          fontWeight: fontMedium,
          color: onSurface,
        ),
        dataTextStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
          fontWeight: fontRegular,
          color: onSurface,
        ),
        horizontalMargin: isDesktop ? spaceLarge : spaceMedium,
        columnSpacing: isDesktop ? 56 : 48,
        dataRowMinHeight: isDesktop ? 52 : 48,
        dataRowMaxHeight: isDesktop ? 72 : 64,
      ),
      
      // Time Picker Theme - Adaptatif
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation2 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 20.0 : radiusMedium,
          ),
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 12.0 : radiusSmall,
          ),
        ),
      ),
      
      // Date Picker Theme - Adaptatif
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation2 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? 20.0 : radiusMedium,
          ),
        ),
        headerBackgroundColor: primaryContainer,
        headerForegroundColor: onPrimaryContainer,
        dayStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
        ),
        yearStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
        ),
      ),
      
      // ===== COMPOSANTS MANQUANTS - AJOUT FINAL =====
      
      // Expansion Tile Theme - Adaptatif
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceLarge : spaceMedium,
        ),
        childrenPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceLarge : spaceMedium,
          vertical: spaceSmall,
        ),
        iconColor: onSurfaceVariant,
        collapsedIconColor: onSurfaceVariant,
        textColor: onSurface,
        collapsedTextColor: onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusMedium : radiusSmall,
          ),
        ),
      ),
      
      // Search Bar Theme - Adaptatif (Material 3)
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(
          isApplePlatform ? elevation1 : elevation2,
        ),
        backgroundColor: WidgetStateProperty.all(surfaceVariant),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(
            horizontal: isDesktop ? spaceMedium : spaceSmall,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isApplePlatform ? radiusLarge : radiusMedium,
            ),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.inter(
            fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
            color: onSurface,
          ),
        ),
        hintStyle: WidgetStateProperty.all(
          GoogleFonts.inter(
            fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
            color: onSurfaceVariant,
          ),
        ),
      ),
      
      // Search View Theme - Adaptatif (Material 3)
      searchViewTheme: SearchViewThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation2 : elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusLarge : radiusMedium,
          ),
        ),
        headerTextStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
          color: onSurface,
        ),
        headerHintStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize16 : AppTheme.fontSize14,
          color: onSurfaceVariant,
        ),
      ),
      
      // App Bar Theme pour Bottom AppBar - Adaptatif
      bottomAppBarTheme: BottomAppBarThemeData(
        color: surface,
        elevation: isApplePlatform ? elevation1 : elevation2,
        shape: const CircularNotchedRectangle(),
        height: isDesktop ? 72 : 64,
      ),
      
      // Segmented Button Theme - Adaptatif (Material 3)
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return onPrimaryContainer;
            }
            return onSurface;
          }),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(
              fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
              fontWeight: fontMedium,
            ),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: isDesktop ? spaceMedium : spaceSmall,
              vertical: isDesktop ? spaceSmall : space4,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                isApplePlatform ? radiusMedium : radiusSmall,
              ),
            ),
          ),
        ),
      ),
      
      // Action Icon Theme - Adaptatif (Material 3)
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => Icon(
          isApplePlatform ? Icons.arrow_back_ios : Icons.arrow_back,
          size: 24,
        ),
        closeButtonIconBuilder: (context) => Icon(
          isApplePlatform ? Icons.close : Icons.close,
          size: 24,
        ),
        drawerButtonIconBuilder: (context) => Icon(
          Icons.menu,
          size: 24,
        ),
        endDrawerButtonIconBuilder: (context) => Icon(
          Icons.menu,
          size: 24,
        ),
      ),
      
      // Toggle Buttons Theme - Adaptatif
      toggleButtonsTheme: ToggleButtonsThemeData(
        borderRadius: BorderRadius.circular(
          isApplePlatform ? radiusMedium : radiusSmall,
        ),
        selectedColor: onPrimaryContainer,
        fillColor: primaryContainer,
        color: onSurface,
        borderColor: outline,
        selectedBorderColor: primaryColor,
        textStyle: GoogleFonts.inter(
          fontSize: isDesktop ? AppTheme.fontSize14 : AppTheme.fontSize13,
          fontWeight: fontMedium,
        ),
        constraints: BoxConstraints(
          minHeight: isDesktop ? 48 : 40,
          minWidth: isDesktop ? 72 : 64,
        ),
      ),
      
      // Bottom Navigation Bar Theme déjà fait mais améliorer
      // Navigation Bar Theme (Material 3 style) - Adaptatif
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: isApplePlatform ? elevation1 : elevation2,
        height: isDesktop ? 72 : 64,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusLarge : radiusMedium,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.inter(
            fontSize: isDesktop ? AppTheme.fontSize13 : AppTheme.fontSize12,
            fontWeight: states.contains(WidgetState.selected) ? fontMedium : fontRegular,
            color: states.contains(WidgetState.selected) ? onSurface : onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: isDesktop ? 28 : 24,
            color: states.contains(WidgetState.selected) ? primaryColor : onSurfaceVariant,
          );
        }),
      ),
    );
  }
  
  // === THÈME SOMBRE COMPLET ===
  
  static ThemeData get darkTheme {
    const darkColorScheme = ColorScheme.dark(
      // Couleurs principales (adaptées pour le sombre)
      primary: Color(0xFFFFB4A9), // Rouge clair adapté
      onPrimary: Color(0xFF570100), // Rouge très foncé sur primary
      primaryContainer: Color(0xFF6E0200), // Container primary sombre
      onPrimaryContainer: Color(0xFFFFDAD4), // Texte clair sur container
      
      // Couleurs secondaires
      secondary: Color(0xFFE7BDB6), // Brun-rouge clair
      onSecondary: Color(0xFF442926), // Brun foncé sur secondary
      secondaryContainer: Color(0xFF5D3F3B), // Container secondary
      onSecondaryContainer: Color(0xFFFFDAD4), // Texte sur container secondary
      
      // Couleurs tertiaires
      tertiary: Color(0xFFDFC38C), // Brun doré clair
      onTertiary: Color(0xFF3E2E04), // Brun très foncé sur tertiary
      tertiaryContainer: Color(0xFF564419), // Container tertiary
      onTertiaryContainer: Color(0xFFFCDFA6), // Texte sur container tertiary
      
      // Couleurs d'erreur
      error: Color(0xFFFFB4AB), // Rouge erreur clair
      onError: Color(0xFF690005), // Rouge foncé sur erreur
      errorContainer: Color(0xFF93000A), // Container erreur
      onErrorContainer: Color(0xFFFFDAD6), // Texte sur container erreur
      
      // Couleurs de surface
      surface: Color(0xFF1A110F), // Surface principale sombre
      onSurface: Color(0xFFF1DDD9), // Texte principal clair
      surfaceVariant: Color(0xFF534340), // Surface variante
      onSurfaceVariant: Color(0xFFD8C2BC), // Texte sur surface variante
      surfaceTint: Color(0xFFFFB4A9), // Tint = primary
      
      // Surfaces containers
      surfaceContainerLowest: Color(0xFF0F0605), // Container le plus bas
      surfaceContainer: Color(0xFF1F1715), // Container normal
      surfaceContainerHigh: Color(0xFF2A1D1A), // Container élevé
      surfaceContainerHighest: Color(0xFF352621), // Container le plus élevé
      
      // Couleurs de background
      background: Color(0xFF1A110F), // Background sombre
      onBackground: Color(0xFFF1DDD9), // Texte sur background
      
      // Couleurs d'outline
      outline: Color(0xFFA08C87), // Outline principal
      outlineVariant: Color(0xFF534340), // Outline variant
      
      // Couleurs étendues
      inverseSurface: Color(0xFFF1DDD9), // Surface inverse (clair)
      onInverseSurface: Color(0xFF382E2C), // Texte sur surface inverse
      inversePrimary: Color(0xFF860505), // Primary inverse (notre rouge principal)
      
      // Couleur d'ombre
      shadow: Color(0xFF000000), // Ombre noire
      scrim: Color(0xFF000000), // Scrim noir
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      
      // Police personnalisée Inter
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          // Titres
          displayLarge: GoogleFonts.inter(
            fontSize: 57,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.25,
            color: darkColorScheme.onSurface,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 45,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: darkColorScheme.onSurface,
          ),
          displaySmall: GoogleFonts.inter(
            fontSize: 36,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: darkColorScheme.onSurface,
          ),
          
          // Headlines
          headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: darkColorScheme.onSurface,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: darkColorScheme.onSurface,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: darkColorScheme.onSurface,
          ),
          
          // Titres
          titleLarge: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: darkColorScheme.onSurface,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: darkColorScheme.onSurface,
          ),
          titleSmall: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: darkColorScheme.onSurface,
          ),
          
          // Corps de texte
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: darkColorScheme.onSurface,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.25,
            color: darkColorScheme.onSurface,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
            color: darkColorScheme.onSurfaceVariant,
          ),
          
          // Labels
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: darkColorScheme.onSurface,
          ),
          labelMedium: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: darkColorScheme.onSurface,
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: darkColorScheme.onSurfaceVariant,
          ),
        ),
      ),
      
      // Configuration des composants Material 3
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkColorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: darkColorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: darkColorScheme.onSurface),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      
      // Configuration des cartes
      cardTheme: CardThemeData(
        color: darkColorScheme.surfaceContainer,
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(spaceSmall),
      ),
      
      // Configuration des boutons élevés
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: elevation1,
          padding: EdgeInsets.symmetric(
            // Plus de padding horizontal sur Android
            horizontal: isApplePlatform ? spaceLarge : spaceLarge + 4,
            vertical: spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: fontSize14,
            fontWeight: fontSemiBold,
            height: isApplePlatform ? 1.2 : 1.3,
          ),
          minimumSize: const Size(64, 42),
        ),
      ),
      
      // Configuration des boutons remplis
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLarge,
            vertical: spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: fontSize14,
            fontWeight: fontSemiBold,
          ),
        ),
      ),
      
      // Configuration des boutons avec contour
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          side: BorderSide(color: darkColorScheme.outline),
          padding: EdgeInsets.symmetric(
            // Plus de padding horizontal sur Android
            horizontal: isApplePlatform ? spaceLarge : spaceLarge + 4,
            vertical: spaceMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: fontSize14,
            fontWeight: fontSemiBold,
            height: isApplePlatform ? 1.2 : 1.3,
          ),
          minimumSize: const Size(64, 42),
        ),
      ),
      
      // Configuration des boutons texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 36),
          foregroundColor: darkColorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMedium,
            vertical: spaceSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: fontSize14,
            fontWeight: fontSemiBold,
          ),
        ),
      ),
      
      // Configuration des champs de saisie
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: darkColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceMedium,
        ),
        labelStyle: GoogleFonts.inter(
          color: darkColorScheme.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          color: darkColorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      
      // Configuration de la navigation inférieure
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        selectedItemColor: darkColorScheme.primary,
        unselectedItemColor: darkColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: elevation3,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? fontSize12 : 11,
          fontWeight: fontSemiBold,
          height: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? fontSize12 : 11,
          fontWeight: fontMedium,
          height: 1.2,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Configuration des onglets
      tabBarTheme: TabBarThemeData(
        labelColor: darkColorScheme.primary,
        unselectedLabelColor: darkColorScheme.onSurfaceVariant,
        indicatorColor: darkColorScheme.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 14 : 12,
          fontWeight: fontSemiBold,
          height: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 14 : 12,
          fontWeight: fontMedium,
          height: 1.2,
        ),
      ),
      
      // Chip Theme - Adaptatif (mode sombre)
      chipTheme: ChipThemeData(
        backgroundColor: darkColorScheme.surfaceContainerHighest,
        selectedColor: darkColorScheme.primary,
        disabledColor: darkColorScheme.surfaceContainerHighest.withOpacity(0.5),
        // Couleur du label avec Material State (selected/unselected)
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: isApplePlatform ? 13 : 11.5,
            fontWeight: isSelected ? fontSemiBold : fontMedium,
            color: isSelected ? darkColorScheme.onPrimary : darkColorScheme.onSurfaceVariant,
            letterSpacing: isApplePlatform ? -0.1 : -0.2,
            height: 1.2,
          );
        }),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? spaceMedium : (isApplePlatform ? spaceSmall : 6),
          vertical: isApplePlatform ? spaceSmall : 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isApplePlatform ? radiusMedium : radiusSmall,
          ),
        ),
        // Style alternatif pour chip sélectionné (fallback)
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: isApplePlatform ? 13 : 11.5,
          fontWeight: fontSemiBold,
          color: darkColorScheme.onPrimaryContainer,
          letterSpacing: isApplePlatform ? -0.1 : -0.2,
          height: 1.2,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: isApplePlatform ? 8 : 6),
        // Couleur de l'icône avec Material State
        iconTheme: IconThemeData(
          color: darkColorScheme.onSurfaceVariant,
          size: 16,
        ),
      ),
      
      // Configuration des listes
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: darkColorScheme.primaryContainer.withOpacity(0.1),
        iconColor: darkColorScheme.onSurfaceVariant,
        textColor: darkColorScheme.onSurface,
        titleTextStyle: GoogleFonts.inter(
          fontSize: fontSize16,
          fontWeight: fontMedium,
          color: darkColorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: fontSize14,
          color: darkColorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceSmall,
        ),
      ),
      
      // Configuration des switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.onPrimary;
          }
          return darkColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primary;
          }
          return darkColorScheme.surfaceVariant;
        }),
      ),
      
      // Configuration des checkboxes
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(darkColorScheme.onPrimary),
        side: BorderSide(color: darkColorScheme.outline),
      ),
      
      // Configuration des radio buttons
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primary;
          }
          return darkColorScheme.onSurfaceVariant;
        }),
      ),
      
      // Configuration des sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: darkColorScheme.primary,
        inactiveTrackColor: darkColorScheme.surfaceVariant,
        thumbColor: darkColorScheme.primary,
        overlayColor: darkColorScheme.primary.withOpacity(0.1),
        valueIndicatorColor: darkColorScheme.primary,
        valueIndicatorTextStyle: GoogleFonts.inter(
          color: darkColorScheme.onPrimary,
          fontWeight: fontSemiBold,
        ),
      ),
      
      // Configuration des progress indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: darkColorScheme.primary,
        linearTrackColor: darkColorScheme.surfaceVariant,
        circularTrackColor: darkColorScheme.surfaceVariant,
      ),
      
      // Configuration des dividers
      dividerTheme: DividerThemeData(
        color: darkColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      
      // Configuration des tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: GoogleFonts.inter(
          color: darkColorScheme.onInverseSurface,
          fontSize: fontSize12,
        ),
      ),
      
      // Configuration des snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkColorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.inter(
          color: darkColorScheme.onInverseSurface,
        ),
        actionTextColor: darkColorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      
      // Configuration des dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: darkColorScheme.surface,
        elevation: elevation5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: fontSize20,
          fontWeight: fontSemiBold,
          color: darkColorScheme.onSurface,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: fontSize16,
          color: darkColorScheme.onSurfaceVariant,
        ),
      ),
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