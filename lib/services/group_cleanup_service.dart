import 'package:cloud_firestore/cloud_firestore.dart';

/// Service de nettoyage des événements et meetings orphelins de groupes supprimés
/// 
/// Fournit des méthodes pour:
/// - Détecter les événements liés à des groupes inexistants
/// - Supprimer ces événements orphelins
/// - Nettoyer les meetings orphelins
class GroupCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Résultat du nettoyage
  static CleanupResult? _lastCleanupResult;
  static CleanupResult? get lastCleanupResult => _lastCleanupResult;

  /// Nettoie tous les événements et meetings des groupes supprimés
  /// 
  /// Retourne le nombre d'éléments supprimés
  static Future<CleanupResult> cleanupOrphanedGroupContent({
    bool dryRun = false,
  }) async {
    print('🧹 Début nettoyage événements/meetings orphelins (dryRun: $dryRun)');
    
    final result = CleanupResult();
    
    try {
      // 1. Nettoyer les événements orphelins
      final eventsResult = await _cleanupOrphanEvents(dryRun: dryRun);
      result.eventsDeleted = eventsResult.count;
      result.eventsBySeries.addAll(eventsResult.bySeries);
      result.orphanEvents.addAll(eventsResult.orphans);
      
      // 2. Nettoyer les meetings orphelins
      final meetingsResult = await _cleanupOrphanMeetings(dryRun: dryRun);
      result.meetingsDeleted = meetingsResult;
      
      _lastCleanupResult = result;
      
      print('✅ Nettoyage terminé:');
      print('   - ${result.eventsDeleted} événements');
      print('   - ${result.meetingsDeleted} meetings');
      
      return result;
      
    } catch (e, stackTrace) {
      print('❌ Erreur nettoyage: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  /// Nettoie les événements orphelins
  static Future<_EventCleanupResult> _cleanupOrphanEvents({
    required bool dryRun,
  }) async {
    print('🔍 Recherche événements orphelins...');
    
    final result = _EventCleanupResult();
    
    // Récupérer tous les événements liés à des groupes
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('linkedGroupId', isNotEqualTo: null)
        .get();
    
    print('   📊 ${eventsSnapshot.docs.length} événements liés à des groupes');
    
    final orphanEventIds = <String>[];
    
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
        orphanEventIds.add(eventDoc.id);
        
        final seriesId = eventData['seriesId'] as String?;
        result.bySeries[seriesId] = (result.bySeries[seriesId] ?? 0) + 1;
        
        result.orphans.add(OrphanEventInfo(
          eventId: eventDoc.id,
          title: eventData['title'] ?? 'Sans titre',
          linkedGroupId: linkedGroupId,
          seriesId: seriesId,
          startDate: eventData['startDate'] != null 
              ? (eventData['startDate'] as Timestamp).toDate()
              : null,
        ));
      }
    }
    
    result.count = orphanEventIds.length;
    
    if (orphanEventIds.isEmpty) {
      print('   ✅ Aucun événement orphelin');
      return result;
    }
    
    print('   ❌ ${orphanEventIds.length} événements orphelins trouvés');
    
    if (!dryRun) {
      // Supprimer les événements orphelins
      print('   🗑️ Suppression...');
      final batch = _firestore.batch();
      
      for (int i = 0; i < orphanEventIds.length; i++) {
        final eventRef = _firestore.collection('events').doc(orphanEventIds[i]);
        batch.delete(eventRef);
        
        // Commit tous les 500 documents (limite Firestore)
        if ((i + 1) % 500 == 0) {
          await batch.commit();
          print('      ⏳ ${i + 1}/${orphanEventIds.length}...');
        }
      }
      
      await batch.commit();
      print('   ✅ ${orphanEventIds.length} événements supprimés');
    }
    
    return result;
  }

  /// Nettoie les meetings orphelins
  static Future<int> _cleanupOrphanMeetings({
    required bool dryRun,
  }) async {
    print('🔍 Recherche meetings orphelins...');
    
    final meetingsSnapshot = await _firestore
        .collection('group_meetings')
        .get();
    
    print('   📊 ${meetingsSnapshot.docs.length} meetings au total');
    
    final orphanMeetingIds = <String>[];
    
    for (final meetingDoc in meetingsSnapshot.docs) {
      final meetingData = meetingDoc.data();
      final groupId = meetingData['groupId'] as String?;
      
      if (groupId == null) continue;
      
      // Vérifier si le groupe existe
      final groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();
      
      if (!groupDoc.exists) {
        orphanMeetingIds.add(meetingDoc.id);
      }
    }
    
    if (orphanMeetingIds.isEmpty) {
      print('   ✅ Aucun meeting orphelin');
      return 0;
    }
    
    print('   ❌ ${orphanMeetingIds.length} meetings orphelins trouvés');
    
    if (!dryRun) {
      print('   🗑️ Suppression...');
      final batch = _firestore.batch();
      
      for (int i = 0; i < orphanMeetingIds.length; i++) {
        final meetingRef = _firestore.collection('group_meetings').doc(orphanMeetingIds[i]);
        batch.delete(meetingRef);
        
        if ((i + 1) % 500 == 0) {
          await batch.commit();
          print('      ⏳ ${i + 1}/${orphanMeetingIds.length}...');
        }
      }
      
      await batch.commit();
      print('   ✅ ${orphanMeetingIds.length} meetings supprimés');
    }
    
    return orphanMeetingIds.length;
  }

  /// Compte les événements et meetings orphelins sans les supprimer
  static Future<CleanupStats> getOrphanStats() async {
    final stats = CleanupStats();
    
    // Événements
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('linkedGroupId', isNotEqualTo: null)
        .get();
    
    stats.totalEventsWithGroup = eventsSnapshot.docs.length;
    
    for (final eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data();
      final linkedGroupId = eventData['linkedGroupId'] as String?;
      
      if (linkedGroupId != null) {
        final groupDoc = await _firestore
            .collection('groups')
            .doc(linkedGroupId)
            .get();
        
        if (!groupDoc.exists) {
          stats.orphanEvents++;
        } else {
          stats.validEvents++;
        }
      }
    }
    
    // Meetings
    final meetingsSnapshot = await _firestore
        .collection('group_meetings')
        .get();
    
    stats.totalMeetings = meetingsSnapshot.docs.length;
    
    for (final meetingDoc in meetingsSnapshot.docs) {
      final meetingData = meetingDoc.data();
      final groupId = meetingData['groupId'] as String?;
      
      if (groupId != null) {
        final groupDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .get();
        
        if (!groupDoc.exists) {
          stats.orphanMeetings++;
        } else {
          stats.validMeetings++;
        }
      }
    }
    
    return stats;
  }

  /// Nettoie tous les événements d'un groupe spécifique
  static Future<int> cleanupGroupEvents(String groupId) async {
    print('🗑️ Nettoyage événements du groupe $groupId');
    
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('linkedGroupId', isEqualTo: groupId)
        .get();
    
    if (eventsSnapshot.docs.isEmpty) {
      print('   ✅ Aucun événement à nettoyer');
      return 0;
    }
    
    final batch = _firestore.batch();
    
    for (final eventDoc in eventsSnapshot.docs) {
      batch.delete(eventDoc.reference);
    }
    
    await batch.commit();
    
    print('   ✅ ${eventsSnapshot.docs.length} événements supprimés');
    return eventsSnapshot.docs.length;
  }

  /// Nettoie tous les meetings d'un groupe spécifique
  static Future<int> cleanupGroupMeetings(String groupId) async {
    print('🗑️ Nettoyage meetings du groupe $groupId');
    
    final meetingsSnapshot = await _firestore
        .collection('group_meetings')
        .where('groupId', isEqualTo: groupId)
        .get();
    
    if (meetingsSnapshot.docs.isEmpty) {
      print('   ✅ Aucun meeting à nettoyer');
      return 0;
    }
    
    final batch = _firestore.batch();
    
    for (final meetingDoc in meetingsSnapshot.docs) {
      batch.delete(meetingDoc.reference);
    }
    
    await batch.commit();
    
    print('   ✅ ${meetingsSnapshot.docs.length} meetings supprimés');
    return meetingsSnapshot.docs.length;
  }
}

