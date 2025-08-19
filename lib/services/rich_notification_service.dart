import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rich_notification_model.dart';
import 'push_notification_service.dart';
import 'notification_template_service.dart';

/// Service principal pour la gestion des notifications riches et avancées
class RichNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'rich_notifications';
  static const String _analyticsCollection = 'notification_analytics';

  /// Envoie une notification riche simple
  static Future<String> sendRichNotification({
    required String title,
    required String body,
    required List<String> recipients,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? expiresAt,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final notification = RichNotificationModel(
        title: title,
        body: body,
        type: 'rich',
        senderId: user.uid,
        senderName: user.displayName ?? 'Administrateur',
        recipients: recipients,
        imageUrl: imageUrl,
        actions: actions ?? [],
        data: data ?? {},
        priority: priority,
        expiresAt: expiresAt,
      );

      // Sauvegarder dans Firestore
      await _firestore.collection(_collection).doc(notification.id).set(notification.toJson());

      // Envoyer les notifications push avec gestion d'erreur améliorée
      try {
        await PushNotificationService.sendNotificationToUsers(
          userIds: recipients,
          title: title,
          body: body,
          data: {
            ...data ?? {},
            'notificationId': notification.id,
            'type': 'rich',
            'priority': priority.toString(),
            'imageUrl': imageUrl ?? '',
          },
        );
      } catch (pushError) {
        print('Avertissement - Envoi push échoué: $pushError');
        // La notification est quand même sauvegardée en base
        // Les utilisateurs pourront la voir dans l'app
      }

      // Créer les analytics de base
      await _createBasicAnalytics(notification.id, recipients.length);

      return notification.id;
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification riche: $e');
      rethrow;
    }
  }

  /// Envoie une notification à partir d'un template
  static Future<String> sendTemplatedNotification({
    required String templateId,
    required Map<String, dynamic> variables,
    List<String>? specificUserIds,
    DateTime? scheduledTime,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer le template
      final templateService = NotificationTemplateService();
      final template = await templateService.getTemplateById(templateId);
      if (template == null) throw Exception('Template non trouvé');

      // Rendre le template avec les variables
      final rendered = templateService.renderTemplate(template, variables);

      // Déterminer les destinataires
      List<String> recipients = [];
      if (specificUserIds != null && specificUserIds.isNotEmpty) {
        recipients = specificUserIds;
      } else {
        // Par défaut, envoyer à tous les utilisateurs actifs
        final usersSnapshot = await _firestore
            .collection('people')
            .where('isActive', isEqualTo: true)
            .get();
        recipients = usersSnapshot.docs.map((doc) => doc.id).toList();
      }

      if (recipients.isEmpty) {
        throw Exception('Aucun destinataire trouvé');
      }

      // Créer la notification riche
      final notification = RichNotificationModel(
        title: rendered['title']?.toString() ?? 'Notification',
        body: rendered['body']?.toString() ?? '',
        type: 'templated',
        senderId: user.uid,
        senderName: user.displayName ?? 'Administrateur',
        recipients: recipients,
        imageUrl: rendered['imageUrl']?.toString(),
        actions: [], // Simplifier pour l'instant
        data: {
          'templateId': templateId,
          'variables': variables,
        },
        priority: NotificationPriority.normal,
      );

      // Sauvegarder dans Firestore
      await _firestore.collection(_collection).doc(notification.id).set(notification.toJson());

      // Programmer ou envoyer immédiatement
      if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        await _scheduleNotification(notification, scheduledTime);
      } else {
        await _sendImmediately(notification);
      }

      return notification.id;
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification template: $e');
      rethrow;
    }
  }

  /// Envoie une notification à tous les utilisateurs
  static Future<String> sendToAllUsers({
    required String title,
    required String body,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      // Obtenir tous les utilisateurs actifs
      final usersSnapshot = await _firestore
          .collection('people')
          .where('isActive', isEqualTo: true)
          .get();
      
      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (userIds.isEmpty) {
        throw Exception('Aucun utilisateur actif trouvé');
      }

      print('📤 Envoi à ${userIds.length} utilisateurs...');

      return await sendRichNotification(
        title: title,
        body: body,
        recipients: userIds,
        imageUrl: imageUrl,
        actions: actions,
        data: data,
        priority: priority,
      );
    } catch (e) {
      print('Erreur lors de l\'envoi à tous les utilisateurs: $e');
      rethrow;
    }
  }

  /// Envoie une notification aux administrateurs uniquement
  static Future<String> sendToAdmins({
    required String title,
    required String body,
    String? imageUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    try {
      // Obtenir tous les administrateurs
      final usersSnapshot = await _firestore
          .collection('people')
          .where('isActive', isEqualTo: true)
          .where('roles', arrayContains: 'admin')
          .get();
      
      final adminIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (adminIds.isEmpty) {
        throw Exception('Aucun administrateur trouvé');
      }

      return await sendRichNotification(
        title: title,
        body: body,
        recipients: adminIds,
        imageUrl: imageUrl,
        actions: actions,
        data: {
          ...data ?? {},
          'targetGroup': 'admins',
        },
        priority: priority,
      );
    } catch (e) {
      print('Erreur lors de l\'envoi aux admins: $e');
      rethrow;
    }
  }

  /// Programme une notification pour un envoi différé
  static Future<void> _scheduleNotification(RichNotificationModel notification, DateTime scheduledTime) async {
    try {
      await _firestore.collection('scheduled_notifications').doc(notification.id).set({
        'notificationId': notification.id,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la programmation: $e');
      rethrow;
    }
  }

  /// Envoie immédiatement une notification
  static Future<void> _sendImmediately(RichNotificationModel notification) async {
    try {
      await PushNotificationService.sendNotificationToUsers(
        userIds: notification.recipients,
        title: notification.title,
        body: notification.body,
        data: {
          ...notification.data,
          'notificationId': notification.id,
          'type': 'rich',
          'priority': notification.priority.toString(),
          'imageUrl': notification.imageUrl ?? '',
        },
      );

      // Mettre à jour le statut
      await _firestore.collection(_collection).doc(notification.id).update({
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      // Créer les analytics
      await _createBasicAnalytics(notification.id, notification.recipients.length);
    } catch (e) {
      await _firestore.collection(_collection).doc(notification.id).update({
        'status': 'failed',
        'error': e.toString(),
      });
      rethrow;
    }
  }

  /// Crée les analytics de base pour une notification
  static Future<void> _createBasicAnalytics(String notificationId, int recipientCount) async {
    try {
      await _firestore.collection(_analyticsCollection).doc(notificationId).set({
        'notificationId': notificationId,
        'sentCount': recipientCount,
        'deliveredCount': 0,
        'openedCount': 0,
        'clickedCount': 0,
        'dismissedCount': 0,
        'sentAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la création des analytics: $e');
    }
  }

  /// Récupère toutes les notifications d'un utilisateur
  static Stream<List<RichNotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('recipients', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RichNotificationModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Récupère toutes les notifications envoyées
  static Stream<List<RichNotificationModel>> getAllNotifications() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RichNotificationModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Marque une notification comme lue
  static Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });

      // Mettre à jour les analytics
      await _firestore.collection(_analyticsCollection).doc(notificationId).update({
        'openedCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erreur lors du marquage comme lu: $e');
    }
  }

  /// Enregistre un clic sur une action
  static Future<void> recordActionClick(String notificationId, String actionId, String userId) async {
    try {
      await _firestore.collection(_analyticsCollection).doc(notificationId).update({
        'clickedCount': FieldValue.increment(1),
        'actionClicks': FieldValue.arrayUnion([{
          'actionId': actionId,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        }]),
      });
    } catch (e) {
      print('Erreur lors de l\'enregistrement du clic: $e');
    }
  }

  /// Supprime une notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
      await _firestore.collection(_analyticsCollection).doc(notificationId).delete();
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Récupère les statistiques globales
  static Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      final sentThisMonth = await _firestore
          .collection(_collection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .count()
          .get();

      final totalSent = await _firestore
          .collection(_collection)
          .count()
          .get();

      final analyticsSnapshot = await _firestore
          .collection(_analyticsCollection)
          .get();

      int totalOpened = 0;
      int totalClicked = 0;
      for (final doc in analyticsSnapshot.docs) {
        final data = doc.data();
        totalOpened += (data['openedCount'] as int?) ?? 0;
        totalClicked += (data['clickedCount'] as int?) ?? 0;
      }

      final totalSentCount = totalSent.count ?? 0;
      
      return {
        'totalSent': totalSentCount,
        'sentThisMonth': sentThisMonth.count ?? 0,
        'totalOpened': totalOpened,
        'totalClicked': totalClicked,
        'averageOpenRate': totalSentCount > 0 ? (totalOpened / totalSentCount * 100) : 0,
        'averageClickRate': totalOpened > 0 ? (totalClicked / totalOpened * 100) : 0,
      };
    } catch (e) {
      print('Erreur lors du calcul des stats globales: $e');
      return {};
    }
  }
}
