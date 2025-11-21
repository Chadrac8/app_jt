/// Amélioration du service d'assignation de rôles avec prévention des doublons
/// 
/// Cette classe propose des méthodes améliorées pour éviter les rôles dupliqués

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImprovedRoleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String personsCollection = 'persons';
  static const String userRolesCollection = 'user_roles';
  static const String rolesCollection = 'roles';

  /// Assigne un rôle à plusieurs personnes avec prévention des doublons
  static Future<Map<String, dynamic>> assignRoleToPersonsSafe(
    List<String> personIds, 
    String roleId, {
    bool skipIfExists = true,
    bool cleanupDuplicates = false,
  }) async {
    
    final result = <String, dynamic>{
      'success': 0,
      'skipped': 0,
      'errors': 0,
      'duplicatesRemoved': 0,
      'details': <String, dynamic>{},
    };

    try {
      // 1. Valider le rôle
      final roleDoc = await _firestore.collection(rolesCollection).doc(roleId).get();
      if (!roleDoc.exists) {
        throw Exception('Rôle $roleId introuvable');
      }
      final roleName = roleDoc.data()?['name'] ?? roleId;

      // 2. Traiter chaque personne individuellement
      for (final personId in personIds) {
        try {
          final personResult = await _assignRoleToPersonSafe(
            personId, 
            roleId, 
            roleName,
            skipIfExists: skipIfExists,
            cleanupDuplicates: cleanupDuplicates,
          );

          result['success'] = (result['success'] as int) + (personResult['assigned'] ? 1 : 0);
          result['skipped'] = (result['skipped'] as int) + (personResult['skipped'] ? 1 : 0);
          result['duplicatesRemoved'] = (result['duplicatesRemoved'] as int) + (personResult['duplicatesRemoved'] as int);
          
          result['details'][personId] = personResult;

        } catch (e) {
          result['errors'] = (result['errors'] as int) + 1;
          result['details'][personId] = {
            'assigned': false,
            'skipped': false,
            'error': e.toString(),
            'duplicatesRemoved': 0,
          };
        }
      }

      // 3. Log de l'activité
      await _logBulkRoleAssignment(roleId, roleName, result);

      return result;

    } catch (e) {
      throw Exception('Erreur lors de l\'assignation de rôle: $e');
    }
  }

  /// Assigne un rôle à une personne avec prévention des doublons
  static Future<Map<String, dynamic>> _assignRoleToPersonSafe(
    String personId,
    String roleId,
    String roleName, {
    bool skipIfExists = true,
    bool cleanupDuplicates = false,
  }) async {
    
    final result = {
      'assigned': false,
      'skipped': false,
      'duplicatesRemoved': 0,
      'rolesBefore': <String>[],
      'rolesAfter': <String>[],
    };

    // Transaction pour assurer la cohérence
    await _firestore.runTransaction((transaction) async {
      final personRef = _firestore.collection(personsCollection).doc(personId);
      final personDoc = await transaction.get(personRef);

      if (!personDoc.exists) {
        throw Exception('Personne $personId introuvable');
      }

      final personData = personDoc.data()!;
      final currentRolesList = personData['roles'] ?? [];
      final currentRoles = List<String>.from(currentRolesList);
      
      result['rolesBefore'] = List<String>.from(currentRoles);

      // Nettoyer les doublons existants si demandé
      List<String> cleanedRoles = currentRoles;
      if (cleanupDuplicates) {
        final uniqueRoles = currentRoles.toSet().toList();
        result['duplicatesRemoved'] = currentRoles.length - uniqueRoles.length;
        cleanedRoles = uniqueRoles;
      }

      // Vérifier si le rôle existe déjà
      if (cleanedRoles.contains(roleId)) {
        if (skipIfExists) {
          result['skipped'] = true;
          result['rolesAfter'] = List<String>.from(cleanedRoles);
          return; // Sortir de la transaction sans modification
        }
        // Si on ne skip pas, on continue quand même pour mettre à jour
      }

      // Ajouter le nouveau rôle s'il n'existe pas
      final updatedRoles = List<String>.from(cleanedRoles);
      if (!updatedRoles.contains(roleId)) {
        updatedRoles.add(roleId);
        result['assigned'] = true;
      }

      result['rolesAfter'] = List<String>.from(updatedRoles);

      // Mettre à jour le document
      transaction.update(personRef, {
        'roles': updatedRoles,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid ?? 'system',
      });
    });

    return result;
  }

  /// Retire un rôle de plusieurs personnes avec nettoyage
  static Future<Map<String, dynamic>> removeRoleFromPersonsSafe(
    List<String> personIds, 
    String roleId,
  ) async {
    
    final result = <String, dynamic>{
      'success': 0,
      'notFound': 0,
      'errors': 0,
      'details': <String, dynamic>{},
    };

    try {
      // Valider le rôle
      final roleDoc = await _firestore.collection(rolesCollection).doc(roleId).get();
      final roleName = roleDoc.exists ? (roleDoc.data()?['name'] ?? roleId) : roleId;

      // Traiter chaque personne
      for (final personId in personIds) {
        try {
          final personResult = await _removeRoleFromPersonSafe(personId, roleId);
          
          result['success'] = (result['success'] as int) + (personResult['removed'] ? 1 : 0);
          result['notFound'] = (result['notFound'] as int) + (personResult['notFound'] ? 1 : 0);
          result['details'][personId] = personResult;

        } catch (e) {
          result['errors'] = (result['errors'] as int) + 1;
          result['details'][personId] = {
            'removed': false,
            'notFound': false,
            'error': e.toString(),
          };
        }
      }

      // Log de l'activité
      await _logBulkRoleRemoval(roleId, roleName, result);

      return result;

    } catch (e) {
      throw Exception('Erreur lors du retrait de rôle: $e');
    }
  }

  /// Retire un rôle d'une personne
  static Future<Map<String, dynamic>> _removeRoleFromPersonSafe(
    String personId,
    String roleId,
  ) async {
    
    final result = {
      'removed': false,
      'notFound': false,
      'rolesBefore': <String>[],
      'rolesAfter': <String>[],
    };

    await _firestore.runTransaction((transaction) async {
      final personRef = _firestore.collection(personsCollection).doc(personId);
      final personDoc = await transaction.get(personRef);

      if (!personDoc.exists) {
        throw Exception('Personne $personId introuvable');
      }

      final personData = personDoc.data()!;
      final currentRolesList = personData['roles'] ?? [];
      final currentRoles = List<String>.from(currentRolesList);
      
      result['rolesBefore'] = List<String>.from(currentRoles);

      // Retirer toutes les occurrences du rôle
      final updatedRoles = currentRoles.where((role) => role != roleId).toList();
      
      if (updatedRoles.length == currentRoles.length) {
        result['notFound'] = true;
        result['rolesAfter'] = List<String>.from(currentRoles);
        return;
      }

      result['removed'] = true;
      result['rolesAfter'] = List<String>.from(updatedRoles);

      // Mettre à jour le document
      transaction.update(personRef, {
        'roles': updatedRoles,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid ?? 'system',
      });
    });

    return result;
  }

  /// Nettoie tous les rôles dupliqués d'une personne
  static Future<Map<String, dynamic>> cleanupPersonRolesDuplicates(String personId) async {
    final result = <String, dynamic>{
      'duplicatesRemoved': 0,
      'rolesBefore': <String>[],
      'rolesAfter': <String>[],
    };

    await _firestore.runTransaction((transaction) async {
      final personRef = _firestore.collection(personsCollection).doc(personId);
      final personDoc = await transaction.get(personRef);

      if (!personDoc.exists) {
        throw Exception('Personne $personId introuvable');
      }

      final personData = personDoc.data()!;
      final currentRolesList = personData['roles'] ?? [];
      final currentRoles = List<String>.from(currentRolesList);
      
      result['rolesBefore'] = List<String>.from(currentRoles);

      // Supprimer les doublons
      final uniqueRoles = currentRoles.toSet().toList();
      result['duplicatesRemoved'] = currentRoles.length - uniqueRoles.length;
      result['rolesAfter'] = List<String>.from(uniqueRoles);

      // Mettre à jour seulement s'il y a des doublons
      if ((result['duplicatesRemoved'] as int) > 0) {
        transaction.update(personRef, {
          'roles': uniqueRoles,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastModifiedBy': _auth.currentUser?.uid ?? 'cleanup_system',
        });
      }
    });

    return result;
  }

  /// Vérifie et nettoie tous les doublons dans la base
  static Future<Map<String, dynamic>> cleanupAllRolesDuplicates({int? limit}) async {
    final result = <String, dynamic>{
      'personsProcessed': 0,
      'personsWithDuplicates': 0,
      'totalDuplicatesRemoved': 0,
      'errors': 0,
      'details': <String, dynamic>{},
    };

    try {
      Query query = _firestore
          .collection(personsCollection)
          .where('isActive', isEqualTo: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        try {
          final personCleanup = await cleanupPersonRolesDuplicates(doc.id);
          
          result['personsProcessed'] = (result['personsProcessed'] as int) + 1;
          
          if ((personCleanup['duplicatesRemoved'] as int) > 0) {
            result['personsWithDuplicates'] = (result['personsWithDuplicates'] as int) + 1;
            result['totalDuplicatesRemoved'] = (result['totalDuplicatesRemoved'] as int) + (personCleanup['duplicatesRemoved'] as int);
            
            final personData = doc.data() as Map<String, dynamic>;
            final fullName = '${personData['firstName'] ?? ''} ${personData['lastName'] ?? ''}';
            
            result['details'][doc.id] = {
              'fullName': fullName,
              'duplicatesRemoved': personCleanup['duplicatesRemoved'],
              'rolesBefore': personCleanup['rolesBefore'],
              'rolesAfter': personCleanup['rolesAfter'],
            };
          }

        } catch (e) {
          result['errors'] = (result['errors'] as int) + 1;
          result['details']['error_${doc.id}'] = e.toString();
        }
      }

      // Log de l'activité de nettoyage
      await _logCleanupActivity(result);

    } catch (e) {
      throw Exception('Erreur lors du nettoyage: $e');
    }

    return result;
  }

  /// Log d'assignation en lot
  static Future<void> _logBulkRoleAssignment(String roleId, String roleName, Map<String, dynamic> result) async {
    try {
      await _firestore.collection('role_activity_logs').add({
        'action': 'bulk_role_assignment',
        'roleId': roleId,
        'roleName': roleName,
        'success': result['success'],
        'skipped': result['skipped'],
        'errors': result['errors'],
        'duplicatesRemoved': result['duplicatesRemoved'],
        'performedBy': _auth.currentUser?.uid,
        'performedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors du log d\'assignation: $e');
    }
  }

  /// Log de retrait en lot
  static Future<void> _logBulkRoleRemoval(String roleId, String roleName, Map<String, dynamic> result) async {
    try {
      await _firestore.collection('role_activity_logs').add({
        'action': 'bulk_role_removal',
        'roleId': roleId,
        'roleName': roleName,
        'success': result['success'],
        'notFound': result['notFound'],
        'errors': result['errors'],
        'performedBy': _auth.currentUser?.uid,
        'performedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors du log de retrait: $e');
    }
  }

  /// Log d'activité de nettoyage
  static Future<void> _logCleanupActivity(Map<String, dynamic> result) async {
    try {
      await _firestore.collection('role_activity_logs').add({
        'action': 'roles_duplicates_cleanup',
        'personsProcessed': result['personsProcessed'],
        'personsWithDuplicates': result['personsWithDuplicates'],
        'totalDuplicatesRemoved': result['totalDuplicatesRemoved'],
        'errors': result['errors'],
        'performedBy': _auth.currentUser?.uid ?? 'system',
        'performedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors du log de nettoyage: $e');
    }
  }
}

/// Widget pour afficher les résultats d'assignation de rôles
class RoleAssignmentResultWidget {
  static String formatResult(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    
    buffer.writeln('RÉSULTAT DE L\'ASSIGNATION:');
    buffer.writeln('✅ Succès: ${result['success']}');
    
    if ((result['skipped'] as int) > 0) {
      buffer.writeln('⏭️  Ignorés: ${result['skipped']}');
    }
    
    if ((result['errors'] as int) > 0) {
      buffer.writeln('❌ Erreurs: ${result['errors']}');
    }
    
    if ((result['duplicatesRemoved'] as int) > 0) {
      buffer.writeln('🧹 Doublons supprimés: ${result['duplicatesRemoved']}');
    }
    
    return buffer.toString();
  }
  
  static String formatCleanupResult(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    
    buffer.writeln('RÉSULTAT DU NETTOYAGE:');
    buffer.writeln('📊 Personnes traitées: ${result['personsProcessed']}');
    buffer.writeln('🔍 Personnes avec doublons: ${result['personsWithDuplicates']}');
    buffer.writeln('🧹 Total doublons supprimés: ${result['totalDuplicatesRemoved']}');
    
    if ((result['errors'] as int) > 0) {
      buffer.writeln('❌ Erreurs: ${result['errors']}');
    }
    
    final percentage = result['personsProcessed'] > 0 
        ? ((result['personsWithDuplicates'] as int) / (result['personsProcessed'] as int) * 100).toStringAsFixed(1)
        : '0.0';
    buffer.writeln('📈 Pourcentage avec doublons: $percentage%');
    
    return buffer.toString();
  }
}