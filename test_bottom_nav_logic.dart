import 'package:flutter/material.dart';

void main() {
  // Test de la logique de bottom navigation
  testBottomNavigationLogic();
}

void testBottomNavigationLogic() {
  print('=== TEST BOTTOM NAVIGATION LOGIC ===');
  
  // Simuler 5 modules primaires
  final primaryModules = List.generate(5, (i) => 'Module ${i + 1}');
  
  // Simuler des modules secondaires
  final secondaryModules = ['Module secondaire 1', 'Module secondaire 2'];
  
  final hasMoreItems = secondaryModules.isNotEmpty;
  
  // Logique corrigée
  const maxTotalItems = 5;
  final maxPrimaryItems = hasMoreItems ? (maxTotalItems - 1) : maxTotalItems;
  
  final finalItems = primaryModules.take(maxPrimaryItems).toList();
  final remainingPrimaryItems = primaryModules.skip(maxPrimaryItems).toList();
  final hasMorePrimaryItems = remainingPrimaryItems.isNotEmpty;
  final shouldShowMoreButton = hasMoreItems || hasMorePrimaryItems;
  
  print('Modules primaires: ${primaryModules.length}');
  print('Modules secondaires: ${secondaryModules.length}');
  print('Max items total: $maxTotalItems');
  print('Max items primaires: $maxPrimaryItems');
  print('Items affichés: ${finalItems.length} => $finalItems');
  print('Items débordés: ${remainingPrimaryItems.length} => $remainingPrimaryItems');
  print('Bouton "Plus" nécessaire: $shouldShowMoreButton');
  
  // Simuler le contenu du menu "Plus"
  final allSecondaryItems = [...remainingPrimaryItems, ...secondaryModules];
  print('Contenu du menu "Plus": ${allSecondaryItems.length} => $allSecondaryItems');
  
  print('\n=== RÉSULTAT ===');
  if (shouldShowMoreButton) {
    print('Bottom Nav: ${finalItems.join(', ')}, Plus');
    print('Menu Plus: ${allSecondaryItems.join(', ')}');
  } else {
    print('Bottom Nav: ${finalItems.join(', ')}');
    print('Menu Plus: vide');
  }
}
