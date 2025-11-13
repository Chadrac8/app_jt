import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' as providers;
import '../theme.dart';

/// Utilitaires pour les couleurs adaptatives selon le thème
class ThemeColors {
  /// Obtenir le ThemeProvider depuis le contexte
  static providers.ThemeProvider _getProvider(BuildContext context) {
    return Provider.of<providers.ThemeProvider>(context, listen: false);
  }

  /// Couleur de surface adaptative
  static Color surface(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFF1A110F) 
        : AppTheme.surface;
  }

  /// Couleur de texte sur surface adaptative
  static Color onSurface(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFF1DDD9) 
        : AppTheme.onSurface;
  }

  /// Couleur primaire adaptative
  static Color primary(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFFFB4A9) 
        : AppTheme.primaryColor;
  }

  /// Couleur de container adaptative
  static Color primaryContainer(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFF6E0200) 
        : AppTheme.primaryContainer;
  }

  /// Couleur de texte sur container primaire
  static Color onPrimaryContainer(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFFFDAD4) 
        : AppTheme.onPrimaryContainer;
  }

  /// Couleur de contour adaptative
  static Color outline(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFA08C87) 
        : AppTheme.outline;
  }

  /// Couleur d'erreur adaptative
  static Color error(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFFFB4AB) 
        : AppTheme.error;
  }

  /// Couleur de succès adaptative
  static Color success(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFF6FFF81) 
        : AppTheme.success;
  }

  /// Couleur d'information adaptative
  static Color info(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFD1E4FF) 
        : AppTheme.info;
  }

  /// Couleur d'avertissement adaptative
  static Color warning(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFFFFDCC2) 
        : AppTheme.warning;
  }

  /// Couleur pour les cartes
  static Color card(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFF2D1B17) 
        : AppTheme.white;
  }

  /// Couleur pour les dividers
  static Color divider(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode 
        ? const Color(0xFF534340) 
        : AppTheme.outlineVariant;
  }

  /// Opacité pour overlay selon le thème
  static double overlayOpacity(BuildContext context) {
    final provider = _getProvider(context);
    return provider.isDarkMode ? 0.8 : 0.6;
  }
}

/// Extension pour faciliter l'utilisation des couleurs adaptatives
extension AdaptiveColors on BuildContext {
  /// Couleur de surface adaptative
  Color get adaptiveSurface => ThemeColors.surface(this);

  /// Couleur de texte sur surface adaptative
  Color get adaptiveOnSurface => ThemeColors.onSurface(this);

  /// Couleur primaire adaptative
  Color get adaptivePrimary => ThemeColors.primary(this);

  /// Couleur de container adaptative
  Color get adaptivePrimaryContainer => ThemeColors.primaryContainer(this);

  /// Couleur de texte sur container primaire
  Color get adaptiveOnPrimaryContainer => ThemeColors.onPrimaryContainer(this);

  /// Couleur de contour adaptative
  Color get adaptiveOutline => ThemeColors.outline(this);

  /// Couleur d'erreur adaptative
  Color get adaptiveError => ThemeColors.error(this);

  /// Couleur de succès adaptative
  Color get adaptiveSuccess => ThemeColors.success(this);

  /// Couleur d'information adaptative
  Color get adaptiveInfo => ThemeColors.info(this);

  /// Couleur d'avertissement adaptative
  Color get adaptiveWarning => ThemeColors.warning(this);

  /// Couleur pour les cartes
  Color get adaptiveCard => ThemeColors.card(this);

  /// Couleur pour les dividers
  Color get adaptiveDivider => ThemeColors.divider(this);

  /// Opacité pour overlay selon le thème
  double get adaptiveOverlayOpacity => ThemeColors.overlayOpacity(this);

  /// Vérifier si le thème sombre est actif
  bool get isDarkMode {
    final provider = Provider.of<providers.ThemeProvider>(this, listen: false);
    return provider.isDarkMode;
  }

  /// Obtenir le provider de thème
  providers.ThemeProvider get themeProvider {
    return Provider.of<providers.ThemeProvider>(this, listen: false);
  }
}

/// Widget builder pour réagir aux changements de thème
class ThemeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isDarkMode) builder;

  const ThemeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        return builder(context, themeProvider.isDarkMode);
      },
    );
  }
}

/// Mixin pour les widgets qui ont besoin de réagir au thème
mixin ThemeAware<T extends StatefulWidget> on State<T> {
  bool get isDarkMode => context.isDarkMode;
  providers.ThemeProvider get themeProvider => context.themeProvider;
  
  /// Override cette méthode pour réagir aux changements de thème
  void onThemeChanged(bool isDarkMode) {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onThemeChanged(isDarkMode);
  }
}

/// Couleurs spécifiques au thème de l'église
class ChurchThemeColors {
  /// Rouge principal de la croix - adaptif
  static Color cross(BuildContext context) {
    return context.isDarkMode 
        ? const Color(0xFFFFB4A9) // Rouge clair pour le sombre
        : AppTheme.primaryColor;   // Rouge original pour le clair
  }

  /// Couleur dorée spirituelle - adaptif
  static Color spiritual(BuildContext context) {
    return context.isDarkMode 
        ? const Color(0xFFDFC38C) // Doré clair pour le sombre
        : AppTheme.tertiaryColor; // Doré original pour le clair
  }

  /// Couleur pour les textes spirituels/citations
  static Color spiritualText(BuildContext context) {
    return context.isDarkMode 
        ? const Color(0xFFFCDFA6) // Texte doré clair pour le sombre
        : AppTheme.onTertiaryContainer; // Texte original pour le clair
  }

  /// Couleur pour les éléments de prière/méditation
  static Color prayer(BuildContext context) {
    return context.isDarkMode 
        ? const Color(0xFFE7BDB6) // Brun-rouge clair pour le sombre
        : AppTheme.secondaryColor; // Brun-rouge original pour le clair
  }

  /// Background pour les sections spirituelles
  static Color spiritualBackground(BuildContext context) {
    return context.isDarkMode 
        ? const Color(0xFF564419) // Container tertiary dark
        : AppTheme.tertiaryContainer; // Container tertiary light
  }

  /// Couleur pour les statuts actifs/bénis
  static Color blessed(BuildContext context) {
    return context.isDarkMode 
        ? const Color(0xFF6FFF81) // Vert succès clair pour le sombre
        : AppTheme.success; // Vert succès original pour le clair
  }
}