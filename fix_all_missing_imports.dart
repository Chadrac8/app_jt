import 'dart:io';

void main() async {
  print('Recherche de tous les imports AppTheme manquants...');
  
  final directory = Directory('lib');
  List<String> filesWithMissingImports = [];
  
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      
      // Vérifie si le fichier utilise AppTheme mais n'a pas l'import
      bool usesAppTheme = content.contains('AppTheme.');
      bool hasImport = content.contains("import '../theme.dart';") || 
                      content.contains("import '../../theme.dart';") ||
                      content.contains("import '../../../theme.dart';") ||
                      content.contains("import '../../../../theme.dart';");
      
      if (usesAppTheme && !hasImport) {
        filesWithMissingImports.add(entity.path);
      }
    }
  }
  
  print('Fichiers trouvés avec imports manquants: ${filesWithMissingImports.length}');
  
  for (String filePath in filesWithMissingImports) {
    await addThemeImport(File(filePath));
  }
  
  print('Correction terminée!');
}

Future<void> addThemeImport(File file) async {
  try {
    String content = await file.readAsString();
    
    // Détermine le chemin relatif correct vers theme.dart
    String relativePath = file.path;
    String themeImport = '';
    
    if (relativePath.contains('/lib/widgets/')) {
      themeImport = "../theme.dart";
    } else if (relativePath.contains('/lib/pages/')) {
      themeImport = "../theme.dart";
    } else if (relativePath.contains('/lib/services/')) {
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
      // Remplace les commentaires de removed unused import
      content = content.replaceAll("// Removed unused import '../../theme.dart';", "import '$themeImport';");
      content = content.replaceAll("// Removed unused import '../theme.dart';", "import '$themeImport';");
      
      // Si toujours pas d'import, l'ajoute après les autres imports
      if (!content.contains("import '$themeImport';")) {
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
        content = lines.join('\n');
      }
      
      await file.writeAsString(content);
      print('Import ajouté dans: ${file.path}');
    }
    
  } catch (e) {
    print('Erreur lors du traitement de ${file.path}: $e');
  }
}