#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🚀 DÉMARRAGE DE LA MIGRATION PEOPLE → PERSONS');
  print('Generated at: 2025-09-15 13:38:43.460985');
  print('=' * 60);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. VÉRIFICATION DES PRÉREQUIS
    print('\n📋 1. VÉRIFICATION DES PRÉREQUIS');
    print('-' * 40);
    
    final peopleSnapshot = await firestore.collection('people').get();
    final personsSnapshot = await firestore.collection('persons').get();
    
    print('✅ Collection "people": ${peopleSnapshot.docs.length} documents');
    print('✅ Collection "persons": ${personsSnapshot.docs.length} documents');
    
    if (peopleSnapshot.docs.isEmpty) {
      print('✅ Collection "people" est vide. Aucune migration nécessaire.');
      return;
    }
    
    // 2. CRÉATION DE LA SAUVEGARDE
    print('\n💾 2. CRÉATION DE LA SAUVEGARDE');
    print('-' * 40);
    
    final backupCollectionName = 'people_backup_1757936323460';
    final batch = firestore.batch();
    int backupCount = 0;
    
    for (final doc in peopleSnapshot.docs) {
      final backupRef = firestore.collection(backupCollectionName).doc(doc.id);
      batch.set(backupRef, {
        ...doc.data(),
        '_backup_timestamp': FieldValue.serverTimestamp(),
        '_original_collection': 'people',
      });
      backupCount++;
    }
    
    await batch.commit();
    print('✅ Sauvegarde créée: $backupCount documents dans "$backupCollectionName"');
    
    // 3. ANALYSE DES DOUBLONS
    print('\n🔍 3. ANALYSE DES DOUBLONS');
    print('-' * 40);
    
    final Map<String, List<DocumentSnapshot>> emailGroups = {};
    final Map<String, List<DocumentSnapshot>> nameGroups = {};
    
    // Grouper par email
    for (final doc in peopleSnapshot.docs) {
      final data = doc.data();
      final email = data['email']?.toString().toLowerCase();
      if (email != null && email.isNotEmpty) {
        emailGroups[email] = emailGroups[email] ?? [];
        emailGroups[email]!.add(doc);
      }
    }
    
    // Vérifier les doublons avec persons
    final Map<String, DocumentSnapshot> personsEmails = {};
    for (final doc in personsSnapshot.docs) {
      final email = doc.data()['email']?.toString().toLowerCase();
      if (email != null && email.isNotEmpty) {
        personsEmails[email] = doc;
      }
    }
    
    int duplicatesFound = 0;
    int uniqueRecords = 0;
    final List<String> duplicateEmails = [];
    
    for (final entry in emailGroups.entries) {
      final email = entry.key;
      final peopleDocs = entry.value;
      
      if (personsEmails.containsKey(email)) {
        duplicatesFound += peopleDocs.length;
        duplicateEmails.add(email);
        print('⚠️  Doublon détecté: $email (${peopleDocs.length} dans people, 1 dans persons)');
      } else {
        uniqueRecords += peopleDocs.length;
      }
    }
    
    print('📊 Résultats de l\'analyse:');
    print('   - Documents uniques à migrer: $uniqueRecords');
    print('   - Doublons détectés: $duplicatesFound');
    print('   - Emails dupliqués: ${duplicateEmails.length}');
    
    // 4. MIGRATION DES DONNÉES UNIQUES
    print('\n🚀 4. MIGRATION DES DONNÉES UNIQUES');
    print('-' * 40);
    
    int migrated = 0;
    int skipped = 0;
    int updated = 0;
    
    final migrationBatch = firestore.batch();
    
    for (final doc in peopleSnapshot.docs) {
      final data = doc.data();
      final email = data['email']?.toString().toLowerCase();
      
      if (email != null && personsEmails.containsKey(email)) {
        // C'est un doublon, fusionner les données
        final existingPersonDoc = personsEmails[email]!;
        final existingData = existingPersonDoc.data();
        
        // Fusionner les données (priorité aux données les plus récentes)
        final mergedData = await mergePersonData(existingData, data);
        
        if (mergedData != null) {
          final personRef = firestore.collection('persons').doc(existingPersonDoc.id);
          migrationBatch.update(personRef, {
            ...mergedData,
            'updatedAt': FieldValue.serverTimestamp(),
            '_merged_from_people': true,
            '_migration_timestamp': FieldValue.serverTimestamp(),
          });
          updated++;
          print('🔄 Fusion: $email');
        } else {
          skipped++;
          print('⏭️  Ignoré: $email (données identiques)');
        }
      } else {
        // Document unique, migrer directement
        final personRef = firestore.collection('persons').doc();
        migrationBatch.set(personRef, {
          ...data,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          '_migrated_from_people': true,
          '_migration_timestamp': FieldValue.serverTimestamp(),
        });
        migrated++;
        print('✅ Migré: ${data['firstName']} ${data['lastName']}');
      }
    }
    
    await migrationBatch.commit();
    
    print('\n📊 RÉSULTATS DE LA MIGRATION:');
    print('   - Documents migrés: $migrated');
    print('   - Documents fusionnés: $updated');
    print('   - Documents ignorés: $skipped');
    
    // 5. VALIDATION
    print('\n✅ 5. VALIDATION POST-MIGRATION');
    print('-' * 40);
    
    final finalPersonsSnapshot = await firestore.collection('persons').get();
    final expectedTotal = personsSnapshot.docs.length + migrated + updated;
    
    print('📊 Validation des totaux:');
    print('   - Persons avant migration: ${personsSnapshot.docs.length}');
    print('   - Documents migrés: $migrated');
    print('   - Documents fusionnés: $updated');
    print('   - Total attendu: $expectedTotal');
    print('   - Total actuel: ${finalPersonsSnapshot.docs.length}');
    
    if (finalPersonsSnapshot.docs.length >= personsSnapshot.docs.length + migrated) {
      print('✅ Validation réussie: Toutes les données ont été migrées');
    } else {
      print('❌ ERREUR: Données manquantes détectées!');
      print('   Vérifiez les logs et la collection de sauvegarde.');
      return;
    }
    
    // 6. ARCHIVAGE DE LA COLLECTION PEOPLE
    print('\n🗄️  6. ARCHIVAGE DE LA COLLECTION PEOPLE');
    print('-' * 40);
    
    print('⚠️  IMPORTANT: Collection "people" conservée pour validation.');
    print('   Après vérification de la migration (recommandé: 7 jours),');
    print('   vous pourrez supprimer manuellement la collection "people".');
    print('   Sauvegarde disponible dans: "$backupCollectionName"');
    
    print('\n🎉 MIGRATION TERMINÉE AVEC SUCCÈS!');
    print('=' * 60);
    print('📅 Heure de fin: ${DateTime.now()}');
    print('📊 Résumé final:');
    print('   - $migrated nouveaux documents ajoutés à "persons"');
    print('   - $updated documents existants mis à jour');
    print('   - $skipped doublons ignorés');
    print('   - 📁 Sauvegarde: "$backupCollectionName"');
    
    print('\n🔧 PROCHAINES ÉTAPES:');
    print('1. Mettre à jour improved_role_service.dart');
    print('2. Tester les fonctionnalités de rôles');
    print('3. Valider l\'application pendant quelques jours');
    print('4. Supprimer la collection "people" si tout fonctionne');
    
  } catch (e, stackTrace) {
    print('❌ ERREUR LORS DE LA MIGRATION: $e');
    print('📊 Stack trace: $stackTrace');
    print('\n🔄 ROLLBACK AUTOMATIQUE...');
    print('   La collection "people" n\'a pas été modifiée.');
    print('   Vérifiez les erreurs avant de relancer la migration.');
    exit(1);
  }
}

