import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pour_vous_action.dart';

/// Service pour gérer les actions "Pour vous" du module Vie de l'église
class PourVousActionService {
  static const String _collection = 'pour_vous_actions';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
