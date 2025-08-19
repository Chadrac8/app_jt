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

  print('🔐 Gestion de l\'authentification...');
  User? user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    print('❌ Aucun utilisateur connecté, connexion anonyme...');
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      user = userCredential.user;
      print('✅ Connexion anonyme réussie: ${user!.uid}');
    } catch (e) {
      print('❌ Erreur de connexion anonyme: $e');
      // Essayons de continuer pour voir si on peut diagnostiquer d'autres problèmes
    }
  } else {
    print('✅ Utilisateur déjà connecté: ${user.uid}');
  }

  print('🧪 Test de création de thème...');
  try {
    final themeId = await ThematicPassageService.createTheme(
      name: 'Test Ajout Passage ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Test automatique pour ajouter des passages',
      color: Colors.blue,
      icon: Icons.star,
      isPublic: false,
    );
    
    print('✅ Thème créé avec succès! ID: $themeId');
    
    print('📖 Test d\'ajout de passage biblique...');
    try {
      await ThematicPassageService.addPassageToTheme(
        themeId: themeId,
        reference: 'Jean 3:16',
        book: 'Jean',
        chapter: 3,
        startVerse: 16,
        description: 'Verset test sur l\'amour de Dieu',
        tags: ['amour', 'salut'],
      );
      
      print('✅ Passage ajouté avec succès!');
      
      // Test avec plusieurs versets
      print('📖 Test d\'ajout de passage multi-versets...');
      await ThematicPassageService.addPassageToTheme(
        themeId: themeId,
        reference: 'Matthieu 5:3-5',
        book: 'Matthieu',
        chapter: 5,
        startVerse: 3,
        endVerse: 5,
        description: 'Les béatitudes - premiers versets',
        tags: ['béatitudes', 'enseignement'],
      );
      
      print('✅ Passage multi-versets ajouté avec succès!');
      
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de passage: $e');
    }

    // Vérifier les passages ajoutés
    print('🔍 Vérification des passages ajoutés...');
    try {
      final stream = ThematicPassageService.getUserThemes();
      final themes = await stream.first;
      
      final testTheme = themes.firstWhere((t) => t.id == themeId, 
          orElse: () => throw Exception('Thème test non trouvé'));
      
      print('📊 Thème trouvé: ${testTheme.name}');
      print('📖 Passages dans le thème: ${testTheme.passages.length}');
      
      for (final passage in testTheme.passages) {
        print('  - ${passage.reference}: ${passage.description}');
        print('    Texte: ${passage.text.substring(0, passage.text.length.clamp(0, 100))}...');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
    }

    // Nettoyage
    print('🗑️ Suppression du thème de test...');
    try {
      await ThematicPassageService.deleteTheme(themeId);
      print('✅ Thème supprimé avec succès!');
    } catch (e) {
      print('⚠️ Erreur lors du nettoyage: $e');
    }
    
  } catch (e) {
    print('❌ Erreur lors de la création du thème: $e');
  }

  print('🏁 Test terminé');
}
