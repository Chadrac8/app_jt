import 'dart:io';
import 'dart:convert';

void main() async {
  // Lire le fichier theme.dart pour obtenir les propriétés disponibles
  final themeFile = File('lib/theme.dart');
  final themeContent = await themeFile.readAsString();
  
  // Extraire les propriétés statiques de AppTheme
  final availableProperties = <String>{};
  final propertyRegex = RegExp(r'static\s+const\s+[A-Za-z0-9_<>]+\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=');
  
  for (final match in propertyRegex.allMatches(themeContent)) {
    availableProperties.add(match.group(1)!);
  }
  
  print('Propriétés disponibles dans AppTheme: ${availableProperties.length}');
  print('Exemples: ${availableProperties.take(10).join(', ')}...\n');
  
  // Scanner tous les fichiers pour trouver les utilisations d'AppTheme
  final usedProperties = <String>{};
  final invalidProperties = <String, List<String>>{};
  
  final libDir = Directory('lib');
  await for (final file in libDir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart') && !file.path.endsWith('/theme.dart')) {
      final content = await file.readAsString();
      final usageRegex = RegExp(r'AppTheme\.([a-zA-Z_][a-zA-Z0-9_]*)');
      
      for (final match in usageRegex.allMatches(content)) {
        final property = match.group(1)!;
        usedProperties.add(property);
        
        if (!availableProperties.contains(property)) {
          invalidProperties.putIfAbsent(property, () => []).add(file.path);
        }
      }
    }
  }
  
  print('Propriétés utilisées: ${usedProperties.length}');
  print('Propriétés invalides trouvées: ${invalidProperties.length}\n');
  
  if (invalidProperties.isNotEmpty) {
    print('⚠️  PROPRIÉTÉS INVALIDES DÉTECTÉES:');
    invalidProperties.forEach((property, files) {
      print('- AppTheme.$property');
      for (final file in files.take(3)) {
        print('  → $file');
      }
      if (files.length > 3) {
        print('  → ... et ${files.length - 3} autres fichiers');
      }
      print('');
    });
    
    // Suggestions de remplacement
    print('💡 SUGGESTIONS DE CORRECTION:');
    invalidProperties.keys.forEach((invalidProp) {
      final suggestions = availableProperties.where((validProp) => 
        validProp.toLowerCase().contains(invalidProp.toLowerCase().substring(0, 3)) ||
        invalidProp.toLowerCase().contains(validProp.toLowerCase().substring(0, 3))
      ).take(3);
      
      if (suggestions.isNotEmpty) {
        print('- $invalidProp → ${suggestions.join(' ou ')}');
      } else {
        print('- $invalidProp → Propriété à créer ou remplacer manuellement');
      }
    });
  } else {
    print('✅ Toutes les propriétés AppTheme utilisées sont valides !');
  }
}