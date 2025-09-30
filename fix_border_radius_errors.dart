import 'dart:io';

void main() async {
  final directory = Directory('lib');
  await fixBorderRadiusErrors(directory);
  print('Correction des erreurs BorderRadius terminée!');
}

Future<void> fixBorderRadiusErrors(Directory directory) async {
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await fixFileContent(entity);
    }
  }
}

Future<void> fixFileContent(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;
    
    // Correction pour borderRadius: AppTheme.radius...
    content = content.replaceAllMapped(
      RegExp(r'borderRadius:\s*AppTheme\.(radius\w+)(?![.]|\w)'),
      (match) => 'borderRadius: BorderRadius.circular(AppTheme.${match.group(1)})'
    );
    
    // Correction pour borderRadius: dans ClipRRect
    content = content.replaceAllMapped(
      RegExp(r'borderRadius:\s*AppTheme\.(radius\w+)(?=\s*[,)])', multiLine: true),
      (match) => 'borderRadius: BorderRadius.circular(AppTheme.${match.group(1)})'
    );
    
    // Correction pour BorderRadius.all avec AppTheme.radius...
    content = content.replaceAllMapped(
      RegExp(r'BorderRadius\.all\(\s*Radius\.circular\(\s*AppTheme\.(radius\w+)\s*\)\s*\)'),
      (match) => 'BorderRadius.circular(AppTheme.${match.group(1)})'
    );
    
    // Correction spéciale pour les cas où on a juste AppTheme.radius... sans contexte
    final lines = content.split('\n');
    final correctedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      // Recherche des patterns spécifiques où radius est utilisé directement
      if (line.contains('borderRadius:') && line.contains('AppTheme.radius')) {
        // Vérifie si ce n'est pas déjà encapsulé dans BorderRadius.circular
        if (!line.contains('BorderRadius.circular')) {
          line = line.replaceAllMapped(
            RegExp(r'borderRadius:\s*AppTheme\.(radius\w+)'),
            (match) => 'borderRadius: BorderRadius.circular(AppTheme.${match.group(1)})'
          );
        }
      }
      
      // Pour Material borderRadius
      if (line.contains('borderRadius:') && line.contains('AppTheme.radius') && !line.contains('BorderRadius.circular')) {
        line = line.replaceAllMapped(
          RegExp(r'AppTheme\.(radius\w+)(?![.]|\w)'),
          (match) => 'BorderRadius.circular(AppTheme.${match.group(1)})'
        );
      }
      
      // Pour ClipRRect borderRadius
      if (line.contains('ClipRRect') || (i > 0 && lines[i-1].contains('ClipRRect'))) {
        if (line.contains('borderRadius:') && line.contains('AppTheme.radius') && !line.contains('BorderRadius.circular')) {
          line = line.replaceAllMapped(
            RegExp(r'borderRadius:\s*AppTheme\.(radius\w+)'),
            (match) => 'borderRadius: BorderRadius.circular(AppTheme.${match.group(1)})'
          );
        }
      }
      
      correctedLines.add(line);
    }
    
    content = correctedLines.join('\n');
    
    // Si le contenu a changé, écrire le fichier
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Corrigé: ${file.path}');
    }
    
  } catch (e) {
    print('Erreur lors du traitement de ${file.path}: $e');
  }
}