import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

/// Script de migration pour corriger les événements récurrents existants
/// qui ont isRecurring=true mais recurrence=null
class FixExistingRecurringEvents {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Callback pour les logs
  static void Function(String)? onLog;

  /// Logs un message
  static void _log(String message) {
    _log(message);
    onLog?.call(message);
  }

  /// Exécute la migration
  static Future<void> run() async {
    _log('🔧 Début de la migration des événements récurrents...\n');

    try {
      // 1. Récupérer tous les événements marqués comme récurrents
      final eventsSnapshot = await _firestore
          .collection('events')
          .where('isRecurring', isEqualTo: true)
          .get();

      if (eventsSnapshot.docs.isEmpty) {
        _log('✅ Aucun événement récurrent trouvé');
        return;
      }

      _log('📊 ${eventsSnapshot.docs.length} événements récurrents trouvés\n');

      int fixed = 0;
      int alreadyOk = 0;
      int errors = 0;

      for (final eventDoc in eventsSnapshot.docs) {
        final eventData = eventDoc.data();
        final eventId = eventDoc.id;

        _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _log('📅 Événement: ${eventData['title']}');
        _log('🆔 ID: $eventId');

        // Vérifier si l'événement a déjà un champ recurrence
        if (eventData['recurrence'] != null) {
          _log('✅ Champ recurrence déjà présent, skip');
          alreadyOk++;
          continue;
        }

        _log('⚠️  Champ recurrence manquant, tentative de correction...');

        // 2. Chercher la règle de récurrence correspondante dans event_recurrences
        final recurrenceSnapshot = await _firestore
            .collection('event_recurrences')
            .where('parentEventId', isEqualTo: eventId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (recurrenceSnapshot.docs.isEmpty) {
          _log('❌ Aucune règle de récurrence trouvée dans event_recurrences');
          errors++;
          continue;
        }

        final recurrenceDoc = recurrenceSnapshot.docs.first;
        final recurrenceData = recurrenceDoc.data();
        
        _log('✅ Règle de récurrence trouvée: ${recurrenceDoc.id}');

        // 3. Convertir EventRecurrenceModel en EventRecurrence
        try {
          final eventRecurrence = _convertToEventRecurrence(
            recurrenceData,
            eventData['startDate'] is Timestamp
                ? (eventData['startDate'] as Timestamp).toDate()
                : DateTime.now(),
          );

          // 4. Mettre à jour l'événement avec le champ recurrence
          await _firestore.collection('events').doc(eventId).update({
            'recurrence': eventRecurrence.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          _log('✅ Événement mis à jour avec succès');
          fixed++;
        } catch (e) {
          _log('❌ Erreur lors de la conversion/mise à jour: $e');
          errors++;
        }

        _log('');
      }

      // 5. Résumé
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('📊 RÉSUMÉ DE LA MIGRATION');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('✅ Événements corrigés: $fixed');
      _log('✓  Déjà OK: $alreadyOk');
      _log('❌ Erreurs: $errors');
      _log('📊 Total traité: ${eventsSnapshot.docs.length}');
      _log('');
      _log('✅ Migration terminée !');
    } catch (e) {
      _log('❌ Erreur fatale lors de la migration: $e');
      rethrow;
    }
  }

  /// Convertit EventRecurrenceModel en EventRecurrence
  static EventRecurrence _convertToEventRecurrence(
    Map<String, dynamic> recurrenceData,
    DateTime startDate,
  ) {
    // Récupérer le type de récurrence
    final typeStr = recurrenceData['type']?.toString() ?? 'weekly';
    final frequency = _mapStringToFrequency(typeStr);
    
    // Récupérer l'intervalle
    final interval = recurrenceData['interval'] ?? 1;

    // Récupérer les jours de semaine si présents
    List<WeekDay>? daysOfWeek;
    if (recurrenceData['daysOfWeek'] != null) {
      daysOfWeek = (recurrenceData['daysOfWeek'] as List)
          .map((day) => _mapIntToWeekDay(day as int))
          .toList();
    }

    // Récupérer le jour du mois si présent
    final dayOfMonth = recurrenceData['dayOfMonth'];

    // Récupérer le mois de l'année si présent
    final monthOfYear = recurrenceData['monthOfYear'];

    // Récupérer la date de fin si présente
    DateTime? endDate;
    if (recurrenceData['endDate'] != null) {
      endDate = recurrenceData['endDate'] is Timestamp
          ? (recurrenceData['endDate'] as Timestamp).toDate()
          : DateTime.parse(recurrenceData['endDate'].toString());
    }

    // Récupérer le nombre d'occurrences si présent
    final occurrenceCount = recurrenceData['occurrenceCount'];

    // Déterminer le type de fin
    final endType = occurrenceCount != null
        ? RecurrenceEndType.afterOccurrences
        : (endDate != null ? RecurrenceEndType.onDate : RecurrenceEndType.never);

    // Créer l'objet EventRecurrence approprié selon le type
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return EventRecurrence.daily(
          interval: interval,
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );

      case RecurrenceFrequency.weekly:
        return EventRecurrence.weekly(
          interval: interval,
          daysOfWeek: daysOfWeek ?? [_getWeekDayFromDate(startDate)],
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );

      case RecurrenceFrequency.monthly:
        return EventRecurrence.monthly(
          interval: interval,
          dayOfMonth: dayOfMonth ?? startDate.day,
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );

      case RecurrenceFrequency.yearly:
        return EventRecurrence.yearly(
          interval: interval,
          monthOfYear: monthOfYear ?? startDate.month,
          dayOfMonth: dayOfMonth ?? startDate.day,
          endType: endType,
          occurrences: occurrenceCount,
          endDate: endDate,
        );
    }
  }

  /// Mappe une chaîne vers RecurrenceFrequency
  static RecurrenceFrequency _mapStringToFrequency(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'yearly':
        return RecurrenceFrequency.yearly;
      default:
        return RecurrenceFrequency.weekly;
    }
  }

  /// Mappe un entier vers WeekDay
  static WeekDay _mapIntToWeekDay(int day) {
    switch (day) {
      case 1:
        return WeekDay.monday;
      case 2:
        return WeekDay.tuesday;
      case 3:
        return WeekDay.wednesday;
      case 4:
        return WeekDay.thursday;
      case 5:
        return WeekDay.friday;
      case 6:
        return WeekDay.saturday;
      case 7:
        return WeekDay.sunday;
      default:
        return WeekDay.sunday;
    }
  }

  /// Récupère le WeekDay d'une date
  static WeekDay _getWeekDayFromDate(DateTime date) {
    return _mapIntToWeekDay(date.weekday);
  }
}
