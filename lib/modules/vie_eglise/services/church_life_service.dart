import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/church_life_item.dart';

class ChurchLifeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'church_life_items';

  /// Obtenir tous les éléments de vie d'église actifs pour les membres
  static Future<List<ChurchLifeItem>> getActiveItems() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('publishDate', isLessThanOrEqualTo: DateTime.now())
          .orderBy('publishDate', descending: true)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchLifeItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des éléments de vie d\'église: $e');
      return [];
    }
  }

  /// Stream des éléments actifs
  static Stream<List<ChurchLifeItem>> getActiveItemsStream() {
    try {
      return _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('publishDate', isLessThanOrEqualTo: DateTime.now())
          .orderBy('publishDate', descending: true)
          .orderBy('priority', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ChurchLifeItem.fromFirestore(doc))
              .toList())
          .handleError((error) {
            print('Erreur stream éléments vie église: $error');
            return _getActiveItemsStreamFallback();
          });
    } catch (e) {
      print('Erreur lors de la création du stream: $e');
      return Stream.value(<ChurchLifeItem>[]);
    }
  }

  /// Stream de fallback sans orderBy complexe
  static Stream<List<ChurchLifeItem>> _getActiveItemsStreamFallback() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ChurchLifeItem.fromFirestore(doc))
              .where((item) => item.publishDate == null || 
                              item.publishDate!.isBefore(DateTime.now()) ||
                              item.publishDate!.isAtSameMomentAs(DateTime.now()))
              .toList();
          
          // Trier manuellement
          items.sort((a, b) {
            final dateCompare = (b.publishDate ?? b.createdAt)
                .compareTo(a.publishDate ?? a.createdAt);
            return dateCompare != 0 ? dateCompare : b.priority.compareTo(a.priority);
          });
          return items;
        });
  }

  /// Obtenir tous les éléments (admin)
  static Future<List<ChurchLifeItem>> getAllItems() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchLifeItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération de tous les éléments: $e');
      return [];
    }
  }

  /// Stream de tous les éléments (admin)
  static Stream<List<ChurchLifeItem>> getAllItemsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChurchLifeItem.fromFirestore(doc))
            .toList());
  }

  /// Obtenir les éléments par catégorie
  static Future<List<ChurchLifeItem>> getItemsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchLifeItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération par catégorie: $e');
      return [];
    }
  }

  /// Créer un nouvel élément
  static Future<String> createItem(ChurchLifeItem item) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(item.copyWith(
            createdBy: _auth.currentUser?.uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'élément: $e');
      rethrow;
    }
  }

  /// Mettre à jour un élément
  static Future<void> updateItem(String itemId, ChurchLifeItem item) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(itemId)
          .update(item.copyWith(
            id: itemId,
            updatedAt: DateTime.now(),
          ).toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }

  /// Supprimer un élément
  static Future<void> deleteItem(String itemId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(itemId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Obtenir un élément par ID
  static Future<ChurchLifeItem?> getItemById(String itemId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(itemId)
          .get();
      
      if (doc.exists) {
        return ChurchLifeItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération par ID: $e');
      return null;
    }
  }

  /// Rechercher des éléments
  static Future<List<ChurchLifeItem>> searchItems(String query) async {
    try {
      // Note: Firestore ne supporte pas la recherche full-text nativement
      // Cette implémentation basique recherche dans les titres
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final allItems = querySnapshot.docs
          .map((doc) => ChurchLifeItem.fromFirestore(doc))
          .toList();

      // Filtrer côté client (pour une recherche plus avancée, utiliser Algolia)
      final searchQuery = query.toLowerCase();
      return allItems.where((item) {
        return item.title.toLowerCase().contains(searchQuery) ||
               item.description.toLowerCase().contains(searchQuery) ||
               item.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }
}
