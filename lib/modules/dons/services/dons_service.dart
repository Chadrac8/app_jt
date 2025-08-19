import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/don_model.dart';

class DonsService {
  static const String _collectionName = 'dons';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un nouveau don
  static Future<String> createDon(Don don) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(don.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du don: $e');
    }
  }

  /// Obtenir un don par ID
  static Future<Don?> getDonById(String id) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();
      
      if (doc.exists) {
        return Don.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du don: $e');
    }
  }

  /// Mettre à jour un don
  static Future<void> updateDon(String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du don: $e');
    }
  }

  /// Supprimer un don
  static Future<void> deleteDon(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du don: $e');
    }
  }

  /// Obtenir tous les dons (pour admin)
  static Stream<List<Don>> getAllDonsStream() {
    try {
      return _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Don.fromFirestore(doc))
              .toList());
    } catch (e) {
      // Retourner un stream vide en cas d'erreur
      return Stream.value([]);
    }
  }

  /// Obtenir les dons d'un utilisateur spécifique
  static Stream<List<Don>> getDonsByUserStream(String userId) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('donorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Don.fromFirestore(doc))
              .toList());
    } catch (e) {
      // Retourner un stream vide en cas d'erreur
      return Stream.value([]);
    }
  }

  /// Obtenir les dons par statut
  static Stream<List<Don>> getDonsByStatusStream(String status) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Don.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Obtenir les dons par période
  static Stream<List<Don>> getDonsByPeriodStream(DateTime startDate, DateTime endDate) {
    try {
      return _firestore
          .collection(_collectionName)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Don.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Obtenir les statistiques des dons
  static Future<Map<String, dynamic>> getDonStatistics() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalAmount = 0;
      int totalDons = snapshot.docs.length;
      Map<String, double> purposeBreakdown = {};
      Map<String, int> monthlyBreakdown = {};

      for (var doc in snapshot.docs) {
        final don = Don.fromFirestore(doc);
        totalAmount += don.amount;

        // Répartition par objectif
        purposeBreakdown[don.purpose] = (purposeBreakdown[don.purpose] ?? 0) + don.amount;

        // Répartition mensuelle
        final monthKey = '${don.createdAt.year}-${don.createdAt.month.toString().padLeft(2, '0')}';
        monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? 0) + 1;
      }

      return {
        'totalAmount': totalAmount,
        'totalDons': totalDons,
        'averageAmount': totalDons > 0 ? totalAmount / totalDons : 0,
        'purposeBreakdown': purposeBreakdown,
        'monthlyBreakdown': monthlyBreakdown,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Traiter un don (marquer comme terminé)
  static Future<void> processDon(String donId, String processedBy) async {
    try {
      await updateDon(donId, {
        'status': 'completed',
        'processedBy': processedBy,
        'processedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors du traitement du don: $e');
    }
  }

  /// Annuler un don
  static Future<void> cancelDon(String donId, String cancelledBy) async {
    try {
      await updateDon(donId, {
        'status': 'cancelled',
        'processedBy': cancelledBy,
        'processedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation du don: $e');
    }
  }

  /// Rechercher des dons
  static Future<List<Don>> searchDons(String query) async {
    try {
      // Recherche par nom du donateur
      final nameQuery = await _firestore
          .collection(_collectionName)
          .where('donorName', isGreaterThanOrEqualTo: query)
          .where('donorName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Recherche par email
      final emailQuery = await _firestore
          .collection(_collectionName)
          .where('donorEmail', isGreaterThanOrEqualTo: query)
          .where('donorEmail', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Combiner les résultats
      final results = <Don>[];
      final seenIds = <String>{};

      for (var doc in [...nameQuery.docs, ...emailQuery.docs]) {
        if (!seenIds.contains(doc.id)) {
          results.add(Don.fromFirestore(doc));
          seenIds.add(doc.id);
        }
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  /// Créer un don récurrent
  static Future<void> createRecurringDon(Don don) async {
    try {
      // Créer le don initial
      await createDon(don);

      // Programmer les prochains paiements (logique à implémenter selon les besoins)
      // Cette fonction pourrait être appelée par un Cloud Function
    } catch (e) {
      throw Exception('Erreur lors de la création du don récurrent: $e');
    }
  }

  /// Obtenir le total des dons pour une période
  static Future<double> getTotalDonationAmount({
    DateTime? startDate,
    DateTime? endDate,
    String? purpose,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'completed');

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      if (purpose != null) {
        query = query.where('purpose', isEqualTo: purpose);
      }

      final snapshot = await query.get();
      double total = 0;

      for (var doc in snapshot.docs) {
        final don = Don.fromFirestore(doc);
        total += don.amount;
      }

      return total;
    } catch (e) {
      throw Exception('Erreur lors du calcul du total: $e');
    }
  }
}
