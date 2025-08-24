import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/pour_vous_action.dart';

/// Service pour gérer les actions "Pour vous" du module Vie de l'église
class PourVousActionService {
  static const String _collection = 'pour_vous_actions';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Récupère toutes les actions actives, triées par ordre
  Stream<List<PourVousAction>> getActiveActions() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          final actions = snapshot.docs
              .map((doc) => PourVousAction.fromFirestore(doc))
              .toList();
          
          // Tri secondaire par titre en mémoire pour éviter l'index composite
          actions.sort((a, b) {
            final orderComparison = a.order.compareTo(b.order);
            if (orderComparison != 0) return orderComparison;
            return a.title.compareTo(b.title);
          });
          
          return actions;
        });
  }

  /// Récupère toutes les actions (pour l'admin)
  Stream<List<PourVousAction>> getAllActions() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          final actions = snapshot.docs
              .map((doc) => PourVousAction.fromFirestore(doc))
              .toList();
          
          // Tri secondaire par titre en mémoire pour éviter l'index composite
          actions.sort((a, b) {
            final orderComparison = a.order.compareTo(b.order);
            if (orderComparison != 0) return orderComparison;
            return a.title.compareTo(b.title);
          });
          
          return actions;
        });
  }

  /// Récupère une action par son ID
  Future<PourVousAction?> getActionById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return PourVousAction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'action $id: $e');
      return null;
    }
  }

  /// Ajoute une nouvelle action
  Future<bool> addAction(PourVousAction action) async {
    try {
      await _firestore.collection(_collection).add(action.toFirestore());
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'action: $e');
      return false;
    }
  }

  /// Crée une nouvelle action et retourne son ID
  Future<String?> createAction(PourVousAction action) async {
    try {
      final docRef = await _firestore.collection(_collection).add(action.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'action: $e');
      return null;
    }
  }

  /// Met à jour une action existante
  Future<bool> updateAction(String id, PourVousAction action) async {
    try {
      await _firestore.collection(_collection).doc(id).update(action.toFirestore());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'action $id: $e');
      return false;
    }
  }

  /// Supprime une action
  Future<bool> deleteAction(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'action $id: $e');
      return false;
    }
  }

  /// Active/désactive une action
  Future<bool> toggleActionStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut de l\'action $id: $e');
      return false;
    }
  }

  /// Met à jour l'ordre des actions
  Future<bool> updateActionsOrder(List<PourVousAction> actions) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < actions.length; i++) {
        final action = actions[i];
        final docRef = _firestore.collection(_collection).doc(action.id);
        batch.update(docRef, {
          'order': i + 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'ordre des actions: $e');
      return false;
    }
  }

  /// Initialise les actions par défaut si aucune n'existe
  Future<bool> initializeDefaultActions() async {
    try {
      final existingActions = await _firestore.collection(_collection).limit(1).get();
      
      if (existingActions.docs.isEmpty) {
        print('Aucune action trouvée, initialisation des actions par défaut...');
        
        final defaultActions = PourVousAction.getDefaultActions();
        final batch = _firestore.batch();
        
        for (final action in defaultActions) {
          final docRef = _firestore.collection(_collection).doc();
          batch.set(docRef, action.toFirestore());
        }
        
        await batch.commit();
        print('${defaultActions.length} actions par défaut créées avec succès');
        return true;
      }
      
      return true;
    } catch (e) {
      print('Erreur lors de l\'initialisation des actions par défaut: $e');
      return false;
    }
  }

  /// Vérifie si les actions par défaut existent et les crée si nécessaire
  Future<void> ensureDefaultActionsExist() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      if (snapshot.docs.isEmpty) {
        await initializeDefaultActions();
      }
    } catch (e) {
      print('Erreur lors de la vérification des actions par défaut: $e');
    }
  }

  /// Récupère les statistiques des actions
  Future<Map<String, int>> getActionsStats() async {
    try {
      final allSnapshot = await _firestore.collection(_collection).get();
      final activeSnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      
      return {
        'total': allSnapshot.docs.length,
        'active': activeSnapshot.docs.length,
        'inactive': allSnapshot.docs.length - activeSnapshot.docs.length,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  /// Upload une image vers Firebase Storage
  Future<String?> uploadImage(File imageFile, String actionId) async {
    try {
      final ref = _storage.ref().child('pour_vous_actions').child('$actionId.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Erreur lors de l\'upload de l\'image: $e');
      return null;
    }
  }

  /// Supprimer une image de Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }

  /// Obtenir les actions par groupe
  Stream<List<PourVousAction>> getActionsByGroup(String groupId) {
    return _firestore
        .collection(_collection)
        .where('groupId', isEqualTo: groupId)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PourVousAction.fromFirestore(doc))
            .toList());
  }

  /// Réorganiser les actions
  Future<bool> reorderActions(List<PourVousAction> actions) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < actions.length; i++) {
        final docRef = _firestore.collection(_collection).doc(actions[i].id);
        batch.update(docRef, {
          'order': i,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de la réorganisation des actions: $e');
      return false;
    }
  }

  /// Dupliquer une action
  Future<String?> duplicateAction(String actionId) async {
    try {
      final action = await getActionById(actionId);
      if (action != null) {
        final duplicatedAction = action.copyWith(
          id: '',
          title: '${action.title} (Copie)',
          order: action.order + 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        return await createAction(duplicatedAction);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la duplication de l\'action: $e');
      return null;
    }
  }

  /// Exporter les actions au format JSON
  Future<Map<String, dynamic>> exportActions() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final actions = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      return {
        'exported_at': DateTime.now().toIso8601String(),
        'total_actions': actions.length,
        'actions': actions,
      };
    } catch (e) {
      print('Erreur lors de l\'export des actions: $e');
      return {};
    }
  }

  /// Importer des actions depuis un JSON
  Future<bool> importActions(Map<String, dynamic> data) async {
    try {
      final actions = data['actions'] as List<dynamic>;
      final batch = _firestore.batch();
      
      for (final actionData in actions) {
        final docRef = _firestore.collection(_collection).doc();
        final Map<String, dynamic> cleanData = Map<String, dynamic>.from(actionData);
        cleanData.remove('id'); // Supprimer l'ancien ID
        cleanData['createdAt'] = Timestamp.fromDate(DateTime.now());
        cleanData['updatedAt'] = Timestamp.fromDate(DateTime.now());
        
        batch.set(docRef, cleanData);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de l\'import des actions: $e');
      return false;
    }
  }

  /// Rechercher des actions
  Future<List<PourVousAction>> searchActions(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final allActions = snapshot.docs
          .map((doc) => PourVousAction.fromFirestore(doc))
          .toList();
      
      final lowerQuery = query.toLowerCase();
      return allActions.where((action) {
        return action.title.toLowerCase().contains(lowerQuery) ||
               action.description.toLowerCase().contains(lowerQuery) ||
               action.actionType.toLowerCase().contains(lowerQuery) ||
               (action.targetModule?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }
}
