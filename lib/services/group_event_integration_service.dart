import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/event_model.dart' hide RecurrenceFrequency;
import '../models/recurrence_config.dart';
import 'event_series_service.dart';

/// 🔄 Service d'intégration Groupes ↔ Événements (Planning Center Groups style)
/// 
/// Gère la création automatique d'événements depuis les groupes avec:
/// - Génération d'événements récurrents depuis la config groupe
/// - Synchronisation bidirectionnelle groupe ↔ événement
/// - Modification en portée (occurrence seule, futures, toutes)
/// - Liens linkedGroupId ↔ linkedEventId
class GroupEventIntegrationService {
  final FirebaseFirestore _firestore;
  final EventSeriesService _eventSeriesService;

  GroupEventIntegrationService({
    FirebaseFirestore? firestore,
    EventSeriesService? eventSeriesService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _eventSeriesService = eventSeriesService ?? EventSeriesService();

  /// 📌 Crée un groupe avec génération automatique d'événements
  /// 
  /// Paramètres:
  /// - [group]: GroupModel avec generateEvents=true et recurrenceConfig rempli
  /// - [createdBy]: ID utilisateur créateur
  /// 
  /// Retourne: ID du groupe créé
  /// 
  /// Processus:
  /// 1. Crée le groupe dans Firestore
  /// 2. Si generateEvents=true, génère série d'événements
  /// 3. Crée GroupMeetingModel pour chaque événement
  /// 4. Lie groupe ↔ événements via linkedEventSeriesId/linkedGroupId
  Future<String> createGroupWithEvents({
    required GroupModel group,
    required String createdBy,
  }) async {
    // Validation
    if (group.generateEvents) {
      if (group.recurrenceConfig == null) {
        throw ArgumentError('recurrenceConfig requis si generateEvents=true');
      }
      if (group.recurrenceStartDate == null) {
        throw ArgumentError('recurrenceStartDate requis si generateEvents=true');
      }
    }

    // 1. Créer le groupe
    final groupRef = _firestore.collection('groups').doc();
    final groupId = groupRef.id;

    // 2. Générer série d'événements si demandé
    String? eventSeriesId;
    List<EventModel> events = [];
    List<GroupMeetingModel> meetings = [];

    if (group.generateEvents) {
      eventSeriesId = _firestore.collection('events').doc().id;
      
      // Générer événements depuis config récurrence
      events = await _generateEventsFromRecurrence(
        groupId: groupId,
        groupName: group.name,
        seriesId: eventSeriesId,
        recurrenceConfig: RecurrenceConfig.fromMap(group.recurrenceConfig!),
        startDate: group.recurrenceStartDate!,
        endDate: group.recurrenceEndDate,
        maxOccurrences: group.maxOccurrences,
        createdBy: createdBy,
      );

      // Créer meetings liés aux événements
      meetings = events.map<GroupMeetingModel>((event) {
        return GroupMeetingModel(
          id: _firestore.collection('groups').doc(groupId).collection('meetings').doc().id,
          groupId: groupId,
          title: event.title,
          date: event.startDate,
          location: event.location ?? group.location,
          description: event.description,
          isRecurring: true,
          seriesId: eventSeriesId,
          linkedEventId: event.id,
          isModified: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    }

    // 3. Sauvegarder groupe avec linkedEventSeriesId
    final groupToSave = group.copyWith(
      linkedEventSeriesId: eventSeriesId,
    );

    await groupRef.set(groupToSave.toFirestore());

    // 4. Sauvegarder événements
    final batch = _firestore.batch();
    for (final event in events) {
      final eventRef = _firestore.collection('events').doc(event.id);
      batch.set(eventRef, event.toFirestore());
    }

    // 5. Sauvegarder meetings
    for (final meeting in meetings) {
      final meetingRef = groupRef.collection('meetings').doc(meeting.id);
      batch.set(meetingRef, meeting.toFirestore());
    }

    await batch.commit();

    return groupId;
  }

  /// 🔄 Active la génération d'événements pour un groupe existant
  /// 
  /// Paramètres:
  /// - [groupId]: ID du groupe
  /// - [recurrenceConfig]: Configuration récurrence
  /// - [startDate]: Date début récurrence
  /// - [endDate]: Date fin (optionnel)
  /// - [maxOccurrences]: Nombre max occurrences (optionnel)
  /// - [userId]: ID utilisateur effectuant l'action
  Future<void> enableEventsForGroup({
    required String groupId,
    required RecurrenceConfig recurrenceConfig,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
    required String userId,
  }) async {
    // Récupérer groupe
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Groupe non trouvé: $groupId');
    }

    final group = GroupModel.fromFirestore(groupDoc);

    // Générer série d'événements
    final eventSeriesId = _firestore.collection('events').doc().id;
    
    final events = await _generateEventsFromRecurrence(
      groupId: groupId,
      groupName: group.name,
      seriesId: eventSeriesId,
      recurrenceConfig: recurrenceConfig,
      startDate: startDate,
      endDate: endDate,
      maxOccurrences: maxOccurrences,
      createdBy: userId,
    );

    // Créer meetings
    final meetings = events.map<GroupMeetingModel>((event) {
      return GroupMeetingModel(
        id: '',  // ID sera généré par Firestore
        groupId: groupId,
        title: event.title,
        date: event.startDate,
        location: event.location,
        description: event.description,
        isRecurring: true,
        seriesId: eventSeriesId,
        linkedEventId: event.id,
        isModified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    // Sauvegarder
    final batch = _firestore.batch();

    // Mettre à jour groupe
    batch.update(groupDoc.reference, {
      'generateEvents': true,
      'linkedEventSeriesId': eventSeriesId,
      'recurrenceConfig': recurrenceConfig.toMap(),
      'recurrenceStartDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'recurrenceEndDate': Timestamp.fromDate(endDate),
      if (maxOccurrences != null) 'maxOccurrences': maxOccurrences,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Sauvegarder événements
    for (final event in events) {
      final eventRef = _firestore.collection('events').doc(event.id);
      batch.set(eventRef, event.toFirestore());
    }

    // 🔥 CORRECTION: Sauvegarder meetings dans la collection racine 'group_meetings'
    // (pas dans la sous-collection groups/{groupId}/meetings)
    for (final meeting in meetings) {
      final meetingRef = _firestore.collection('group_meetings').doc();  // Collection racine
      batch.set(meetingRef, {
        ...meeting.toFirestore(),
        'id': meetingRef.id,  // Ajouter l'ID généré
      });
    }

    await batch.commit();
    
    print('✅ Groupe avec événements créé:');
    print('   - ${events.length} événements');
    print('   - ${meetings.length} meetings');
  }

  /// ✏️ Met à jour un groupe et ses événements (avec choix de portée)
  /// 
  /// Paramètres:
  /// - [groupId]: ID du groupe
  /// - [updates]: Map des champs à mettre à jour
  /// - [scope]: Portée modification (thisOccurrenceOnly, thisAndFutureOccurrences, allOccurrences)
  /// - [occurrenceDate]: Date occurrence concernée (si scope != allOccurrences)
  /// - [userId]: ID utilisateur
  Future<void> updateGroupWithEvents({
    required String groupId,
    required Map<String, dynamic> updates,
    required GroupEditScope scope,
    DateTime? occurrenceDate,
    required String userId,
  }) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Groupe non trouvé: $groupId');
    }

    final group = GroupModel.fromFirestore(groupDoc);

    if (!group.generateEvents) {
      // Groupe sans événements: mise à jour simple
      await groupDoc.reference.update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Groupe avec événements: gérer portée
    switch (scope) {
      case GroupEditScope.thisOccurrenceOnly:
        if (occurrenceDate == null) {
          throw ArgumentError('occurrenceDate requis pour thisOccurrenceOnly');
        }
        await _updateSingleOccurrence(
          groupId: groupId,
          occurrenceDate: occurrenceDate,
          updates: updates,
          userId: userId,
        );
        break;

      case GroupEditScope.thisAndFutureOccurrences:
        if (occurrenceDate == null) {
          throw ArgumentError('occurrenceDate requis pour thisAndFutureOccurrences');
        }
        await _updateFutureOccurrences(
          groupId: groupId,
          fromDate: occurrenceDate,
          updates: updates,
          userId: userId,
        );
        break;

      case GroupEditScope.allOccurrences:
        await _updateAllOccurrences(
          groupId: groupId,
          updates: updates,
          userId: userId,
        );
        break;
    }
  }

  /// 🔗 Synchronise un meeting avec son événement lié
  /// 
  /// Utilisé quand l'événement est modifié directement
  Future<void> syncMeetingWithEvent({
    required String eventId,
    required String userId,
  }) async {
    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('Événement non trouvé: $eventId');
    }

    final event = EventModel.fromFirestore(eventDoc);
    
    if (event.linkedGroupId == null || event.linkedMeetingId == null) {
      // Événement non lié à un groupe
      return;
    }

    // Récupérer meeting
    final meetingRef = _firestore
        .collection('groups')
        .doc(event.linkedGroupId)
        .collection('meetings')
        .doc(event.linkedMeetingId);

    final meetingDoc = await meetingRef.get();
    if (!meetingDoc.exists) {
      throw Exception('Meeting non trouvé: ${event.linkedMeetingId}');
    }

    // Mettre à jour meeting depuis événement
    await meetingRef.update({
      'title': event.title,
      'date': Timestamp.fromDate(event.startDate),
      'startTime': Timestamp.fromDate(event.startDate),
      'endTime': event.endDate != null ? Timestamp.fromDate(event.endDate!) : Timestamp.fromDate(event.startDate),
      'location': event.location,
      'description': event.description,
      'isModified': true, // Marquer comme modifié
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔄 Génère événements depuis config récurrence groupe
  Future<List<EventModel>> _generateEventsFromRecurrence({
    required String groupId,
    required String groupName,
    required String seriesId,
    required RecurrenceConfig recurrenceConfig,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
    required String createdBy,
  }) async {
    final events = <EventModel>[];

    // Calculer nombre d'occurrences
    final totalOccurrences = maxOccurrences ?? recurrenceConfig.calculateTotalOccurrences();

    DateTime currentDate = startDate;
    
    for (int i = 0; i < totalOccurrences; i++) {
      // Vérifier date fin
      if (endDate != null && currentDate.isAfter(endDate)) {
        break;
      }

      // Créer événement
      final eventId = _firestore.collection('events').doc().id;
      
      // Parser l'heure depuis le format "HH:mm"
      final timeParts = recurrenceConfig.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final event = EventModel(
        id: eventId,
        title: 'Réunion $groupName',
        description: 'Réunion de groupe générée automatiquement',
        startDate: DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        ),
        endDate: DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        ).add(Duration(minutes: recurrenceConfig.durationMinutes)),
        location: '',
        type: 'group_meeting',
        responsibleIds: [],
        visibility: 'public',
        visibilityTargets: [],
        status: 'published',
        isRecurring: true,
        seriesId: seriesId,
        isSeriesMaster: i == 0,
        linkedGroupId: groupId,
        isGroupEvent: true,
        occurrenceIndex: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
        lastModifiedBy: createdBy,
      );

      events.add(event);

      // Calculer prochaine date
      currentDate = _getNextOccurrence(
        currentDate: currentDate,
        recurrenceConfig: recurrenceConfig,
      );
    }

    return events;
  }

  /// 📅 Calcule prochaine occurrence selon config récurrence
  DateTime _getNextOccurrence({
    required DateTime currentDate,
    required RecurrenceConfig recurrenceConfig,
  }) {
    switch (recurrenceConfig.frequency) {
      case RecurrenceFrequency.daily:
        return currentDate.add(Duration(days: recurrenceConfig.interval));

      case RecurrenceFrequency.weekly:
        return currentDate.add(Duration(days: 7 * recurrenceConfig.interval));

      case RecurrenceFrequency.monthly:
        return DateTime(
          currentDate.year,
          currentDate.month + recurrenceConfig.interval,
          currentDate.day,
        );

      case RecurrenceFrequency.yearly:
        return DateTime(
          currentDate.year + recurrenceConfig.interval,
          currentDate.month,
          currentDate.day,
        );

      case RecurrenceFrequency.custom:
        // Pour custom, utiliser weekly par défaut
        return currentDate.add(Duration(days: 7 * recurrenceConfig.interval));
    }
  }

  /// ✏️ Met à jour une seule occurrence
  Future<void> _updateSingleOccurrence({
    required String groupId,
    required DateTime occurrenceDate,
    required Map<String, dynamic> updates,
    required String userId,
  }) async {
    // Trouver meeting correspondant à la date
    final meetingsSnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('meetings')
        .where('date', isEqualTo: Timestamp.fromDate(occurrenceDate))
        .limit(1)
        .get();

    if (meetingsSnapshot.docs.isEmpty) {
      throw Exception('Meeting non trouvé pour date: $occurrenceDate');
    }

    final meetingDoc = meetingsSnapshot.docs.first;
    final meeting = GroupMeetingModel.fromFirestore(meetingDoc);

    // Mettre à jour meeting
    await meetingDoc.reference.update({
      ...updates,
      'isModified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mettre à jour événement lié si existe
    if (meeting.linkedEventId != null) {
      final eventRef = _firestore.collection('events').doc(meeting.linkedEventId);
      await eventRef.update({
        ...updates,
        'isModifiedOccurrence': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ✏️ Met à jour occurrences futures (à partir d'une date)
  Future<void> _updateFutureOccurrences({
    required String groupId,
    required DateTime fromDate,
    required Map<String, dynamic> updates,
    required String userId,
  }) async {
    // Trouver tous meetings >= fromDate
    final meetingsSnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('meetings')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
        .get();

    final batch = _firestore.batch();

    for (final meetingDoc in meetingsSnapshot.docs) {
      final meeting = GroupMeetingModel.fromFirestore(meetingDoc);

      // Mettre à jour meeting
      batch.update(meetingDoc.reference, {
        ...updates,
        'isModified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour événement lié
      if (meeting.linkedEventId != null) {
        final eventRef = _firestore.collection('events').doc(meeting.linkedEventId);
        batch.update(eventRef, {
          ...updates,
          'isModifiedOccurrence': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// ✏️ Met à jour toutes les occurrences
  Future<void> _updateAllOccurrences({
    required String groupId,
    required Map<String, dynamic> updates,
    required String userId,
  }) async {
    // Mettre à jour groupe
    await _firestore.collection('groups').doc(groupId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mettre à jour tous meetings
    final meetingsSnapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('meetings')
        .get();

    final batch = _firestore.batch();

    for (final meetingDoc in meetingsSnapshot.docs) {
      final meeting = GroupMeetingModel.fromFirestore(meetingDoc);

      batch.update(meetingDoc.reference, {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour événement lié
      if (meeting.linkedEventId != null) {
        final eventRef = _firestore.collection('events').doc(meeting.linkedEventId);
        batch.update(eventRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  /// 🗑️ Supprime un groupe et ses événements liés
  Future<void> deleteGroupWithEvents({
    required String groupId,
    required String userId,
  }) async {
    print('🗑️ Suppression groupe $groupId avec tous ses événements/meetings');
    
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Groupe non trouvé: $groupId');
    }
    
    // 🔥 CORRECTION: Supprimer TOUS les événements liés au groupe (pas seulement ceux de la série)
    print('   🔍 Recherche de tous les événements liés au groupe...');
    final eventsSnapshot = await _firestore
        .collection('events')
        .where('linkedGroupId', isEqualTo: groupId)
        .get();

    print('   📊 ${eventsSnapshot.docs.length} événements trouvés');

    // Utiliser plusieurs batches si nécessaire (max 500 opérations par batch)
    final batches = <WriteBatch>[];
    var currentBatch = _firestore.batch();
    var operationCount = 0;

    // Supprimer tous les événements du groupe
    for (final eventDoc in eventsSnapshot.docs) {
      currentBatch.delete(eventDoc.reference);
      operationCount++;
      
      if (operationCount >= 500) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }

    // Supprimer meetings (collection group_meetings)
    print('   🔍 Recherche de tous les meetings du groupe...');
    final meetingsSnapshot = await _firestore
        .collection('group_meetings')
        .where('groupId', isEqualTo: groupId)
        .get();

    print('   📊 ${meetingsSnapshot.docs.length} meetings trouvés');

    for (final meetingDoc in meetingsSnapshot.docs) {
      currentBatch.delete(meetingDoc.reference);
      operationCount++;
      
      if (operationCount >= 500) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }

    // Supprimer membres du groupe
    print('   🔍 Recherche des membres du groupe...');
    final membersSnapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .get();

    print('   📊 ${membersSnapshot.docs.length} membres trouvés');

    for (final memberDoc in membersSnapshot.docs) {
      currentBatch.delete(memberDoc.reference);
      operationCount++;
      
      if (operationCount >= 500) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
        operationCount = 0;
      }
    }

    // Supprimer le groupe lui-même
    currentBatch.delete(groupDoc.reference);
    operationCount++;

    // Ajouter le dernier batch s'il contient des opérations
    if (operationCount > 0) {
      batches.add(currentBatch);
    }

    // Commit tous les batches
    print('   💾 Commit de ${batches.length} batch(es)...');
    for (int i = 0; i < batches.length; i++) {
      await batches[i].commit();
      print('      ✅ Batch ${i + 1}/${batches.length} committed');
    }

    print('   ✅ Groupe supprimé avec:');
    print('      - ${eventsSnapshot.docs.length} événements');
    print('      - ${meetingsSnapshot.docs.length} meetings');
    print('      - ${membersSnapshot.docs.length} membres');
  }
}
