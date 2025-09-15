#!/usr/bin/env dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🔍 ANALYSE COMPARATIVE DES COLLECTIONS PEOPLE vs PERSONS');
  print('=' * 60);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. Analyser la collection 'people'
    print('\n📊 ANALYSE DE LA COLLECTION "people"');
    print('-' * 40);
    
    final peopleSnapshot = await firestore.collection('people').get();
    print('📝 Nombre de documents: ${peopleSnapshot.docs.length}');
    
    if (peopleSnapshot.docs.isNotEmpty) {
      print('\n🔸 Exemple de structure des données:');
      final samplePeopleDoc = peopleSnapshot.docs.first;
      final peopleData = samplePeopleDoc.data();
      print('📄 ID: ${samplePeopleDoc.id}');
      print('📄 Champs disponibles: ${peopleData.keys.toList()}');
      
      // Analyser les champs communs
      final Map<String, int> fieldCount = {};
      for (final doc in peopleSnapshot.docs) {
        final data = doc.data();
        for (final field in data.keys) {
          fieldCount[field] = (fieldCount[field] ?? 0) + 1;
        }
      }
      
      print('\n📈 Statistiques des champs:');
      fieldCount.entries.forEach((entry) {
        final percentage = ((entry.value / peopleSnapshot.docs.length) * 100).toStringAsFixed(1);
        print('   ${entry.key}: ${entry.value}/${peopleSnapshot.docs.length} documents ($percentage%)');
      });
      
      // Vérifier les timestamps pour déterminer la récence
      if (peopleData.containsKey('createdAt') || peopleData.containsKey('updatedAt')) {
        final timestamps = peopleSnapshot.docs.map((doc) {
          final data = doc.data();
          DateTime? created;
          DateTime? updated;
          
          try {
            if (data['createdAt'] is Timestamp) {
              created = (data['createdAt'] as Timestamp).toDate();
            } else if (data['createdAt'] is String) {
              created = DateTime.parse(data['createdAt']);
            }
            
            if (data['updatedAt'] is Timestamp) {
              updated = (data['updatedAt'] as Timestamp).toDate();
            } else if (data['updatedAt'] is String) {
              updated = DateTime.parse(data['updatedAt']);
            }
          } catch (e) {
            // Ignore parsing errors
          }
          
          return {
            'id': doc.id,
            'created': created,
            'updated': updated,
          };
        }).toList();
        
        final recentCreated = timestamps
            .where((t) => t['created'] != null)
            .map((t) => t['created'] as DateTime)
            .where((d) => d.isAfter(DateTime.now().subtract(Duration(days: 30))))
            .length;
            
        final recentUpdated = timestamps
            .where((t) => t['updated'] != null)
            .map((t) => t['updated'] as DateTime)
            .where((d) => d.isAfter(DateTime.now().subtract(Duration(days: 30))))
            .length;
            
        print('\n⏰ Activité récente (30 derniers jours):');
        print('   Créations récentes: $recentCreated');
        print('   Mises à jour récentes: $recentUpdated');
      }
    }
    
    // 2. Analyser la collection 'persons'
    print('\n\n📊 ANALYSE DE LA COLLECTION "persons"');
    print('-' * 40);
    
    final personsSnapshot = await firestore.collection('persons').get();
    print('📝 Nombre de documents: ${personsSnapshot.docs.length}');
    
    if (personsSnapshot.docs.isNotEmpty) {
      print('\n🔸 Exemple de structure des données:');
      final samplePersonsDoc = personsSnapshot.docs.first;
      final personsData = samplePersonsDoc.data();
      print('📄 ID: ${samplePersonsDoc.id}');
      print('📄 Champs disponibles: ${personsData.keys.toList()}');
      
      // Analyser les champs communs
      final Map<String, int> fieldCount = {};
      for (final doc in personsSnapshot.docs) {
        final data = doc.data();
        for (final field in data.keys) {
          fieldCount[field] = (fieldCount[field] ?? 0) + 1;
        }
      }
      
      print('\n📈 Statistiques des champs:');
      fieldCount.entries.forEach((entry) {
        final percentage = ((entry.value / personsSnapshot.docs.length) * 100).toStringAsFixed(1);
        print('   ${entry.key}: ${entry.value}/${personsSnapshot.docs.length} documents ($percentage%)');
      });
      
      // Vérifier les timestamps pour déterminer la récence
      if (personsData.containsKey('createdAt') || personsData.containsKey('updatedAt')) {
        final timestamps = personsSnapshot.docs.map((doc) {
          final data = doc.data();
          DateTime? created;
          DateTime? updated;
          
          try {
            if (data['createdAt'] is Timestamp) {
              created = (data['createdAt'] as Timestamp).toDate();
            } else if (data['createdAt'] is String) {
              created = DateTime.parse(data['createdAt']);
            }
            
            if (data['updatedAt'] is Timestamp) {
              updated = (data['updatedAt'] as Timestamp).toDate();
            } else if (data['updatedAt'] is String) {
              updated = DateTime.parse(data['updatedAt']);
            }
          } catch (e) {
            // Ignore parsing errors
          }
          
          return {
            'id': doc.id,
            'created': created,
            'updated': updated,
          };
        }).toList();
        
        final recentCreated = timestamps
            .where((t) => t['created'] != null)
            .map((t) => t['created'] as DateTime)
            .where((d) => d.isAfter(DateTime.now().subtract(Duration(days: 30))))
            .length;
            
        final recentUpdated = timestamps
            .where((t) => t['updated'] != null)
            .map((t) => t['updated'] as DateTime)
            .where((d) => d.isAfter(DateTime.now().subtract(Duration(days: 30))))
            .length;
            
        print('\n⏰ Activité récente (30 derniers jours):');
        print('   Créations récentes: $recentCreated');
        print('   Mises à jour récentes: $recentUpdated');
      }
    }
    
    // 3. Comparer les collections
    print('\n\n🔍 COMPARAISON DÉTAILLÉE');
    print('-' * 40);
    
    if (peopleSnapshot.docs.isNotEmpty && personsSnapshot.docs.isNotEmpty) {
      // Vérifier les doublons par email
      final peopleEmails = <String>{};
      final personsEmails = <String>{};
      
      for (final doc in peopleSnapshot.docs) {
        final email = doc.data()['email']?.toString();
        if (email != null && email.isNotEmpty) {
          peopleEmails.add(email.toLowerCase());
        }
      }
      
      for (final doc in personsSnapshot.docs) {
        final email = doc.data()['email']?.toString();
        if (email != null && email.isNotEmpty) {
          personsEmails.add(email.toLowerCase());
        }
      }
      
      final commonEmails = peopleEmails.intersection(personsEmails);
      final uniquePeople = peopleEmails.difference(personsEmails);
      final uniquePersons = personsEmails.difference(peopleEmails);
      
      print('📧 Analyse des emails:');
      print('   Emails communs: ${commonEmails.length}');
      print('   Emails uniques dans "people": ${uniquePeople.length}');
      print('   Emails uniques dans "persons": ${uniquePersons.length}');
      
      if (commonEmails.isNotEmpty) {
        print('\n⚠️  ATTENTION: ${commonEmails.length} personnes semblent être dupliquées entre les collections!');
        
        // Afficher quelques exemples d'emails dupliqués
        final examples = commonEmails.take(5).toList();
        print('   Exemples d\'emails dupliqués:');
        for (final email in examples) {
          print('     - $email');
        }
      }
    }
    
    // 4. Recommandations
    print('\n\n💡 RECOMMANDATIONS');
    print('-' * 40);
    
    final peopleCount = peopleSnapshot.docs.length;
    final personsCount = personsSnapshot.docs.length;
    
    if (personsCount > peopleCount) {
      print('✅ Collection "persons" recommandée comme principale:');
      print('   - Plus de documents ($personsCount vs $peopleCount)');
      print('   - Utilisée dans firebase_service.dart (service principal)');
      print('   - Index Firestore configurés pour cette collection');
    } else if (peopleCount > personsCount) {
      print('⚠️  Collection "people" contient plus de documents ($peopleCount vs $personsCount)');
      print('   Mais "persons" reste recommandée pour la cohérence du code');
    } else {
      print('🤔 Les deux collections ont le même nombre de documents');
      print('   "persons" recommandée pour la cohérence architecturale');
    }
    
    print('\n🎯 ACTIONS SUGGÉRÉES:');
    print('1. Migrer les données uniques de "people" vers "persons"');
    print('2. Résoudre les doublons en fusionnant les informations');
    print('3. Mettre à jour improved_role_service.dart pour utiliser "persons"');
    print('4. Supprimer la collection "people" après migration');
    
  } catch (e) {
    print('❌ Erreur lors de l\'analyse: $e');
    exit(1);
  }
  
  print('\n✅ Analyse terminée!');
}