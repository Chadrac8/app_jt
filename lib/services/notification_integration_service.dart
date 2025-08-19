import 'push_notification_service.dart';

/// Service d'intégration des notifications avec les autres modules
class NotificationIntegrationService {
  
  /// Envoie une notification pour un nouveau rendez-vous
  static Future<void> notifyNewAppointment({
    required String responsableId,
    required String membreName,
    required DateTime dateTime,
    required String motif,
  }) async {
    await PushNotificationService.sendNotificationToUser(
      userId: responsableId,
      title: 'Nouvelle demande de rendez-vous',
      body: '$membreName souhaite un rendez-vous le ${_formatDate(dateTime)}',
      data: {
        'type': 'appointment',
        'action': 'new',
        'membreName': membreName,
        'dateTime': dateTime.toIso8601String(),
        'motif': motif,
      },
    );
  }

  /// Envoie une notification de confirmation de rendez-vous
  static Future<void> notifyAppointmentConfirmed({
    required String membreId,
    required DateTime dateTime,
    required String responsableName,
  }) async {
    await PushNotificationService.sendNotificationToUser(
      userId: membreId,
      title: 'Rendez-vous confirmé',
      body: 'Votre rendez-vous avec $responsableName le ${_formatDate(dateTime)} a été confirmé',
      data: {
        'type': 'appointment',
        'action': 'confirmed',
        'responsableName': responsableName,
        'dateTime': dateTime.toIso8601String(),
      },
    );
  }

  /// Envoie une notification d'annulation de rendez-vous
  static Future<void> notifyAppointmentCancelled({
    required String userId,
    required DateTime dateTime,
    required String reason,
  }) async {
    await PushNotificationService.sendNotificationToUser(
      userId: userId,
      title: 'Rendez-vous annulé',
      body: 'Le rendez-vous du ${_formatDate(dateTime)} a été annulé. Raison: $reason',
      data: {
        'type': 'appointment',
        'action': 'cancelled',
        'dateTime': dateTime.toIso8601String(),
        'reason': reason,
      },
    );
  }

  /// Envoie un rappel de rendez-vous
  static Future<void> notifyAppointmentReminder({
    required String userId,
    required DateTime dateTime,
    required String location,
    required bool isOneHourBefore,
  }) async {
    final timeText = isOneHourBefore ? 'dans 1 heure' : 'demain';
    
    await PushNotificationService.sendNotificationToUser(
      userId: userId,
      title: 'Rappel de rendez-vous',
      body: 'Votre rendez-vous est prévu $timeText à $location',
      data: {
        'type': 'appointment',
        'action': 'reminder',
        'dateTime': dateTime.toIso8601String(),
        'location': location,
        'isOneHourBefore': isOneHourBefore.toString(),
      },
    );
  }

  /// Envoie une notification pour un nouveau service/événement
  static Future<void> notifyNewEvent({
    required List<String> userIds,
    required String title,
    required String description,
    required DateTime dateTime,
    required String type, // 'service' ou 'event'
  }) async {
    await PushNotificationService.sendNotificationToUsers(
      userIds: userIds,
      title: 'Nouvel ${type == 'service' ? 'service' : 'événement'}',
      body: '$title - ${_formatDate(dateTime)}',
      data: {
        'type': type,
        'action': 'new',
        'title': title,
        'description': description,
        'dateTime': dateTime.toIso8601String(),
      },
    );
  }

  /// Envoie une notification de rappel de service
  static Future<void> notifyServiceReminder({
    required String userId,
    required String serviceName,
    required DateTime dateTime,
    required String position,
  }) async {
    await PushNotificationService.sendNotificationToUser(
      userId: userId,
      title: 'Rappel de service',
      body: 'Service "$serviceName" demain - Position: $position',
      data: {
        'type': 'service',
        'action': 'reminder',
        'serviceName': serviceName,
        'dateTime': dateTime.toIso8601String(),
        'position': position,
      },
    );
  }

  /// Envoie une notification pour une nouvelle étude biblique
  static Future<void> notifyNewBibleStudy({
    required List<String> userIds,
    required String title,
    required String description,
    required String authorName,
  }) async {
    await PushNotificationService.sendNotificationToUsers(
      userIds: userIds,
      title: 'Nouvelle étude biblique',
      body: '"$title" par $authorName',
      data: {
        'type': 'bible_study',
        'action': 'new',
        'title': title,
        'description': description,
        'authorName': authorName,
      },
    );
  }

