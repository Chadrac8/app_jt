import 'dart:io';

void main() async {
  final directory = Directory('lib');
  await fixMissingAppThemeImports(directory);
  print('Correction des imports AppTheme manquants terminée!');
}

Future<void> fixMissingAppThemeImports(Directory directory) async {
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await fixFileImports(entity);
    }
  }
}

Future<void> fixFileImports(File file) async {
  try {
    String content = await file.readAsString();
    
    // Vérifie si le fichier utilise AppTheme mais n'a pas l'import
    if (content.contains('AppTheme.') && !content.contains("import '../theme.dart';") && !content.contains("import '../../theme.dart';")) {
      
      // Détermine le chemin relatif correct vers theme.dart
      String relativePath = file.path;
      String themeImport = '';
      
      if (relativePath.contains('/lib/widgets/')) {
        themeImport = "../theme.dart";
      } else if (relativePath.contains('/lib/pages/')) {
        themeImport = "../theme.dart";
      } else if (relativePath.contains('/lib/modules/')) {
        // Compte le nombre de niveaux de profondeur
        String modulesPart = relativePath.split('/lib/modules/')[1];
        int levels = modulesPart.split('/').length - 1; // -1 car le dernier est le fichier
        themeImport = '../' * (levels + 1) + 'theme.dart';
      } else if (relativePath.contains('/lib/')) {
        // Pour les autres fichiers dans lib
        String libPart = relativePath.split('/lib/')[1];
        int levels = libPart.split('/').length - 1;
        themeImport = '../' * levels + 'theme.dart';
      }
      
      if (themeImport.isNotEmpty) {
        // Trouve la position après le dernier import
        List<String> lines = content.split('\n');
        int insertPosition = 0;
        
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            insertPosition = i + 1;
          } else if (lines[i].trim().isEmpty && insertPosition > 0) {
            // Ligne vide après les imports
            break;
          } else if (!lines[i].startsWith('import ') && !lines[i].trim().isEmpty && insertPosition > 0) {
            // Première ligne non-import et non-vide
            break;
          }
        }
        
        // Insère l'import
        lines.insert(insertPosition, "import '$themeImport';");
        
        String newContent = lines.join('\n');
        
        if (newContent != content) {
          await file.writeAsString(newContent);
          print('Import ajouté dans: ${file.path}');
        }
      }
    }
    
  } catch (e) {
    print('Erreur lors du traitement de ${file.path}: $e');
  }
}