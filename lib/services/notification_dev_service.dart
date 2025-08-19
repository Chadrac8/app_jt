import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';

/// Service utilitaire pour gérer les tokens de développement et debug
class NotificationDevService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialise les tokens de test pour le développement
  static Future<void> ensureDevTokensExist() async {
    if (!kDebugMode) return;

    try {
      print('🔧 Mode développement - Vérification des tokens...');

      // Obtenir tous les utilisateurs
      final usersSnapshot = await _firestore
          .collection('people')
          .where('isActive', isEqualTo: true)
          .limit(10) // Limiter pour les tests
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('⚠️  Aucun utilisateur trouvé pour créer les tokens de test');
        return;
      }

      final userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
      print('👥 Trouvé ${userIds.length} utilisateurs');

      // Vérifier les tokens existants
      final tokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .get();

      final existingTokenUsers = tokensSnapshot.docs.map((doc) => doc.id).toSet();
      final usersWithoutTokens = userIds.where((id) => !existingTokenUsers.contains(id)).toList();

      if (usersWithoutTokens.isNotEmpty) {
        print('🔧 Création de tokens de test pour ${usersWithoutTokens.length} utilisateurs...');
        await PushNotificationService.createTestTokensForUsers(usersWithoutTokens);
        print('✅ Tokens de test créés!');
      } else {
        print('✅ Tous les utilisateurs ont déjà des tokens');
      }

      // Si l'utilisateur actuel n'a pas de token, créer un vrai token
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userTokenDoc = await _firestore
            .collection('fcm_tokens')
            .doc(currentUser.uid)
            .get();

        if (!userTokenDoc.exists || 
            userTokenDoc.data()?['token']?.toString().startsWith('test_token_') == true) {
          print('🔧 Initialisation du token FCM pour l\'utilisateur actuel...');
          await PushNotificationService.initialize();
        }
      }

    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des tokens de dev: $e');
    }
  }

  /// Envoie une notification de test
  static Future<void> sendTestNotification({
    String? specificUserId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final List<String> recipients;
      if (specificUserId != null) {
        recipients = [specificUserId];
      } else {
        // Envoyer à l'utilisateur actuel seulement
        recipients = [currentUser.uid];
      }

      // Créer une notification de test
      await _firestore.collection('rich_notifications').add({
        'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'title': '🧪 Notification de Test',
        'body': 'Ceci est une notification de test envoyée à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'type': 'test',
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Test Admin',
        'recipients': recipients,
        'priority': 'normal',
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'test': true,
          'source': 'dev_service',
        },
      });

      // Envoyer la notification push
      await PushNotificationService.sendNotificationToUsers(
        userIds: recipients,
        title: '🧪 Test Push',
        body: 'Notification push de test - ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        data: {
          'test': 'true',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Notification de test envoyée à ${recipients.length} utilisateur(s)');

    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification de test: $e');
      rethrow;
    }
  }

  /// Vérifie l'état des notifications pour un utilisateur
  static Future<Map<String, dynamic>> checkUserNotificationStatus(String userId) async {
    try {
      // Vérifier le token FCM
      final tokenDoc = await _firestore
          .collection('fcm_tokens')
          .doc(userId)
          .get();

      // Vérifier les notifications reçues
      final notificationsSnapshot = await _firestore
          .collection('rich_notifications')
          .where('recipients', arrayContains: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      // Vérifier les analytics
      final analyticsSnapshot = await _firestore
          .collection('notification_analytics')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      return {
        'hasToken': tokenDoc.exists,
        'tokenData': tokenDoc.exists ? tokenDoc.data() : null,
        'notificationsReceived': notificationsSnapshot.docs.length,
        'lastNotification': notificationsSnapshot.docs.isNotEmpty
            ? notificationsSnapshot.docs.first.data()
            : null,
        'analyticsCount': analyticsSnapshot.docs.length,
      };

    } catch (e) {
      return {
        'error': e.toString(),
        'hasToken': false,
        'notificationsReceived': 0,
        'analyticsCount': 0,
      };
    }
  }

  /// Nettoie les tokens de test (à utiliser avant la production)
  static Future<void> cleanupTestTokens() async {
    try {
      print('🧹 Nettoyage des tokens de test...');

      final testTokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('platform', isEqualTo: 'test')
          .get();

      final batch = _firestore.batch();
      for (final doc in testTokensSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ${testTokensSnapshot.docs.length} tokens de test supprimés');

    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Affiche un rapport de l'état des notifications
  static Future<void> printNotificationReport() async {
    try {
      print('\n📊 RAPPORT DES NOTIFICATIONS');
      print('=' * 40);

      // Utilisateurs
      final usersSnapshot = await _firestore.collection('people').get();
      print('👥 Utilisateurs totaux: ${usersSnapshot.docs.length}');

      // Tokens
      final tokensSnapshot = await _firestore.collection('fcm_tokens').get();
      final realTokens = tokensSnapshot.docs.where((doc) => 
        doc.data()['platform'] != 'test'
      ).length;
      final testTokens = tokensSnapshot.docs.length - realTokens;
      
      print('🔑 Tokens FCM: ${tokensSnapshot.docs.length} total');
      print('   - Réels: $realTokens');
      print('   - Test: $testTokens');

      // Notifications
      final notificationsSnapshot = await _firestore
          .collection('rich_notifications')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final todayNotifications = notificationsSnapshot.docs.where((doc) {
        final timestamp = doc.data()['timestamp'] as Timestamp?;
        return timestamp?.toDate().isAfter(todayStart) ?? false;
      }).length;

      print('📨 Notifications: ${notificationsSnapshot.docs.length} récentes');
      print('   - Aujourd\'hui: $todayNotifications');

      // Analytics
      final analyticsSnapshot = await _firestore
          .collection('notification_analytics')
          .get();
      print('📈 Analytics: ${analyticsSnapshot.docs.length} entrées');

      print('=' * 40);

    } catch (e) {
      print('❌ Erreur lors de la génération du rapport: $e');
    }
  }
}
