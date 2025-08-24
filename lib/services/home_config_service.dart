import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_config_model.dart';

/// Service pour gérer la configuration de la page d'accueil membre
class HomeConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection Firestore
  static const String _collectionName = 'home_config';
  static const String _configDocId = 'main_config';

  /// Obtenir la configuration active de l'accueil
  static Future<HomeConfigModel> getActiveHomeConfig() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .get();

      if (doc.exists) {
        return HomeConfigModel.fromFirestore(doc);
      } else {
        // Si aucune configuration n'existe, créer et retourner la configuration par défaut
        await _createDefaultConfig();
        return HomeConfigModel.defaultConfig;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la configuration d\'accueil: $e');
      return HomeConfigModel.defaultConfig;
    }
  }

  /// Obtenir la configuration (alias pour Perfect 13 compatibility)
  static Future<HomeConfigModel> getHomeConfig() async {
    return getActiveHomeConfig();
  }

  /// Stream pour écouter les changements de configuration
  static Stream<HomeConfigModel> getHomeConfigStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_configDocId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return HomeConfigModel.fromFirestore(doc);
          } else {
            // Créer la configuration par défaut si elle n'existe pas
            _createDefaultConfig();
            return HomeConfigModel.defaultConfig;
          }
        });
  }

  /// Mettre à jour la configuration complète de l'accueil
  static Future<void> updateHomeConfig(HomeConfigModel config) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final updatedConfig = config.copyWith(
        updatedAt: now,
        lastModifiedBy: user.uid,
      );

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(updatedConfig.toFirestore(), SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration d\'accueil: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration de couverture
  static Future<void> updateCoverConfig({
    required String coverImageUrl,
    List<String>? coverImageUrls,
    String? coverVideoUrl,
    bool? useVideo,
    String? coverTitle,
    String? coverSubtitle,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'coverImageUrl': coverImageUrl,
        'coverImageUrls': coverImageUrls ?? [],
        'coverVideoUrl': coverVideoUrl,
        'useVideo': useVideo ?? false,
        'coverTitle': coverTitle,
        'coverSubtitle': coverSubtitle,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration de couverture: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration du live
  static Future<void> updateLiveConfig({
    DateTime? liveDateTime,
    String? liveUrl,
    bool? isLiveActive,
    String? liveDescription,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'liveDateTime': liveDateTime != null ? Timestamp.fromDate(liveDateTime) : null,
        'liveUrl': liveUrl,
        'isLiveActive': isLiveActive ?? false,
        'liveDescription': liveDescription,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration du live: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration du pain quotidien
  static Future<void> updateDailyBreadConfig({
    String? dailyBreadTitle,
    String? dailyBreadVerse,
    String? dailyBreadReference,
    bool? isDailyBreadActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'dailyBreadTitle': dailyBreadTitle,
        'dailyBreadVerse': dailyBreadVerse,
        'dailyBreadReference': dailyBreadReference,
        'isDailyBreadActive': isDailyBreadActive ?? true,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration du pain quotidien: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration de la dernière prédication (Perfect 13 compatibility)
  static Future<void> updateSermonConfig({
    String? sermonTitle,
    String? sermonYouTubeUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'sermonTitle': sermonTitle,
        'sermonYouTubeUrl': sermonYouTubeUrl,
        'lastUpdated': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration du sermon: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration de la dernière prédication
  static Future<void> updateLastSermonConfig({
    String? lastSermonTitle,
    String? lastSermonPreacher,
    String? lastSermonDuration,
    String? lastSermonThumbnailUrl,
    String? lastSermonUrl,
    bool? isLastSermonActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'lastSermonTitle': lastSermonTitle,
        'lastSermonPreacher': lastSermonPreacher,
        'lastSermonDuration': lastSermonDuration,
        'lastSermonThumbnailUrl': lastSermonThumbnailUrl,
        'lastSermonUrl': lastSermonUrl,
        'isLastSermonActive': isLastSermonActive ?? true,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration de la prédication: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration des événements
  static Future<void> updateEventsConfig({
    List<Map<String, dynamic>>? upcomingEvents,
    bool? areEventsActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'upcomingEvents': upcomingEvents ?? [],
        'areEventsActive': areEventsActive ?? true,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration des événements: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration des actions rapides
  static Future<void> updateQuickActionsConfig({
    List<Map<String, dynamic>>? quickActions,
    bool? areQuickActionsActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'quickActions': quickActions ?? [],
        'areQuickActionsActive': areQuickActionsActive ?? true,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration des actions rapides: $e');
      rethrow;
    }
  }

  /// Mettre à jour la configuration des contacts
  static Future<void> updateContactConfig({
    String? contactEmail,
    String? contactPhone,
    String? contactWhatsApp,
    String? contactAddress,
    bool? isContactActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final configData = {
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'contactWhatsApp': contactWhatsApp,
        'contactAddress': contactAddress,
        'isContactActive': isContactActive ?? true,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData, SetOptions(merge: true));

    } catch (e) {
      print('Erreur lors de la mise à jour de la configuration des contacts: $e');
      rethrow;
    }
  }

  /// Créer la configuration par défaut
  static Future<void> _createDefaultConfig() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Création de la configuration par défaut sans utilisateur authentifié');
      }

      final defaultConfig = HomeConfigModel.defaultConfig.copyWith(
        createdBy: user?.uid,
        lastModifiedBy: user?.uid,
      );

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(defaultConfig.toFirestore());

    } catch (e) {
      print('Erreur lors de la création de la configuration par défaut: $e');
    }
  }

  /// Réinitialiser la configuration
  static Future<void> resetToDefault() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final defaultConfig = HomeConfigModel.defaultConfig.copyWith(
        updatedAt: now,
        lastModifiedBy: user.uid,
      );

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(defaultConfig.toFirestore());

    } catch (e) {
      print('Erreur lors de la réinitialisation de la configuration: $e');
      rethrow;
    }
  }

  /// Vérifier si une configuration existe
  static Future<bool> configExists() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Erreur lors de la vérification de l\'existence de la configuration: $e');
      return false;
    }
  }

  /// Obtenir l'historique des modifications (dernières 20)
  static Future<List<Map<String, dynamic>>> getConfigHistory() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Sauvegarder une version dans l'historique
  static Future<void> saveToHistory(String action) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final config = await getActiveHomeConfig();
      
      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .collection('history')
          .add({
        'action': action,
        'timestamp': Timestamp.now(),
        'userId': user.uid,
        'config': config.toFirestore(),
      });
    } catch (e) {
      print('Erreur lors de la sauvegarde dans l\'historique: $e');
    }
  }
}
