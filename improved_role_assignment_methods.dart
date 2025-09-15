/// Version améliorée de assignRoleToPersons qui évite les doublons
/// Remplacer la méthode existante dans lib/services/roles_firebase_service.dart

// Role Assignment - VERSION AMÉLIORÉE SANS DOUBLONS
static Future<void> assignRoleToPersons(List<String> personIds, String roleId) async {
  try {
    final role = await getRole(roleId);
    if (role == null) {
      throw Exception('Rôle introuvable');
    }

    // Traiter chaque personne individuellement avec transaction
    for (String personId in personIds) {
      await _assignRoleToPersonSafely(personId, roleId);
    }

    await _logRoleActivity(roleId, 'role_assigned', {
      'roleName': role.name,
      'personIds': personIds,
      'personCount': personIds.length,
    });
  } catch (e) {
    throw Exception('Erreur lors de l\'assignation du rôle: $e');
  }
}

/// Assigne un rôle à une personne en évitant les doublons
static Future<void> _assignRoleToPersonSafely(String personId, String roleId) async {
  await _firestore.runTransaction((transaction) async {
    final personRef = _firestore.collection(personsCollection).doc(personId);
    final personDoc = await transaction.get(personRef);

    if (!personDoc.exists) {
      throw Exception('Personne $personId introuvable');
    }

    final personData = personDoc.data()!;
    final currentRoles = List<String>.from(personData['roles'] ?? []);

    // Vérifier si le rôle existe déjà
    if (!currentRoles.contains(roleId)) {
      // Ajouter le rôle seulement s'il n'existe pas
      currentRoles.add(roleId);
      
      transaction.update(personRef, {
        'roles': currentRoles,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });
    }
    // Si le rôle existe déjà, ne rien faire (évite le doublon)
  });
}

/// Nettoie les rôles dupliqués pour une personne
static Future<Map<String, dynamic>> cleanupPersonRoles(String personId) async {
  Map<String, dynamic> result = {
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
    final currentRoles = List<String>.from(personData['roles'] ?? []);
    result['rolesBefore'] = List<String>.from(currentRoles);

    // Supprimer les doublons en gardant seulement les valeurs uniques
    final uniqueRoles = currentRoles.toSet().toList();
    result['duplicatesRemoved'] = currentRoles.length - uniqueRoles.length;
    result['rolesAfter'] = List<String>.from(uniqueRoles);

    // Mettre à jour seulement s'il y a des doublons
    if (result['duplicatesRemoved'] > 0) {
      transaction.update(personRef, {
        'roles': uniqueRoles,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid ?? 'cleanup_system',
      });
    }
  });

  return result;
}

/// Nettoie tous les rôles dupliqués dans la base
static Future<Map<String, dynamic>> cleanupAllDuplicateRoles() async {
  Map<String, dynamic> result = {
    'personsProcessed': 0,
    'personsWithDuplicates': 0,
    'totalDuplicatesRemoved': 0,
    'errors': 0,
    'details': <String, dynamic>{},
  };

  try {
    final snapshot = await _firestore
        .collection(personsCollection)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      try {
        final personCleanup = await cleanupPersonRoles(doc.id);
        
        result['personsProcessed'] = (result['personsProcessed'] as int) + 1;
        
        if ((personCleanup['duplicatesRemoved'] as int) > 0) {
          result['personsWithDuplicates'] = (result['personsWithDuplicates'] as int) + 1;
          result['totalDuplicatesRemoved'] = (result['totalDuplicatesRemoved'] as int) + (personCleanup['duplicatesRemoved'] as int);
          
          final personData = doc.data();
          final fullName = '${personData['firstName'] ?? ''} ${personData['lastName'] ?? ''}';
          
          result['details'][doc.id] = {
            'fullName': fullName,
            'email': personData['email'] ?? '',
            'duplicatesRemoved': personCleanup['duplicatesRemoved'],
            'rolesBefore': personCleanup['rolesBefore'],
            'rolesAfter': personCleanup['rolesAfter'],
          };
        }

      } catch (e) {
        result['errors'] = (result['errors'] as int) + 1;
        print('Erreur pour la personne ${doc.id}: $e');
      }
    }

    // Log de l'activité de nettoyage
    await _logRoleActivity('cleanup', 'bulk_cleanup', {
      'personsProcessed': result['personsProcessed'],
      'personsWithDuplicates': result['personsWithDuplicates'],
      'totalDuplicatesRemoved': result['totalDuplicatesRemoved'],
      'errors': result['errors'],
    });

  } catch (e) {
    throw Exception('Erreur lors du nettoyage global: $e');
  }

  return result;
}

/// Version améliorée de removeRoleFromPersons
static Future<void> removeRoleFromPersons(List<String> personIds, String roleId) async {
  try {
    final role = await getRole(roleId);
    if (role == null) {
      throw Exception('Rôle introuvable');
    }

    // Traiter chaque personne individuellement avec transaction
    for (String personId in personIds) {
      await _removeRoleFromPersonSafely(personId, roleId);
    }

    await _logRoleActivity(roleId, 'role_removed', {
      'roleName': role.name,
      'personIds': personIds,
      'personCount': personIds.length,
    });
  } catch (e) {
    throw Exception('Erreur lors du retrait du rôle: $e');
  }
}

/// Retire un rôle d'une personne de manière sûre
static Future<void> _removeRoleFromPersonSafely(String personId, String roleId) async {
  await _firestore.runTransaction((transaction) async {
    final personRef = _firestore.collection(personsCollection).doc(personId);
    final personDoc = await transaction.get(personRef);

    if (!personDoc.exists) {
      throw Exception('Personne $personId introuvable');
    }

    final personData = personDoc.data()!;
    final currentRoles = List<String>.from(personData['roles'] ?? []);

    // Supprimer toutes les occurrences du rôle (pour nettoyer les doublons existants)
    final updatedRoles = currentRoles.where((role) => role != roleId).toList();

    // Mettre à jour seulement si des rôles ont été supprimés
    if (updatedRoles.length != currentRoles.length) {
      transaction.update(personRef, {
        'roles': updatedRoles,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': _auth.currentUser?.uid,
      });
    }
  });
}