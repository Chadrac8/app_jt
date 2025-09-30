import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'lib/modules/songs/services/songs_firebase_service.dart';

Future<void> main() async {
  print('🎵 Renumération automatique des cantiques');
  print('=========================================');

  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');

    // Demander confirmation
    print('\n❓ Cette opération va identifier automatiquement les cantiques');
    print('   et les renumérotter à partir de 1. Continuer? (y/N)');
    
    final input = stdin.readLineSync()?.toLowerCase();
    if (input != 'y' && input != 'yes') {
      print('❌ Opération annulée');
      return;
    }

    print('\n🔄 Renumération en cours...');
    
    // Exécuter la renumération
    final result = await SongsFirebaseService.renumberCantiques();
    
    if (result['success'] == true) {
      print('\n✅ ${result['message']}');
      print('📊 Cantiques trouvés: ${result['cantiquesFound']}');
      print('📝 Cantiques modifiés: ${result['cantiquesUpdated']}');
      
      if (result['updates'] != null && (result['updates'] as Map).isNotEmpty) {
        print('\n📋 Modifications effectuées:');
        final updates = result['updates'] as Map<String, int>;
        updates.forEach((title, number) {
          print('   $number - $title');
        });
      }
      
      print('\n🎯 Les cantiques sont maintenant numérotés de 1 à ${result['cantiquesFound']}');
    } else {
      print('❌ ${result['message']}');
    }

  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('\n🎉 Opération terminée!');
}