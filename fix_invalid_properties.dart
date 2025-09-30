import 'dart:io';

void main() async {
  // Corriger les erreurs de propriétés AppTheme incorrectes
  final fixes = [
    // Corrections des erreurs de propriétés avec des nombres incorrects
    {'from': 'AppTheme.black10012', 'to': 'AppTheme.black100'},
    {'from': 'AppTheme.black10054', 'to': 'AppTheme.black100'},
    {'from': 'AppTheme.black10026', 'to': 'AppTheme.black100'},
    {'from': 'AppTheme.black10045', 'to': 'AppTheme.black100'},
    {'from': 'AppTheme.grey5000', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.white10024', 'to': 'AppTheme.white100'},
    {'from': 'AppTheme.white10054', 'to': 'AppTheme.white100'},
    {'from': 'AppTheme.white10060', 'to': 'AppTheme.white100'},
  ];
  
  final libDir = Directory('lib');
  int totalFiles = 0;
  int modifiedFiles = 0;
  
  await for (final file in libDir.list(recursive: true, followLinks: false)) {
    if (file is File && file.path.endsWith('.dart')) {
      totalFiles++;
      
      String content = await file.readAsString();
      String originalContent = content;
      
      for (final fix in fixes) {
        content = content.replaceAll(fix['from']!, fix['to']!);
      }
      
      if (content != originalContent) {
        await file.writeAsString(content);
        modifiedFiles++;
        print('Corrigé: ${file.path}');
      }
    }
  }
  
  print('Correction terminée: $modifiedFiles fichiers modifiés sur $totalFiles fichiers analysés');
}