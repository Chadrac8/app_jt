import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour représenter un don
class Don {
  final String id;
  final String donorId; // ID de l'utilisateur qui fait le don
  final String? donorName; // Nom du donateur (peut être anonyme)
  final String? donorEmail;
  final double amount; // Montant du don
  final String currency; // Devise (EUR, USD, etc.)
  final String type; // 'one_time', 'monthly', 'yearly'
  final String purpose; // 'general', 'missions', 'building', 'charity', 'other'
  final String? customPurpose; // Description personnalisée si purpose = 'other'
  final String status; // 'pending', 'completed', 'failed', 'cancelled'
  final String? paymentMethod; // 'card', 'bank_transfer', 'cash', 'check'
  final String? transactionId; // ID de transaction du système de paiement
  final bool isAnonymous; // Don anonyme
  final bool isRecurring; // Don récurrent
  final DateTime? nextPaymentDate; // Prochaine date de paiement pour les dons récurrents
  final String? message; // Message du donateur
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? processedBy; // ID de l'admin qui a traité le don
  final DateTime? processedAt;
  final Map<String, dynamic>? metadata; // Données supplémentaires

  Don({
    required this.id,
    required this.donorId,
    this.donorName,
    this.donorEmail,
    required this.amount,
    this.currency = 'EUR',
    this.type = 'one_time',
    this.purpose = 'general',
    this.customPurpose,
    this.status = 'pending',
    this.paymentMethod,
    this.transactionId,
    this.isAnonymous = false,
    this.isRecurring = false,
    this.nextPaymentDate,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.processedBy,
    this.processedAt,
    this.metadata,
  });

  factory Don.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Don(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'],
      donorEmail: data['donorEmail'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      type: data['type'] ?? 'one_time',
      purpose: data['purpose'] ?? 'general',
      customPurpose: data['customPurpose'],
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'],
      transactionId: data['transactionId'],
      isAnonymous: data['isAnonymous'] ?? false,
      isRecurring: data['isRecurring'] ?? false,
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      message: data['message'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedBy: data['processedBy'],
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'donorEmail': donorEmail,
      'amount': amount,
      'currency': currency,
      'type': type,
      'purpose': purpose,
      'customPurpose': customPurpose,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'isAnonymous': isAnonymous,
      'isRecurring': isRecurring,
      'nextPaymentDate': nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate!) : null,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'processedBy': processedBy,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'metadata': metadata,
    };
  }

  Don copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? donorEmail,
    double? amount,
    String? currency,
    String? type,
    String? purpose,
    String? customPurpose,
    String? status,
    String? paymentMethod,
    String? transactionId,
    bool? isAnonymous,
    bool? isRecurring,
    DateTime? nextPaymentDate,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? processedBy,
    DateTime? processedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Don(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      donorEmail: donorEmail ?? this.donorEmail,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      purpose: purpose ?? this.purpose,
      customPurpose: customPurpose ?? this.customPurpose,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isRecurring: isRecurring ?? this.isRecurring,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Types de dons disponibles
enum DonType {
  oneTime('one_time', 'Don unique'),
  monthly('monthly', 'Don mensuel'),
  yearly('yearly', 'Don annuel');

  const DonType(this.value, this.label);

  final String value;
  final String label;

  static DonType fromValue(String value) {
    return DonType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DonType.oneTime,
    );
  }
}

/// Objectifs de dons disponibles
enum DonPurpose {
  general('general', 'Don général'),
  missions('missions', 'Missions'),
  building('building', 'Bâtiment'),
  charity('charity', 'Œuvres caritatives'),
  youth('youth', 'Ministère jeunesse'),
  music('music', 'Ministère musical'),
  other('other', 'Autre');

  const DonPurpose(this.value, this.label);

  final String value;
  final String label;

  static DonPurpose fromValue(String value) {
    return DonPurpose.values.firstWhere(
      (purpose) => purpose.value == value,
      orElse: () => DonPurpose.general,
    );
  }
}

/// Statuts de dons disponibles
enum DonStatus {
  pending('pending', 'En attente'),
  completed('completed', 'Terminé'),
  failed('failed', 'Échoué'),
  cancelled('cancelled', 'Annulé');

  const DonStatus(this.value, this.label);

  final String value;
  final String label;

  static DonStatus fromValue(String value) {
    return DonStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DonStatus.pending,
    );
  }
}
