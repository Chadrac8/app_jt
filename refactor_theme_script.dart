import 'dart:io';

/// Script pour automatiser la refactorisation du thème
/// Remplace les couleurs, typographies et designs en dur par les références au theme.dart
void main() async {
  final List<String> filesToProcess = await findDartFiles('lib');
  
  for (String filePath in filesToProcess) {
    if (filePath.contains('theme.dart')) continue; // Ignorer le fichier theme.dart lui-même
    
    await refactorFile(filePath);
  }
  
  print('Refactorisation terminée !');
}

/// Trouve tous les fichiers Dart dans un répertoire
Future<List<String>> findDartFiles(String directory) async {
  final List<String> files = [];
  final dir = Directory(directory);
  
  await for (FileSystemEntity entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity.path);
    }
  }
  
  return files;
}

/// Refactorise un fichier en remplaçant les couleurs en dur
Future<void> refactorFile(String filePath) async {
  final file = File(filePath);
  String content = await file.readAsString();
  bool modified = false;
  
  // Vérifier si le fichier importe déjà le theme
  bool hasThemeImport = content.contains("import '../theme.dart'") || 
                       content.contains("import '../../theme.dart'") ||
                       content.contains("import '../../../theme.dart'");
  
  // Remplacements de couleurs communes
  final Map<String, String> colorReplacements = {
    'Colors.white': 'AppTheme.white100',
    'Colors.black': 'AppTheme.black100',
    'Colors.red': 'AppTheme.redStandard',
    'Colors.blue': 'AppTheme.blueStandard',
    'Colors.green': 'AppTheme.greenStandard',
    'Colors.orange': 'AppTheme.orangeStandard',
    'Colors.pink': 'AppTheme.pinkStandard',
    'Colors.grey': 'AppTheme.grey500',
    'Colors.grey[50]': 'AppTheme.grey50',
    'Colors.grey[100]': 'AppTheme.grey100',
    'Colors.grey[200]': 'AppTheme.grey200',
    'Colors.grey[300]': 'AppTheme.grey300',
    'Colors.grey[400]': 'AppTheme.grey400',
    'Colors.grey[500]': 'AppTheme.grey500',
    'Colors.grey[600]': 'AppTheme.grey600',
    'Colors.grey[700]': 'AppTheme.grey700',
    'Colors.grey[800]': 'AppTheme.grey800',
    'Colors.grey[900]': 'AppTheme.grey900',
  };
  
  // Remplacements de BorderRadius
  final Map<String, String> borderRadiusReplacements = {
    'BorderRadius.circular(8)': 'AppTheme.borderRadiusSmall',
    'BorderRadius.circular(12)': 'AppTheme.borderRadiusMedium',
    'BorderRadius.circular(16)': 'AppTheme.borderRadiusLarge',
    'BorderRadius.circular(20)': 'AppTheme.borderRadiusXLarge',
    'BorderRadius.circular(32)': 'AppTheme.borderRadiusRound',
  };
  
  // Remplacements de FontWeight
  final Map<String, String> fontWeightReplacements = {
    'FontWeight.w300': 'AppTheme.fontLight',
    'FontWeight.w400': 'AppTheme.fontRegular',
    'FontWeight.w500': 'AppTheme.fontMedium',
    'FontWeight.w600': 'AppTheme.fontSemiBold',
    'FontWeight.w700': 'AppTheme.fontBold',
    'FontWeight.w800': 'AppTheme.fontExtraBold',
    'FontWeight.bold': 'AppTheme.fontBold',
  };
  
  // Appliquer les remplacements de couleurs
  for (var entry in colorReplacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }
  
  // Appliquer les remplacements de BorderRadius
  for (var entry in borderRadiusReplacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }
  
  // Appliquer les remplacements de FontWeight
  for (var entry in fontWeightReplacements.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }
  
  // Ajouter l'import du theme si nécessaire et si des modifications ont été faites
  if (modified && !hasThemeImport) {
    // Déterminer le bon chemin d'import selon le niveau du fichier
    String importPath = '../theme.dart';
    if (filePath.contains('/pages/')) importPath = '../theme.dart';
    else if (filePath.contains('/widgets/')) importPath = '../theme.dart';
    else if (filePath.contains('/modules/')) {
      if (filePath.split('/modules/').last.split('/').length > 2) {
        importPath = '../../../theme.dart';
      } else {
        importPath = '../../theme.dart';
      }
    }
    
    // Trouver la position pour insérer l'import
    final lines = content.split('\n');
    int insertPosition = 0;
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ') && !lines[i].contains('dart:')) {
        insertPosition = i + 1;
      } else if (lines[i].startsWith('import ') && lines[i].contains('dart:')) {
        if (insertPosition == 0) insertPosition = i + 1;
      }
    }
    
    lines.insert(insertPosition, "import '$importPath';");
    content = lines.join('\n');
  }
  
  // Sauvegarder le fichier si modifié
  if (modified) {
    await file.writeAsString(content);
    print('Refactorisé: $filePath');
  }
}