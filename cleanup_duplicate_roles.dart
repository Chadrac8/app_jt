import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script pour nettoyer les rôles en double dans la collection people
/// 
/// Ce script va :
/// 1. Identifier les personnes avec des rôles dupliqués dans le champ roles[]
/// 2. Supprimer les doublons en gardant seulement une instance de chaque rôle
/// 3. Mettre à jour les documents dans Firestore
/// 4. Générer un rapport détaillé des modifications

void main() async {
  await Firebase.initializeApp();
  print('🚀 Démarrage du nettoyage des rôles dupliqués...\n');
  
  await cleanupDuplicateRoles();
  
  print('\n✅ Nettoyage terminé !');
}

Future<void> cleanupDuplicateRoles() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. Récupérer toutes les personnes actives
    print('📊 Analyse des personnes avec rôles...');
    final personsSnapshot = await firestore
        .collection('people')
        .where('isActive', isEqualTo: true)
        .get();
    
    print('   Trouvé ${personsSnapshot.docs.length} personnes actives');
    
    // 2. Analyser les rôles et identifier les doublons
    int totalPersons = 0;
    int personsWithDuplicates = 0;
    int totalDuplicatesRemoved = 0;
    List<Map<String, dynamic>> cleanupReport = [];
    
    for (final personDoc in personsSnapshot.docs) {
      final personData = personDoc.data();
      final personId = personDoc.id;
      final firstName = personData['firstName'] ?? '';
      final lastName = personData['lastName'] ?? '';
      final email = personData['email'] ?? '';
      
      // Récupérer et analyser les rôles
      final rolesList = personData['roles'];
      if (rolesList == null || rolesList is! List) {
        continue;
      }
      
      final roles = List<String>.from(rolesList);
      totalPersons++;
      
      // Identifier les doublons
      final uniqueRoles = <String>{};
      final duplicates = <String>[];
      
      for (final role in roles) {
        if (uniqueRoles.contains(role)) {
          duplicates.add(role);
        } else {
          uniqueRoles.add(role);
        }
      }
      
      // Si des doublons sont trouvés
      if (duplicates.isNotEmpty) {
        personsWithDuplicates++;
        totalDuplicatesRemoved += duplicates.length;
        
        print('   🔍 Doublons trouvés pour: $firstName $lastName ($email)');
        print('      Rôles avant: $roles');
        print('      Doublons: $duplicates');
        print('      Rôles après: ${uniqueRoles.toList()}');
        
        // Préparer le rapport
        cleanupReport.add({
          'personId': personId,
          'fullName': '$firstName $lastName',
          'email': email,
          'rolesBefore': List<String>.from(roles),
          'rolesAfter': uniqueRoles.toList(),
          'duplicatesRemoved': List<String>.from(duplicates),
          'duplicateCount': duplicates.length,
        });
        
        // Mettre à jour le document avec les rôles uniques
        try {
          await firestore.collection('people').doc(personId).update({
            'roles': uniqueRoles.toList(),
            'updatedAt': FieldValue.serverTimestamp(),
            'lastModifiedBy': 'cleanup_script',
          });
          
          print('      ✅ Mis à jour avec succès\n');
          
        } catch (e) {
          print('      ❌ Erreur lors de la mise à jour: $e\n');
        }
      }
    }
    
    // 3. Générer le rapport final
    print('📈 RAPPORT DE NETTOYAGE');
    print('=' * 50);
    print('Personnes analysées: $totalPersons');
    print('Personnes avec doublons: $personsWithDuplicates');
    print('Total doublons supprimés: $totalDuplicatesRemoved');
    
    if (cleanupReport.isNotEmpty) {
      print('\n📋 DÉTAIL DES MODIFICATIONS:');
      print('-' * 50);
      
      for (final report in cleanupReport) {
        print('Personne: ${report['fullName']} (${report['email']})');
        print('  ID: ${report['personId']}');
        print('  Rôles avant: ${report['rolesBefore']}');
        print('  Rôles après: ${report['rolesAfter']}');
        print('  Doublons supprimés: ${report['duplicatesRemoved']} (${report['duplicateCount']} instances)');
        print('');
      }
    }
    
    // 4. Vérification finale
    print('🔍 VÉRIFICATION FINALE...');
    await verifyCleanup();
    
  } catch (e) {
    print('❌ Erreur lors du nettoyage: $e');
  }
}

