import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'une demande
enum RequestStatus {
  pending('En attente'),
  inProgress('En cours'),
  completed('Terminée'),
  cancelled('Annulée');

  const RequestStatus(this.label);
  final String label;
}

/// Modèle pour les demandes soumises par les membres
class MemberRequest {
  final String id;
  final String actionId;
  final String actionTitle;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String title;
  final String description;
  final Map<String, dynamic> additionalData;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? handledBy;
  final String? responseNote;
  final DateTime? handledAt;

  MemberRequest({
    required this.id,
    required this.actionId,
    required this.actionTitle,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.title,
    required this.description,
    this.additionalData = const {},
    this.status = RequestStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.handledBy,
    this.responseNote,
    this.handledAt,
  });

  factory MemberRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MemberRequest(
      id: doc.id,
      actionId: data['actionId'] ?? '',
      actionTitle: data['actionTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      additionalData: data['additionalData'] ?? {},
      status: RequestStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      handledBy: data['handledBy'],
      responseNote: data['responseNote'],
      handledAt: (data['handledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'actionId': actionId,
      'actionTitle': actionTitle,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'title': title,
      'description': description,
      'additionalData': additionalData,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'handledBy': handledBy,
      'responseNote': responseNote,
      'handledAt': handledAt != null ? Timestamp.fromDate(handledAt!) : null,
    };
  }

  MemberRequest copyWith({
    String? id,
    String? actionId,
    String? actionTitle,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? title,
    String? description,
    Map<String, dynamic>? additionalData,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? handledBy,
    String? responseNote,
    DateTime? handledAt,
  }) {
    return MemberRequest(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      actionTitle: actionTitle ?? this.actionTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      additionalData: additionalData ?? this.additionalData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      handledBy: handledBy ?? this.handledBy,
      responseNote: responseNote ?? this.responseNote,
      handledAt: handledAt ?? this.handledAt,
    );
  }

  @override
  String toString() {
    return 'MemberRequest(id: $id, title: $title, status: ${status.label})';
  }
}
