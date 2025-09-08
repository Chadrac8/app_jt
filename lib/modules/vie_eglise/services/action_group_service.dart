import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/action_group.dart';
import 'package:flutter/material.dart';

class ActionGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'action_groups';

  // Obtenir tous les groupes
  Stream<List<ActionGroup>> getAllGroups() {
    return _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActionGroup.fromFirestore(doc))
            .toList());
  }

  // Obtenir les groupes actifs
  Stream<List<ActionGroup>> getActiveGroups() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActionGroup.fromFirestore(doc))
            .toList());
  }

  // Obtenir un groupe par ID
  Future<ActionGroup?> getGroupById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ActionGroup.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du groupe: $e');
      return null;
    }
  }

  // Créer un nouveau groupe
  Future<String?> createGroup(ActionGroup group) async {
    try {
      final docRef = await _firestore.collection(_collection).add(group.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du groupe: $e');
      return null;
    }
  }

  // Mettre à jour un groupe
  Future<bool> updateGroup(String id, ActionGroup group) async {
    try {
      await _firestore.collection(_collection).doc(id).update(
        group.copyWith(updatedAt: DateTime.now()).toFirestore());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du groupe: $e');
      return false;
    }
  }

  // Supprimer un groupe
  Future<bool> deleteGroup(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du groupe: $e');
      return false;
    }
  }

  // Activer/désactiver un groupe
  Future<bool> toggleGroupStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut du groupe: $e');
      return false;
    }
  }

  // Réorganiser les groupes
  Future<bool> reorderGroups(List<ActionGroup> groups) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < groups.length; i++) {
        final docRef = _firestore.collection(_collection).doc(groups[i].id);
        batch.update(docRef, {
          'order': i,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de la réorganisation des groupes: $e');
      return false;
    }
  }

  // Compter les actions dans un groupe
  Future<int> countActionsInGroup(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('pour_vous_actions')
          .where('groupId', isEqualTo: groupId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des actions dans le groupe: $e');
      return 0;
    }
  }

  // Déplacer des actions vers un autre groupe
  Future<bool> moveActionsToGroup(List<String> actionIds, String newGroupId) async {
    try {
      final batch = _firestore.batch();
      
      for (final actionId in actionIds) {
        final docRef = _firestore.collection('pour_vous_actions').doc(actionId);
        batch.update(docRef, {
          'groupId': newGroupId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors du déplacement des actions: $e');
      return false;
    }
  }

  // Initialiser les groupes par défaut
  Future<void> initializeDefaultGroups() async {
    try {
      // Vérifier si des groupes existent déjà
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Des groupes existent déjà, initialisation annulée');
        return;
      }
      
      await createDefaultGroups();
    } catch (e) {
      print('Erreur lors de l\'initialisation des groupes par défaut: $e');
    }
  }

  // Créer les groupes par défaut
  Future<void> createDefaultGroups() async {
    try {
      final defaultGroups = [
        ActionGroup(
          id: '',
          name: 'Relation avec les pasteurs',
          description: 'Actions pour interagir avec l\'équipe pastorale',
          icon: Icons.people,
          iconCodePoint: Icons.people.codePoint.toString(),
          color: '#FF6B35',
          order: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionGroup(
          id: '',
          name: 'Participer aux services',
          description: 'Opportunités de participation active aux services',
          icon: Icons.church,
          iconCodePoint: Icons.church.codePoint.toString(),
          color: '#4A90E2',
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionGroup(
          id: '',
          name: 'Amélioration de l\'église',
          description: 'Propositions et contributions pour l\'amélioration',
          icon: Icons.lightbulb,
          iconCodePoint: Icons.lightbulb.codePoint.toString(),
          color: '#F5A623',
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionGroup(
          id: '',
          name: 'Vie spirituelle',
          description: 'Actions pour approfondir votre foi',
          icon: Icons.favorite,
          iconCodePoint: Icons.favorite.codePoint.toString(),
          color: '#BD10E0',
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionGroup(
          id: '',
          name: 'En savoir plus sur l\'église',
          description: 'Informations et ressources sur l\'église',
          icon: Icons.info,
          iconCodePoint: Icons.info.codePoint.toString(),
          color: '#50E3C2',
          order: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final group in defaultGroups) {
        await createGroup(group);
      }
      
      print('Groupes par défaut créés avec succès');
    } catch (e) {
      print('Erreur lors de la création des groupes par défaut: $e');
    }
  }
}
