import 'package:flutter/material.dart';
import '../services/reading_preferences_service.dart';

/// Provider pour gérer les préférences de lecture
class ReadingPreferencesProvider extends ChangeNotifier {
  ReadingPreferences _preferences = const ReadingPreferences();
  
  ReadingPreferences get preferences => _preferences;
  
  bool get darkMode => _preferences.darkMode;
  double get fontSize => _preferences.fontSize;
  double get brightness => _preferences.brightness;
  double get lineHeight => _preferences.lineHeight;
  String get fontFamily => _preferences.fontFamily;
  
  ReadingPreferencesProvider() {
    _loadPreferences();
  }
  
  /// Charge les préférences depuis le stockage
  Future<void> _loadPreferences() async {
    _preferences = await ReadingPreferencesService.getPreferences();
    notifyListeners();
  }
  
  /// Active/désactive le mode sombre
  Future<void> toggleDarkMode() async {
    await setDarkMode(!_preferences.darkMode);
  }
  
  /// Définit le mode sombre
  Future<void> setDarkMode(bool enabled) async {
    await ReadingPreferencesService.setDarkMode(enabled);
    _preferences = _preferences.copyWith(darkMode: enabled);
    notifyListeners();
  }
  
  /// Définit la taille de police
  Future<void> setFontSize(double size) async {
    await ReadingPreferencesService.setFontSize(size);
    _preferences = _preferences.copyWith(fontSize: size);
    notifyListeners();
  }
  
  /// Augmente la taille de police
  Future<void> increaseFontSize() async {
    final newSize = (_preferences.fontSize + 2).clamp(14.0, 32.0);
    await setFontSize(newSize);
  }
  
  /// Diminue la taille de police
  Future<void> decreaseFontSize() async {
    final newSize = (_preferences.fontSize - 2).clamp(14.0, 32.0);
    await setFontSize(newSize);
  }
  
  /// Définit la luminosité
  Future<void> setBrightness(double brightness) async {
    await ReadingPreferencesService.setBrightness(brightness);
    _preferences = _preferences.copyWith(brightness: brightness);
    notifyListeners();
  }
  
  /// Définit la hauteur de ligne
  Future<void> setLineHeight(double height) async {
    await ReadingPreferencesService.setLineHeight(height);
    _preferences = _preferences.copyWith(lineHeight: height);
    notifyListeners();
  }
  
  /// Définit la famille de police
  Future<void> setFontFamily(String fontFamily) async {
    await ReadingPreferencesService.setFontFamily(fontFamily);
    _preferences = _preferences.copyWith(fontFamily: fontFamily);
    notifyListeners();
  }
  
  /// Réinitialise aux valeurs par défaut
  Future<void> reset() async {
    await ReadingPreferencesService.reset();
    _preferences = const ReadingPreferences();
    notifyListeners();
  }
}
