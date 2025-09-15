import 'dart:io';
import 'lib/services/encoding_fix_service.dart';

void main() {
  print('🔧 Test du service de correction d\'encodage');
  print('=' * 50);
  
  // Test des caractères français courants
  Map<String, String> testCases = {
    // Entités HTML basiques
    '&eacute;glise': 'église',
    'pri&egrave;re': 'prière',
    'r&ecirc;ve': 'rêve',
    '&agrave; bient&ocirc;t': 'à bientôt',
    'L&rsquo;amour': 'L\'amour',
    
    // Caractères UTF-8 mal encodés
    'Ã©glise': 'église',
    'priÃ¨re': 'prière',
    'rÃªve': 'rêve',
    'Ã  bientÃ´t': 'à bientôt',
    'lâ€™amour': 'l\'amour',
    
    // Apostrophes et guillemets
    'câ€™est': 'c\'est',
    'lâ€™Ã©glise': 'l\'église',
    '&ldquo;Bonjour&rdquo;': '"Bonjour"',
    
    // Espaces multiples et nettoyage
    'Bonjour   monde': 'Bonjour monde',
    '  Début  et  fin  ': 'Début et fin',
    
    // Mélange de problèmes
    'Lâ€™&eacute;glise  de  DieuÂ ': 'L\'église de Dieu',
    'Prions&nbsp;ensemble': 'Prions ensemble',
  };
  
  print('📋 Tests des corrections d\'encodage :');
  print('-' * 50);
  
  int passedTests = 0;
  int totalTests = testCases.length;
  
  testCases.forEach((input, expected) {
    String result = EncodingFixService.fixEncoding(input);
    bool passed = result == expected;
    
    if (passed) {
      passedTests++;
      print('✅ PASS: "$input" -> "$result"');
    } else {
      print('❌ FAIL: "$input"');
      print('   Attendu: "$expected"');
      print('   Obtenu:  "$result"');
    }
  });
  
  print('-' * 50);
  print('📊 Résultats: $passedTests/$totalTests tests réussis');
  
  if (passedTests == totalTests) {
    print('🎉 Tous les tests sont passés !');
  } else {
    print('⚠️  ${totalTests - passedTests} test(s) ont échoué');
  }
  
  // Test avec un texte réaliste de pain quotidien
  print('\n🍞 Test avec texte réaliste de pain quotidien :');
  print('-' * 50);
  
  String sampleText = '''
    &ldquo;Venez &agrave; moi, vous tous qui &ecirc;tes fatigu&eacute;s et charg&eacute;s, 
    et je vous donnerai du repos.&rdquo; - Matthieu 11:28
    
    L&rsquo;&Eacute;glise est le corps du Christ. C&rsquo;est un lieu de paix et de pri&egrave;re.
    &nbsp;&nbsp;Que Dieu vous b&eacute;nisse abondamment !
  ''';
  
  print('Texte original:');
  print(sampleText);
  print('\nTexte corrigé:');
  String correctedText = EncodingFixService.fixEncoding(sampleText);
  print(correctedText);
}
