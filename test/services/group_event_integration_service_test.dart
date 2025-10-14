import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:jubile_tabernacle_france/services/group_event_integration_service.dart';
import 'package:jubile_tabernacle_france/models/group_model.dart';
import 'package:jubile_tabernacle_france/models/event_model.dart';
import 'package:jubile_tabernacle_france/models/recurrence_config.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GroupEventIntegrationService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = GroupEventIntegrationService(firestore: fakeFirestore);
  });

  group('GroupEventIntegrationService', () {
    test('createEventFromMeeting - creates event with correct data', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Jeunes Adultes',
        description: 'Groupe jeunes adultes',
        category: 'fellowship',
        leaderId: 'leader1',
        leaderName: 'Jean Dupont',
        leaderPhone: '0123456789',
        memberCount: 15,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
      );

      final meeting = GroupMeetingModel(
        id: 'meeting1',
        date: DateTime(2025, 10, 14, 19, 30),
        location: 'Salle 3',
        description: 'Réunion hebdomadaire',
        isRecurring: true,
        seriesId: 'series1',
      );

      final event = await service.createEventFromMeeting(group, meeting);

      expect(event, isNotNull);
      expect(event!.title, contains('Jeunes Adultes'));
      expect(event.startDate, meeting.date);
      expect(event.location, meeting.location);
      expect(event.isGroupEvent, true);
      expect(event.linkedGroupId, group.id);
      expect(event.linkedGroupName, group.name);
    });

    test('syncMeetingWithEvent - updates event when meeting changes', () async {
      // Créer événement initial
      final eventRef = await fakeFirestore.collection('events').add({
        'title': 'Jeunes Adultes - Réunion',
        'startDate': DateTime(2025, 10, 14, 19, 30).toIso8601String(),
        'location': 'Salle 3',
        'isGroupEvent': true,
        'linkedGroupId': 'group1',
      });

      // Créer meeting lié
      final groupRef = fakeFirestore.collection('groups').doc('group1');
      await groupRef.set({'name': 'Jeunes Adultes'});
      
      final meetingRef = await groupRef.collection('meetings').add({
        'date': DateTime(2025, 10, 14, 19, 30).toIso8601String(),
        'location': 'Salle 3',
        'linkedEventId': eventRef.id,
      });

      final meeting = GroupMeetingModel(
        id: meetingRef.id,
        date: DateTime(2025, 10, 14, 20, 0), // Heure changée
        location: 'Salle 5', // Lieu changé
        linkedEventId: eventRef.id,
      );

      // Sync
      await service.syncMeetingWithEvent('group1', meeting);

      // Vérifier événement mis à jour
      final updatedEvent = await eventRef.get();
      expect(updatedEvent.exists, true);
      expect(updatedEvent.data()?['location'], 'Salle 5');
    });

    test('generateEventsForGroup - daily frequency', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Prière quotidienne',
        description: 'Groupe prière',
        category: 'prayer',
        leaderId: 'leader1',
        leaderName: 'Marie Martin',
        leaderPhone: '0123456789',
        memberCount: 10,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
        recurrenceConfig: RecurrenceConfig(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: DateTime(2025, 10, 14, 7, 0),
          endType: RecurrenceEndType.after,
          occurrences: 5,
          duration: 60,
        ),
      );

      final events = await service.generateEventsForGroup(group);

      expect(events.length, 5);
      expect(events[0].startDate.day, 14);
      expect(events[1].startDate.day, 15);
      expect(events[2].startDate.day, 16);
      expect(events[3].startDate.day, 17);
      expect(events[4].startDate.day, 18);
    });

    test('generateEventsForGroup - weekly frequency', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Jeunes Adultes',
        description: 'Groupe jeunes',
        category: 'fellowship',
        leaderId: 'leader1',
        leaderName: 'Jean Dupont',
        leaderPhone: '0123456789',
        memberCount: 15,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
        recurrenceConfig: RecurrenceConfig(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          startDate: DateTime(2025, 10, 14, 19, 30), // Mardi
          endType: RecurrenceEndType.after,
          occurrences: 3,
          daysOfWeek: [2, 4], // Mardi, Jeudi
          duration: 120,
        ),
      );

      final events = await service.generateEventsForGroup(group);

      expect(events.length, 3);
      expect(events[0].startDate.weekday, 2); // Mardi
      expect(events[1].startDate.weekday, 4); // Jeudi
      expect(events[2].startDate.weekday, 2); // Mardi suivant
    });

    test('generateEventsForGroup - excludes dates', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Groupe test',
        description: 'Test excludeDates',
        category: 'fellowship',
        leaderId: 'leader1',
        leaderName: 'Test User',
        leaderPhone: '0123456789',
        memberCount: 10,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
        recurrenceConfig: RecurrenceConfig(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: DateTime(2025, 10, 14),
          endType: RecurrenceEndType.after,
          occurrences: 5,
          excludeDates: [
            DateTime(2025, 10, 15), // Exclu
            DateTime(2025, 10, 17), // Exclu
          ],
        ),
      );

      final events = await service.generateEventsForGroup(group);

      expect(events.length, 3); // 5 - 2 exclus
      expect(events[0].startDate.day, 14);
      expect(events[1].startDate.day, 16);
      expect(events[2].startDate.day, 18);
    });

    test('generateEventsForGroup - respects endDate', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Groupe limité',
        description: 'Test endDate',
        category: 'fellowship',
        leaderId: 'leader1',
        leaderName: 'Test User',
        leaderPhone: '0123456789',
        memberCount: 10,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
        recurrenceConfig: RecurrenceConfig(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          startDate: DateTime(2025, 10, 14),
          endType: RecurrenceEndType.on,
          endDate: DateTime(2025, 10, 16),
        ),
      );

      final events = await service.generateEventsForGroup(group);

      expect(events.length, 3); // 14, 15, 16
      expect(events.last.startDate.day, 16);
    });

    test('generateEventsForGroup - monthly on day of month', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Réunion mensuelle',
        description: 'Chaque 14 du mois',
        category: 'fellowship',
        leaderId: 'leader1',
        leaderName: 'Test User',
        leaderPhone: '0123456789',
        memberCount: 10,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
        recurrenceConfig: RecurrenceConfig(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime(2025, 10, 14),
          endType: RecurrenceEndType.after,
          occurrences: 3,
          monthlyType: MonthlyRecurrenceType.dayOfMonth,
        ),
      );

      final events = await service.generateEventsForGroup(group);

      expect(events.length, 3);
      expect(events[0].startDate.day, 14);
      expect(events[0].startDate.month, 10);
      expect(events[1].startDate.day, 14);
      expect(events[1].startDate.month, 11);
      expect(events[2].startDate.day, 14);
      expect(events[2].startDate.month, 12);
    });

    test('generateEventsForGroup - handles edge case (31st of month)', () async {
      final group = GroupModel(
        id: 'group1',
        name: 'Groupe 31',
        description: 'Test 31ème jour',
        category: 'fellowship',
        leaderId: 'leader1',
        leaderName: 'Test User',
        leaderPhone: '0123456789',
        memberCount: 10,
        createdAt: DateTime.now(),
        isActive: true,
        generateEvents: true,
        recurrenceConfig: RecurrenceConfig(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: DateTime(2025, 10, 31), // 31 octobre
          endType: RecurrenceEndType.after,
          occurrences: 3,
          monthlyType: MonthlyRecurrenceType.dayOfMonth,
        ),
      );

      final events = await service.generateEventsForGroup(group);

      expect(events.length, 3);
      expect(events[0].startDate.day, 31); // 31 oct
      // Novembre n'a que 30 jours → 30 nov
      expect(events[1].startDate.month, 11);
      expect(events[2].startDate.day, 31); // 31 déc
    });

    test('unlinkMeetingFromEvent - removes link', () async {
      // Créer événement
      final eventRef = await fakeFirestore.collection('events').add({
        'title': 'Test Event',
        'linkedGroupId': 'group1',
      });

      // Créer meeting lié
      final groupRef = fakeFirestore.collection('groups').doc('group1');
      await groupRef.set({'name': 'Test Group'});
      
      final meetingRef = await groupRef.collection('meetings').add({
        'date': DateTime.now().toIso8601String(),
        'linkedEventId': eventRef.id,
      });

      // Unlink
      await service.unlinkMeetingFromEvent('group1', meetingRef.id);

      // Vérifier meeting mis à jour
      final updatedMeeting = await meetingRef.get();
      expect(updatedMeeting.data()?['linkedEventId'], isNull);
    });
  });
}
