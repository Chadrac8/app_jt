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
      
      // Corriger les expressions const avec withOpacity
      // Pattern: const Text(...style: TextStyle(...withOpacity...
      final regex = RegExp(
        r'const\s+Text\s*\(\s*([^,]+,\s*)?style:\s*TextStyle\s*\([^)]*\.withOpacity\([^)]*\)[^)]*\)',
        multiLine: true,
        dotAll: true
      );
      
      content = content.replaceAllMapped(regex, (match) {
        String matchText = match.group(0)!;
        // Remplacer 'const Text(' par 'Text('
        return matchText.replaceFirst('const Text(', 'Text(');
      });
      
      // Pattern plus simple: const Text avec TextStyle contenant withOpacity
      content = content.replaceAllMapped(
        RegExp(r'const\s+Text\s*\(\s*[^,]+,\s*style:\s*const\s+TextStyle\([^)]*withOpacity[^)]*\)[^)]*\)', 
               multiLine: true, dotAll: true),
        (match) => match.group(0)!.replaceFirst('const Text(', 'Text(').replaceFirst('const TextStyle(', 'TextStyle(')
      );
      
      // Pattern encore plus spécifique pour les cas simples
      content = content.replaceAllMapped(
        RegExp(r'const\s+Text\s*\(\s*([^,]+),\s*style:\s*TextStyle\s*\(\s*([^)]*withOpacity[^)]*)\s*\)\s*,?\s*\)', 
               multiLine: true, dotAll: true),
        (match) => match.group(0)!.replaceFirst('const Text(', 'Text(')
      );
      
      if (content != originalContent) {
        await file.writeAsString(content);
        modifiedFiles++;
        print('Corrigé: ${file.path}');
      }
    }
  }
  
  print('Correction terminée: $modifiedFiles fichiers modifiés sur $totalFiles fichiers analysés');
}