import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_model.dart';
import '../auth/auth_service.dart';
import '../services/user_profile_service.dart';

/// Service pour gérer le cache local des images de profil
/// Assure la persistance des avatars entre les redémarrages de l'application
class ProfileImageCacheService {
  static const String _cacheKeyPrefix = 'profile_image_cache_';
  static const String _timestampSuffix = '_timestamp';
  static const int _cacheValidityDays = 7;
  
  /// Sauvegarde l'URL de l'image de profil en cache pour un utilisateur
  static Future<void> cacheProfileImageUrl(String userId, String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString('${_cacheKeyPrefix}${userId}', imageUrl);
      await prefs.setInt('${_cacheKeyPrefix}${userId}${_timestampSuffix}', timestamp);
      
      print('Image cached for user $userId: $imageUrl');
    } catch (e) {
      print('Erreur lors de la mise en cache de l\'image: $e');
    }
  }
  
  /// Récupère l'URL de l'image de profil depuis le cache
  static Future<String?> getCachedProfileImageUrl(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Vérifier la validité du cache
      final timestamp = prefs.getInt('${_cacheKeyPrefix}${userId}${_timestampSuffix}');
      if (timestamp == null) return null;
      
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final daysDifference = now.difference(cacheDate).inDays;
      
      if (daysDifference > _cacheValidityDays) {
        // Cache expiré, le supprimer
        await clearCachedProfileImage(userId);
        return null;
      }
      
      final cachedUrl = prefs.getString('${_cacheKeyPrefix}${userId}');
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        print('Image récupérée du cache pour user $userId');
        return cachedUrl;
      }
      
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
      return null;
    }
  }
  
  /// Supprime l'image de profil du cache pour un utilisateur
  static Future<void> clearCachedProfileImage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}${userId}');
      await prefs.remove('${_cacheKeyPrefix}${userId}${_timestampSuffix}');
      print('Cache supprimé pour user $userId');
    } catch (e) {
      print('Erreur lors de la suppression du cache: $e');
    }
  }
  
  /// Nettoie tous les caches expirés
  static Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();
      
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix) && key.endsWith(_timestampSuffix)) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
            final daysDifference = now.difference(cacheDate).inDays;
            
            if (daysDifference > _cacheValidityDays) {
              final userId = key
                  .replaceFirst(_cacheKeyPrefix, '')
                  .replaceFirst(_timestampSuffix, '');
              await clearCachedProfileImage(userId);
            }
          }
        }
      }
    } catch (e) {
      print('Erreur lors du nettoyage du cache: $e');
    }
  }
  
  /// Précharge l'image de profil depuis Firebase pour un utilisateur
  static Future<void> preloadProfileImage(PersonModel person) async {
    try {
      if (person.id.isEmpty || person.profileImageUrl == null || person.profileImageUrl!.isEmpty) {
        return;
      }
      
      // Vérifier si on a déjà une version récente en cache
      final cachedUrl = await getCachedProfileImageUrl(person.id);
      if (cachedUrl != null && cachedUrl == person.profileImageUrl) {
        print('Image déjà en cache pour ${person.id}');
        return;
      }
      
      // Mettre à jour le cache avec la nouvelle URL
      await cacheProfileImageUrl(person.id, person.profileImageUrl!);
      
      print('Image préchargée pour ${person.id}');
    } catch (e) {
      print('Erreur lors du préchargement: $e');
    }
  }
  
  /// Initialise le cache au démarrage de l'application
  static Future<void> initializeCache() async {
    try {
      // Nettoyer les caches expirés
      await cleanupExpiredCache();
      
      // Précharger l'image de l'utilisateur actuel
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        final person = await UserProfileService.getCurrentUserProfile();
        if (person != null) {
          await preloadProfileImage(person);
        }
      }
      
      print('Cache d\'images de profil initialisé');
    } catch (e) {
      print('Erreur lors de l\'initialisation du cache: $e');
    }
  }
}
