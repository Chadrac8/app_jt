import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jubile_tabernacle_france/models/recurrence_config.dart';

/// Script migration groupes existants vers nouveau système intégration événements
/// 
/// Usage:
/// ```dart
/// await migrateExistingGroups();
/// ```
/// 
/// Ce script :
/// - Analyse tous les groupes existants
/// - Propose conversion vers système récurrence
/// - Crée événements automatiquement
/// - Conserve données existantes
void main() async {
  print('🔄 Migration Groupes → Intégration Événements');
  print('=' * 60);
  
  try {
    final stats = await migrateExistingGroups();
    
    print('\n✅ Migration terminée avec succès !');
    print('📊 Statistiques :');
    print('   - Groupes analysés : ${stats['analyzed']}');
    print('   - Groupes migrés : ${stats['migrated']}');
    print('   - Événements créés : ${stats['eventsCreated']}');
    print('   - Erreurs : ${stats['errors']}');
    
  } catch (e) {
    print('\n❌ Erreur migration : $e');
  }
}

/// Migre tous les groupes existants
Future<Map<String, int>> migrateExistingGroups({
  bool dryRun = false,
  bool autoConfirm = false,
}) async {
  final firestore = FirebaseFirestore.instance;
  final stats = {
    'analyzed': 0,
    'migrated': 0,
    'eventsCreated': 0,
    'errors': 0,
    'skipped': 0,
  };

  print('\n📋 Mode : ${dryRun ? 'DRY RUN (simulation)' : 'PRODUCTION'}');
  print('⚙️  Auto-confirm : ${autoConfirm ? 'OUI' : 'NON'}\n');

  // 1. Récupérer tous les groupes actifs
  final groupsSnapshot = await firestore
      .collection('groups')
      .where('isActive', isEqualTo: true)
      .get();

  stats['analyzed'] = groupsSnapshot.docs.length;
  print('📊 ${stats['analyzed']} groupes actifs trouvés\n');

  for (final groupDoc in groupsSnapshot.docs) {
    final groupData = groupDoc.data();
    final groupId = groupDoc.id;
    final groupName = groupData['name'] ?? 'Sans nom';

    print('─' * 60);
    print('👥 Groupe: $groupName (ID: $groupId)');

    try {
      // Vérifier si déjà migré
      if (groupData['generateEvents'] == true) {
        print('   ⏭️  Déjà migré (generateEvents = true)');
        stats['skipped']++;
        continue;
      }

      // Analyser configuration existante
      final frequency = groupData['frequency'] ?? '';
      final dayOfWeek = groupData['dayOfWeek'] as int?;
      final time = groupData['time'] ?? '';

      if (frequency.isEmpty || dayOfWeek == null || time.isEmpty) {
        print('   ⚠️  Configuration incomplète, migration impossible');
        stats['skipped']++;
        continue;
      }

      // Proposer migration
      print('   📅 Configuration actuelle :');
      print('      - Fréquence : $frequency');
      print('      - Jour : ${_getDayName(dayOfWeek)} ($dayOfWeek)');
      print('      - Heure : $time');

      // Créer RecurrenceConfig
      final recurrenceConfig = _createRecurrenceConfig(
        frequency: frequency,
        dayOfWeek: dayOfWeek,
        time: time,
      );

      if (recurrenceConfig == null) {
        print('   ❌ Impossible de créer configuration récurrence');
        stats['errors']++;
        continue;
      }

      print('   ✅ Configuration récurrence créée :');
      print('      - Fréquence : ${recurrenceConfig.frequency.displayName}');
      print('      - Intervalle : ${recurrenceConfig.interval}');
      if (recurrenceConfig.daysOfWeek != null) {
        print('      - Jours : ${recurrenceConfig.daysOfWeek}');
      }

      // Confirmer migration
      if (!autoConfirm && !dryRun) {
        print('\n   ❓ Migrer ce groupe ? (y/n)');
        // final response = stdin.readLineSync();
        // if (response?.toLowerCase() != 'y') {
        //   print('   ⏭️  Migration annulée par l'utilisateur');
        //   stats['skipped']++;
        //   continue;
        // }
        // Pour l'instant, on skip sans stdin
        print('   ⏭️  Migration manuelle requise (stdin non supporté)');
        stats['skipped']++;
        continue;
      }

      if (dryRun) {
        print('   🔄 DRY RUN - Aucune modification effectuée');
        stats['migrated']++;
        continue;
      }

      // Effectuer migration
      final batch = firestore.batch();

      // Mettre à jour groupe
      batch.update(groupDoc.reference, {
        'generateEvents': true,
        'recurrenceConfig': recurrenceConfig.toJson(),
        'recurrenceStartDate': recurrenceConfig.startDate,
        'migratedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      print('   ✅ Groupe migré avec succès');
      stats['migrated']++;

      // Générer événements (optionnel pour ne pas surcharger)
      // Décommenter pour générer automatiquement
      // final eventsCount = await _generateEventsForGroup(
      //   firestore: firestore,
      //   groupId: groupId,
      //   groupData: groupData,
      //   recurrenceConfig: recurrenceConfig,
      // );
      // stats['eventsCreated'] = (stats['eventsCreated'] ?? 0) + eventsCount;
      // print('   📅 $eventsCount événements créés');

    } catch (e) {
      print('   ❌ Erreur migration groupe $groupName : $e');
      stats['errors']++;
    }
  }

  return stats;
}

/// Crée RecurrenceConfig depuis ancienne configuration
RecurrenceConfig? _createRecurrenceConfig({
  required String frequency,
  required int dayOfWeek,
  required String time,
}) {
  try {
    final timeParts = time.split(':');
    if (timeParts.length != 2) return null;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return null;

    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Mapper ancienne frequency vers RecurrenceFrequency
    RecurrenceFrequency? freq;
    List<int>? daysOfWeek;

    switch (frequency.toLowerCase()) {
      case 'weekly':
      case 'hebdomadaire':
        freq = RecurrenceFrequency.weekly;
        daysOfWeek = [dayOfWeek];
        break;

      case 'biweekly':
      case 'bi-hebdomadaire':
        freq = RecurrenceFrequency.weekly;
        daysOfWeek = [dayOfWeek];
        // interval sera 2 (toutes les 2 semaines)
        break;

      case 'monthly':
      case 'mensuel':
        freq = RecurrenceFrequency.monthly;
        break;

      case 'daily':
      case 'quotidien':
        freq = RecurrenceFrequency.daily;
        break;

      default:
        return null;
    }

    return RecurrenceConfig(
      frequency: freq,
      interval: frequency.toLowerCase().contains('biweekly') ? 2 : 1,
      startDate: startDate,
      endType: RecurrenceEndType.never,
      daysOfWeek: daysOfWeek,
      duration: 120, // 2h par défaut
    );

  } catch (e) {
    print('   ❌ Erreur création RecurrenceConfig : $e');
    return null;
  }
}

/// Génère événements pour un groupe migré
Future<int> _generateEventsForGroup({
  required FirebaseFirestore firestore,
  required String groupId,
  required Map<String, dynamic> groupData,
  required RecurrenceConfig recurrenceConfig,
}) async {
  try {
    final groupName = groupData['name'] ?? 'Réunion';
    final location = groupData['location'] ?? '';
    final description = groupData['description'] ?? '';

    int eventsCreated = 0;
    DateTime currentDate = recurrenceConfig.startDate;
    final endDate = DateTime.now().add(const Duration(days: 365 * 2)); // 2 ans

    final batch = firestore.batch();
    int batchCount = 0;

    while (currentDate.isBefore(endDate) && eventsCreated < 100) {
      // Limiter à 100 événements par migration pour performance
      
      if (recurrenceConfig.shouldGenerateOccurrence(currentDate)) {
        final eventRef = firestore.collection('events').doc();
        
        batch.set(eventRef, {
          'title': '$groupName - Réunion',
          'description': description,
          'location': location,
          'startDate': Timestamp.fromDate(currentDate),
          'endDate': Timestamp.fromDate(
            currentDate.add(Duration(minutes: recurrenceConfig.duration ?? 120)),
          ),
          'isGroupEvent': true,
          'linkedGroupId': groupId,
          'linkedGroupName': groupName,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'migration_script',
        });

        eventsCreated++;
        batchCount++;

        // Commit par batch de 500 (limite Firestore)
        if (batchCount >= 500) {
          await batch.commit();
          batchCount = 0;
        }
      }

      currentDate = recurrenceConfig.getNextOccurrence(currentDate);
    }

    // Commit dernier batch
    if (batchCount > 0) {
      await batch.commit();
    }

    return eventsCreated;

  } catch (e) {
    print('   ❌ Erreur génération événements : $e');
    return 0;
  }
}

/// Obtient nom jour français
String _getDayName(int dayOfWeek) {
  const days = [
    '',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : 'Inconnu';
}

/// Migrer un seul groupe (pour tests)
Future<bool> migrateSingleGroup(String groupId) async {
  final firestore = FirebaseFirestore.instance;

  print('🔄 Migration groupe individuel : $groupId\n');

  try {
    final groupDoc = await firestore.collection('groups').doc(groupId).get();

    if (!groupDoc.exists) {
      print('❌ Groupe non trouvé');
      return false;
    }

    final groupData = groupDoc.data()!;
    final groupName = groupData['name'] ?? 'Sans nom';

    print('👥 Groupe: $groupName');

    // Vérifier si déjà migré
    if (groupData['generateEvents'] == true) {
      print('⚠️  Groupe déjà migré');
      return false;
    }

    // Créer RecurrenceConfig
    final recurrenceConfig = _createRecurrenceConfig(
      frequency: groupData['frequency'] ?? '',
      dayOfWeek: groupData['dayOfWeek'] as int? ?? 1,
      time: groupData['time'] ?? '',
    );

    if (recurrenceConfig == null) {
      print('❌ Impossible de créer configuration');
      return false;
    }

    // Mettre à jour groupe
    await groupDoc.reference.update({
      'generateEvents': true,
      'recurrenceConfig': recurrenceConfig.toJson(),
      'recurrenceStartDate': recurrenceConfig.startDate,
      'migratedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Groupe migré avec succès');

    // Générer événements
    final eventsCount = await _generateEventsForGroup(
      firestore: firestore,
      groupId: groupId,
      groupData: groupData,
      recurrenceConfig: recurrenceConfig,
    );

    print('📅 $eventsCount événements créés');

    return true;

  } catch (e) {
    print('❌ Erreur migration : $e');
    return false;
  }
}

/// Rollback migration pour un groupe
Future<bool> rollbackGroupMigration(String groupId) async {
  final firestore = FirebaseFirestore.instance;

  print('⏪ Rollback migration groupe : $groupId\n');

  try {
    final groupDoc = await firestore.collection('groups').doc(groupId).get();

    if (!groupDoc.exists) {
      print('❌ Groupe non trouvé');
      return false;
    }

    final groupData = groupDoc.data()!;
    final groupName = groupData['name'] ?? 'Sans nom';

    print('👥 Groupe: $groupName');

    // Supprimer événements générés
    final eventsSnapshot = await firestore
        .collection('events')
        .where('linkedGroupId', isEqualTo: groupId)
        .get();

    final batch = firestore.batch();

    for (final eventDoc in eventsSnapshot.docs) {
      batch.delete(eventDoc.reference);
    }

    // Réinitialiser groupe
    batch.update(groupDoc.reference, {
      'generateEvents': false,
      'recurrenceConfig': FieldValue.delete(),
      'recurrenceStartDate': FieldValue.delete(),
      'recurrenceEndDate': FieldValue.delete(),
      'maxOccurrences': FieldValue.delete(),
      'linkedEventSeriesId': FieldValue.delete(),
      'rolledBackAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    print('✅ Rollback effectué');
    print('📅 ${eventsSnapshot.docs.length} événements supprimés');

    return true;

  } catch (e) {
    print('❌ Erreur rollback : $e');
    return false;
  }
}

/// Statistiques migration
Future<void> printMigrationStats() async {
  final firestore = FirebaseFirestore.instance;

  print('\n📊 Statistiques Migration');
  print('=' * 60);

  try {
    // Groupes total
    final totalGroups = await firestore.collection('groups').count().get();
    print('📁 Total groupes : ${totalGroups.count}');

    // Groupes actifs
    final activeGroups = await firestore
        .collection('groups')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    print('✅ Groupes actifs : ${activeGroups.count}');

    // Groupes avec génération événements
    final migratedGroups = await firestore
        .collection('groups')
        .where('generateEvents', isEqualTo: true)
        .count()
        .get();
    print('🔄 Groupes migrés : ${migratedGroups.count}');

    // Événements générés
    final groupEvents = await firestore
        .collection('events')
        .where('isGroupEvent', isEqualTo: true)
        .count()
        .get();
    print('📅 Événements générés : ${groupEvents.count}');

    // Pourcentage migration
    if (activeGroups.count! > 0) {
      final percentage = 
          (migratedGroups.count! / activeGroups.count! * 100).toStringAsFixed(1);
      print('\n📈 Progression : $percentage% des groupes actifs migrés');
    }

  } catch (e) {
    print('❌ Erreur récupération stats : $e');
  }
}
