import 'dart:io';

void main() async {
  print('🔧 Recherche de duplications du module "Le Message"...\n');

  // Vérifier app_modules.dart
  final appModulesFile = File('lib/config/app_modules.dart');
  if (await appModulesFile.exists()) {
    final content = await appModulesFile.readAsString();
    final messageMatches = 'message'.allMatches(content).length;
    final leMessageMatches = 'Le Message'.allMatches(content).length;
    
    print('📄 app_modules.dart:');
    print('  - Occurrences de "message": $messageMatches');
    print('  - Occurrences de "Le Message": $leMessageMatches');
  }

  print('');

  // Vérifier app_config_firebase_service.dart
  final firebaseServiceFile = File('lib/services/app_config_firebase_service.dart');
  if (await firebaseServiceFile.exists()) {
    final content = await firebaseServiceFile.readAsString();
    final messageMatches = 'message'.allMatches(content).length;
    final leMessageMatches = 'Le Message'.allMatches(content).length;
    
    print('📄 app_config_firebase_service.dart:');
    print('  - Occurrences de "message": $messageMatches');
    print('  - Occurrences de "Le Message": $leMessageMatches');
    
    // Rechercher isPrimaryInBottomNav pour le module message
    final lines = content.split('\n');
    bool inMessageModule = false;
    String? isPrimaryValue;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.contains("id: 'message'")) {
        inMessageModule = true;
        print('  - Module "message" trouvé ligne ${i + 1}');
      }
      
      if (inMessageModule && line.contains('isPrimaryInBottomNav:')) {
        isPrimaryValue = line.split(':')[1].trim().replaceAll(',', '');
        print('  - isPrimaryInBottomNav: $isPrimaryValue');
        break;
      }
      
      if (inMessageModule && line.contains('},')) {
        break;
      }
    }
  }

  print('\n🔍 Analyse terminée.');
  print('\n💡 Le problème vient probablement de:');
  print('1. Une duplication dans la base de données Firebase');
  print('2. Une incohérence entre configuration locale et Firebase');
  print('3. Un bug dans la logique de construction du menu Plus');
}
