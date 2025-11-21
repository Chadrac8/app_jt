import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_song_reservation_model.dart';

class SpecialSongReservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection
  static const String reservationsCollection = 'special_song_reservations';

  /// Crée une nouvelle réservation
  static Future<String> createReservation(SpecialSongReservationModel reservation) async {
    try {
      // Vérifier que la date est un dimanche
      if (reservation.reservedDate.weekday != DateTime.sunday) {
        throw Exception('Seuls les dimanches peuvent être réservés');
      }

      // Vérifier que la date est dans le mois courant
      final now = DateTime.now();
      if (reservation.reservedDate.year != now.year || 
          reservation.reservedDate.month != now.month) {
        throw Exception('Les réservations ne sont autorisées que pour le mois en cours');
      }

      // Vérifier que la date n'est pas dans le passé
      final today = DateTime(now.year, now.month, now.day);
      final reservationDay = DateTime(
        reservation.reservedDate.year, 
        reservation.reservedDate.month, 
        reservation.reservedDate.day
      );
      if (reservationDay.isBefore(today)) {
        throw Exception('Impossible de réserver une date passée');
      }

      // Vérifier qu'il n'y a pas déjà une réservation pour cette date
      final existingReservation = await _getReservationForDate(reservation.reservedDate);
      if (existingReservation != null) {
        throw Exception('Ce dimanche est déjà réservé');
      }

      // Vérifier que la personne n'a pas déjà une réservation ce mois
      final hasExistingReservation = await _hasPersonReservedThisMonth(reservation.personId);
      if (hasExistingReservation) {
        throw Exception('Vous avez déjà une réservation pour ce mois');
      }

      // Créer la réservation
      final docRef = await _firestore.collection(reservationsCollection).add(reservation.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }

  /// Met à jour une réservation existante
  static Future<void> updateReservation(SpecialSongReservationModel reservation) async {
    try {
      await _firestore
          .collection(reservationsCollection)
          .doc(reservation.id)
          .update(reservation.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la réservation: $e');
    }
  }

  /// Annule une réservation
  static Future<void> cancelReservation(String reservationId) async {
    try {
      await _firestore
          .collection(reservationsCollection)
          .doc(reservationId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'annulation de la réservation: $e');
    }
  }

  /// Supprime une réservation
  static Future<void> deleteReservation(String reservationId) async {
    try {
      await _firestore
          .collection(reservationsCollection)
          .doc(reservationId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la réservation: $e');
    }
  }

  /// Récupère une réservation par ID
  static Future<SpecialSongReservationModel?> getReservation(String reservationId) async {
    try {
      final doc = await _firestore
          .collection(reservationsCollection)
          .doc(reservationId)
          .get();
      
      if (doc.exists) {
        return SpecialSongReservationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la réservation: $e');
    }
  }

  /// Récupère toutes les réservations du mois courant
  static Future<List<SpecialSongReservationModel>> getCurrentMonthReservations() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await _firestore
          .collection(reservationsCollection)
          .where('reservedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('reservedDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('status', isEqualTo: 'active')
          .orderBy('reservedDate')
          .get();

      return snapshot.docs
          .map((doc) => SpecialSongReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations du mois: $e');
    }
  }

  /// Récupère les réservations d'une personne
  static Future<List<SpecialSongReservationModel>> getPersonReservations(String personId) async {
    try {
      final snapshot = await _firestore
          .collection(reservationsCollection)
          .where('personId', isEqualTo: personId)
          .orderBy('reservedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SpecialSongReservationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des réservations de la personne: $e');
    }
  }

  /// Obtient les statistiques mensuelles
  static Future<MonthlyReservationStats> getMonthlyStats({int? year, int? month}) async {
    try {
      final now = DateTime.now();
      final targetYear = year ?? now.year;
      final targetMonth = month ?? now.month;

      // Récupérer toutes les réservations du mois
      final startOfMonth = DateTime(targetYear, targetMonth, 1);
      final endOfMonth = DateTime(targetYear, targetMonth + 1, 0);

      final snapshot = await _firestore
          .collection(reservationsCollection)
          .where('reservedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('reservedDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('status', isEqualTo: 'active')
          .get();

      final reservations = snapshot.docs
          .map((doc) => SpecialSongReservationModel.fromFirestore(doc))
          .toList();

      // Calculer tous les dimanches du mois
      final allSundays = MonthlyReservationStats.getSundaysInMonth(targetYear, targetMonth);
      
      // Identifier les dimanches réservés
      final reservedSundays = reservations
          .map((r) => DateTime(r.reservedDate.year, r.reservedDate.month, r.reservedDate.day))
          .toList();

      // Calculer les dimanches disponibles (futurs uniquement si c'est le mois courant)
      List<DateTime> availableSundays = allSundays;
      if (targetYear == now.year && targetMonth == now.month) {
        final today = DateTime(now.year, now.month, now.day);
        availableSundays = allSundays.where((sunday) {
          final sundayDate = DateTime(sunday.year, sunday.month, sunday.day);
          return !sundayDate.isBefore(today);
        }).toList();
      }

      return MonthlyReservationStats(
        year: targetYear,
        month: targetMonth,
        reservations: reservations,
        availableSundays: availableSundays,
        reservedSundays: reservedSundays,
      );
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques mensuelles: $e');
    }
  }

  /// Vérifie si une date est disponible pour réservation
  static Future<bool> isDateAvailable(DateTime date) async {
    try {
      // Vérifier que c'est un dimanche
      if (date.weekday != DateTime.sunday) return false;

      // Vérifier que c'est dans le mois courant
      final now = DateTime.now();
      if (date.year != now.year || date.month != now.month) return false;

      // Vérifier que ce n'est pas dans le passé
      final today = DateTime(now.year, now.month, now.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      if (checkDate.isBefore(today)) return false;

      // Vérifier qu'il n'y a pas déjà une réservation
      final existingReservation = await _getReservationForDate(date);
      return existingReservation == null;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si une personne peut réserver (pas de réservation ce mois)
  static Future<bool> canPersonReserve(String personId) async {
    try {
      return !(await _hasPersonReservedThisMonth(personId));
    } catch (e) {
      return false;
    }
  }

  /// Stream des réservations du mois courant
  static Stream<List<SpecialSongReservationModel>> getCurrentMonthReservationsStream() {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      return _firestore
          .collection(reservationsCollection)
          .where('reservedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('reservedDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('status', isEqualTo: 'active')
          .orderBy('reservedDate')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SpecialSongReservationModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors du stream des réservations: $e');
    }
  }

  // Méthodes privées

  /// Récupère une réservation pour une date donnée
  static Future<SpecialSongReservationModel?> _getReservationForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection(reservationsCollection)
          .where('reservedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('reservedDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SpecialSongReservationModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si une personne a déjà une réservation ce mois
  static Future<bool> _hasPersonReservedThisMonth(String personId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final snapshot = await _firestore
          .collection(reservationsCollection)
          .where('personId', isEqualTo: personId)
          .where('reservedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('reservedDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}