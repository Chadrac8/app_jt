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

  print('🧪 Test complet - Création de thème et ajout de passages...');
  
  try {
    // Étape 1: Créer un thème
    print('\n📋 Étape 1: Création d\'un thème...');
    final themeId = await ThematicPassageService.createTheme(
      name: 'Test Complet ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Test automatique complet avec ajout de passages',
      color: Colors.purple,
      icon: Icons.favorite,
      isPublic: false,
    );
    print('✅ Thème créé: $themeId');
    
    // Vérifier l'utilisateur après création
    final userAfterCreate = FirebaseAuth.instance.currentUser;
    print('👤 Utilisateur après création: ${userAfterCreate?.uid ?? "Aucun"}');
    
    // Étape 2: Ajouter plusieurs passages
    print('\n📖 Étape 2: Ajout de passages bibliques...');
    
    // Passage 1: Verset unique
    await ThematicPassageService.addPassageToTheme(
      themeId: themeId,
      reference: 'Jean 3:16',
      book: 'Jean',
      chapter: 3,
      startVerse: 16,
      description: 'L\'amour de Dieu pour le monde',
      tags: ['amour', 'salut', 'éternité'],
    );
    print('✅ Passage 1 ajouté: Jean 3:16');
    
    // Passage 2: Multiple versets
    await ThematicPassageService.addPassageToTheme(
      themeId: themeId,
      reference: 'Psaumes 23:1-3',
      book: 'Psaumes',
      chapter: 23,
      startVerse: 1,
      endVerse: 3,
      description: 'Le Seigneur est mon berger',
      tags: ['protection', 'confiance', 'berger'],
    );
    print('✅ Passage 2 ajouté: Psaumes 23:1-3');
    
    // Passage 3: Autre verset
    await ThematicPassageService.addPassageToTheme(
      themeId: themeId,
      reference: 'Philippiens 4:13',
      book: 'Philippiens',
      chapter: 4,
      startVerse: 13,
      description: 'Je puis tout par celui qui me fortifie',
      tags: ['force', 'persévérance', 'foi'],
    );
    print('✅ Passage 3 ajouté: Philippiens 4:13');
    
    // Étape 3: Vérifier le thème et ses passages
    print('\n🔍 Étape 3: Vérification du thème...');
    final stream = ThematicPassageService.getUserThemes();
    final themes = await stream.first;
    
    final testTheme = themes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => throw Exception('Thème non trouvé')
    );
    
    print('📊 Thème vérifié: ${testTheme.name}');
    print('📖 Nombre de passages: ${testTheme.passages.length}');
    print('');
    
    for (int i = 0; i < testTheme.passages.length; i++) {
      final passage = testTheme.passages[i];
      print('Passage ${i + 1}:');
      print('  📍 Référence: ${passage.reference}');
      print('  📝 Description: ${passage.description}');
      print('  📜 Texte: ${passage.text.substring(0, passage.text.length.clamp(0, 100))}${passage.text.length > 100 ? "..." : ""}');
      print('  🏷️  Tags: ${passage.tags.join(", ")}');
      print('');
    }
    
    // Étape 4: Test de modification
    print('🔄 Étape 4: Test de modification du thème...');
    await ThematicPassageService.updateTheme(
      themeId: themeId,
      name: 'Test Complet Modifié',
      description: 'Description mise à jour avec succès',
      color: Colors.green,
      icon: Icons.star,
      isPublic: true,
    );
    print('✅ Thème modifié avec succès');
    
    // Étape 5: Nettoyage
    print('\n🗑️ Étape 5: Nettoyage...');
    await ThematicPassageService.deleteTheme(themeId);
    print('✅ Thème et passages supprimés');
    
    print('\n🎉 SUCCÈS TOTAL! Toutes les fonctionnalités marchent parfaitement!');
    print('');
    print('✅ Création de thème');
    print('✅ Ajout de passages (verset unique et multiples)');
    print('✅ Récupération des textes bibliques');
    print('✅ Modification de thème');
    print('✅ Suppression complète');
    
  } catch (e) {
    print('\n❌ ERREUR: $e');
    print('');
    
    if (e.toString().contains('admin-restricted-operation')) {
      print('🔧 SOLUTION:');
      print('1. Ouvrez: https://console.firebase.google.com/project/hjye25u8iwm0i0zls78urffsc0jcgj/authentication/providers');
      print('2. Activez "Anonymous" dans Sign-in method');
      print('3. Relancez ce test');
    }
  }

  print('\n🏁 Test terminé');
}
