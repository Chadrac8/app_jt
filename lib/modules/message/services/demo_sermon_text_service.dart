import 'package:flutter/services.dart' show rootBundle;

/// Service pour charger les textes de sermon de démonstration depuis les assets
class DemoSermonTextService {
  /// Charge le texte d'un sermon de démo depuis les assets
  static Future<String?> loadDemoSermonText(String sermonId) async {
    try {
      final path = 'assets/demo_sermons/$sermonId.html';
      final content = await rootBundle.loadString(path);
      return content;
    } catch (e) {
      print('Erreur lors du chargement du texte de démo pour $sermonId: $e');
      return null;
    }
  }

  /// Vérifie si un texte de démo existe pour un sermon donné
  static Future<bool> hasDemoText(String sermonId) async {
    try {
      await rootBundle.loadString('assets/demo_sermons/$sermonId.html');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Liste des sermons de démo disponibles
  static const List<String> availableDemoSermons = [
    '63-0317E',
    '65-1125',
  ];

  /// Obtient l'URL locale du texte de démo (pour utiliser avec rootBundle)
  static String getDemoTextAssetPath(String sermonId) {
    return 'assets/demo_sermons/$sermonId.html';
  }
}