/// Résultat du nettoyage
class CleanupResult {
  int eventsDeleted = 0;
  int meetingsDeleted = 0;
  Map<String?, int> eventsBySeries = {};
  List<OrphanEventInfo> orphanEvents = [];

  int get totalDeleted => eventsDeleted + meetingsDeleted;

  @override
  String toString() {
    return 'CleanupResult(events: $eventsDeleted, meetings: $meetingsDeleted, '
        'total: $totalDeleted, series: ${eventsBySeries.length})';
  }
}

/// Statistiques des éléments orphelins
class CleanupStats {
  int totalEventsWithGroup = 0;
  int validEvents = 0;
  int orphanEvents = 0;
  
  int totalMeetings = 0;
  int validMeetings = 0;
  int orphanMeetings = 0;

  bool get hasOrphans => orphanEvents > 0 || orphanMeetings > 0;
  int get totalOrphans => orphanEvents + orphanMeetings;

  @override
  String toString() {
    return 'CleanupStats(\n'
        '  Événements: $orphanEvents orphelins / $totalEventsWithGroup total\n'
        '  Meetings: $orphanMeetings orphelins / $totalMeetings total\n'
        '  Total orphelins: $totalOrphans\n'
        ')';
  }
}

/// Information sur un événement orphelin
class OrphanEventInfo {
  final String eventId;
  final String title;
  final String linkedGroupId;
  final String? seriesId;
  final DateTime? startDate;

  OrphanEventInfo({
    required this.eventId,
    required this.title,
    required this.linkedGroupId,
    this.seriesId,
    this.startDate,
  });

  @override
  String toString() {
    return 'OrphanEvent(id: $eventId, title: $title, group: $linkedGroupId, series: $seriesId)';
  }
}

/// Résultat interne du nettoyage d'événements
class _EventCleanupResult {
  int count = 0;
  Map<String?, int> bySeries = {};
  List<OrphanEventInfo> orphans = [];
}
