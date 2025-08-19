import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';
import 'lib/modules/bible/services/thematic_passage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔥 Initialisation Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialisé');

  print('🔐 État d\'authentification initial...');
  User? user = FirebaseAuth.instance.currentUser;
  print('Utilisateur actuel: ${user?.uid ?? "Aucun"}');

  print('📊 Test du stream getUserThemes...');
  try {
    final stream = ThematicPassageService.getUserThemes();
    
    // Écouter le stream pendant 10 secondes
    final subscription = stream.listen(
      (themes) {
        print('📡 Stream utilisateur émis: ${themes.length} thèmes');
        for (final theme in themes) {
          print('  - ${theme.name}: ${theme.passages.length} passages (créé par: ${theme.createdBy})');
        }
      },
      onError: (error) {
        print('❌ Erreur dans le stream utilisateur: $error');
      },
    );

    await Future.delayed(const Duration(seconds: 10));
    subscription.cancel();
    
    // Vérifier l'état après
    final finalUser = FirebaseAuth.instance.currentUser;
    print('👤 Utilisateur final: ${finalUser?.uid ?? "Aucun"}');
    
    print('✅ Test terminé');
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('🏁 Test de diagnostic terminé');
}
