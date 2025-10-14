import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧹 Nettoyage temporaire des événements orphelins
/// 
/// CE FICHIER EST TEMPORAIRE - À SUPPRIMER APRÈS UTILISATION !
/// 
/// Ce script recherche et supprime les événements du calendrier
/// dont les réunions de groupe correspondantes ont été supprimées.
class TempOrphanCleanup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Nettoie tous les événements orphelins
  /// 
  /// Processus :
  /// 1. Récupère tous les événements liés à des groupes
  /// 2. Vérifie si la réunion correspondante existe
  /// 3. Supprime les événements sans réunion (orphelins)
  static Future<void> cleanupOrphanEvents() async {
    print('🔍 Recherche des événements orphelins...\n');
    
    // 1. Récupérer tous les événements liés à des groupes
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('linkedGroupId', isNotEqualTo: null)
        .get();
    
    print('📊 ${eventsSnapshot.docs.length} événements de groupes trouvés');
    
    final orphanIds = <String>[];
    final orphanTitles = <String>[];
    
    // 2. Vérifier chaque événement
    for (final eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data();
      final linkedEventId = eventDoc.id;
      final eventTitle = eventData['title'] as String? ?? 'Sans titre';
      
      // Chercher si une réunion correspondante existe
      final meetingsSnapshot = await _firestore
          .collection('group_meetings')
          .where('linkedEventId', isEqualTo: linkedEventId)
          .limit(1)
          .get();
      
      // Si aucune réunion trouvée → Orphelin !
      if (meetingsSnapshot.docs.isEmpty) {
        orphanIds.add(eventDoc.id);
        orphanTitles.add(eventTitle);
        
        print('⚠️  Orphelin trouvé: $eventTitle (ID: ${eventDoc.id})');
      }
    }
    
    if (orphanIds.isEmpty) {
      print('\n✅ Aucun événement orphelin trouvé\n');
      return;
    }
    
    print('\n📋 ${orphanIds.length} événements orphelins détectés:');
    for (int i = 0; i < orphanTitles.length; i++) {
      print('   ${i + 1}. ${orphanTitles[i]}');
    }
    
    print('\n🗑️  Suppression en cours...\n');
    
    // 3. Supprimer les orphelins
    final batch = _firestore.batch();
    for (final orphanId in orphanIds) {
      batch.delete(_firestore.collection('events').doc(orphanId));
    }
    
    await batch.commit();
    
    print('✅ ${orphanIds.length} événements orphelins supprimés !\n');
  }
  
  /// Alternative : Nettoyer des événements spécifiques par titre
  /// 
  /// Utile si vous connaissez les titres exacts des événements à supprimer
  static Future<void> cleanupEventsByTitle(List<String> titles) async {
    print('🔍 Recherche des événements: ${titles.join(", ")}\n');
    
    final batch = _firestore.batch();
    int deletedCount = 0;
    
    for (final title in titles) {
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('title', isEqualTo: title)
          .get();
      
      for (final doc in eventsSnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
        print('🗑️  Suppression: $title (ID: ${doc.id})');
      }
    }
    
    if (deletedCount == 0) {
      print('⚠️  Aucun événement trouvé avec ces titres\n');
      return;
    }
    
    await batch.commit();
    print('\n✅ $deletedCount événements supprimés !\n');
  }
}

/// Fonction principale pour lancer le nettoyage
/// 
/// Utilisez cette fonction depuis un bouton admin
Future<void> runCleanup() async {
  try {
    await TempOrphanCleanup.cleanupOrphanEvents();
    print('🎉 Nettoyage terminé avec succès');
  } catch (e, stackTrace) {
    print('❌ Erreur: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Fonction pour nettoyer des événements spécifiques
/// 
/// Exemple d'utilisation :
/// ```dart
/// await runSpecificCleanup(['réunion ndndnd', 'réunion Ecole du dimanche']);
/// ```
Future<void> runSpecificCleanup(List<String> eventTitles) async {
  try {
    await TempOrphanCleanup.cleanupEventsByTitle(eventTitles);
    print('🎉 Nettoyage spécifique terminé avec succès');
  } catch (e, stackTrace) {
    print('❌ Erreur: $e');
    print('Stack trace: $stackTrace');
  }
}
