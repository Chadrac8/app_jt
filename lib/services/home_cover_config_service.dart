import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/home_cover_config_model.dart';

/// Service pour gérer la configuration de l'image de couverture de l'accueil membre
class HomeCoverConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection Firestore
  static const String _collectionName = 'home_cover_config';
  static const String _configDocId = 'main_config';

  /// Obtenir la configuration active de l'image de couverture
  static Future<HomeCoverConfigModel> getActiveCoverConfig() async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .get();

      if (doc.exists) {
        return HomeCoverConfigModel.fromFirestore(doc);
      } else {
        // Si aucune configuration n'existe, créer et retourner la configuration par défaut
        await _createDefaultConfig();
        return HomeCoverConfigModel.defaultConfig;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la configuration de couverture: $e');
      return HomeCoverConfigModel.defaultConfig;
    }
  }

  /// Stream pour écouter les changements de configuration
  static Stream<HomeCoverConfigModel> getCoverConfigStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_configDocId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return HomeCoverConfigModel.fromFirestore(doc);
          } else {
            // Créer la configuration par défaut si elle n'existe pas
            _createDefaultConfig();
            return HomeCoverConfigModel.defaultConfig;
          }
        });
  }

  /// Mettre à jour la configuration de l'image de couverture
  static Future<void> updateCoverConfig({
    required String coverImageUrl,
    List<String>? coverImageUrls,
    String? coverVideoUrl,
    bool? useVideo,
    String? coverTitle,
    String? coverSubtitle,
    DateTime? liveDateTime,
    String? liveUrl,
    bool? isLiveActive,
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
        'isActive': true,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
        'liveDateTime': liveDateTime != null ? Timestamp.fromDate(liveDateTime) : null,
        'liveUrl': liveUrl,
        'isLiveActive': isLiveActive ?? false,
      };

      // Vérifier si le document existe
      final doc = await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .get();

      if (doc.exists) {
        // Mettre à jour le document existant
        await _firestore
            .collection(_collectionName)
            .doc(_configDocId)
            .update(configData);
      } else {
        // Créer un nouveau document avec les champs supplémentaires
        configData['createdAt'] = Timestamp.fromDate(now);
        configData['createdBy'] = user.uid;
        
        await _firestore
            .collection(_collectionName)
            .doc(_configDocId)
            .set(configData);
      }

      print('✅ Configuration de l\'image de couverture mise à jour');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la configuration: $e');
      throw Exception('Erreur lors de la mise à jour de la configuration: $e');
    }
  }

  /// Mettre à jour seulement les informations du live
  static Future<void> updateLiveConfig({
    DateTime? liveDateTime,
    String? liveUrl,
    bool? isLiveActive,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final now = DateTime.now();
      final liveConfigData = {
        'liveDateTime': liveDateTime != null ? Timestamp.fromDate(liveDateTime) : null,
        'liveUrl': liveUrl,
        'isLiveActive': isLiveActive ?? false,
        'updatedAt': Timestamp.fromDate(now),
        'lastModifiedBy': user.uid,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .update(liveConfigData);

      print('✅ Configuration du live mise à jour');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du live: $e');
      throw Exception('Erreur lors de la mise à jour du live: $e');
    }
  }

  /// Réinitialiser à la configuration par défaut
  static Future<void> resetToDefault() async {
    try {
      final defaultConfig = HomeCoverConfigModel.defaultConfig;
      await updateCoverConfig(
        coverImageUrl: defaultConfig.coverImageUrl,
        coverTitle: defaultConfig.coverTitle,
        coverSubtitle: defaultConfig.coverSubtitle,
        liveDateTime: defaultConfig.liveDateTime,
        liveUrl: defaultConfig.liveUrl,
        isLiveActive: defaultConfig.isLiveActive);
      print('✅ Configuration réinitialisée aux valeurs par défaut');
    } catch (e) {
      print('❌ Erreur lors de la réinitialisation: $e');
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Créer la configuration par défaut si elle n'existe pas
  static Future<void> _createDefaultConfig() async {
    try {
      final user = _auth.currentUser;
      final defaultConfig = HomeCoverConfigModel.defaultConfig;
      
      final configData = defaultConfig.toFirestore();
      if (user != null) {
        configData['createdBy'] = user.uid;
        configData['lastModifiedBy'] = user.uid;
      }

      await _firestore
          .collection(_collectionName)
          .doc(_configDocId)
          .set(configData);
      
      print('✅ Configuration par défaut créée');
    } catch (e) {
      print('❌ Erreur lors de la création de la configuration par défaut: $e');
    }
  }

  /// Valider une URL d'image
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // Vérifier que c'est une URL absolue avec http/https
      if (!uri.isAbsolute || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      
      // URLs Firebase Storage
      if (url.contains('firebasestorage.googleapis.com')) {
        return true; // Les URLs Firebase Storage sont toujours valides
      }
      
      // URLs classiques avec extension d'image
      final lowerUrl = url.toLowerCase();
      return (lowerUrl.contains('.jpg') ||
              lowerUrl.contains('.jpeg') ||
              lowerUrl.contains('.png') ||
              lowerUrl.contains('.webp') ||
              lowerUrl.contains('.gif'));
    } catch (e) {
      return false;
    }
  }

  /// Valider une URL de live
  static bool isValidLiveUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // Vérifier que c'est une URL absolue avec http/https
      if (!uri.isAbsolute || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      
      // URLs de plateformes de streaming connues
      final lowerUrl = url.toLowerCase();
      return (lowerUrl.contains('youtube.com') ||
              lowerUrl.contains('youtu.be') ||
              lowerUrl.contains('facebook.com') ||
              lowerUrl.contains('instagram.com') ||
              lowerUrl.contains('twitch.tv') ||
              lowerUrl.contains('vimeo.com') ||
              url.startsWith('https://')); // Accepter uniquement les URLs HTTPS pour la sécurité
    } catch (e) {
      return false;
    }
  }

  /// Obtenir des suggestions d'images par défaut
  static List<String> getDefaultImageSuggestions() {
    return [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1438032005730-c779502df39b?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800&h=400&fit=crop',
    ];
  }

  /// Statistiques d'utilisation (pour l'admin)
  static Future<Map<String, dynamic>> getUsageStats() async {
    try {
      final config = await getActiveCoverConfig();
      return {
        'currentImageUrl': config.coverImageUrl,
        'lastUpdated': config.updatedAt,
        'lastModifiedBy': config.lastModifiedBy,
        'isActive': config.isActive,
        'hasCustomTitle': config.coverTitle != null && config.coverTitle!.isNotEmpty,
        'hasCustomSubtitle': config.coverSubtitle != null && config.coverSubtitle!.isNotEmpty,
      };
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }
}
