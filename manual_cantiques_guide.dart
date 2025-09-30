import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  print('🎵 Script simple de renumération des cantiques');
  print('==============================================');

  try {
    // Vérifier si Firebase CLI est disponible
    final result = await Process.run('firebase', ['--version']);
    if (result.exitCode != 0) {
      print('❌ Firebase CLI non trouvé. Installez-le avec: npm install -g firebase-tools');
      exit(1);
    }

    print('✅ Firebase CLI trouvé');

    // Demander le projet Firebase
    print('\n📋 Projets Firebase disponibles:');
    final projectsResult = await Process.run('firebase', ['projects:list']);
    if (projectsResult.exitCode == 0) {
      print(projectsResult.stdout);
    }

    print('\n❓ Entrez l\'ID de votre projet Firebase:');
    final projectId = stdin.readLineSync();
    
    if (projectId == null || projectId.isEmpty) {
      print('❌ ID de projet requis');
      exit(1);
    }

    // Se connecter au projet
    final useResult = await Process.run('firebase', ['use', projectId]);
    if (useResult.exitCode != 0) {
      print('❌ Impossible de se connecter au projet: $projectId');
      print(useResult.stderr);
      exit(1);
    }

    print('✅ Connecté au projet: $projectId');

    // Récupérer les données des chants
    print('\n📚 Récupération des chants...');
    final firestoreResult = await Process.run('firebase', [
      'firestore:export',
      '--collection-ids',
      'songs',
      'temp_export',
      '--format',
      'json'
    ]);

    if (firestoreResult.exitCode != 0) {
      print('❌ Erreur lors de l\'export: ${firestoreResult.stderr}');
      exit(1);
    }

    print('✅ Données exportées');

    // Instructions manuelles pour l'utilisateur
    print('\n📝 INSTRUCTIONS MANUELLES:');
    print('1. Ouvrez votre console Firebase: https://console.firebase.google.com');
    print('2. Sélectionnez votre projet: $projectId');
    print('3. Allez dans Firestore Database');
    print('4. Ouvrez la collection "songs"');
    print('5. Pour chaque cantique que vous voulez renumérotter:');
    print('   - Cliquez sur le document');
    print('   - Modifiez le champ "number"');
    print('   - Attribuez les numéros 1, 2, 3, etc. selon l\'ordre souhaité');
    print('');
    print('💡 CONSEIL: Identifiez les cantiques par:');
    print('   - Titres commençant par "Ô", "O", "Mon", "Ma", etc.');
    print('   - Catégories contenant "cantique" ou "hymne"');
    print('   - Chants traditionnels/religieux');
    print('');
    print('🎯 OBJECTIF: Les cantiques doivent avoir les numéros 1, 2, 3, ...');
    print('   Les autres chants peuvent garder leurs numéros actuels (243+)');

  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }

  print('\n🎉 Consultez les instructions ci-dessus pour renumérotter manuellement');
}