  /// Envoie une notification pour un nouvel article biblique
  static Future<void> notifyNewBibleArticle({
    required List<String> userIds,
    required String title,
    required String category,
    required String authorName,
  }) async {
    for (final userId in userIds) {
      await PushNotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Nouvel article biblique',
        body: '"$title" dans la catégorie $category',
        data: {
          'type': 'bible_article',
          'action': 'new',
          'title': title,
          'category': category,
          'authorName': authorName,
        },
      );
    }
  }

  /// Envoie une notification pour un nouveau message/blog
  static Future<void> notifyNewBlogPost({
    required List<String> userIds,
    required String title,
    required String authorName,
    required String category,
  }) async {
    for (final userId in userIds) {
      await PushNotificationService.sendNotificationToUser(
        userId: userId,
        title: 'Nouvel article de blog',
        body: '"$title" par $authorName',
        data: {
          'type': 'blog',
          'action': 'new',
          'title': title,
          'authorName': authorName,
          'category': category,
        },
      );
    }
  }

  /// Envoie une notification urgente à tous les utilisateurs
  static Future<void> notifyUrgentMessage({
    required List<String> userIds,
    required String title,
    required String message,
  }) async {
    for (final userId in userIds) {
      await PushNotificationService.sendNotificationToUser(
        userId: userId,
        title: '🚨 $title',
        body: message,
        data: {
          'type': 'urgent',
          'action': 'broadcast',
          'title': title,
          'message': message,
        },
      );
    }
  }

  /// Envoie une notification de bienvenue pour les nouveaux membres
  static Future<void> notifyWelcomeNewMember({
    required String userId,
    required String firstName,
  }) async {
    await PushNotificationService.sendNotificationToUser(
      userId: userId,
      title: 'Bienvenue !',
      body: 'Bonjour $firstName, bienvenue dans notre communauté !',
      data: {
        'type': 'welcome',
        'action': 'new_member',
        'firstName': firstName,
      },
    );
  }

  /// Envoie une notification de rappel de formulaire
  static Future<void> notifyFormReminder({
    required String userId,
    required String formTitle,
    required DateTime deadline,
  }) async {
    await PushNotificationService.sendNotificationToUser(
      userId: userId,
      title: 'Rappel de formulaire',
      body: 'N\'oubliez pas de remplir "$formTitle" avant le ${_formatDate(deadline)}',
      data: {
        'type': 'form',
        'action': 'reminder',
        'formTitle': formTitle,
        'deadline': deadline.toIso8601String(),
      },
    );
  }

  /// Envoie une notification pour un anniversaire
  static Future<void> notifyBirthday({
    required List<String> userIds,
    required String birthdayPersonName,
    required DateTime birthday,
  }) async {
    for (final userId in userIds) {
      await PushNotificationService.sendNotificationToUser(
        userId: userId,
        title: '🎂 Anniversaire',
        body: 'C\'est l\'anniversaire de $birthdayPersonName aujourd\'hui !',
        data: {
          'type': 'birthday',
          'action': 'notification',
          'birthdayPersonName': birthdayPersonName,
          'birthday': birthday.toIso8601String(),
        },
      );
    }
  }

  /// Envoie une notification d'administration générale
  static Future<void> sendAdminNotification({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    final data = {
      'type': type,
      'source': 'admin',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await PushNotificationService.sendNotificationToUsers(
      userIds: userIds,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Envoie une notification urgente
  static Future<void> sendUrgentNotification({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, dynamic>? additionalData,
  }) async {
    await sendAdminNotification(
      userIds: userIds,
      title: '🚨 URGENT: $title',
      body: message,
      type: 'urgent',
      additionalData: {
        'priority': 'high',
        'urgent': true,
        ...?additionalData,
      },
    );
  }

  /// Envoie une notification de rappel
  static Future<void> sendReminder({
    required List<String> userIds,
    required String title,
    required String message,
    DateTime? reminderDate,
    Map<String, dynamic>? additionalData,
  }) async {
    await sendAdminNotification(
      userIds: userIds,
      title: '⏰ Rappel: $title',
      body: message,
      type: 'reminder',
      additionalData: {
        'reminderDate': reminderDate?.toIso8601String(),
        ...?additionalData,
      },
    );
  }

  /// Formate une date pour l'affichage
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'demain à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == -1) {
      return 'hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
