import 'package:cloud_firestore/cloud_firestore.dart';

/// Script ultra-simple pour débugger et corriger les événements récurrents
class QuickRecurrenceFix {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Callback pour les logs
  static void Function(String)? onLog;
  
  /// Log un message
  static void _log(String message) {
    print(message); // ← CORRIGÉ : print au lieu de _log
    onLog?.call(message);
  }

  /// Diagnostic complet et correction automatique
  static Future<void> fixNow() async {
    _log('🔧 DIAGNOSTIC ET CORRECTION DES ÉVÉNEMENTS RÉCURRENTS\n');
    
    try {
      // 1. Récupérer TOUS les événements récurrents
      final eventsQuery = await _firestore
          .collection('events')
          .where('isRecurring', isEqualTo: true)
          .get();

      if (eventsQuery.docs.isEmpty) {
        _log('❌ PROBLÈME : Aucun événement récurrent trouvé !');
        _log('➜ Solution : Créez un service récurrent d\'abord\n');
        return;
      }

      _log('📊 ${eventsQuery.docs.length} événements récurrents trouvés\n');

      int fixed = 0;
      int alreadyOk = 0;
      int noRecurrenceRule = 0;

      for (final eventDoc in eventsQuery.docs) {
        final eventData = eventDoc.data();
        final eventId = eventDoc.id;
        
        _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _log('📅 ${eventData['title']}');
        _log('🆔 $eventId');

        // Vérifier le champ recurrence
        if (eventData['recurrence'] != null) {
          _log('✅ Champ recurrence OK');
          alreadyOk++;
          continue;
        }

        _log('❌ Champ recurrence MANQUANT');
        
        // Chercher dans event_recurrences
        final recurrenceQuery = await _firestore
            .collection('event_recurrences')
            .where('parentEventId', isEqualTo: eventId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (recurrenceQuery.docs.isEmpty) {
          _log('⚠️  Aucune règle dans event_recurrences');
          noRecurrenceRule++;
          
          // SOLUTION : Créer une récurrence par défaut hebdomadaire
          _log('🔧 Création récurrence par défaut (hebdomadaire)...');
          
          final startDate = eventData['startDate'] is Timestamp
              ? (eventData['startDate'] as Timestamp).toDate()
              : DateTime.now();
          
          final weekDay = _getWeekDay(startDate.weekday);
          
          await _firestore.collection('events').doc(eventId).update({
            'recurrence': {
              'frequency': 'weekly',
              'interval': 1,
              'daysOfWeek': [weekDay],
              'endType': 'never',
              'occurrences': null,
              'endDate': null,
              'exceptions': [],
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          _log('✅ Récurrence hebdomadaire créée');
          fixed++;
          continue;
        }

        // Convertir la règle existante
        final recurrenceData = recurrenceQuery.docs.first.data();
        _log('🔄 Conversion de la règle existante...');
        
        final startDate = eventData['startDate'] is Timestamp
            ? (eventData['startDate'] as Timestamp).toDate()
            : DateTime.now();
        
        final recurrenceMap = _convertRecurrence(recurrenceData, startDate);
        
        await _firestore.collection('events').doc(eventId).update({
          'recurrence': recurrenceMap,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        _log('✅ Récurrence convertie et ajoutée');
        fixed++;
      }

      _log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('📊 RÉSUMÉ');
      _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log('✅ Corrigés : $fixed');
      _log('✓  Déjà OK : $alreadyOk');
      _log('⚠️  Créés par défaut : $noRecurrenceRule');
      _log('\n🎉 TERMINÉ ! Vérifiez maintenant le calendrier.');
      
    } catch (e, stack) {
      _log('\n❌ ERREUR : $e');
      _log('Stack: $stack');
    }
  }

  /// Convertit une règle event_recurrences en format EventRecurrence
  static Map<String, dynamic> _convertRecurrence(
    Map<String, dynamic> recurrenceData,
    DateTime startDate,
  ) {
    final type = recurrenceData['type']?.toString() ?? 'weekly';
    final interval = recurrenceData['interval'] ?? 1;
    
    List<String>? daysOfWeek;
    if (recurrenceData['daysOfWeek'] != null) {
      daysOfWeek = (recurrenceData['daysOfWeek'] as List)
          .map((day) => _getWeekDay(day as int))
          .toList();
    }

    DateTime? endDate;
    if (recurrenceData['endDate'] != null) {
      endDate = recurrenceData['endDate'] is Timestamp
          ? (recurrenceData['endDate'] as Timestamp).toDate()
          : DateTime.parse(recurrenceData['endDate'].toString());
    }

    final occurrences = recurrenceData['occurrenceCount'];
    final endType = occurrences != null
        ? 'afterOccurrences'
        : (endDate != null ? 'onDate' : 'never');

    return {
      'frequency': type,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': recurrenceData['dayOfMonth'],
      'weekOfMonth': null,
      'monthOfYear': recurrenceData['monthOfYear'],
      'endType': endType,
      'occurrences': occurrences,
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'exceptions': [],
    };
  }

  /// Convertit un numéro de jour en nom
  static String _getWeekDay(int day) {
    switch (day) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'sunday';
    }
  }
}
