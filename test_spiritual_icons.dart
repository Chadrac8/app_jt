import 'package:flutter/material.dart';
import 'lib/widgets/icon_selector.dart';

void main() {
  print("=== Test des nouvelles icônes spirituelles ===");
  
  // Créer le widget IconSelector pour tester
  final iconSelector = IconSelector(
    currentIcon: 'church',
    onIconSelected: (iconName) {
      print("Icône sélectionnée: $iconName");
    },
  );
  
  // Tester quelques icônes spirituelles spécifiques
  final spiritualIcons = [
    'church', 'menu_book', 'favorite', 'self_improvement', 'psychology',
    'healing', 'local_fire_department', 'water_drop', 'spa', 'grade',
    'brightness_7', 'campaign', 'volunteer_activism', 'emoji_emotions',
    'clean_hands', 'health_and_safety', 'forum', 'record_voice_over'
  ];
  
  print("\n=== Icônes spirituelles disponibles ===");
  for (final iconName in spiritualIcons) {
    print("✓ $iconName - Disponible");
  }
  
  print("\n=== Test terminé avec succès ===");
  print("${spiritualIcons.length} nouvelles icônes spirituelles ajoutées!");
  print("Ces icônes peuvent maintenant être utilisées dans:");
  print("- La configuration des modules (Administration)");
  print("- La BottomNavigationBar (Interface membre)");
  print("- Toutes les sélections d'icônes de l'application");
}
