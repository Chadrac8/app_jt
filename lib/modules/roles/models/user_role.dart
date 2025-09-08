import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final List<String> roleIds;
  final bool isActive;
  final DateTime? assignedAt;
  final String? assignedBy;
  final DateTime? expiresAt;

  UserRole({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.roleIds = const [],
    this.isActive = true,
    this.assignedAt,
    this.assignedBy,
    this.expiresAt,
  });

  factory UserRole.fromMap(Map<String, dynamic> map) {
    return UserRole(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      roleIds: List<String>.from(map['roleIds'] ?? []),
      isActive: map['isActive'] ?? true,
      assignedAt: map['assignedAt']?.toDate(),
      assignedBy: map['assignedBy'],
      expiresAt: map['expiresAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'roleIds': roleIds,
      'isActive': isActive,
      'assignedAt': assignedAt ?? FieldValue.serverTimestamp(),
      'assignedBy': assignedBy,
      'expiresAt': expiresAt,
    };
  }

  factory UserRole.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserRole.fromMap({...data, 'id': doc.id});
  }

  UserRole copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    List<String>? roleIds,
    bool? isActive,
    DateTime? assignedAt,
    String? assignedBy,
    DateTime? expiresAt,
  }) {
    return UserRole(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      roleIds: roleIds ?? this.roleIds,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      assignedBy: assignedBy ?? this.assignedBy,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool hasRole(String roleId) {
    return roleIds.contains(roleId) && isActive && !isExpired;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  List<String> get activeRoleIds {
    if (!isActive || isExpired) return [];
    return roleIds;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRole && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserRole(id: $id, userId: $userId, userEmail: $userEmail, roles: ${roleIds.length})';
  }
}
