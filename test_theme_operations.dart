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

  print('🔐 Vérification de l\'authentification...');
  User? user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    print('❌ Aucun utilisateur connecté, connexion anonyme...');
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
      print('✅ Connexion anonyme réussie: ${user!.uid}');
    } catch (e) {
      print('❌ Erreur de connexion anonyme: $e');
      return;
    }
  } else {
    print('✅ Utilisateur déjà connecté: ${user.uid}');
  }

  print('🧪 Test de création de thème...');
  try {
    final themeId = await ThematicPassageService.createTheme(
      name: 'Test Création ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Test automatique de création de thème',
      color: Colors.blue,
      icon: Icons.star,
      isPublic: false,
    );
    
    print('✅ Thème créé avec succès! ID: $themeId');
    
    print('🔄 Test de modification de thème...');
    await ThematicPassageService.updateTheme(
      themeId: themeId,
      name: 'Test Modifié',
      description: 'Test automatique de modification',
      color: Colors.green,
      icon: Icons.favorite,
      isPublic: true,
    );
    
    print('✅ Thème modifié avec succès!');
    
    print('🗑️ Suppression du thème de test...');
    await ThematicPassageService.deleteTheme(themeId);
    print('✅ Thème supprimé avec succès!');
    
  } catch (e) {
    print('❌ Erreur lors des opérations: $e');
  }

  print('🏁 Test terminé');
}
