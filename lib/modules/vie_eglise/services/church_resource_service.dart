import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/church_resource.dart';

class ChurchResourceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'church_resources';

  /// Obtenir toutes les ressources actives pour les membres
  static Future<List<ChurchResource>> getActiveResources() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchResource.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des ressources: $e');
      return [];
    }
  }

  /// Stream des ressources actives
  static Stream<List<ChurchResource>> getActiveResourcesStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChurchResource.fromFirestore(doc))
            .toList());
  }

  /// Obtenir toutes les ressources (admin)
  static Stream<List<ChurchResource>> getAllResourcesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChurchResource.fromFirestore(doc))
            .toList());
  }

  /// Obtenir les ressources par catégorie
  static Future<List<ChurchResource>> getResourcesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchResource.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération par catégorie: $e');
      return [];
    }
  }

  /// Obtenir les ressources par type
  static Future<List<ChurchResource>> getResourcesByType(String type) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('resourceType', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchResource.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération par type: $e');
      return [];
    }
  }

  /// Créer une nouvelle ressource
  static Future<String> createResource(ChurchResource resource) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(resource.copyWith(
            createdBy: _auth.currentUser?.uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la ressource: $e');
      rethrow;
    }
  }

  /// Mettre à jour une ressource
  static Future<void> updateResource(String resourceId, ChurchResource resource) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(resourceId)
          .update(resource.copyWith(
            id: resourceId,
            updatedAt: DateTime.now(),
          ).toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }

  /// Supprimer une ressource
  static Future<void> deleteResource(String resourceId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(resourceId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Obtenir une ressource par ID
  static Future<ChurchResource?> getResourceById(String resourceId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(resourceId)
          .get();
      
      if (doc.exists) {
        return ChurchResource.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération par ID: $e');
      return null;
    }
  }

  /// Incrémenter le compteur de téléchargements
  static Future<void> incrementDownloadCount(String resourceId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(resourceId)
          .update({
        'downloadCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erreur lors de l\'incrémentation: $e');
    }
  }

  /// Rechercher des ressources
  static Future<List<ChurchResource>> searchResources(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final allResources = querySnapshot.docs
          .map((doc) => ChurchResource.fromFirestore(doc))
          .toList();

      // Filtrer côté client
      final searchQuery = query.toLowerCase();
      return allResources.where((resource) {
        return resource.title.toLowerCase().contains(searchQuery) ||
               resource.description.toLowerCase().contains(searchQuery) ||
               resource.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// Obtenir les ressources les plus téléchargées
  static Future<List<ChurchResource>> getPopularResources({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('downloadCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchResource.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des ressources populaires: $e');
      return [];
    }
  }
}
