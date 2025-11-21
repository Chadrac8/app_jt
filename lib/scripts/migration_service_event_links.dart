import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de migration pour ajouter les liens bidirectionnels
/// aux services et événements existants
class MigrationScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migre tous les services et événements existants
  static Future<void> migrateAll() async {
    print('🚀 Début de la migration...');
    
    try {
      // 1. Migrer les événements liés à des services
      await _migrateEventsLinkedToServices();
      
      // 2. Activer les inscriptions pour les événements-services
      await _enableRegistrationsForServiceEvents();
      
      // 3. Vérifier l'intégrité des liens
      await _verifyLinksIntegrity();
      
      print('✅ Migration terminée avec succès!');
    } catch (e) {
      print('❌ Erreur migration: $e');
      rethrow;
    }
  }

  /// Migre les événements qui ont un linkedServiceId manquant
  static Future<void> _migrateEventsLinkedToServices() async {
    print('\n📝 Étape 1: Migration des liens événements → services');
    
    try {
      // Récupérer tous les services qui ont un linkedEventId
      final servicesQuery = await _firestore
          .collection('services')
          .where('linkedEventId', isNull: false)
          .get();
      
      print('   Trouvé ${servicesQuery.docs.length} services liés');
      
      int migrated = 0;
      int skipped = 0;
      int errors = 0;
      
      for (final serviceDoc in servicesQuery.docs) {
        try {
          final serviceData = serviceDoc.data();
          final linkedEventId = serviceData['linkedEventId'] as String?;
          
          if (linkedEventId == null) continue;
          
          // Récupérer l'événement
          final eventDoc = await _firestore
              .collection('events')
              .doc(linkedEventId)
              .get();
          
          if (!eventDoc.exists) {
            print('   ⚠️ Événement $linkedEventId non trouvé pour service ${serviceDoc.id}');
            errors++;
            continue;
          }
          
          final eventData = eventDoc.data()!;
          
          // Vérifier si déjà migré
          if (eventData['linkedServiceId'] != null && 
              eventData['linkedServiceId'] == serviceDoc.id) {
            print('   ✓ Événement $linkedEventId déjà migré');
            skipped++;
            continue;
          }
          
          // Mettre à jour l'événement avec le lien vers le service
          await _firestore
              .collection('events')
              .doc(linkedEventId)
              .update({
                'linkedServiceId': serviceDoc.id,
                'isServiceEvent': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          migrated++;
          print('   ✅ Événement $linkedEventId lié au service ${serviceDoc.id}');
        } catch (e) {
          errors++;
          print('   ❌ Erreur pour service ${serviceDoc.id}: $e');
        }
      }
      
      print('\n   📊 Résultat:');
      print('      ✅ Migrés: $migrated');
      print('      ⏭️  Ignorés: $skipped');
      print('      ❌ Erreurs: $errors');
    } catch (e) {
      print('   ❌ Erreur étape 1: $e');
      rethrow;
    }
  }

  /// Active les inscriptions pour tous les événements-services
  static Future<void> _enableRegistrationsForServiceEvents() async {
    print('\n📝 Étape 2: Activation des inscriptions pour événements-services');
    
    try {
      // Récupérer tous les événements-services
      final eventsQuery = await _firestore
          .collection('events')
          .where('isServiceEvent', isEqualTo: true)
          .get();
      
      print('   Trouvé ${eventsQuery.docs.length} événements-services');
      
      int updated = 0;
      int skipped = 0;
      
      for (final eventDoc in eventsQuery.docs) {
        try {
          final eventData = eventDoc.data();
          
          // Vérifier si déjà activé
          if (eventData['isRegistrationEnabled'] == true) {
            skipped++;
            continue;
          }
          
          // Activer les inscriptions
          await _firestore
              .collection('events')
              .doc(eventDoc.id)
              .update({
                'isRegistrationEnabled': true,
                'hasWaitingList': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          updated++;
          print('   ✅ Inscriptions activées pour événement ${eventDoc.id}');
        } catch (e) {
          print('   ❌ Erreur pour événement ${eventDoc.id}: $e');
        }
      }
      
      print('\n   📊 Résultat:');
      print('      ✅ Mis à jour: $updated');
      print('      ⏭️  Déjà actifs: $skipped');
    } catch (e) {
      print('   ❌ Erreur étape 2: $e');
      rethrow;
    }
  }

  /// Vérifie l'intégrité des liens bidirectionnels
  static Future<void> _verifyLinksIntegrity() async {
    print('\n📝 Étape 3: Vérification de l\'intégrité des liens');
    
    try {
      // Récupérer tous les services avec linkedEventId
      final servicesQuery = await _firestore
          .collection('services')
          .where('linkedEventId', isNull: false)
          .get();
      
      int valid = 0;
      int broken = 0;
      List<String> brokenLinks = [];
      
      for (final serviceDoc in servicesQuery.docs) {
        final serviceData = serviceDoc.data();
        final linkedEventId = serviceData['linkedEventId'] as String?;
        
        if (linkedEventId == null) continue;
        
        // Vérifier que l'événement existe
        final eventDoc = await _firestore
            .collection('events')
            .doc(linkedEventId)
            .get();
        
        if (!eventDoc.exists) {
          broken++;
          brokenLinks.add('Service ${serviceDoc.id} → Événement $linkedEventId (MANQUANT)');
          print('   ❌ Lien cassé: Service ${serviceDoc.id} pointe vers événement inexistant $linkedEventId');
          continue;
        }
        
        final eventData = eventDoc.data()!;
        
        // Vérifier le lien inverse
        if (eventData['linkedServiceId'] != serviceDoc.id) {
          broken++;
          brokenLinks.add('Service ${serviceDoc.id} ↔ Événement $linkedEventId (LIEN INVERSE MANQUANT)');
          print('   ⚠️ Lien incomplet: Événement $linkedEventId ne pointe pas vers service ${serviceDoc.id}');
          continue;
        }
        
        // Vérifier le flag isServiceEvent
        if (eventData['isServiceEvent'] != true) {
          broken++;
          brokenLinks.add('Service ${serviceDoc.id} ↔ Événement $linkedEventId (FLAG MANQUANT)');
          print('   ⚠️ Flag manquant: Événement $linkedEventId n\'a pas isServiceEvent=true');
          continue;
        }
        
        valid++;
      }
      
      print('\n   📊 Résultat:');
      print('      ✅ Liens valides: $valid');
      print('      ❌ Liens cassés: $broken');
      
      if (broken > 0) {
        print('\n   ⚠️ LIENS CASSÉS DÉTECTÉS:');
        for (final link in brokenLinks) {
          print('      - $link');
        }
      }
    } catch (e) {
      print('   ❌ Erreur étape 3: $e');
      rethrow;
    }
  }

  /// Répare les liens cassés (optionnel)
  static Future<void> repairBrokenLinks() async {
    print('\n🔧 Réparation des liens cassés...');
    
    try {
      // Récupérer tous les services
      final servicesQuery = await _firestore
          .collection('services')
          .where('linkedEventId', isNull: false)
          .get();
      
      int repaired = 0;
      int removed = 0;
      
      for (final serviceDoc in servicesQuery.docs) {
        final serviceData = serviceDoc.data();
        final linkedEventId = serviceData['linkedEventId'] as String?;
        
        if (linkedEventId == null) continue;
        
        // Vérifier que l'événement existe
        final eventDoc = await _firestore
            .collection('events')
            .doc(linkedEventId)
            .get();
        
        if (!eventDoc.exists) {
          // Supprimer le lien du service car l'événement n'existe plus
          await _firestore
              .collection('services')
              .doc(serviceDoc.id)
              .update({
                'linkedEventId': FieldValue.delete(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          removed++;
          print('   🗑️ Lien supprimé du service ${serviceDoc.id} (événement inexistant)');
          continue;
        }
        
        final eventData = eventDoc.data()!;
        
        // Réparer le lien inverse si manquant
        if (eventData['linkedServiceId'] != serviceDoc.id ||
            eventData['isServiceEvent'] != true) {
          await _firestore
              .collection('events')
              .doc(linkedEventId)
              .update({
                'linkedServiceId': serviceDoc.id,
                'isServiceEvent': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          
          repaired++;
          print('   ✅ Lien réparé: Service ${serviceDoc.id} ↔ Événement $linkedEventId');
        }
      }
      
      print('\n   📊 Résultat:');
      print('      ✅ Liens réparés: $repaired');
      print('      🗑️ Liens supprimés: $removed');
    } catch (e) {
      print('   ❌ Erreur réparation: $e');
      rethrow;
    }
  }

  /// Génère un rapport de migration
  static Future<Map<String, dynamic>> generateMigrationReport() async {
    print('\n📊 Génération du rapport de migration...');
    
    try {
      // Compter les services
      final totalServices = await _firestore.collection('services').count().get();
      final servicesWithEvent = await _firestore
          .collection('services')
          .where('linkedEventId', isNull: false)
          .count()
          .get();
      
      // Compter les événements
      final totalEvents = await _firestore.collection('events').count().get();
      final serviceEvents = await _firestore
          .collection('events')
          .where('isServiceEvent', isEqualTo: true)
          .count()
          .get();
      
      // Compter les événements avec inscriptions activées
      final eventsWithRegistration = await _firestore
          .collection('events')
          .where('isServiceEvent', isEqualTo: true)
          .where('isRegistrationEnabled', isEqualTo: true)
          .count()
          .get();
      
      final report = {
        'services': {
          'total': totalServices.count ?? 0,
          'withLinkedEvent': servicesWithEvent.count ?? 0,
          'percentage': (totalServices.count ?? 0) > 0
              ? ((servicesWithEvent.count ?? 0) / (totalServices.count ?? 1) * 100).toStringAsFixed(1)
              : '0.0',
        },
        'events': {
          'total': totalEvents.count ?? 0,
          'serviceEvents': serviceEvents.count ?? 0,
          'percentage': (totalEvents.count ?? 0) > 0
              ? ((serviceEvents.count ?? 0) / (totalEvents.count ?? 1) * 100).toStringAsFixed(1)
              : '0.0',
        },
        'registrations': {
          'enabled': eventsWithRegistration.count ?? 0,
          'percentage': (serviceEvents.count ?? 0) > 0
              ? ((eventsWithRegistration.count ?? 0) / (serviceEvents.count ?? 1) * 100).toStringAsFixed(1)
              : '0.0',
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final services = report['services'] as Map<String, dynamic>;
      final events = report['events'] as Map<String, dynamic>;
      final registrations = report['registrations'] as Map<String, dynamic>;
      
      print('\n   📊 RAPPORT DE MIGRATION:');
      print('   ════════════════════════');
      print('   Services:');
      print('      Total: ${services['total']}');
      print('      Avec événement lié: ${services['withLinkedEvent']} (${services['percentage']}%)');
      print('   ');
      print('   Événements:');
      print('      Total: ${events['total']}');
      print('      Événements-services: ${events['serviceEvents']} (${events['percentage']}%)');
      print('   ');
      print('   Inscriptions:');
      print('      Activées: ${registrations['enabled']} (${registrations['percentage']}%)');
      print('   ');
      print('   Date: ${report['timestamp']}');
      print('   ════════════════════════\n');
      
      return report;
    } catch (e) {
      print('   ❌ Erreur génération rapport: $e');
      return {};
    }
  }
}
