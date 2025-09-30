import 'dart:io';

void main() async {
  final mappings = {
    // Corrections des propriétés de rayon de bordure
    'AppTheme.borderRadiusSmall': 'AppTheme.radiusSmall',
    'AppTheme.borderRadiusMedium': 'AppTheme.radiusMedium', 
    'AppTheme.borderRadiusLarge': 'AppTheme.radiusLarge',
    'AppTheme.borderRadiusXLarge': 'AppTheme.radiusXLarge',
    'AppTheme.borderRadiusRound': 'AppTheme.radiusRound',
    
    // Corrections des propriétés de couleurs manquantes
    'AppTheme.pinkStandardAccent': 'AppTheme.primaryColor',
    'AppTheme.orangeStandardAccent': 'AppTheme.warningColor',
    
    // Pour lightTheme, il faut créer une approche différente car c'est un ThemeData
  };
  
  final libDir = Directory('lib');
  int totalFiles = 0;
  int modifiedFiles = 0;
  
  await for (final file in libDir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      totalFiles++;
      
      String content = await file.readAsString();
      String originalContent = content;
      
      // Appliquer tous les mappings
      mappings.forEach((oldProperty, newProperty) {
        content = content.replaceAll(oldProperty, newProperty);
      });
      
      if (content != originalContent) {
        await file.writeAsString(content);
        modifiedFiles++;
        print('Corrigé: ${file.path}');
      }
    }
  }
  
  print('Mappings appliqués: $modifiedFiles fichiers modifiés sur $totalFiles fichiers analysés');
  
  // Cas spécial pour lightTheme - chercher et signaler
  print('\n🔍 Recherche de AppTheme.lightTheme...');
  await for (final file in libDir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = await file.readAsString();
      if (content.contains('AppTheme.lightTheme')) {
        print('⚠️  AppTheme.lightTheme trouvé dans: ${file.path}');
        // Ces cas nécessitent une correction manuelle car lightTheme doit être remplacé
        // par une méthode qui retourne un ThemeData complet
      }
    }
  }
}