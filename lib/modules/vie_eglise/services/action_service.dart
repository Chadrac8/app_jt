import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pour_vous_action.dart';

class ActionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'pour_vous_actions';

  // Obtenir toutes les actions
  Stream<List<PourVousAction>> getAllActions() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PourVousAction.fromFirestore(doc))
            .toList());
  }

  // Obtenir les actions actives
  Stream<List<PourVousAction>> getActiveActions() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PourVousAction.fromFirestore(doc))
            .toList());
  }

  // Obtenir les actions par groupe
  Stream<List<PourVousAction>> getActionsByGroup(String groupId) {
    return _firestore
        .collection(_collection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PourVousAction.fromFirestore(doc))
            .toList());
  }

  // Obtenir une action par ID
  Future<PourVousAction?> getActionById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return PourVousAction.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'action: $e');
      return null;
    }
  }

  // Créer une nouvelle action
  Future<String?> createAction(PourVousAction action) async {
    try {
      final docRef = await _firestore.collection(_collection).add(action.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'action: $e');
      throw Exception('Erreur lors de la création de l\'action: $e');
    }
  }

  // Mettre à jour une action
  Future<bool> updateAction(String id, PourVousAction action) async {
    try {
      await _firestore.collection(_collection).doc(id).update(action.toFirestore());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'action: $e');
      throw Exception('Erreur lors de la mise à jour de l\'action: $e');
    }
  }

  // Supprimer une action
  Future<bool> deleteAction(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'action: $e');
      throw Exception('Erreur lors de la suppression de l\'action: $e');
    }
  }

  // Mettre à jour le statut d'une action
  Future<bool> toggleActionStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Mettre à jour l'ordre des actions
  Future<bool> updateActionOrder(String id, int order) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'order': order,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'ordre: $e');
      throw Exception('Erreur lors de la mise à jour de l\'ordre: $e');
    }
  }

  // Obtenir les statistiques des actions
  Future<Map<String, dynamic>> getActionsStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final actions = snapshot.docs.map((doc) => PourVousAction.fromFirestore(doc)).toList();
      
      final total = actions.length;
      final active = actions.where((a) => a.isActive).length;
      final inactive = total - active;
      
      // Stats par type
      final Map<String, int> byType = {};
      for (final action in actions) {
        byType[action.actionType] = (byType[action.actionType] ?? 0) + 1;
      }
      
      // Stats par catégorie
      final Map<String, int> byCategory = {};
      for (final action in actions) {
        if (action.category != null) {
          byCategory[action.category!] = (byCategory[action.category!] ?? 0) + 1;
        }
      }
      
      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'byType': byType,
        'byCategory': byCategory,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'byType': <String, int>{},
        'byCategory': <String, int>{},
      };
    }
  }

  // Rechercher des actions
  Future<List<PourVousAction>> searchActions(String query) async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final actions = snapshot.docs.map((doc) => PourVousAction.fromFirestore(doc)).toList();
      
      final lowerQuery = query.toLowerCase();
      return actions.where((action) =>
        action.title.toLowerCase().contains(lowerQuery) ||
        action.description.toLowerCase().contains(lowerQuery)
      ).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }

  // Dupliquer une action
  Future<String?> duplicateAction(String id) async {
    try {
      final action = await getActionById(id);
      if (action == null) return null;
      
      final duplicatedAction = action.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${action.title} (Copie)',
        order: action.order + 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return await createAction(duplicatedAction);
    } catch (e) {
      print('Erreur lors de la duplication: $e');
      throw Exception('Erreur lors de la duplication: $e');
    }
  }

  // Réorganiser les actions
  Future<bool> reorderActions(List<String> actionIds) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < actionIds.length; i++) {
        final docRef = _firestore.collection(_collection).doc(actionIds[i]);
        batch.update(docRef, {
          'order': i + 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de la réorganisation: $e');
      throw Exception('Erreur lors de la réorganisation: $e');
    }
  }
}