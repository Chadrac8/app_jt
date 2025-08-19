// Test simple de la logique de navigation
void main() {
  print("Test de la logique de bottom navigation");
  
  // Simulation des données
  List<Map<String, dynamic>> primaryModules = [
    {'id': '1', 'titre': 'Module 1'},
    {'id': '2', 'titre': 'Module 2'},
    {'id': '3', 'titre': 'Module 3'},
    {'id': '4', 'titre': 'Module 4'},
    {'id': '5', 'titre': 'Module 5'},
  ];
  
  List<Map<String, dynamic>> secondaryModules = [
    {'id': '6', 'titre': 'Module Secondaire 1'},
    {'id': '7', 'titre': 'Module Secondaire 2'},
  ];
  
  testNavigationLogic(primaryModules, secondaryModules);
  
  // Test sans modules secondaires
  print("\n--- Test sans modules secondaires ---");
  testNavigationLogic(primaryModules, []);
  
  // Test avec moins de 5 modules primaires
  print("\n--- Test avec 3 modules primaires ---");
  testNavigationLogic(primaryModules.take(3).toList(), secondaryModules);
}

void testNavigationLogic(List<Map<String, dynamic>> primaryModules, 
                        List<Map<String, dynamic>> secondaryModules) {
  print("Modules primaires: ${primaryModules.length}");
  print("Modules secondaires: ${secondaryModules.length}");
  
  bool hasMoreItems = secondaryModules.isNotEmpty;
  int maxPrimaryItems = hasMoreItems ? 4 : 5;
  
  print("HasMoreItems: $hasMoreItems");
  print("MaxPrimaryItems: $maxPrimaryItems");
  
  List<Map<String, dynamic>> visiblePrimaryModules;
  List<Map<String, dynamic>> overflowPrimaryModules = [];
  
  if (primaryModules.length > maxPrimaryItems) {
    visiblePrimaryModules = primaryModules.take(maxPrimaryItems).toList();
    overflowPrimaryModules = primaryModules.skip(maxPrimaryItems).toList();
  } else {
    visiblePrimaryModules = primaryModules;
  }
  
  print("Modules primaires visibles: ${visiblePrimaryModules.length}");
  print("Modules primaires en overflow: ${overflowPrimaryModules.length}");
  
  // Construction des éléments de navigation
  List<String> navItems = [];
  
  // Ajouter les modules primaires visibles
  for (var module in visiblePrimaryModules) {
    navItems.add(module['titre']);
  }
  
  // Ajouter le bouton "Plus" si nécessaire
  if (hasMoreItems || overflowPrimaryModules.isNotEmpty) {
    navItems.add("Plus");
  }
  
  print("Éléments de navigation: ${navItems.length}");
  print("Items: ${navItems.join(', ')}");
  
  // Contenu du menu "Plus"
  if (hasMoreItems || overflowPrimaryModules.isNotEmpty) {
    List<String> moreMenuItems = [];
    
    // Ajouter les modules primaires en overflow
    for (var module in overflowPrimaryModules) {
      moreMenuItems.add(module['titre']);
    }
    
    // Ajouter les modules secondaires
    for (var module in secondaryModules) {
      moreMenuItems.add(module['titre']);
    }
    
    print("Menu 'Plus' contient: ${moreMenuItems.length} items");
    print("Items du menu Plus: ${moreMenuItems.join(', ')}");
  }
  
  // Vérification
  bool success = true;
  
  if (primaryModules.length <= 5 && secondaryModules.isEmpty) {
    // Tous les modules primaires doivent être visibles
    if (visiblePrimaryModules.length != primaryModules.length) {
      print("ERREUR: Tous les modules primaires devraient être visibles");
      success = false;
    }
    if (navItems.contains("Plus")) {
      print("ERREUR: Le bouton Plus ne devrait pas être présent");
      success = false;
    }
  } else if (primaryModules.length == 5 && secondaryModules.isNotEmpty) {
    // 4 modules primaires visibles + bouton Plus
    if (visiblePrimaryModules.length != 4) {
      print("ERREUR: 4 modules primaires devraient être visibles");
      success = false;
    }
    if (overflowPrimaryModules.length != 1) {
      print("ERREUR: 1 module primaire devrait être en overflow");
      success = false;
    }
    if (!navItems.contains("Plus")) {
      print("ERREUR: Le bouton Plus devrait être présent");
      success = false;
    }
  }
  
  if (success) {
    print("✅ Test réussi");
  } else {
    print("❌ Test échoué");
  }
}