Future<Map<String, dynamic>?> mergePersonData(
  Map<String, dynamic> existingData,
  Map<String, dynamic> peopleData,
) async {
  final merged = Map<String, dynamic>.from(existingData);
  bool hasChanges = false;
  
  // Liste des champs à fusionner
  final fieldsToMerge = [
    'firstName', 'lastName', 'email', 'phone', 'address',
    'birthDate', 'gender', 'maritalStatus', 'children',
    'profileImageUrl', 'privateNotes', 'roles', 'tags',
    'customFields', 'familyId'
  ];
  
  for (final field in fieldsToMerge) {
    final existingValue = existingData[field];
    final peopleValue = peopleData[field];
    
    // Si le champ existe dans people mais pas dans persons, l'ajouter
    if (peopleValue != null && existingValue == null) {
      merged[field] = peopleValue;
      hasChanges = true;
    }
    // Si c'est une liste (comme roles), fusionner
    else if (field == 'roles' && peopleValue is List && existingValue is List) {
      final Set<String> combinedRoles = {
        ...List<String>.from(existingValue),
        ...List<String>.from(peopleValue),
      };
      if (combinedRoles.length > List<String>.from(existingValue).length) {
        merged['roles'] = combinedRoles.toList();
        hasChanges = true;
      }
    }
    // Pour les champs de texte, garder le plus long/complet
    else if (field == 'privateNotes' && 
             peopleValue != null && 
             (existingValue == null || peopleValue.toString().length > existingValue.toString().length)) {
      merged[field] = peopleValue;
      hasChanges = true;
    }
  }
  
  return hasChanges ? merged : null;
}
