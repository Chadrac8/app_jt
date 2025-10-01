import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Dossier lib/ non trouvé');
    return;
  }

  int totalFiles = 0;

  await processDirectory(libDir, (fileCount) {
    totalFiles += fileCount;
  });

  print('\n🎉 Ajout des imports AppTheme terminé !');
  print('📊 $totalFiles fichiers traités');
}

Future<void> processDirectory(Directory dir, Function(int) callback) async {
  int totalFiles = 0;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      
      // Si le fichier utilise AppTheme mais n'importe pas theme.dart
      if (content.contains('AppTheme.') && 
          !content.contains("import '../theme.dart'") &&
          !content.contains("import '../../theme.dart'") &&
          !content.contains("import '../../../theme.dart'") &&
          !entity.path.endsWith('theme.dart')) {
        
        // Détermine le bon import selon la profondeur
        String importPath;
        final pathParts = entity.path.split('/');
        final libIndex = pathParts.indexOf('lib');
        final depth = pathParts.length - libIndex - 2; // -2 pour lib/ et le fichier
        
        if (depth == 0) {
          importPath = "import 'theme.dart';";
        } else if (depth == 1) {
          importPath = "import '../theme.dart';";
        } else if (depth == 2) {
          importPath = "import '../../theme.dart';";
        } else {
          importPath = "import '../../../theme.dart';";
        }

        // Trouve la ligne d'import à partir de laquelle insérer
        final lines = content.split('\n');
        int insertIndex = 0;
        
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            insertIndex = i + 1;
          } else if (lines[i].trim().isEmpty && insertIndex > 0) {
            break;
          }
        }

        // Insère l'import
        lines.insert(insertIndex, importPath);
        final newContent = lines.join('\n');
        
        await entity.writeAsString(newContent);
        totalFiles++;
        print('✅ ${entity.path}: import ajouté');
      }
    }
  }

  callback(totalFiles);
}