import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/modules/bible/services/thematic_passage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Initialisation Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialisé');

  print('🔍 Test de connexion...');
  final isConnected = await ThematicPassageService.checkFirebaseConnection();
  print('Connexion: ${isConnected ? "✅ OK" : "❌ KO"}');

  print('📊 Test du stream getPublicThemes...');
  try {
    final stream = ThematicPassageService.getPublicThemes();
    
    // Écouter le stream pendant 10 secondes
    final subscription = stream.listen(
      (themes) {
        print('📡 Stream émis: ${themes.length} thèmes');
        for (final theme in themes) {
          print('  - ${theme.name}: ${theme.passages.length} passages');
        }
      },
      onError: (error) {
        print('❌ Erreur dans le stream: $error');
      },
    );

    await Future.delayed(const Duration(seconds: 10));
    subscription.cancel();
    print('✅ Test terminé');
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('🏁 Test de diagnostic terminé');
}
