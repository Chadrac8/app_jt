import 'dart:io';

/// Script pour corriger les erreurs de couleur avec index (ex: AppTheme.greenStandard[600])
void main() async {
  final List<String> filesToProcess = await findDartFiles('lib');
  
  for (String filePath in filesToProcess) {
    await fixColorIndexErrors(filePath);
  }
  
  print('Correction des erreurs d\'index de couleur terminée !');
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

/// Corrige les erreurs d'index de couleur
Future<void> fixColorIndexErrors(String filePath) async {
  final file = File(filePath);
  String content = await file.readAsString();
  bool modified = false;
  
  // Remplacements pour corriger les erreurs d'index
  final Map<String, String> fixes = {
    // Couleurs avec index vers couleurs grises appropriées
    'AppTheme.greenStandard[50]': 'AppTheme.grey50',
    'AppTheme.greenStandard[100]': 'AppTheme.grey100',
    'AppTheme.greenStandard[200]': 'AppTheme.grey200',
    'AppTheme.greenStandard[300]': 'AppTheme.grey300',
    'AppTheme.greenStandard[400]': 'AppTheme.grey400',
    'AppTheme.greenStandard[500]': 'AppTheme.grey500',
    'AppTheme.greenStandard[600]': 'AppTheme.grey600',
    'AppTheme.greenStandard[700]': 'AppTheme.grey700',
    'AppTheme.greenStandard[800]': 'AppTheme.grey800',
    'AppTheme.greenStandard[900]': 'AppTheme.grey900',
    
    'AppTheme.blueStandard[50]': 'AppTheme.grey50',
    'AppTheme.blueStandard[100]': 'AppTheme.grey100',
    'AppTheme.blueStandard[200]': 'AppTheme.grey200',
    'AppTheme.blueStandard[300]': 'AppTheme.grey300',
    'AppTheme.blueStandard[400]': 'AppTheme.grey400',
    'AppTheme.blueStandard[500]': 'AppTheme.grey500',
    'AppTheme.blueStandard[600]': 'AppTheme.grey600',
    'AppTheme.blueStandard[700]': 'AppTheme.grey700',
    'AppTheme.blueStandard[800]': 'AppTheme.grey800',
    'AppTheme.blueStandard[900]': 'AppTheme.grey900',
    
    'AppTheme.redStandard[50]': 'AppTheme.grey50',
    'AppTheme.redStandard[100]': 'AppTheme.grey100',
    'AppTheme.redStandard[200]': 'AppTheme.grey200',
    'AppTheme.redStandard[300]': 'AppTheme.grey300',
    'AppTheme.redStandard[400]': 'AppTheme.grey400',
    'AppTheme.redStandard[500]': 'AppTheme.grey500',
    'AppTheme.redStandard[600]': 'AppTheme.grey600',
    'AppTheme.redStandard[700]': 'AppTheme.grey700',
    'AppTheme.redStandard[800]': 'AppTheme.grey800',
    'AppTheme.redStandard[900]': 'AppTheme.grey900',
    
    'AppTheme.orangeStandard[50]': 'AppTheme.grey50',
    'AppTheme.orangeStandard[100]': 'AppTheme.grey100',
    'AppTheme.orangeStandard[200]': 'AppTheme.grey200',
    'AppTheme.orangeStandard[300]': 'AppTheme.grey300',
    'AppTheme.orangeStandard[400]': 'AppTheme.grey400',
    'AppTheme.orangeStandard[500]': 'AppTheme.grey500',
    'AppTheme.orangeStandard[600]': 'AppTheme.grey600',
    'AppTheme.orangeStandard[700]': 'AppTheme.grey700',
    'AppTheme.orangeStandard[800]': 'AppTheme.grey800',
    'AppTheme.orangeStandard[900]': 'AppTheme.grey900',
    
    'AppTheme.pinkStandard[50]': 'AppTheme.grey50',
    'AppTheme.pinkStandard[100]': 'AppTheme.grey100',
    'AppTheme.pinkStandard[200]': 'AppTheme.grey200',
    'AppTheme.pinkStandard[300]': 'AppTheme.grey300',
    'AppTheme.pinkStandard[400]': 'AppTheme.grey400',
    'AppTheme.pinkStandard[500]': 'AppTheme.grey500',
    'AppTheme.pinkStandard[600]': 'AppTheme.grey600',
    'AppTheme.pinkStandard[700]': 'AppTheme.grey700',
    'AppTheme.pinkStandard[800]': 'AppTheme.grey800',
    'AppTheme.pinkStandard[900]': 'AppTheme.grey900',
  };
  
  // Appliquer les corrections
  for (var entry in fixes.entries) {
    if (content.contains(entry.key)) {
      content = content.replaceAll(entry.key, entry.value);
      modified = true;
    }
  }
  
  // Retirer les '!' inutiles après les remplacements
  content = content.replaceAll('AppTheme.grey50!', 'AppTheme.grey50');
  content = content.replaceAll('AppTheme.grey100!', 'AppTheme.grey100');
  content = content.replaceAll('AppTheme.grey200!', 'AppTheme.grey200');
  content = content.replaceAll('AppTheme.grey300!', 'AppTheme.grey300');
  content = content.replaceAll('AppTheme.grey400!', 'AppTheme.grey400');
  content = content.replaceAll('AppTheme.grey500!', 'AppTheme.grey500');
  content = content.replaceAll('AppTheme.grey600!', 'AppTheme.grey600');
  content = content.replaceAll('AppTheme.grey700!', 'AppTheme.grey700');
  content = content.replaceAll('AppTheme.grey800!', 'AppTheme.grey800');
  content = content.replaceAll('AppTheme.grey900!', 'AppTheme.grey900');
  
  // Sauvegarder le fichier si modifié
  if (modified) {
    await file.writeAsString(content);
    print('Corrigé: $filePath');
  }
}