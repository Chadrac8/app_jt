import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/church_service.dart';

class ChurchServiceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'church_services';

  /// Obtenir tous les services actifs pour les membres
  static Future<List<ChurchService>> getActiveServices() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('scheduleDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ChurchService.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des services: $e');
      // Fallback sans orderBy sur scheduleDate
      return _getActiveServicesFallback();
    }
  }

  /// Fallback sans orderBy complexe
  static Future<List<ChurchService>> _getActiveServicesFallback() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final services = querySnapshot.docs
          .map((doc) => ChurchService.fromFirestore(doc))
          .toList();

      // Trier manuellement
      services.sort((a, b) {
        final dateA = a.scheduleDate ?? DateTime.now();
        final dateB = b.scheduleDate ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      return services;
    } catch (e) {
      print('Erreur fallback services: $e');
      return [];
    }
  }

  /// Stream des services actifs
  static Stream<List<ChurchService>> getActiveServicesStream() {
    try {
      return _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final services = snapshot.docs
                .map((doc) => ChurchService.fromFirestore(doc))
                .toList();

            // Trier manuellement côté client
            services.sort((a, b) {
              final dateA = a.scheduleDate ?? DateTime.now();
              final dateB = b.scheduleDate ?? DateTime.now();
              return dateA.compareTo(dateB);
            });

            return services;
          });
    } catch (e) {
      print('Erreur lors de la création du stream services: $e');
      return Stream.value(<ChurchService>[]);
    }
  }

  /// Stream de tous les services (admin)
  static Stream<List<ChurchService>> getAllServicesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChurchService.fromFirestore(doc))
            .toList());
  }

  /// Obtenir les services par type
  static Future<List<ChurchService>> getServicesByType(String type) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('serviceType', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .get();

      final services = querySnapshot.docs
          .map((doc) => ChurchService.fromFirestore(doc))
          .toList();

      // Trier par date de planification
      services.sort((a, b) {
        final dateA = a.scheduleDate ?? DateTime.now();
        final dateB = b.scheduleDate ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      return services;
    } catch (e) {
      print('Erreur lors de la récupération par type: $e');
      return [];
    }
  }

  /// Obtenir les services à venir
  static Future<List<ChurchService>> getUpcomingServices() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('scheduleDate', isGreaterThanOrEqualTo: now)
          .get();

      final services = querySnapshot.docs
          .map((doc) => ChurchService.fromFirestore(doc))
          .toList();

      services.sort((a, b) {
        final dateA = a.scheduleDate ?? DateTime.now();
        final dateB = b.scheduleDate ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      return services;
    } catch (e) {
      print('Erreur lors de la récupération des services à venir: $e');
      return [];
    }
  }

  /// Créer un nouveau service
  static Future<String> createService(ChurchService service) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(service.copyWith(
            createdBy: _auth.currentUser?.uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ).toFirestore());
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du service: $e');
      rethrow;
    }
  }

  /// Mettre à jour un service
  static Future<void> updateService(String serviceId, ChurchService service) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(serviceId)
          .update(service.copyWith(
            id: serviceId,
            updatedAt: DateTime.now(),
          ).toFirestore());
    } catch (e) {
      print('Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }

  /// Supprimer un service
  static Future<void> deleteService(String serviceId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(serviceId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Obtenir un service par ID
  static Future<ChurchService?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(serviceId)
          .get();
      
      if (doc.exists) {
        return ChurchService.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération par ID: $e');
      return null;
    }
  }

  /// Incrémenter le compteur de participation
  static Future<void> incrementAttendanceCount(String serviceId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(serviceId)
          .update({
        'attendanceCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erreur lors de l\'incrémentation: $e');
    }
  }

  /// Rechercher des services
  static Future<List<ChurchService>> searchServices(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final allServices = querySnapshot.docs
          .map((doc) => ChurchService.fromFirestore(doc))
          .toList();

      // Filtrer côté client
      final searchQuery = query.toLowerCase();
      return allServices.where((service) {
        return service.title.toLowerCase().contains(searchQuery) ||
               service.description.toLowerCase().contains(searchQuery) ||
               (service.pastor?.toLowerCase().contains(searchQuery) ?? false) ||
               service.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }
}
