import 'package:cloud_firestore/cloud_firestore.dart';

/// Diagnostic ultra-détaillé pour comprendre pourquoi les occurrences n'apparaissent pas
class CalendarDiagnostic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static void Function(String)? onLog;
  
  static void _log(String message) {
    print(message);
    onLog?.call(message);
  }

  /// Diagnostic complet
  static Future<void> diagnose() async {
    _log('🔍 DIAGNOSTIC COMPLET DU CALENDRIER\n');
    
    try {
      // 1. Vérifier les événements récurrents
      _log('━━━ ÉTAPE 1 : ÉVÉNEMENTS RÉCURRENTS ━━━');
      final recurringEvents = await _firestore
          .collection('events')
          .where('isRecurring', isEqualTo: true)
          .get();
      
      _log('📊 ${recurringEvents.docs.length} événements récurrents trouvés\n');
      
      if (recurringEvents.docs.isEmpty) {
        _log('❌ PROBLÈME : Aucun événement récurrent dans la base !');
        _log('➜ Solution : Créez d\'abord un service récurrent\n');
        return;
      }
      
      // 2. Analyser chaque événement
      int withRecurrence = 0;
      int withoutRecurrence = 0;
      int published = 0;
      int notPublished = 0;
      
      for (final doc in recurringEvents.docs) {
        final data = doc.data();
        final hasRecurrence = data['recurrence'] != null;
        final status = data['status'] ?? 'brouillon';
        final isPublished = status == 'publie';
        
        _log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _log('📅 ${data['title']}');
        _log('🆔 ${doc.id}');
        _log('📝 Statut: $status ${isPublished ? '✅' : '❌ PAS PUBLIÉ'}');
        _log('🔄 isRecurring: ${data['isRecurring']}');
        _log('📋 Champ recurrence: ${hasRecurrence ? '✅ Présent' : '❌ Absent'}');
        
        if (hasRecurrence) {
          final rec = data['recurrence'] as Map<String, dynamic>;
          _log('   ├─ frequency: ${rec['frequency']}');
          _log('   ├─ interval: ${rec['interval']}');
          _log('   ├─ daysOfWeek: ${rec['daysOfWeek']}');
          _log('   └─ endType: ${rec['endType']}');
          withRecurrence++;
        } else {
          withoutRecurrence++;
        }
        
        if (isPublished) {
          published++;
        } else {
          notPublished++;
          _log('⚠️  ATTENTION : Événement NON PUBLIÉ !');
          _log('   Le calendrier filtre par status="publie"');
        }
        _log('');
      }
      
      // 3. Test de génération d'occurrences
      _log('\n━━━ ÉTAPE 2 : TEST GÉNÉRATION D\'OCCURRENCES ━━━');
      
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 2, 1);
      
      _log('📅 Période testée : ${_formatDate(startDate)} → ${_formatDate(endDate)}\n');
      
      for (final doc in recurringEvents.docs.take(3)) {
        final data = doc.data();
        final recurrence = data['recurrence'];
        
        if (recurrence == null) continue;
        
        _log('🧪 Test pour: ${data['title']}');
        
        try {
          final rec = recurrence as Map<String, dynamic>;
          final frequency = rec['frequency'];
          final interval = rec['interval'] ?? 1;
          final eventStartDate = (data['startDate'] as Timestamp).toDate();
          
          _log('   Date début: ${_formatDate(eventStartDate)}');
          _log('   Fréquence: $frequency (interval: $interval)');
          
          // Générer quelques occurrences manuellement
          final occurrences = _generateTestOccurrences(
            eventStartDate,
            frequency,
            interval,
            rec['daysOfWeek'],
            startDate,
            endDate,
          );
          
          _log('   ✅ ${occurrences.length} occurrences générées:');
          for (final occ in occurrences.take(5)) {
            _log('      • ${_formatDate(occ)}');
          }
          
        } catch (e) {
          _log('   ❌ Erreur lors de la génération: $e');
        }
        _log('');
      }
      
      // 4. Résumé
      _log('\n━━━ RÉSUMÉ DU DIAGNOSTIC ━━━');
      _log('📊 Événements récurrents: ${recurringEvents.docs.length}');
      _log('✅ Avec champ recurrence: $withRecurrence');
      _log('❌ Sans champ recurrence: $withoutRecurrence');
      _log('✅ Publiés: $published');
      _log('❌ Non publiés: $notPublished');
      
      _log('\n━━━ PROBLÈMES DÉTECTÉS ━━━');
      
      if (withoutRecurrence > 0) {
        _log('⚠️  $withoutRecurrence événements sans champ recurrence');
        _log('   → Relancez le fix pour les corriger');
      }
      
      if (notPublished > 0) {
        _log('⚠️  $notPublished événements NON PUBLIÉS');
        _log('   → Le calendrier ne montre que les événements publiés !');
        _log('   → Allez dans l\'admin et publiez ces événements');
      }
      
      if (withRecurrence > 0 && published > 0) {
        _log('\n✅ Configuration OK pour afficher les occurrences !');
        _log('➜ Si vous ne les voyez toujours pas:');
        _log('   1. Rechargez complètement le calendrier (Cmd+R)');
        _log('   2. Vérifiez la période affichée (dates futures)');
        _log('   3. Désactivez les filtres de recherche/type');
      }
      
      _log('\n✅ DIAGNOSTIC TERMINÉ');
      
    } catch (e, stack) {
      _log('\n❌ ERREUR DIAGNOSTIC: $e');
      _log('Stack: $stack');
    }
  }
  
  /// Génère des occurrences de test
  static List<DateTime> _generateTestOccurrences(
    DateTime eventStart,
    String frequency,
    int interval,
    dynamic daysOfWeek,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final occurrences = <DateTime>[];
    var current = eventStart;
    
    // Avancer jusqu'au début de la période
    while (current.isBefore(rangeStart)) {
      current = _nextOccurrence(current, frequency, interval, daysOfWeek);
    }
    
    // Générer les occurrences dans la période
    while (current.isBefore(rangeEnd) && occurrences.length < 20) {
      occurrences.add(current);
      current = _nextOccurrence(current, frequency, interval, daysOfWeek);
    }
    
    return occurrences;
  }
  
  static DateTime _nextOccurrence(
    DateTime current,
    String frequency,
    int interval,
    dynamic daysOfWeek,
  ) {
    switch (frequency) {
      case 'daily':
        return current.add(Duration(days: interval));
      case 'weekly':
        return current.add(Duration(days: 7 * interval));
      case 'monthly':
        return DateTime(current.year, current.month + interval, current.day);
      case 'yearly':
        return DateTime(current.year + interval, current.month, current.day);
      default:
        return current.add(const Duration(days: 7));
    }
  }
  
  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
