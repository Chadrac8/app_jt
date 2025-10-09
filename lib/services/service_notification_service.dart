import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/service_model.dart';
import 'package:intl/intl.dart';

/// Service de notifications pour les services et événements
class ServiceNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Envoie une notification de nouveau service
  static Future<void> notifyNewService(ServiceModel service) async {
    try {
      print('📧 Envoi notification nouveau service: ${service.name}');
      
      // Récupérer tous les membres de l'église
      final members = await _getChurchMembers();
      
      if (members.isEmpty) {
        print('⚠️ Aucun membre à notifier');
        return;
      }
      
      // Envoyer notification via Firebase Cloud Messaging
      await _functions.httpsCallable('sendNotificationToMultiple').call({
        'userIds': members,
        'notification': {
          'title': 'Nouveau service: ${service.name}',
          'body': 'Le ${_formatDate(service.dateTime)} à ${_formatTime(service.dateTime)}',
          'imageUrl': null,
        },
        'data': {
          'type': 'new_service',
          'serviceId': service.id,
          'eventId': service.linkedEventId,
          'action': 'view_service',
        },
      });
      
      print('✅ Notification envoyée à ${members.length} membres');
    } catch (e) {
      print('❌ Erreur envoi notification nouveau service: $e');
      // Ne pas bloquer si la notification échoue
    }
  }
  
  /// Envoie un rappel 24h avant le service
  static Future<void> scheduleServiceReminder(ServiceModel service) async {
    try {
      print('⏰ Planification rappel service: ${service.name}');
      
      final reminderTime = service.dateTime.subtract(const Duration(hours: 24));
      
      // Vérifier que le rappel est dans le futur
      if (reminderTime.isBefore(DateTime.now())) {
        print('⚠️ Service trop proche, rappel non planifié');
        return;
      }
      
      // Utiliser Firebase Cloud Functions pour scheduler
      await _functions.httpsCallable('scheduleNotification').call({
        'serviceId': service.id,
        'scheduledFor': reminderTime.toIso8601String(),
        'notification': {
          'title': 'Rappel: ${service.name}',
          'body': 'Le service aura lieu demain à ${_formatTime(service.dateTime)}',
        },
        'data': {
          'type': 'service_reminder',
          'serviceId': service.id,
          'eventId': service.linkedEventId,
          'action': 'view_service',
        },
      });
      
      print('✅ Rappel planifié pour ${_formatDateTime(reminderTime)}');
    } catch (e) {
      print('❌ Erreur planification rappel: $e');
      // Ne pas bloquer si la planification échoue
    }
  }
  
  /// Notifie les changements de service
  static Future<void> notifyServiceUpdate(ServiceModel service) async {
    try {
      print('🔔 Notification modification service: ${service.name}');
      
      // Récupérer les personnes inscrites via l'événement lié
      List<String> registeredUserIds = [];
      
      if (service.linkedEventId != null) {
        // Récupérer toutes les inscriptions confirmées
        final registrationsQuery = await _firestore
            .collection('event_registrations')
            .where('eventId', isEqualTo: service.linkedEventId!)
            .where('status', isEqualTo: 'confirmed')
            .get();
        
        registeredUserIds = registrationsQuery.docs
            .map((doc) => doc.data()['personId'] as String)
            .toList();
      }
      
      // Si personne n'est inscrit, notifier tous les membres
      if (registeredUserIds.isEmpty) {
        registeredUserIds = await _getChurchMembers();
      }
      
      if (registeredUserIds.isEmpty) {
        print('⚠️ Aucune personne à notifier');
        return;
      }
      
      await _functions.httpsCallable('sendNotificationToMultiple').call({
        'userIds': registeredUserIds,
        'notification': {
          'title': 'Modification: ${service.name}',
          'body': 'Le service a été modifié. Consultez les détails.',
        },
        'data': {
          'type': 'service_update',
          'serviceId': service.id,
          'eventId': service.linkedEventId,
          'action': 'view_service',
        },
      });
      
      print('✅ Notification envoyée à ${registeredUserIds.length} personnes');
    } catch (e) {
      print('❌ Erreur notification modification: $e');
    }
  }
  
  /// Notifie l'annulation d'un service
  static Future<void> notifyServiceCancellation(ServiceModel service) async {
    try {
      print('❌ Notification annulation service: ${service.name}');
      
      // Récupérer les personnes inscrites
      List<String> registeredUserIds = [];
      
      if (service.linkedEventId != null) {
        // Récupérer toutes les inscriptions confirmées
        final registrationsQuery = await _firestore
            .collection('event_registrations')
            .where('eventId', isEqualTo: service.linkedEventId!)
            .where('status', isEqualTo: 'confirmed')
            .get();
        
        registeredUserIds = registrationsQuery.docs
            .map((doc) => doc.data()['personId'] as String)
            .toList();
      }
      
      // Si personne n'est inscrit, notifier tous les membres
      if (registeredUserIds.isEmpty) {
        registeredUserIds = await _getChurchMembers();
      }
      
      if (registeredUserIds.isEmpty) {
        print('⚠️ Aucune personne à notifier');
        return;
      }
      
      await _functions.httpsCallable('sendNotificationToMultiple').call({
        'userIds': registeredUserIds,
        'notification': {
          'title': '⚠️ Service annulé: ${service.name}',
          'body': 'Le service du ${_formatDate(service.dateTime)} est annulé.',
        },
        'data': {
          'type': 'service_cancelled',
          'serviceId': service.id,
          'action': 'dismiss',
        },
      });
      
      print('✅ Notification d\'annulation envoyée à ${registeredUserIds.length} personnes');
    } catch (e) {
      print('❌ Erreur notification annulation: $e');
    }
  }
  
  /// Récupère tous les IDs de membres de l'église
  static Future<List<String>> _getChurchMembers() async {
    try {
      final query = await _firestore
          .collection('persons')
          .where('isActive', isEqualTo: true)
          .get();
      
      return query.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ Erreur récupération membres: $e');
      return [];
    }
  }
  
  /// Formate une date
  static String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    return formatter.format(date);
  }
  
  /// Formate une heure
  static String _formatTime(DateTime date) {
    final DateFormat formatter = DateFormat('HH:mm', 'fr_FR');
    return formatter.format(date);
  }
  
  /// Formate une date et heure
  static String _formatDateTime(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR');
    return formatter.format(date);
  }
}
