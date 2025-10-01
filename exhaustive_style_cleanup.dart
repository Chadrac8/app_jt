#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🚀 DÉMARRAGE DU NETTOYAGE EXHAUSTIF - TOUS LES FICHIERS');
  
  // Configuration des remplacements
  final Map<String, String> colorReplacements = {
    // Colors.amber variants
    'Colors.amber[50]': 'AppTheme.warning.withAlpha(25)',
    'Colors.amber[100]': 'AppTheme.warning.withAlpha(51)',
    'Colors.amber[200]': 'AppTheme.warning.withAlpha(102)',
    'Colors.amber[300]': 'AppTheme.warning.withAlpha(153)',
    'Colors.amber[400]': 'AppTheme.warning.withAlpha(204)',
    'Colors.amber[500]': 'AppTheme.warning',
    'Colors.amber[600]': 'AppTheme.warning',
    'Colors.amber[700]': 'AppTheme.warning',
    'Colors.amber[800]': 'AppTheme.warning',
    'Colors.amber[900]': 'AppTheme.warning',
    'Colors.amber': 'AppTheme.warningColor',
    'Colors.amber.withOpacity(0.05)': 'AppTheme.warning.withAlpha(13)',
    'Colors.amber.withOpacity(0.1)': 'AppTheme.warning.withAlpha(25)',
    'Colors.amber.withOpacity(0.2)': 'AppTheme.warning.withAlpha(51)',
    'Colors.amber.withOpacity(0.3)': 'AppTheme.warning.withAlpha(76)',
    'Colors.amber.withOpacity(0.6)': 'AppTheme.warning.withAlpha(153)',
    
    // Colors.purple variants
    'Colors.purple[50]': 'AppTheme.primaryColor.withAlpha(25)',
    'Colors.purple[100]': 'AppTheme.primaryColor.withAlpha(51)',
    'Colors.purple[200]': 'AppTheme.primaryColor.withAlpha(102)',
    'Colors.purple[300]': 'AppTheme.primaryColor.withAlpha(153)',
    'Colors.purple[400]': 'AppTheme.primaryColor.withAlpha(204)',
    'Colors.purple[500]': 'AppTheme.primaryColor',
    'Colors.purple[600]': 'AppTheme.primaryColor',
    'Colors.purple[700]': 'AppTheme.primaryColor',
    'Colors.purple[800]': 'AppTheme.primaryColor',
    'Colors.purple[900]': 'AppTheme.primaryColor',
    'Colors.purple': 'AppTheme.primaryColor',
    'Colors.purple.withOpacity(0.1)': 'AppTheme.primaryColor.withAlpha(25)',
    
    // Colors.indigo variants
    'Colors.indigo[50]': 'AppTheme.secondaryColor.withAlpha(25)',
    'Colors.indigo[100]': 'AppTheme.secondaryColor.withAlpha(51)',
    'Colors.indigo[200]': 'AppTheme.secondaryColor.withAlpha(102)',
    'Colors.indigo[300]': 'AppTheme.secondaryColor.withAlpha(153)',
    'Colors.indigo[400]': 'AppTheme.secondaryColor.withAlpha(204)',
    'Colors.indigo[500]': 'AppTheme.secondaryColor',
    'Colors.indigo[600]': 'AppTheme.secondaryColor',
    'Colors.indigo[700]': 'AppTheme.secondaryColor',
    'Colors.indigo[800]': 'AppTheme.secondaryColor',
    'Colors.indigo[900]': 'AppTheme.secondaryColor',
    'Colors.indigo': 'AppTheme.secondaryColor',
    
    // Colors.green variants
    'Colors.green[50]': 'AppTheme.successColor.withAlpha(25)',
    'Colors.green[100]': 'AppTheme.successColor.withAlpha(51)',
    'Colors.green[200]': 'AppTheme.successColor.withAlpha(102)',
    'Colors.green[300]': 'AppTheme.successColor.withAlpha(153)',
    'Colors.green[400]': 'AppTheme.successColor.withAlpha(204)',
    'Colors.green[500]': 'AppTheme.successColor',
    'Colors.green[600]': 'AppTheme.successColor',
    'Colors.green[700]': 'AppTheme.successColor',
    'Colors.green[800]': 'AppTheme.successColor',
    'Colors.green[900]': 'AppTheme.successColor',
    'Colors.green': 'AppTheme.successColor',
    
    // Colors.red variants  
    'Colors.red[50]': 'AppTheme.errorColor.withAlpha(25)',
    'Colors.red[100]': 'AppTheme.errorColor.withAlpha(51)',
    'Colors.red[200]': 'AppTheme.errorColor.withAlpha(102)',
    'Colors.red[300]': 'AppTheme.errorColor.withAlpha(153)',
    'Colors.red[400]': 'AppTheme.errorColor.withAlpha(204)',
    'Colors.red[500]': 'AppTheme.errorColor',
    'Colors.red[600]': 'AppTheme.errorColor',
    'Colors.red[700]': 'AppTheme.errorColor',
    'Colors.red[800]': 'AppTheme.errorColor',
    'Colors.red[900]': 'AppTheme.errorColor',
    'Colors.red': 'AppTheme.errorColor',
    
    // Colors.blue variants
    'Colors.blue[50]': 'AppTheme.infoColor.withAlpha(25)',
    'Colors.blue[100]': 'AppTheme.infoColor.withAlpha(51)',
    'Colors.blue[200]': 'AppTheme.infoColor.withAlpha(102)',
    'Colors.blue[300]': 'AppTheme.infoColor.withAlpha(153)',
    'Colors.blue[400]': 'AppTheme.infoColor.withAlpha(204)',
    'Colors.blue[500]': 'AppTheme.infoColor',
    'Colors.blue[600]': 'AppTheme.infoColor',
    'Colors.blue[700]': 'AppTheme.infoColor',
    'Colors.blue[800]': 'AppTheme.infoColor',
    'Colors.blue[900]': 'AppTheme.infoColor',
    'Colors.blue': 'AppTheme.infoColor',
    
    // Colors.orange variants
    'Colors.orange[50]': 'AppTheme.warning.withAlpha(25)',
    'Colors.orange[100]': 'AppTheme.warning.withAlpha(51)',
    'Colors.orange[200]': 'AppTheme.warning.withAlpha(102)',
    'Colors.orange[300]': 'AppTheme.warning.withAlpha(153)',
    'Colors.orange[400]': 'AppTheme.warning.withAlpha(204)',
    'Colors.orange[500]': 'AppTheme.warning',
    'Colors.orange[600]': 'AppTheme.warning',
    'Colors.orange[700]': 'AppTheme.warning',
    'Colors.orange[800]': 'AppTheme.warning',
    'Colors.orange[900]': 'AppTheme.warning',
    'Colors.orange': 'AppTheme.warning',
    
    // Colors.grey variants
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
    'Colors.grey': 'AppTheme.grey500',
    
    // Autres couleurs spécialisées
    'Colors.deepPurple': 'AppTheme.primaryDark',
    'Colors.deepOrange': 'AppTheme.warningColor',
    'Colors.cyan': 'AppTheme.infoColor',
    'Colors.teal': 'AppTheme.secondaryColor',
    'Colors.brown': 'AppTheme.tertiaryColor',
    'Colors.pink': 'AppTheme.pinkStandard',
    'Colors.lime': 'AppTheme.successColor',
    
    // Variantes avec ! (non-null assertion)
    'Colors.amber[50]!': 'AppTheme.warning.withAlpha(25)',
    'Colors.amber[100]!': 'AppTheme.warning.withAlpha(51)',
    'Colors.amber[600]!': 'AppTheme.warning',
    'Colors.amber[700]!': 'AppTheme.warning',
    'Colors.purple[100]!': 'AppTheme.primaryColor.withAlpha(51)',
    'Colors.purple[200]!': 'AppTheme.primaryColor.withAlpha(102)',
    'Colors.purple[700]!': 'AppTheme.primaryColor',
    'Colors.purple[800]!': 'AppTheme.primaryColor',
    'Colors.green.shade100': 'AppTheme.successContainer',
    'Colors.green.shade800': 'AppTheme.successColor',  
    'Colors.red.shade100': 'AppTheme.errorContainer',
    'Colors.red.shade800': 'AppTheme.errorColor',
  };
  
  // Obtenir tous les fichiers .dart dans lib/
  final libDir = Directory('lib');
  final dartFiles = <File>[];
  
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      dartFiles.add(entity);
    }
  }
  
  print('📁 ${dartFiles.length} fichiers .dart trouvés');
  
  int totalReplacements = 0;
  List<String> modifiedFiles = [];
  
  for (final file in dartFiles) {
    try {
      String content = await file.readAsString();
      String originalContent = content;
      
      // Appliquer tous les remplacements
      for (final replacement in colorReplacements.entries) {
        if (content.contains(replacement.key)) {
          content = content.replaceAll(replacement.key, replacement.value);
          totalReplacements++;
        }
      }
      
      // Si le fichier a été modifié, l'écrire
      if (content != originalContent) {
        await file.writeAsString(content);
        modifiedFiles.add(file.path);
        print('✅ ${file.path} - Modifié');
      }
    } catch (e) {
      print('❌ Erreur avec ${file.path}: $e');
    }
  }
  
  print('\n🎉 NETTOYAGE TERMINÉ !');
  print('📊 ${totalReplacements} remplacements effectués');
  print('📁 ${modifiedFiles.length} fichiers modifiés');
  print('\n📋 Fichiers modifiés:');
  for (final file in modifiedFiles) {
    print('  • $file');
  }
  
  // Vérifier que les imports AppTheme sont présents
  print('\n🔍 Vérification des imports AppTheme...');
  await _checkAndAddAppThemeImports(modifiedFiles);
  
  print('\n✨ SUCCÈS COMPLET ! Votre application a maintenant un style uniforme.');
}

