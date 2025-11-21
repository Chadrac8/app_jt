import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/recurrence_config.dart';
import 'group_event_integration_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔄 Extension pour GroupsFirebaseService avec intégration événements
/// 
/// Fournit des méthodes façade pour :
/// - Activer génération événements sur groupe existant
/// - Mettre à jour groupe avec choix de portée
/// - Synchroniser meetings ↔ événements
/// - Obtenir statistiques événements liés
class GroupsEventsFacade {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GroupEventIntegrationService _integrationService = 
      GroupEventIntegrationService();

  /// 🔄 Active la génération d'événements pour un groupe existant
  /// 
  /// **Utilisé pour:** Transformer un groupe simple en groupe avec événements automatiques
  /// 
  /// **Processus:**
  /// 1. Récupère groupe existant
  /// 2. Génère série événements depuis config récurrence
  /// 3. Crée GroupMeetingModel pour chaque événement
  /// 4. Lie groupe ↔ événements via linkedEventSeriesId
  /// 
  /// **Paramètres:**
  /// - [groupId]: ID du groupe à modifier
  /// - [recurrenceConfig]: Configuration récurrence (Map depuis RecurrenceConfig.toMap())
  /// - [startDate]: Date début récurrence
  /// - [endDate]: Date fin (optionnel, si null utilise maxOccurrences)
  /// - [maxOccurrences]: Nombre max occurrences (optionnel, si null utilise endDate)
  /// 
  /// **Exemple:**
  /// ```dart
  /// await GroupsEventsFacade.enableEventsForGroup(
  ///   groupId: 'group123',
  ///   recurrenceConfig: RecurrenceConfig(
  ///     frequency: RecurrenceFrequency.weekly,
  ///     dayOfWeek: 5, // Vendredi
  ///     time: TimeOfDay(hour: 19, minute: 30),
  ///     duration: Duration(hours: 2),
  ///   ).toMap(),
  ///   startDate: DateTime(2025, 1, 17),
  ///   endDate: DateTime(2025, 6, 30),
  /// );
  /// ```
  static Future<void> enableEventsForGroup({
    required String groupId,
    required Map<String, dynamic> recurrenceConfig,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'system';
      
      // Importer RecurrenceConfig depuis map
      final config = RecurrenceConfig.fromMap(recurrenceConfig);
      
      await _integrationService.enableEventsForGroup(
        groupId: groupId,
        recurrenceConfig: config,
        startDate: startDate,
        endDate: endDate,
        maxOccurrences: maxOccurrences,
        userId: userId,
      );
      
      // Log activity
      await _logGroupActivity(groupId, 'events_enabled', {
        'startDate': startDate.toIso8601String(),
        'frequency': config.frequency.toString(),
        'interval': config.interval,
        'totalOccurrences': config.calculateTotalOccurrences(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'activation des événements: $e');
    }
  }
  
  /// ✏️ Met à jour un groupe avec choix de portée (pour groupes récurrents)
  /// 
  /// **Style Google Calendar:** Permet de choisir quelles occurrences modifier
  /// 
  /// **Portées disponibles:**
  /// - `GroupEditScope.thisOccurrenceOnly`: Modifie uniquement l'occurrence sélectionnée
  /// - `GroupEditScope.thisAndFutureOccurrences`: Modifie cette occurrence et toutes les suivantes
  /// - `GroupEditScope.allOccurrences`: Modifie toutes les occurrences (passées, présentes, futures)
  /// 
  /// **Paramètres:**
  /// - [groupId]: ID du groupe
  /// - [updates]: Map des champs à mettre à jour (ex: {'location': 'Nouvelle salle', 'description': '...'})
  /// - [scope]: Portée modification (enum GroupEditScope)
  /// - [occurrenceDate]: Date occurrence concernée (requis si scope != allOccurrences)
  /// 
  /// **Exemple:**
  /// ```dart
  /// // Changer salle pour réunions à partir du 15 mars
  /// await GroupsEventsFacade.updateGroupWithScope(
  ///   groupId: 'group123',
  ///   updates: {
  ///     'location': 'Salle 203',
  ///     'description': 'Nouvelle salle plus spacieuse',
  ///   },
  ///   scope: GroupEditScope.thisAndFutureOccurrences,
  ///   occurrenceDate: DateTime(2025, 3, 15),
  /// );
  /// ```
  static Future<void> updateGroupWithScope({
    required String groupId,
    required Map<String, dynamic> updates,
    required GroupEditScope scope,
    DateTime? occurrenceDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'system';
      
      // Valider paramètres
      if (scope != GroupEditScope.allOccurrences && occurrenceDate == null) {
        throw ArgumentError(
          'occurrenceDate requis pour scope ${scope.label}',
        );
      }
      
      await _integrationService.updateGroupWithEvents(
        groupId: groupId,
        updates: updates,
        scope: scope,
        occurrenceDate: occurrenceDate,
        userId: userId,
      );
      
      // Log activity
      await _logGroupActivity(groupId, 'update_with_scope', {
        'scope': scope.label,
        'occurrenceDate': occurrenceDate?.toIso8601String(),
        'updatedFields': updates.keys.toList(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour avec portée: $e');
    }
  }
  
  /// 🔗 Synchronise un meeting avec son événement lié
  /// 
  /// **Utilisé quand:** L'événement est modifié directement dans le calendrier
  /// 
  /// **Processus:**
  /// 1. Récupère événement depuis ID
  /// 2. Trouve meeting lié via linkedMeetingId
  /// 3. Met à jour meeting avec données événement
  /// 4. Marque meeting comme modifié (isModified: true)
  /// 
  /// **Paramètres:**
  /// - [eventId]: ID de l'événement modifié
  /// 
  /// **Exemple:**
  /// ```dart
  /// // Appelé automatiquement quand événement modifié
  /// await GroupsEventsFacade.syncMeetingWithEvent('event456');
  /// ```
  static Future<void> syncMeetingWithEvent(String eventId) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'system';
      
      await _integrationService.syncMeetingWithEvent(
        eventId: eventId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Erreur lors de la synchronisation: $e');
    }
  }
  
  /// 📊 Obtient les statistiques des événements liés à un groupe
  /// 
  /// **Retourne:**
  /// ```dart
  /// {
  ///   'hasEvents': true/false,
  ///   'totalEvents': 26,
  ///   'upcomingEvents': 18,
  ///   'pastEvents': 8,
  ///   'linkedEventSeriesId': 'series789',
  /// }
  /// ```
  /// 
  /// **Paramètres:**
  /// - [groupId]: ID du groupe
  /// 
  /// **Exemple:**
  /// ```dart
  /// final stats = await GroupsEventsFacade.getGroupEventsStats('group123');
  /// print('${stats['upcomingEvents']} réunions à venir');
  /// ```
  static Future<Map<String, dynamic>> getGroupEventsStats(String groupId) async {
    try {
      // Récupérer groupe
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Groupe non trouvé: $groupId');
      }
      
      final group = GroupModel.fromFirestore(groupDoc);
      
      if (!group.generateEvents || group.linkedEventSeriesId == null) {
        return {
          'hasEvents': false,
          'totalEvents': 0,
          'upcomingEvents': 0,
          'pastEvents': 0,
        };
      }
      
      final now = Timestamp.now();
      
      // Compter événements totaux
      final totalSnapshot = await _firestore
          .collection('events')
          .where('seriesId', isEqualTo: group.linkedEventSeriesId)
          .where('linkedGroupId', isEqualTo: groupId)
          .get();
      
      // Compter événements futurs
      final upcomingSnapshot = await _firestore
          .collection('events')
          .where('seriesId', isEqualTo: group.linkedEventSeriesId)
          .where('linkedGroupId', isEqualTo: groupId)
          .where('startDate', isGreaterThanOrEqualTo: now)
          .get();
      
      // Compter modifications
      int modifiedCount = 0;
      for (final doc in totalSnapshot.docs) {
        final data = doc.data();
        if (data['isModifiedOccurrence'] == true) {
          modifiedCount++;
        }
      }
      
      return {
        'hasEvents': true,
        'totalEvents': totalSnapshot.docs.length,
        'upcomingEvents': upcomingSnapshot.docs.length,
        'pastEvents': totalSnapshot.docs.length - upcomingSnapshot.docs.length,
        'modifiedEvents': modifiedCount,
        'linkedEventSeriesId': group.linkedEventSeriesId,
        'recurrenceDescription': group.recurrenceConfig != null
            ? RecurrenceConfig.fromMap(group.recurrenceConfig!).description
            : null,
      };
    } catch (e) {
      print('Erreur lors du calcul des stats événements: $e');
      return {
        'hasEvents': false,
        'totalEvents': 0,
        'upcomingEvents': 0,
        'pastEvents': 0,
        'error': e.toString(),
      };
    }
  }
  
  /// 📋 Obtient la liste des événements liés à un groupe
  /// 
  /// **Retourne:** Liste des événements triés par date
  /// 
  /// **Paramètres:**
  /// - [groupId]: ID du groupe
  /// - [upcomingOnly]: Si true, retourne uniquement événements futurs (défaut: false)
  /// - [limit]: Nombre max résultats (défaut: 100)
  static Future<List<Map<String, dynamic>>> getGroupEvents({
    required String groupId,
    bool upcomingOnly = false,
    int limit = 100,
  }) async {
    try {
      // Récupérer groupe
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        return [];
      }
      
      final group = GroupModel.fromFirestore(groupDoc);
      
      if (!group.generateEvents || group.linkedEventSeriesId == null) {
        return [];
      }
      
      Query query = _firestore
          .collection('events')
          .where('seriesId', isEqualTo: group.linkedEventSeriesId)
          .where('linkedGroupId', isEqualTo: groupId);
      
      if (upcomingOnly) {
        query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.now());
      }
      
      query = query.orderBy('startDate').limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des événements: $e');
      return [];
    }
  }
  
  /// 🗑️ Désactive la génération d'événements pour un groupe
  /// 
  /// **Attention:** Ne supprime PAS les événements déjà créés,
  /// désactive uniquement la génération future
  static Future<void> disableEventsForGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'generateEvents': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _logGroupActivity(groupId, 'events_disabled', {});
    } catch (e) {
      throw Exception('Erreur lors de la désactivation des événements: $e');
    }
  }
  
  // Helper: Log activity
  static Future<void> _logGroupActivity(
    String groupId,
    String action,
    Map<String, dynamic> details,
  ) async {
    try {
      await _firestore.collection('group_activity_logs').add({
        'groupId': groupId,
        'action': action,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      print('Failed to log group activity: $e');
    }
  }
}
