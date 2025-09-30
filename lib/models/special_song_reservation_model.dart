import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les réservations de chants spéciaux
class SpecialSongReservationModel {
  final String id;
  final String personId;
  final String fullName;
  final String email;
  final String phone;
  final String songTitle;
  final String? musicianLink;
  final DateTime reservedDate; // Le dimanche réservé
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'active', 'cancelled', 'completed'

  const SpecialSongReservationModel({
    required this.id,
    required this.personId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.songTitle,
    this.musicianLink,
    required this.reservedDate,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
  });

  /// Crée une instance depuis Firestore
  factory SpecialSongReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialSongReservationModel(
      id: doc.id,
      personId: data['personId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      songTitle: data['songTitle'] ?? '',
      musicianLink: data['musicianLink'],
      reservedDate: (data['reservedDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'personId': personId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'songTitle': songTitle,
      'musicianLink': musicianLink,
      'reservedDate': Timestamp.fromDate(reservedDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
    };
  }

  /// Crée une copie avec modifications
  SpecialSongReservationModel copyWith({
    String? id,
    String? personId,
    String? fullName,
    String? email,
    String? phone,
    String? songTitle,
    String? musicianLink,
    DateTime? reservedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return SpecialSongReservationModel(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      songTitle: songTitle ?? this.songTitle,
      musicianLink: musicianLink ?? this.musicianLink,
      reservedDate: reservedDate ?? this.reservedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  /// Vérifie si la réservation est pour ce mois
  bool isForCurrentMonth() {
    final now = DateTime.now();
    return reservedDate.year == now.year && reservedDate.month == now.month;
  }

  /// Vérifie si la réservation est active
  bool get isActive => status == 'active';

  @override
  String toString() {
    return 'SpecialSongReservationModel(id: $id, fullName: $fullName, songTitle: $songTitle, reservedDate: $reservedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialSongReservationModel &&
        other.id == id &&
        other.personId == personId &&
        other.reservedDate == reservedDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^ personId.hashCode ^ reservedDate.hashCode;
  }
}

/// Modèle pour les statistiques mensuelles des réservations
class MonthlyReservationStats {
  final int year;
  final int month;
  final List<SpecialSongReservationModel> reservations;
  final List<DateTime> availableSundays;
  final List<DateTime> reservedSundays;

  const MonthlyReservationStats({
    required this.year,
    required this.month,
    required this.reservations,
    required this.availableSundays,
    required this.reservedSundays,
  });

  /// Vérifie si un dimanche spécifique est disponible
  bool isSundayAvailable(DateTime sunday) {
    return availableSundays.contains(sunday) && !reservedSundays.contains(sunday);
  }

  /// Obtient les dimanches du mois
  static List<DateTime> getSundaysInMonth(int year, int month) {
    final sundays = <DateTime>[];
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    // Trouve le premier dimanche du mois
    DateTime current = firstDay;
    while (current.weekday != DateTime.sunday) {
      current = current.add(const Duration(days: 1));
    }
    
    // Ajoute tous les dimanches du mois
    while (current.isBefore(lastDay) || current.day == lastDay.day) {
      sundays.add(current);
      current = current.add(const Duration(days: 7));
    }
    
    return sundays;
  }

  /// Vérifie si une personne a déjà une réservation ce mois
  bool hasPersonReservedThisMonth(String personId) {
    return reservations.any((r) => r.personId == personId && r.isActive);
  }
}