/// Vérifie qu'il n'y a plus de doublons après le nettoyage
Future<void> verifyCleanup() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    final personsSnapshot = await firestore
        .collection('people')
        .where('isActive', isEqualTo: true)
        .get();
    
    int personsChecked = 0;
    int remainingDuplicates = 0;
    
    for (final personDoc in personsSnapshot.docs) {
      final personData = personDoc.data();
      final rolesList = personData['roles'];
      
      if (rolesList != null && rolesList is List) {
        final roles = List<String>.from(rolesList);
        final uniqueRoles = roles.toSet();
        
        personsChecked++;
        
        if (roles.length != uniqueRoles.length) {
          remainingDuplicates++;
          final firstName = personData['firstName'] ?? '';
          final lastName = personData['lastName'] ?? '';
          print('   ⚠️  Doublons restants pour: $firstName $lastName - Rôles: $roles');
        }
      }
    }
    
    print('Personnes vérifiées: $personsChecked');
    if (remainingDuplicates == 0) {
      print('✅ Aucun doublon restant détecté !');
    } else {
      print('⚠️  $remainingDuplicates personne(s) ont encore des doublons');
    }
    
  } catch (e) {
    print('❌ Erreur lors de la vérification: $e');
  }
}

/// Fonction utilitaire pour analyser les doublons sans les corriger
Future<void> analyzeOnly() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    print('🔍 ANALYSE DES DOUBLONS SEULEMENT (sans correction)...\n');
    
    final personsSnapshot = await firestore
        .collection('people')
        .where('isActive', isEqualTo: true)
        .get();
    
    print('📊 Analyse de ${personsSnapshot.docs.length} personnes...\n');
    
    int totalPersonsWithRoles = 0;
    int personsWithDuplicates = 0;
    Map<String, int> duplicateStats = {};
    
    for (final personDoc in personsSnapshot.docs) {
      final personData = personDoc.data();
      final firstName = personData['firstName'] ?? '';
      final lastName = personData['lastName'] ?? '';
      final email = personData['email'] ?? '';
      
      final rolesList = personData['roles'];
      if (rolesList == null || rolesList is! List) {
        continue;
      }
      
      final roles = List<String>.from(rolesList);
      if (roles.isEmpty) continue;
      
      totalPersonsWithRoles++;
      
      // Compter les occurrences de chaque rôle
      final roleCounts = <String, int>{};
      for (final role in roles) {
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
      
      // Identifier les doublons
      final duplicatedRoles = roleCounts.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key)
          .toList();
      
      if (duplicatedRoles.isNotEmpty) {
        personsWithDuplicates++;
        
        print('🔍 $firstName $lastName ($email)');
        print('   Rôles: $roles');
        for (final role in duplicatedRoles) {
          final count = roleCounts[role]!;
          print('   ⚠️  "$role" apparaît $count fois');
          duplicateStats[role] = (duplicateStats[role] ?? 0) + (count - 1);
        }
        print('');
      }
    }
    
    print('📈 STATISTIQUES:');
    print('=' * 40);
    print('Personnes avec rôles: $totalPersonsWithRoles');
    print('Personnes avec doublons: $personsWithDuplicates');
    
    if (duplicateStats.isNotEmpty) {
      print('\n📊 RÔLES DUPLIQUÉS:');
      duplicateStats.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..forEach((entry) {
            print('   "${entry.key}": ${entry.value} doublons');
          });
    }
    
  } catch (e) {
    print('❌ Erreur lors de l\'analyse: $e');
  }
}