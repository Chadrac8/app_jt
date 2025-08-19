import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/action_item.dart';
import '../models/member_request.dart';

class PourVousService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _actionsCollection = 'pour_vous_actions';
  static const String _requestsCollection = 'pour_vous_requests';

  // === GESTION DES ACTIONS ===

  /// Obtenir toutes les actions actives pour les membres
  static Future<List<ActionItem>> getActiveActions() async {
    try {
      final querySnapshot = await _firestore
          .collection(_actionsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return querySnapshot.docs
          .map((doc) => ActionItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des actions: $e');
      return [];
    }
  }

  /// Obtenir toutes les actions (admin)
  static Future<List<ActionItem>> getAllActions() async {
    try {
      final querySnapshot = await _firestore
          .collection(_actionsCollection)
          .orderBy('order')
          .get();

      return querySnapshot.docs
          .map((doc) => ActionItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération de toutes les actions: $e');
      return [];
    }
  }

  /// Stream des actions actives
  static Stream<List<ActionItem>> getActiveActionsStream() {
    try {
      return _firestore
          .collection(_actionsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ActionItem.fromFirestore(doc))
              .toList())
          .handleError((error) {
            print('Erreur stream actions actives: $error');
            // Si erreur d'index, essayer sans orderBy
            if (error.toString().contains('requires an index')) {
              return _getActiveActionsStreamFallback();
            }
            throw error;
          });
    } catch (e) {
      print('Erreur lors de la création du stream: $e');
      // Retourner un stream avec une liste vide
      return Stream.value(<ActionItem>[]);
    }
  }

  /// Stream de fallback sans orderBy pour éviter les erreurs d'index
  static Stream<List<ActionItem>> _getActiveActionsStreamFallback() {
    return _firestore
        .collection(_actionsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final actions = snapshot.docs
              .map((doc) => ActionItem.fromFirestore(doc))
              .toList();
          // Trier manuellement
          actions.sort((a, b) {
            final orderCompare = a.order.compareTo(b.order);
            return orderCompare != 0 ? orderCompare : a.title.compareTo(b.title);
          });
          return actions;
        });
  }

  /// Stream de toutes les actions (admin)
  static Stream<List<ActionItem>> getAllActionsStream() {
    try {
      return _firestore
          .collection(_actionsCollection)
          .orderBy('order')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ActionItem.fromFirestore(doc))
              .toList())
          .handleError((error) {
            print('Erreur stream toutes actions: $error');
            // Si erreur d'index, essayer sans orderBy
            if (error.toString().contains('requires an index')) {
              return _getAllActionsStreamFallback();
            }
            throw error;
          });
    } catch (e) {
      print('Erreur lors de la création du stream: $e');
      // Retourner un stream avec une liste vide
      return Stream.value(<ActionItem>[]);
    }
  }

  /// Stream de fallback pour toutes les actions sans orderBy
  static Stream<List<ActionItem>> _getAllActionsStreamFallback() {
    return _firestore
        .collection(_actionsCollection)
        .snapshots()
        .map((snapshot) {
          final actions = snapshot.docs
              .map((doc) => ActionItem.fromFirestore(doc))
              .toList();
          // Trier manuellement
          actions.sort((a, b) => a.order.compareTo(b.order));
          return actions;
        });
  }

  /// Créer une nouvelle action
  static Future<String> createAction(ActionItem action) async {
    try {
      final docRef = await _firestore
          .collection(_actionsCollection)
          .add(action.copyWith(
            createdBy: _auth.currentUser?.uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de l\'action: $e');
      rethrow;
    }
  }

  /// Mettre à jour une action
  static Future<void> updateAction(String actionId, ActionItem action) async {
    try {
      await _firestore
          .collection(_actionsCollection)
          .doc(actionId)
          .update(action.copyWith(
            id: actionId,
            updatedAt: DateTime.now(),
          ).toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'action: $e');
      rethrow;
    }
  }

  /// Supprimer une action
  static Future<void> deleteAction(String actionId) async {
    try {
      await _firestore
          .collection(_actionsCollection)
          .doc(actionId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression de l\'action: $e');
      rethrow;
    }
  }

  /// Obtenir une action par ID
  static Future<ActionItem?> getActionById(String actionId) async {
    try {
      final doc = await _firestore
          .collection(_actionsCollection)
          .doc(actionId)
          .get();
      
      if (doc.exists) {
        return ActionItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'action: $e');
      return null;
    }
  }

  // === GESTION DES DEMANDES ===

  /// Créer une nouvelle demande
  static Future<String> createRequest(MemberRequest request) async {
    try {
      final docRef = await _firestore
          .collection(_requestsCollection)
          .add(request.copyWith(
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la demande: $e');
      rethrow;
    }
  }

  /// Obtenir toutes les demandes (admin)
  static Future<List<MemberRequest>> getAllRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_requestsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MemberRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des demandes: $e');
      return [];
    }
  }

  /// Obtenir les demandes d'un utilisateur
  static Future<List<MemberRequest>> getUserRequests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_requestsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MemberRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des demandes utilisateur: $e');
      return [];
    }
  }

  /// Stream de toutes les demandes (admin)
  static Stream<List<MemberRequest>> getAllRequestsStream() {
    return _firestore
        .collection(_requestsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberRequest.fromFirestore(doc))
            .toList());
  }

  /// Stream des demandes d'un utilisateur
  static Stream<List<MemberRequest>> getUserRequestsStream(String userId) {
    return _firestore
        .collection(_requestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberRequest.fromFirestore(doc))
            .toList());
  }

  /// Mettre à jour le statut d'une demande
  static Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status, {
    String? handledBy,
    String? responseNote,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (handledBy != null) {
        updateData['handledBy'] = handledBy;
        updateData['handledAt'] = Timestamp.fromDate(DateTime.now());
      }

      if (responseNote != null) {
        updateData['responseNote'] = responseNote;
      }

      await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .update(updateData);
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      rethrow;
    }
  }

  /// Supprimer une demande
  static Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression de la demande: $e');
      rethrow;
    }
  }

  /// Obtenir les statistiques des demandes
  static Future<Map<String, int>> getRequestsStats() async {
    try {
      final querySnapshot = await _firestore
          .collection(_requestsCollection)
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'cancelled': 0,
      };
    }
  }

  // === MÉTHODES D'INITIALISATION ===

  /// Initialiser les actions par défaut
  static Future<void> initializeDefaultActions() async {
    try {
      print('🔄 Initialisation des actions pour "Pour vous"...');
      
      // Vérifier si des actions existent déjà
      final querySnapshot = await _firestore
          .collection(_actionsCollection)
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        print('✅ Actions déjà existantes, aucune initialisation nécessaire');
        return;
      }

      print('📝 Création des actions par défaut...');

      final defaultActions = [
        ActionItem(
          id: '',
          title: 'Demander une prière',
          description: 'Partagez vos demandes de prière avec la communauté',
          iconName: 'prayer',
          redirectRoute: '/member/prayers',
          isActive: true,
          order: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionItem(
          id: '',
          title: 'Demander le baptême',
          description: 'Formulaire de demande de baptême',
          iconName: 'water_drop',
          redirectRoute: '/member/forms',
          isActive: true,
          order: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionItem(
          id: '',
          title: 'Rejoindre un groupe',
          description: 'Découvrez et rejoignez nos groupes de communion',
          iconName: 'groups',
          redirectRoute: '/member/groups',
          isActive: true,
          order: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionItem(
          id: '',
          title: 'Réserver un rendez-vous',
          description: 'Prenez rendez-vous avec le pasteur ou un responsable',
          iconName: 'schedule',
          redirectRoute: '/member/appointments',
          isActive: true,
          order: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionItem(
          id: '',
          title: 'Poser une question',
          description: 'Posez vos questions au pasteur ou aux responsables',
          iconName: 'help',
          redirectRoute: '/member/forms',
          isActive: true,
          order: 5,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ActionItem(
          id: '',
          title: 'Proposer une idée',
          description: 'Partagez vos idées pour améliorer la vie de l\'église',
          iconName: 'lightbulb',
          redirectRoute: '/member/forms',
          isActive: true,
          order: 6,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      int created = 0;
      for (final action in defaultActions) {
        try {
          await createAction(action);
          created++;
          print('✅ Action créée: ${action.title}');
        } catch (e) {
          print('❌ Erreur lors de la création de "${action.title}": $e');
        }
      }

      print('✅ Initialisation terminée: $created/${defaultActions.length} actions créées');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des actions: $e');
      // En cas d'erreur Firebase, on peut essayer de continuer quand même
      if (e.toString().contains('indexes') || e.toString().contains('permission')) {
        print('💡 L\'erreur semble liée aux indexes Firestore ou permissions');
      }
    }
  }
}
