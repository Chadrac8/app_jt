import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service de gestion des notifications push Firebase
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _tokensCollection = 'fcm_tokens';
  static const String _notificationsCollection = 'push_notifications';
  
  static String? _currentToken;
  static bool _isInitialized = false;

  /// Initialise le service de notifications push
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Demander les permissions
      await _requestPermissions();
      
      // Obtenir le token FCM
      await _getToken();
      
      // Configurer les gestionnaires de messages
      _setupMessageHandlers();
      
      // Écouter les changements de token
      _setupTokenRefresh();
      
      _isInitialized = true;
      debugPrint('Service de notifications push initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des notifications push: $e');
    }
  }

  /// Demande les permissions pour les notifications
  static Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Statut des permissions: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Erreur lors de la demande de permissions: $e');
    }
  }

  /// Obtient et stocke le token FCM
  static Future<void> _getToken() async {
    try {
      // Sur iOS, s'assurer que le token APNS est disponible
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('Token APNS non disponible, tentative d\'attendre...');
            // Attendre un peu et réessayer
            await Future.delayed(const Duration(seconds: 2));
            final retryApnsToken = await _messaging.getAPNSToken();
            if (retryApnsToken == null) {
              debugPrint('Token APNS toujours non disponible après retry');
              return;
            }
          }
          debugPrint('Token APNS disponible');
        } catch (e) {
          debugPrint('Erreur lors de la vérification du token APNS: $e');
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        await _saveTokenToFirestore(token);
        await _saveTokenLocally(token);
        debugPrint('Token FCM obtenu: ${token.substring(0, 20)}...');
      } else {
        debugPrint('Token FCM vide ou null');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'obtention du token: $e');
    }
  }

  /// Sauvegarde le token dans Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection(_tokensCollection).doc(user.uid).set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'userId': user.uid,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      debugPrint('Token sauvegardé dans Firestore');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du token: $e');
    }
  }

  /// Sauvegarde le token localement
  static Future<void> _saveTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde locale du token: $e');
    }
  }

  /// Configure les gestionnaires de messages
  static void _setupMessageHandlers() {
    // Messages reçus en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message reçu en foreground: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Messages reçus quand l'app est en background mais ouverte
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message ouvert depuis background: ${message.messageId}');
      _handleMessageOpened(message);
    });

    // Gestion des messages en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Configure l'écoute du refresh de token
  static void _setupTokenRefresh() {
    _messaging.onTokenRefresh.listen((String token) {
      debugPrint('Token FCM rafraîchi');
      _currentToken = token;
      _saveTokenToFirestore(token);
      _saveTokenLocally(token);
    });
  }

  /// Gestionnaire pour les messages en foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    // Afficher une notification locale ou un snackbar
    _showLocalNotification(message);
    
    // Enregistrer la notification
    _saveNotificationToFirestore(message);
  }

  /// Gestionnaire pour les messages ouverts
  static void _handleMessageOpened(RemoteMessage message) {
    debugPrint('Notification ouverte: ${message.data}');
    
    // Navigation basée sur les données du message
    _handleNotificationNavigation(message);
    
    // Marquer comme lue
    _markNotificationAsRead(message.messageId);
  }

  /// Affiche une notification locale
  static void _showLocalNotification(RemoteMessage message) {
    // Ici vous pouvez utiliser un package comme flutter_local_notifications
    // pour afficher des notifications personnalisées
    debugPrint('Affichage notification locale: ${message.notification?.title}');
  }

  /// Sauvegarde la notification dans Firestore
  static Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection(_notificationsCollection).add({
        'userId': user.uid,
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'isRead': false,
        'receivedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      });
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  /// Gère la navigation basée sur la notification
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    switch (type) {
      case 'appointment':
        // Naviguer vers les rendez-vous
        debugPrint('Navigation vers les rendez-vous');
        break;
      case 'service':
        // Naviguer vers les services
        debugPrint('Navigation vers les services');
        break;
      case 'event':
        // Naviguer vers les événements
        debugPrint('Navigation vers les événements');
        break;
      case 'bible_study':
        // Naviguer vers les études bibliques
        debugPrint('Navigation vers les études bibliques');
        break;
      default:
        debugPrint('Type de notification non géré: $type');
    }
  }

  /// Marque une notification comme lue
  static Future<void> _markNotificationAsRead(String? messageId) async {
    if (messageId == null) return;
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('messageId', isEqualTo: messageId)
          .limit(1)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage comme lu: $e');
    }
  }

  /// Envoie une notification à un utilisateur spécifique
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtenir le token de l'utilisateur
      final tokenDoc = await _firestore
          .collection(_tokensCollection)
          .doc(userId)
          .get();

      if (!tokenDoc.exists) {
        debugPrint('Token non trouvé pour l\'utilisateur: $userId');
        return;
      }

      final token = tokenDoc.data()?['token'] as String?;
      if (token == null) {
        debugPrint('Token vide pour l\'utilisateur: $userId');
        return;
      }

      // Envoyer la notification via l'API FCM
      // Ceci nécessite l'implémentation côté serveur (Firebase Functions)
      await _sendNotificationViaAPI(
        token: token,
        title: title,
        body: body,
        data: data,
      );

    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  /// Envoie une notification à plusieurs utilisateurs
  static Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Obtenir tous les tokens des utilisateurs
      final tokens = <String>[];
      final missingTokenUsers = <String>[];
      
      for (final userId in userIds) {
        final tokenDoc = await _firestore
            .collection(_tokensCollection)
            .doc(userId)
            .get();
            
        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data();
          final token = tokenData?['token'] as String?;
          final isActive = tokenData?['isActive'] as bool? ?? true;
          
          if (token != null && isActive) {
            tokens.add(token);
          } else {
            missingTokenUsers.add(userId);
          }
        } else {
          missingTokenUsers.add(userId);
        }
      }

      debugPrint('Tokens trouvés: ${tokens.length}/${userIds.length}');
      
      if (missingTokenUsers.isNotEmpty) {
        debugPrint('Utilisateurs sans token: ${missingTokenUsers.length}');
        if (kDebugMode) {
          debugPrint('IDs sans token: ${missingTokenUsers.take(5).join(", ")}${missingTokenUsers.length > 5 ? "..." : ""}');
        }
      }

      if (tokens.isEmpty) {
        throw Exception('Aucun token valide trouvé pour les utilisateurs spécifiés');
      }

      // Envoyer via Cloud Functions (multicast)
      await _sendMulticastNotification(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
      );

      debugPrint('Notification envoyée à ${tokens.length} tokens');

    } catch (e) {
      debugPrint('Erreur lors de l\'envoi des notifications multiples: $e');
      rethrow; // Relancer l'erreur pour que le service appelant puisse la gérer
    }
  }

  /// Envoie une notification multicast via Cloud Functions
  static Future<void> _sendMulticastNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendMulticastNotification');
      
      final result = await callable.call({
        'tokens': tokens,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      debugPrint('Notifications multicast envoyées: ${result.data}');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi multicast: $e');
      // Fallback : envoyer individuellement
      for (final token in tokens) {
        await _sendNotificationViaAPI(
          token: token,
          title: title,
          body: body,
          data: data,
        );
      }
    }
  }

  /// Envoie une notification via l'API FCM (Firebase Functions)
  static Future<void> _sendNotificationViaAPI({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendPushNotification');
      
      final result = await callable.call({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      debugPrint('Notification envoyée avec succès: ${result.data}');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi via Cloud Functions: $e');
      // Fallback : enregistrer dans Firestore pour traitement ultérieur
      await _saveNotificationForLaterProcessing(token, title, body, data);
    }
  }

  /// Sauvegarde une notification pour traitement ultérieur
  static Future<void> _saveNotificationForLaterProcessing(
    String token,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      await _firestore.collection('pending_notifications').add({
        'token': token,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });
      debugPrint('Notification mise en attente pour traitement ultérieur');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la notification: $e');
    }
  }

  /// Obtient toutes les notifications de l'utilisateur
  static Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('receivedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Obtient le nombre de notifications non lues
  static Stream<int> getUnreadNotificationsCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Marque toutes les notifications comme lues
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Erreur lors du marquage de toutes les notifications: $e');
    }
  }

  /// Marque une notification spécifique comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Erreur lors du marquage de la notification: $e');
    }
  }

  /// Supprime une notification spécifique
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la notification: $e');
    }
  }

  /// Nettoie les tokens invalides de la base de données
  static Future<void> cleanInvalidTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Supprimer le token actuel s'il est invalide
      await _firestore
          .collection(_tokensCollection)
          .doc(user.uid)
          .delete();

      debugPrint('Token invalide supprimé pour l\'utilisateur: ${user.uid}');
      
      // Réinitialiser le token local
      _currentToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      
      // Tenter de récupérer un nouveau token
      await Future.delayed(const Duration(seconds: 1));
      await _getToken();
      
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des tokens invalides: $e');
    }
  }

  /// Supprime le token lors de la déconnexion
  static Future<void> deleteToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Supprimer de Firestore
      await _firestore
          .collection(_tokensCollection)
          .doc(user.uid)
          .update({'isActive': false});

      // Supprimer localement
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');

      // Supprimer le token Firebase
      await _messaging.deleteToken();
      
      _currentToken = null;
      debugPrint('Token supprimé');
    } catch (e) {
      debugPrint('Erreur lors de la suppression du token: $e');
    }
  }

  /// Obtient le token actuel
  static String? get currentToken => _currentToken;

  /// Vérifie si le service est initialisé
  static bool get isInitialized => _isInitialized;

  /// Utilitaire pour le développement - Crée des tokens de test
  static Future<void> createTestTokensForUsers(List<String> userIds) async {
    if (!kDebugMode) return; // Seulement en mode debug
    
    try {
      for (final userId in userIds) {
        await _firestore.collection(_tokensCollection).doc(userId).set({
          'token': 'test_token_$userId',
          'platform': 'test',
          'userId': userId,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isActive': true,
        }, SetOptions(merge: true));
      }
      debugPrint('Tokens de test créés pour ${userIds.length} utilisateurs');
    } catch (e) {
      debugPrint('Erreur lors de la création des tokens de test: $e');
    }
  }

  /// Obtient tous les tokens des utilisateurs (pour debug)
  static Future<List<String>> getAllUserTokens() async {
    try {
      final snapshot = await _firestore
          .collection(_tokensCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final tokens = <String>[];
      for (final doc in snapshot.docs) {
        final token = doc.data()['token'] as String?;
        if (token != null && !token.startsWith('test_token_')) {
          tokens.add(token);
        }
      }
      
      debugPrint('Trouvé ${tokens.length} tokens réels');
      return tokens;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des tokens: $e');
      return [];
    }
  }
}

/// Gestionnaire pour les messages en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Message reçu en background: ${message.messageId}');
  
  // Ici vous pouvez traiter les messages en background
  // Attention: limitez les opérations lourdes
}
