import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant l'assignation d'un rôle à un utilisateur
class UserRole {
  final String id;
  final String userId;
  final String roleId;
  final String roleName; // Dénormalisé pour éviter les jointures
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime? revokedAt;
  final String? revokedBy;
  final String? revocationReason;

  UserRole({
    required this.id,
    required this.userId,
    required this.roleId,
    required this.roleName,
    required this.assignedBy,
    required this.assignedAt,
    this.expiresAt,
    this.isActive = true,
    this.reason,
    this.metadata,
    this.revokedAt,
    this.revokedBy,
    this.revocationReason,
  });

  /// Vérifie si l'assignation est toujours valide
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Vérifie si l'assignation a expiré
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Nombre de jours avant expiration (null si pas d'expiration)
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory UserRole.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserRole(
      id: doc.id,
      userId: data['userId'] ?? '',
      roleId: data['roleId'] ?? '',
      roleName: data['roleName'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      reason: data['reason'],
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata']) 
          : null,
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      revokedBy: data['revokedBy'],
      revocationReason: data['revocationReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'roleId': roleId,
      'roleName': roleName,
      'assignedBy': assignedBy,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'reason': reason,
      'metadata': metadata,
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'revokedBy': revokedBy,
      'revocationReason': revocationReason,
    };
  }

  UserRole copyWith({
    String? id,
    String? userId,
    String? roleId,
    String? roleName,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? expiresAt,
    bool? isActive,
    String? reason,
    Map<String, dynamic>? metadata,
    DateTime? revokedAt,
    String? revokedBy,
    String? revocationReason,
  }) {
    return UserRole(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedBy: revokedBy ?? this.revokedBy,
      revocationReason: revocationReason ?? this.revocationReason,
    );
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
    return 'UserRole(id: $id, userId: $userId, roleId: $roleId, roleName: $roleName, isActive: $isActive)';
  }
}

/// Statistiques sur les assignations de rôles
class UserRoleStats {
  final int totalAssignments;
  final int activeAssignments;
  final int expiredAssignments;
  final int revokedAssignments;
  final Map<String, int> assignmentsByRole;
  final Map<String, int> assignmentsByUser;
  final List<UserRole> recentAssignments;
  final List<UserRole> expiringSoon;

  UserRoleStats({
    required this.totalAssignments,
    required this.activeAssignments,
    required this.expiredAssignments,
    required this.revokedAssignments,
    required this.assignmentsByRole,
    required this.assignmentsByUser,
    required this.recentAssignments,
    required this.expiringSoon,
  });

  /// Calcule les statistiques à partir d'une liste d'assignations
  factory UserRoleStats.fromUserRoles(List<UserRole> userRoles) {
    final assignmentsByRole = <String, int>{};
    final assignmentsByUser = <String, int>{};
    final recentAssignments = <UserRole>[];
    final expiringSoon = <UserRole>[];

    int activeCount = 0;
    int expiredCount = 0;
    int revokedCount = 0;

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    for (final userRole in userRoles) {
      // Compter par rôle
      assignmentsByRole[userRole.roleName] = 
          (assignmentsByRole[userRole.roleName] ?? 0) + 1;

      // Compter par utilisateur
      assignmentsByUser[userRole.userId] = 
          (assignmentsByUser[userRole.userId] ?? 0) + 1;

      // Compter par statut
      if (userRole.isActive) {
        if (userRole.isExpired) {
          expiredCount++;
        } else {
          activeCount++;
        }
      } else {
        revokedCount++;
      }

      // Assignations récentes
      if (userRole.assignedAt.isAfter(sevenDaysAgo)) {
        recentAssignments.add(userRole);
      }

      // Assignations expirant bientôt
      if (userRole.expiresAt != null && 
          userRole.expiresAt!.isBefore(thirtyDaysFromNow) &&
          userRole.isActive) {
        expiringSoon.add(userRole);
      }
    }

    // Trier les listes
    recentAssignments.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    expiringSoon.sort((a, b) => a.expiresAt!.compareTo(b.expiresAt!));

    return UserRoleStats(
      totalAssignments: userRoles.length,
      activeAssignments: activeCount,
      expiredAssignments: expiredCount,
      revokedAssignments: revokedCount,
      assignmentsByRole: assignmentsByRole,
      assignmentsByUser: assignmentsByUser,
      recentAssignments: recentAssignments.take(10).toList(),
      expiringSoon: expiringSoon.take(10).toList(),
    );
  }

  /// Taux d'assignations actives
  double get activeRate {
    if (totalAssignments == 0) return 0.0;
    return activeAssignments / totalAssignments;
  }

  /// Taux d'assignations expirées
  double get expiredRate {
    if (totalAssignments == 0) return 0.0;
    return expiredAssignments / totalAssignments;
  }

  /// Taux d'assignations révoquées
  double get revokedRate {
    if (totalAssignments == 0) return 0.0;
    return revokedAssignments / totalAssignments;
  }
}