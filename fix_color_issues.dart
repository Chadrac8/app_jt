import 'dart:io';

void main() async {
  // Corriger les erreurs d'index couleur et les propriétés manquantes
  final fixes = [
    // Corrections des erreurs de shade et index
    {'from': 'AppTheme.grey100[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey100[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey100[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey100[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey100[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey100[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey100[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey100[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey100[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey100[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey200[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey200[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey200[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey200[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey200[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey200[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey200[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey200[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey200[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey200[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey300[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey300[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey300[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey300[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey300[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey300[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey300[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey300[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey300[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey300[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey400[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey400[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey400[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey400[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey400[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey400[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey400[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey400[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey400[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey400[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey500[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey500[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey500[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey500[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey500[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey500[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey500[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey500[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey500[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey500[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey600[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey600[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey600[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey600[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey600[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey600[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey600[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey600[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey600[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey600[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey700[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey700[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey700[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey700[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey700[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey700[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey700[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey700[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey700[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey700[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey800[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey800[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey800[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey800[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey800[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey800[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey800[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey800[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey800[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey800[900]', 'to': 'AppTheme.grey900'},
    
    {'from': 'AppTheme.grey900[50]', 'to': 'AppTheme.grey50'},
    {'from': 'AppTheme.grey900[100]', 'to': 'AppTheme.grey100'},
    {'from': 'AppTheme.grey900[200]', 'to': 'AppTheme.grey200'},
    {'from': 'AppTheme.grey900[300]', 'to': 'AppTheme.grey300'},
    {'from': 'AppTheme.grey900[400]', 'to': 'AppTheme.grey400'},
    {'from': 'AppTheme.grey900[500]', 'to': 'AppTheme.grey500'},
    {'from': 'AppTheme.grey900[600]', 'to': 'AppTheme.grey600'},
    {'from': 'AppTheme.grey900[700]', 'to': 'AppTheme.grey700'},
    {'from': 'AppTheme.grey900[800]', 'to': 'AppTheme.grey800'},
    {'from': 'AppTheme.grey900[900]', 'to': 'AppTheme.grey900'},
    
    // Corrections des propriétés shade
    {'from': '.shade50', 'to': ''},
    {'from': '.shade100', 'to': ''},
    {'from': '.shade200', 'to': ''},
    {'from': '.shade300', 'to': ''},
    {'from': '.shade400', 'to': ''},
    {'from': '.shade500', 'to': ''},
    {'from': '.shade600', 'to': ''},
    {'from': '.shade700', 'to': ''},
    {'from': '.shade800', 'to': ''},
    {'from': '.shade900', 'to': ''},
    
    // Propriétés manquantes
    {'from': 'AppTheme.redStandardAccent', 'to': 'AppTheme.redStandard'},
    {'from': 'AppTheme.black10087', 'to': 'AppTheme.black100.withOpacity(0.87)'},
    {'from': 'AppTheme.white10070', 'to': 'AppTheme.white100.withOpacity(0.70)'},
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