import 'dart:io';

void main() async {
  print('Recherche des couleurs AppTheme manquantes...');
  
  // Lire le fichier theme.dart pour voir les couleurs existantes
  String themeContent = await File('lib/theme.dart').readAsString();
  
  // Rechercher toutes les utilisations de AppTheme. dans le code
  final directory = Directory('lib');
  Set<String> missingColors = {};
  
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      
      // Extraire toutes les références AppTheme.quelqueChose
      RegExp appThemePattern = RegExp(r'AppTheme\.(\w+)');
      Iterable<RegExpMatch> matches = appThemePattern.allMatches(content);
      
      for (RegExpMatch match in matches) {
        String colorName = match.group(1)!;
        
        // Vérifier si cette couleur existe dans theme.dart
        if (!themeContent.contains('static const Color $colorName') && 
            !themeContent.contains('static Color get $colorName') &&
            !themeContent.contains('static const double $colorName') &&
            !themeContent.contains('static const FontWeight $colorName') &&
            !themeContent.contains('static ThemeData get $colorName') &&
            !themeContent.contains('static BorderRadius get $colorName') &&
            !colorName.startsWith('space') && 
            !colorName.startsWith('radius') && 
            !colorName.startsWith('elevation') &&
            !colorName.startsWith('font') &&
            !colorName.startsWith('border') &&
            !colorName.startsWith('light') &&
            !colorName.startsWith('dark') &&
            !colorName.startsWith('color')) {
          missingColors.add(colorName);
        }
      }
    }
  }
  
  print('Couleurs manquantes trouvées:');
  for (String color in missingColors) {
    print('  - $color');
  }
  
  print('\nTotal: ${missingColors.length} couleurs manquantes');
}