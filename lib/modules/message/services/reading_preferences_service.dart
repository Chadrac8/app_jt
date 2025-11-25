import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des préférences de lecture
class ReadingPreferencesService {
  static const String _keyDarkMode = 'reading_dark_mode';
  static const String _keyFontSize = 'reading_font_size';
  static const String _keyBrightness = 'reading_brightness';
  static const String _keyLineHeight = 'reading_line_height';
  static const String _keyFontFamily = 'reading_font_family';
  
  /// Obtient le mode sombre
  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }
  
  /// Définit le mode sombre
  static Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, enabled);
  }
  
  /// Obtient la taille de police (14-32)
  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 16.0;
  }
  
  /// Définit la taille de police
  static Future<void> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size.clamp(14.0, 32.0));
  }
  
  /// Obtient la luminosité (0.0-1.0)
  static Future<double> getBrightness() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyBrightness) ?? 1.0;
  }
  
  /// Définit la luminosité
  static Future<void> setBrightness(double brightness) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBrightness, brightness.clamp(0.0, 1.0));
  }
  
  /// Obtient la hauteur de ligne (1.0-2.0)
  static Future<double> getLineHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyLineHeight) ?? 1.5;
  }
  
  /// Définit la hauteur de ligne
  static Future<void> setLineHeight(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLineHeight, height.clamp(1.0, 2.0));
  }
  
  /// Obtient la famille de police
  static Future<String> getFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFontFamily) ?? 'System';
  }
  
  /// Définit la famille de police
  static Future<void> setFontFamily(String fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontFamily, fontFamily);
  }
  
  /// Obtient les préférences complètes
  static Future<ReadingPreferences> getPreferences() async {
    return ReadingPreferences(
      darkMode: await getDarkMode(),
      fontSize: await getFontSize(),
      brightness: await getBrightness(),
      lineHeight: await getLineHeight(),
      fontFamily: await getFontFamily(),
    );
  }
  
  /// Réinitialise les préférences par défaut
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyFontSize);
    await prefs.remove(_keyBrightness);
    await prefs.remove(_keyLineHeight);
    await prefs.remove(_keyFontFamily);
  }
}

/// Modèle des préférences de lecture
class ReadingPreferences {
  final bool darkMode;
  final double fontSize;
  final double brightness;
  final double lineHeight;
  final String fontFamily;
  
  const ReadingPreferences({
    this.darkMode = false,
    this.fontSize = 16.0,
    this.brightness = 1.0,
    this.lineHeight = 1.5,
    this.fontFamily = 'System',
  });
  
  ReadingPreferences copyWith({
    bool? darkMode,
    double? fontSize,
    double? brightness,
    double? lineHeight,
    String? fontFamily,
  }) {
    return ReadingPreferences(
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      brightness: brightness ?? this.brightness,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
  
  /// Couleur de fond selon le mode
  Color get backgroundColor => darkMode ? const Color(0xFF1A1A1A) : Colors.white;
  
  /// Couleur du texte selon le mode
  Color get textColor => darkMode ? const Color(0xFFE0E0E0) : Colors.black87;
  
  /// Couleur secondaire selon le mode
  Color get secondaryTextColor => darkMode ? const Color(0xFFB0B0B0) : Colors.black54;
  
  /// Style de texte pour le contenu
  TextStyle get contentTextStyle {
    String? actualFontFamily = fontFamily == 'System' ? null : fontFamily;
    
    return TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      color: textColor,
      fontFamily: actualFontFamily,
    );
  }
  
  /// Style de texte pour les titres
  TextStyle get titleTextStyle {
    String? actualFontFamily = fontFamily == 'System' ? null : fontFamily;
    
    return TextStyle(
      fontSize: fontSize + 4,
      height: lineHeight,
      fontWeight: FontWeight.bold,
      color: textColor,
      fontFamily: actualFontFamily,
    );
  }
  
  /// Theme data complet
  ThemeData get themeData {
    if (darkMode) {
      return ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        brightness: Brightness.dark,
      );
    } else {
      return ThemeData.light().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        brightness: Brightness.light,
      );
    }
  }
}

/// Familles de polices disponibles
class FontFamilies {
  static const List<String> available = [
    'System',
    'Serif',
    'Sans Serif',
    'Monospace',
  ];
  
  static String getActualFontFamily(String name) {
    switch (name) {
      case 'Serif':
        return 'serif';
      case 'Sans Serif':
        return 'sans-serif';
      case 'Monospace':
        return 'monospace';
      default:
        return '';
    }
  }
}
