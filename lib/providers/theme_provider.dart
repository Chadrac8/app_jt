import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

enum ThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isSystemDarkMode = false;
  SharedPreferences? _prefs;

  ThemeProvider() {
    _initializeTheme();
  }

  /// Mode de thème actuel
  ThemeMode get themeMode => _themeMode;
  
  /// Indique si le thème sombre est actif
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return _isSystemDarkMode;
    }
  }

  /// Thème Flutter actuel
  ThemeData get currentTheme => isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  /// Initialisation du thème
  Future<void> _initializeTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Charger la préférence sauvegardée
      final savedThemeIndex = _prefs?.getInt(_themePreferenceKey);
      if (savedThemeIndex != null && savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      }

      // Écouter les changements du thème système
      _updateSystemTheme();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du thème: $e');
    }
  }

  /// Mettre à jour le thème système
  void _updateSystemTheme() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isSystemDarkMode = brightness == Brightness.dark;
    
    // Configurer l'interface système selon le thème
    _updateSystemUIOverlay();
  }

  /// Configurer l'interface système selon le thème actuel
  void _updateSystemUIOverlay() {
    final isDark = isDarkMode;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark 
            ? const Color(0xFF1A110F) // Surface color dark
            : AppTheme.surface,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: isDark 
            ? const Color(0xFF534340) // Outline variant dark
            : AppTheme.outlineVariant,
      ),
    );
  }

  /// Changer le mode de thème
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    // Sauvegarder la préférence
    try {
      await _prefs?.setInt(_themePreferenceKey, mode.index);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du thème: $e');
    }
    
    // Mettre à jour l'interface système
    _updateSystemUIOverlay();
    
    notifyListeners();
  }

  /// Basculer entre thème clair et sombre
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Méthodes utilitaires pour obtenir des couleurs selon le thème
  
  /// Couleur de surface adaptative
  Color get adaptiveSurface => isDarkMode 
      ? const Color(0xFF1A110F) 
      : AppTheme.surface;

  /// Couleur de texte sur surface adaptative
  Color get adaptiveOnSurface => isDarkMode 
      ? const Color(0xFFF1DDD9) 
      : AppTheme.onSurface;

  /// Couleur de contour adaptative
  Color get adaptiveOutline => isDarkMode 
      ? const Color(0xFFA08C87) 
      : AppTheme.outline;

  /// Couleur primaire adaptative
  Color get adaptivePrimary => isDarkMode 
      ? const Color(0xFFFFB4A9) 
      : AppTheme.primaryColor;

  /// Couleur de container adaptative
  Color get adaptiveContainer => isDarkMode 
      ? const Color(0xFF6E0200) 
      : AppTheme.primaryContainer;

  /// Couleur d'erreur adaptative
  Color get adaptiveError => isDarkMode 
      ? const Color(0xFFFFB4AB) 
      : AppTheme.error;

  /// Couleur de succès adaptative
  Color get adaptiveSuccess => isDarkMode 
      ? const Color(0xFF6FFF81) 
      : AppTheme.success;

  /// Couleur d'information adaptative
  Color get adaptiveInfo => isDarkMode 
      ? const Color(0xFFD1E4FF) 
      : AppTheme.info;

  /// Couleur d'avertissement adaptative
  Color get adaptiveWarning => isDarkMode 
      ? const Color(0xFFFFDCC2) 
      : AppTheme.warning;

  /// Opacité pour overlay selon le thème
  double get adaptiveOverlayOpacity => isDarkMode ? 0.8 : 0.6;

  /// Couleur pour les dividers
  Color get adaptiveDivider => isDarkMode 
      ? const Color(0xFF534340) 
      : AppTheme.outlineVariant;

  /// Couleur pour les cartes
  Color get adaptiveCard => isDarkMode 
      ? const Color(0xFF2D1B17) 
      : AppTheme.white;

  /// Mettre à jour le thème système (appelé par l'app lors des changements système)
  void updateSystemBrightness() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final newSystemDarkMode = brightness == Brightness.dark;
    
    if (_isSystemDarkMode != newSystemDarkMode) {
      _isSystemDarkMode = newSystemDarkMode;
      _updateSystemUIOverlay();
      notifyListeners();
    }
  }

  /// Disposer des ressources
  @override
  void dispose() {
    super.dispose();
  }
}
