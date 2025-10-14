import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de nettoyage des événements orphelins de groupes supprimés
/// 
/// Ce script :
/// 1. Trouve tous les événements liés à des groupes (linkedGroupId présent)
/// 2. Vérifie si le groupe existe encore
/// 3. Supprime les événements dont le groupe a été supprimé
/// 
/// Usage: dart run scripts/cleanup_orphan_group_events.dart

class OrphanGroupEventsCleanup {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> run() async {
    print('🧹 === Nettoyage des événements orphelins de groupes ===\n');
    
    try {
      // 1. Récupérer tous les événements liés à des groupes
      print('📊 Récupération des événements liés à des groupes...');
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('linkedGroupId', isNotEqualTo: null)
          .get();
      
      print('✅ ${eventsSnapshot.docs.length} événements liés à des groupes trouvés\n');
      
      if (eventsSnapshot.docs.isEmpty) {
        print('✅ Aucun événement lié à un groupe. Nettoyage terminé.');
        return;
      }

      // 2. Vérifier chaque événement
      final orphanEvents = <String, Map<String, dynamic>>{};
      final validEvents = <String>[];
      
      print('🔍 Vérification des groupes associés...\n');
      
      for (final eventDoc in eventsSnapshot.docs) {
        final eventData = eventDoc.data();
        final linkedGroupId = eventData['linkedGroupId'] as String?;
        
        if (linkedGroupId == null) continue;
        
        // Vérifier si le groupe existe
        final groupDoc = await _firestore
            .collection('groups')
            .doc(linkedGroupId)
            .get();
        
        if (!groupDoc.exists) {
          // Groupe supprimé → événement orphelin
          orphanEvents[eventDoc.id] = {
            'eventId': eventDoc.id,
            'linkedGroupId': linkedGroupId,
            'title': eventData['title'] ?? 'Sans titre',
            'startDate': eventData['startDate'],
            'seriesId': eventData['seriesId'],
          };
          
          print('❌ Événement orphelin trouvé:');
          print('   - ID: ${eventDoc.id}');
          print('   - Titre: ${eventData['title']}');
          print('   - Groupe supprimé: $linkedGroupId');
          print('   - Série: ${eventData['seriesId'] ?? 'Aucune'}');
          print('');
        } else {
          validEvents.add(eventDoc.id);
        }
      }

      // 3. Résumé
      print('\n📊 === RÉSUMÉ ===');
      print('✅ Événements valides: ${validEvents.length}');
      print('❌ Événements orphelins: ${orphanEvents.length}');
      
      if (orphanEvents.isEmpty) {
        print('\n✅ Aucun événement orphelin. Base de données propre !');
        return;
      }

      // 4. Regrouper par série
      final seriesGroups = <String?, List<String>>{};
      for (final event in orphanEvents.values) {
        final seriesId = event['seriesId'] as String?;
        seriesGroups.putIfAbsent(seriesId, () => []).add(event['eventId'] as String);
      }

      print('\n📦 Répartition par série:');
      seriesGroups.forEach((seriesId, eventIds) {
        if (seriesId != null) {
          print('   - Série $seriesId: ${eventIds.length} événements');
        } else {
          print('   - Sans série: ${eventIds.length} événements');
        }
      });

      // 5. Suppression
      print('\n🗑️ Suppression des événements orphelins...');
      
      int deletedCount = 0;
      final batch = _firestore.batch();
      
      for (final eventId in orphanEvents.keys) {
        final eventRef = _firestore.collection('events').doc(eventId);
        batch.delete(eventRef);
        deletedCount++;
        
        // Commit tous les 500 documents (limite Firestore)
        if (deletedCount % 500 == 0) {
          await batch.commit();
          print('   ⏳ $deletedCount événements supprimés...');
        }
      }
      
      // Commit final
      await batch.commit();
      
      // 6. Vérifier les meetings orphelins également
      print('\n🔍 Vérification des meetings orphelins...');
      final meetingsSnapshot = await _firestore
          .collection('group_meetings')
          .get();
      
      int orphanMeetingsCount = 0;
      final meetingBatch = _firestore.batch();
      
      for (final meetingDoc in meetingsSnapshot.docs) {
        final meetingData = meetingDoc.data();
        final groupId = meetingData['groupId'] as String?;
        
        if (groupId != null) {
          final groupDoc = await _firestore.collection('groups').doc(groupId).get();
          
          if (!groupDoc.exists) {
            // Meeting orphelin
            meetingBatch.delete(meetingDoc.reference);
            orphanMeetingsCount++;
            
            if (orphanMeetingsCount % 500 == 0) {
              await meetingBatch.commit();
              print('   ⏳ $orphanMeetingsCount meetings supprimés...');
            }
          }
        }
      }
      
      if (orphanMeetingsCount > 0) {
        await meetingBatch.commit();
        print('✅ $orphanMeetingsCount meetings orphelins supprimés');
      } else {
        print('✅ Aucun meeting orphelin trouvé');
      }

      // 7. Résultat final
      print('\n✅ === NETTOYAGE TERMINÉ ===');
      print('🗑️ $deletedCount événements orphelins supprimés');
      print('🗑️ $orphanMeetingsCount meetings orphelins supprimés');
      print('✨ Base de données nettoyée avec succès !');
      
    } catch (e, stackTrace) {
      print('\n❌ ERREUR lors du nettoyage: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Version "dry-run" qui liste sans supprimer
  Future<void> dryRun() async {
    print('🔍 === Mode DRY-RUN (aucune suppression) ===\n');
    
    try {
      // Événements
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('linkedGroupId', isNotEqualTo: null)
          .get();
      
      print('📊 ${eventsSnapshot.docs.length} événements liés à des groupes\n');
      
      int orphanCount = 0;
      final seriesGroups = <String?, int>{};
      
      for (final eventDoc in eventsSnapshot.docs) {
        final eventData = eventDoc.data();
        final linkedGroupId = eventData['linkedGroupId'] as String?;
        
        if (linkedGroupId != null) {
          final groupDoc = await _firestore.collection('groups').doc(linkedGroupId).get();
          
          if (!groupDoc.exists) {
            orphanCount++;
            final seriesId = eventData['seriesId'] as String?;
            seriesGroups[seriesId] = (seriesGroups[seriesId] ?? 0) + 1;
            
            print('❌ Orphelin: ${eventData['title']} (groupe: $linkedGroupId)');
          }
        }
      }

      // Meetings
      final meetingsSnapshot = await _firestore.collection('group_meetings').get();
      int orphanMeetingsCount = 0;
      
      for (final meetingDoc in meetingsSnapshot.docs) {
        final meetingData = meetingDoc.data();
        final groupId = meetingData['groupId'] as String?;
        
        if (groupId != null) {
          final groupDoc = await _firestore.collection('groups').doc(groupId).get();
          
          if (!groupDoc.exists) {
            orphanMeetingsCount++;
            print('❌ Meeting orphelin: ${meetingData['title']} (groupe: $groupId)');
          }
        }
      }

      print('\n📊 === RÉSULTAT DRY-RUN ===');
      print('❌ $orphanCount événements à supprimer');
      print('❌ $orphanMeetingsCount meetings à supprimer');
      
      if (seriesGroups.isNotEmpty) {
        print('\n📦 Par série:');
        seriesGroups.forEach((seriesId, count) {
          if (seriesId != null) {
            print('   - Série $seriesId: $count événements');
          } else {
            print('   - Sans série: $count événements');
          }
        });
      }
      
      if (orphanCount == 0 && orphanMeetingsCount == 0) {
        print('\n✅ Base de données propre !');
      } else {
        print('\n💡 Exécutez run() pour supprimer ces éléments orphelins');
      }
      
    } catch (e, stackTrace) {
      print('\n❌ ERREUR: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

void main() async {
  print('⚠️  Ce script nécessite une connexion Firebase configurée');
  print('Utilisez-le dans le contexte de l\'application Flutter\n');
  
  final cleanup = OrphanGroupEventsCleanup();
  
  // Décommenter l'option souhaitée:
  
  // Mode dry-run (liste seulement, ne supprime pas)
  // await cleanup.dryRun();
  
  // Mode suppression réelle
  // await cleanup.run();
}
