import 'dart:io';

void main() async {
  print('Correction des commentaires "Removed unused import"...');
  
  final directory = Directory('lib');
  int filesFixed = 0;
  
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      String originalContent = content;
      
      // Remplacer les commentaires par les vrais imports
      content = content.replaceAll("// Removed unused import '../../theme.dart';", "import '../theme.dart';");
      content = content.replaceAll("// Removed unused import '../theme.dart';", "import '../theme.dart';");
      content = content.replaceAll("// Removed unused import '../../../theme.dart';", "import '../../theme.dart';");
      content = content.replaceAll("// Removed unused import '../../../../theme.dart';", "import '../../../theme.dart';");
      
      if (content != originalContent) {
        await entity.writeAsString(content);
        print('Corrigé: ${entity.path}');
        filesFixed++;
      }
    }
  }
  
  print('Correction terminée! $filesFixed fichiers corrigés.');
}