Future<void> _checkAndAddAppThemeImports(List<String> modifiedFiles) async {
  for (final filePath in modifiedFiles) {
    final file = File(filePath);
    String content = await file.readAsString();
    
    // Si le fichier utilise AppTheme mais n'a pas l'import
    if (content.contains('AppTheme.') && !content.contains("import '../theme.dart'") && !content.contains("import '../../theme.dart'") && !content.contains("import '../../../theme.dart'")) {
      
      // Déterminer le niveau d'imbrication pour l'import correct
      final pathParts = filePath.split('/');
      final libIndex = pathParts.indexWhere((part) => part == 'lib');
      if (libIndex == -1) continue;
      
      final depth = pathParts.length - libIndex - 2; // -2 pour lib et le fichier lui-même
      final importPath = '../' * depth + 'theme.dart';
      
      // Trouver la position après les imports existants
      final lines = content.split('\n');
      int insertIndex = 0;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ')) {
          insertIndex = i + 1;
        } else if (lines[i].trim().isEmpty && insertIndex > 0) {
          break;
        }
      }
      
      // Ajouter l'import
      lines.insert(insertIndex, "import '$importPath';");
      content = lines.join('\n');
      
      await file.writeAsString(content);
      print('📦 Import ajouté dans $filePath');
    }
  }
}