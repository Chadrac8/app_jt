import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/resource_item.dart';
import '../../../services/image_upload_service.dart';

/// Service pour gérer les ressources dans Firebase
class RessourcesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection des ressources
  static CollectionReference get _resourcesCollection =>
      _firestore.collection('church_resources');

  /// Obtenir toutes les ressources actives pour les membres
  static Stream<List<ResourceItem>> getActiveResourcesStream() {
    try {
      return _resourcesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .orderBy('title')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ResourceItem.fromFirestore(doc))
              .toList())
          .handleError((error) {
            print('Erreur stream ressources actives: $error');
            // Si erreur d'index, essayer sans orderBy
            if (error.toString().contains('requires an index')) {
              return _getActiveResourcesStreamFallback();
            }
            throw error;
          });
    } catch (e) {
      print('Erreur lors de la création du stream ressources: $e');
      // Retourner un stream avec une liste vide
      return Stream.value(<ResourceItem>[]);
    }
  }

  /// Stream de fallback sans orderBy pour éviter les erreurs d'index
  static Stream<List<ResourceItem>> _getActiveResourcesStreamFallback() {
    return _resourcesCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final resources = snapshot.docs
              .map((doc) => ResourceItem.fromFirestore(doc))
              .toList();
          // Trier manuellement
          resources.sort((a, b) {
            final orderCompare = a.order.compareTo(b.order);
            return orderCompare != 0 ? orderCompare : a.title.compareTo(b.title);
          });
          return resources;
        });
  }

  /// Obtenir toutes les ressources pour l'admin
  static Stream<List<ResourceItem>> getAllResourcesStream() {
    try {
      return _resourcesCollection
          .snapshots()
          .map((snapshot) {
            final resources = snapshot.docs
                .map((doc) => ResourceItem.fromFirestore(doc))
                .toList();
            // Trier manuellement pour éviter les erreurs d'index
            resources.sort((a, b) {
              final orderCompare = a.order.compareTo(b.order);
              return orderCompare != 0 ? orderCompare : a.title.compareTo(b.title);
            });
            return resources;
          });
    } catch (e) {
      print('Erreur lors de la création du stream admin ressources: $e');
      // Retourner un stream avec une liste vide en cas d'erreur
      return Stream.value(<ResourceItem>[]);
    }
  }

  /// Obtenir une ressource par ID
  static Future<ResourceItem?> getResourceById(String id) async {
    try {
      final doc = await _resourcesCollection.doc(id).get();
      if (doc.exists) {
        return ResourceItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la ressource: $e');
      return null;
    }
  }

  /// Créer une nouvelle ressource
  static Future<String?> createResource(ResourceItem resource) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final docRef = await _resourcesCollection.add(resource.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la ressource: $e');
      return null;
    }
  }

  /// Créer une nouvelle ressource avec upload d'image
  static Future<String?> createResourceWithImage({
    required ResourceItem resource,
    File? imageFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      String? imageUrl;
      
      // Upload de l'image si fournie
      if (imageFile != null) {
        // Créer d'abord la ressource pour avoir un ID
        final docRef = await _resourcesCollection.add(resource.toFirestore());
        final resourceId = docRef.id;
        
        // Upload l'image avec l'ID de la ressource
        imageUrl = await ImageUploadService.uploadResourceImage(imageFile, resourceId);
        
        if (imageUrl != null) {
          // Mettre à jour la ressource avec l'URL de l'image
          final updatedResource = ResourceItem(
            id: resourceId,
            title: resource.title,
            description: resource.description,
            iconName: resource.iconName,
            redirectUrl: resource.redirectUrl,
            redirectRoute: resource.redirectRoute,
            coverImageUrl: imageUrl,
            isActive: resource.isActive,
            order: resource.order,
            category: resource.category,
            createdAt: resource.createdAt,
            updatedAt: DateTime.now(),
          );
          
          await docRef.update(updatedResource.toFirestore());
        }
        
        return resourceId;
      } else {
        // Pas d'image, création normale
        return await createResource(resource);
      }
    } catch (e) {
      print('Erreur lors de la création de la ressource avec image: $e');
      return null;
    }
  }

  /// Mettre à jour une ressource
  static Future<bool> updateResource(ResourceItem resource) async {
    try {
      await _resourcesCollection.doc(resource.id).update(resource.toFirestore());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la ressource: $e');
      return false;
    }
  }

  /// Mettre à jour une ressource avec upload d'image
  static Future<bool> updateResourceWithImage({
    required ResourceItem resource,
    File? newImageFile,
    bool removeCurrentImage = false,
  }) async {
    try {
      String? imageUrl = resource.coverImageUrl;
      
      // Supprimer l'ancienne image si demandé
      if (removeCurrentImage && resource.coverImageUrl != null) {
        await ImageUploadService.deleteImage(resource.coverImageUrl!);
        imageUrl = null;
      }
      
      // Upload de la nouvelle image si fournie
      if (newImageFile != null) {
        // Supprimer l'ancienne image avant d'uploader la nouvelle
        if (resource.coverImageUrl != null && !removeCurrentImage) {
          await ImageUploadService.deleteImage(resource.coverImageUrl!);
        }
        
        imageUrl = await ImageUploadService.uploadResourceImage(newImageFile, resource.id);
      }
      
      // Créer la ressource mise à jour avec la nouvelle URL d'image
      final updatedResource = ResourceItem(
        id: resource.id,
        title: resource.title,
        description: resource.description,
        iconName: resource.iconName,
        redirectUrl: resource.redirectUrl,
        redirectRoute: resource.redirectRoute,
        coverImageUrl: imageUrl,
        isActive: resource.isActive,
        order: resource.order,
        category: resource.category,
        createdAt: resource.createdAt,
        updatedAt: DateTime.now(),
      );
      
      await _resourcesCollection.doc(resource.id).update(updatedResource.toFirestore());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la ressource avec image: $e');
      return false;
    }
  }

  /// Supprimer une ressource
  static Future<bool> deleteResource(String id) async {
    try {
      await _resourcesCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la ressource: $e');
      return false;
    }
  }

  /// Basculer le statut actif d'une ressource
  static Future<bool> toggleResourceStatus(String id, bool isActive) async {
    try {
      await _resourcesCollection.doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
      return false;
    }
  }

  /// Réorganiser les ressources
  static Future<bool> reorderResources(List<ResourceItem> resources) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < resources.length; i++) {
        final resource = resources[i];
        batch.update(_resourcesCollection.doc(resource.id), {
          'order': i,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de la réorganisation: $e');
      return false;
    }
  }

  /// Initialiser les ressources par défaut
  static Future<void> initializeDefaultResources() async {
    try {
      print('🔄 Tentative d\'initialisation des ressources par défaut...');
      
      final snapshot = await _resourcesCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('✅ Les ressources existent déjà (${snapshot.docs.length} trouvées)');
        return;
      }

      print('📝 Création des ressources par défaut...');
      final defaultResources = [
        ResourceItem(
          id: '',
          title: 'La Bible',
          description: 'Accédez à la Bible interactive avec commentaires et outils d\'étude',
          iconName: 'menu_book',
          redirectRoute: '/member/bible',
          category: 'spiritual',
          order: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ResourceItem(
          id: '',
          title: 'Le Message du temps de la fin',
          description: 'Messages spirituels et enseignements pour notre époque',
          iconName: 'campaign',
          redirectRoute: '/member/message',
          category: 'spiritual',
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ResourceItem(
          id: '',
          title: 'Cantiques',
          description: 'Collection complète des chants et cantiques de l\'église',
          iconName: 'library_music',
          redirectRoute: '/member/songs',
          category: 'worship',
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ResourceItem(
          id: '',
          title: 'Jubilé Tabernacle',
          description: 'Ressources spécifiques de notre église et communauté',
          iconName: 'church',
          redirectUrl: 'https://jubile-tabernacle.org',
          category: 'church',
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      int created = 0;
      for (final resource in defaultResources) {
        try {
          await _resourcesCollection.add(resource.toFirestore());
          created++;
          print('✅ Ressource créée: ${resource.title}');
        } catch (e) {
          print('❌ Erreur lors de la création de "${resource.title}": $e');
        }
      }

      print('✅ Initialisation terminée: $created/${defaultResources.length} ressources créées');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des ressources: $e');
      // En cas d'erreur Firebase, on peut essayer de continuer quand même
      if (e.toString().contains('indexes') || e.toString().contains('permission')) {
        print('💡 L\'erreur semble liée aux indexes Firestore ou permissions');
      }
    }
  }

  /// Obtenir les ressources par catégorie
  static Stream<Map<String, List<ResourceItem>>> getResourcesByCategoryStream() {
    return getActiveResourcesStream().map((resources) {
      final Map<String, List<ResourceItem>> categorizedResources = {};
      
      for (final resource in resources) {
        if (!categorizedResources.containsKey(resource.category)) {
          categorizedResources[resource.category] = [];
        }
        categorizedResources[resource.category]!.add(resource);
      }
      
      return categorizedResources;
    });
  }

  /// Obtenir les catégories disponibles
  static Future<List<String>> getAvailableCategories() async {
    try {
      final snapshot = await _resourcesCollection.get();
      final categories = <String>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String? ?? 'general';
        categories.add(category);
      }
      
      return categories.toList()..sort();
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return ['general', 'spiritual', 'worship', 'church'];
    }
  }
}
