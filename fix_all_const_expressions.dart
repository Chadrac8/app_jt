import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  int totalFiles = 0;
  int modifiedFiles = 0;
  
  await for (final file in libDir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      totalFiles++;
      
      String content = await file.readAsString();
      String originalContent = content;
      
      // Pattern pour corriger const TextStyle avec withOpacity
      RegExp pattern = RegExp(
        r'const\s+TextStyle\s*\(\s*([^)]*withOpacity[^)]*)\s*\)',
        multiLine: true,
        dotAll: true
      );
      
      content = content.replaceAllMapped(pattern, (match) {
        String fullMatch = match.group(0)!;
        // Remplacer 'const TextStyle(' par 'TextStyle('
        return fullMatch.replaceFirst('const TextStyle(', 'TextStyle(');
      });
      
      // Pattern plus large pour capturer d'autres cas
      RegExp pattern2 = RegExp(
        r'const\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(\s*([^)]*\.withOpacity\([^)]*\)[^)]*)\s*\)',
        multiLine: true,
        dotAll: true
      );
      
      content = content.replaceAllMapped(pattern2, (match) {
        String className = match.group(1)!;
        String params = match.group(2)!;
        return '$className($params)';
      });
      
      if (content != originalContent) {
        await file.writeAsString(content);
        modifiedFiles++;
        print('Corrigé: ${file.path}');
      }
    }
  }
  
  print('Correction terminée: $modifiedFiles fichiers modifiés sur $totalFiles fichiers analysés');
}