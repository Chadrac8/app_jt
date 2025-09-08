import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les messages de contact
class ContactMessage {
  final String? id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? adminResponse;
  final DateTime? respondedAt;
  final String? respondedBy;

  const ContactMessage({
    this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.adminResponse,
    this.respondedAt,
    this.respondedBy,
  });

  /// Créer depuis un document Firestore
  factory ContactMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactMessage(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      adminResponse: data['adminResponse'],
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      respondedBy: data['respondedBy'],
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (adminResponse != null) 'adminResponse': adminResponse,
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
      if (respondedBy != null) 'respondedBy': respondedBy,
    };
  }

  /// Créer une copie avec modifications
  ContactMessage copyWith({
    String? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? adminResponse,
    DateTime? respondedAt,
    String? respondedBy,
  }) {
    return ContactMessage(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
      respondedBy: respondedBy ?? this.respondedBy,
    );
  }
}
