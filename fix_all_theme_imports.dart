import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  
  await for (final file in libDir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      await fixThemeImport(file);
    }
  }
  
  print('Correction des imports terminée!');
}

Future<void> fixThemeImport(File file) async {
  try {
    final content = await file.readAsString();
    
    // Calculer le chemin relatif correct vers theme.dart
    final filePath = file.path.replaceFirst(RegExp(r'^.*\/lib\/'), '');
    final pathParts = filePath.split('/');
    final depth = pathParts.length - 1; // Exclure le nom du fichier
    
    String correctPath;
    if (depth == 0) {
      // Fichier directement dans lib/
      correctPath = 'theme.dart';
    } else {
      // Fichier dans un sous-dossier
      correctPath = '../' * depth + 'theme.dart';
    }
    
    // Remplacer les imports incorrects
    final patterns = [
      "import '../theme.dart';",
      "import '../../theme.dart';", 
      "import '../../../theme.dart';",
      "import '../../../../theme.dart';",
      "import 'theme.dart';",
    ];
    
    String newContent = content;
    bool hasChanged = false;
    
    for (final pattern in patterns) {
      if (newContent.contains(pattern) && pattern != "import '$correctPath';") {
        newContent = newContent.replaceAll(pattern, "import '$correctPath';");
        hasChanged = true;
      }
    }
    
    if (hasChanged) {
      await file.writeAsString(newContent);
      print('Corrigé: ${file.path} -> import \'$correctPath\';');
    }
  } catch (e) {
    print('Erreur avec ${file.path}: $e');
  }
}