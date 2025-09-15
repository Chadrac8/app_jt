import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script pour analyser et prévenir les rôles dupliqués
/// 
/// Ce script va :
/// 1. Analyser les causes potentielles des doublons
/// 2. Vérifier la cohérence entre people.roles et user_roles
/// 3. Proposer des améliorations au système de prévention

void main() async {
  await Firebase.initializeApp();
  print('🔍 Analyse des causes de duplication des rôles...\n');
  
  // Analyser seulement (sans corriger)
  await analyzeDuplicateCauses();
  
  print('\n✅ Analyse terminée !');
}

Future<void> analyzeDuplicateCauses() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. Analyser les doublons dans people.roles
    await _analyzePeopleRolesDuplicates(firestore);
    
    // 2. Analyser la cohérence avec user_roles
    await _analyzeUserRolesConsistency(firestore);
    
    // 3. Analyser les patterns de création de rôles
    await _analyzeRoleAssignmentPatterns(firestore);
    
  } catch (e) {
    print('❌ Erreur lors de l\'analyse: $e');
  }
}

Future<void> _analyzePeopleRolesDuplicates(FirebaseFirestore firestore) async {
  print('📊 1. ANALYSE DES DOUBLONS DANS PEOPLE.ROLES');
  print('=' * 50);
  
  final personsSnapshot = await firestore
      .collection('people')
      .where('isActive', isEqualTo: true)
      .get();
  
  int totalPersons = 0;
  int personsWithDuplicates = 0;
  Map<String, int> duplicatesByRole = {};
  Map<String, List<String>> duplicateExamples = {};
  
  for (final personDoc in personsSnapshot.docs) {
    final personData = personDoc.data();
    final rolesList = personData['roles'];
    
    if (rolesList == null || rolesList is! List) continue;
    
    final roles = List<String>.from(rolesList);
    if (roles.isEmpty) continue;
    
    totalPersons++;
    
    // Compter les occurrences
    final roleCounts = <String, int>{};
    for (final role in roles) {
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }
    
    // Identifier les doublons
    final duplicatedRoles = roleCounts.entries
        .where((entry) => entry.value > 1)
        .toList();
    
    if (duplicatedRoles.isNotEmpty) {
      personsWithDuplicates++;
      final fullName = '${personData['firstName'] ?? ''} ${personData['lastName'] ?? ''}';
      
      for (final duplicate in duplicatedRoles) {
        final role = duplicate.key;
        final count = duplicate.value;
        
        duplicatesByRole[role] = (duplicatesByRole[role] ?? 0) + (count - 1);
        
        if (!duplicateExamples.containsKey(role)) {
          duplicateExamples[role] = [];
        }
        if (duplicateExamples[role]!.length < 3) {
          duplicateExamples[role]!.add('$fullName ($count fois)');
        }
      }
    }
  }
  
  print('Personnes analysées: $totalPersons');
  print('Personnes avec doublons: $personsWithDuplicates');
  print('Pourcentage: ${(personsWithDuplicates / totalPersons * 100).toStringAsFixed(1)}%\n');
  
  if (duplicatesByRole.isNotEmpty) {
    print('RÔLES LES PLUS DUPLIQUÉS:');
    final sortedDuplicates = duplicatesByRole.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedDuplicates) {
      print('  "${entry.key}": ${entry.value} doublons');
      if (duplicateExamples.containsKey(entry.key)) {
        for (final example in duplicateExamples[entry.key]!) {
          print('    - $example');
        }
      }
      print('');
    }
  }
}

Future<void> _analyzeUserRolesConsistency(FirebaseFirestore firestore) async {
  print('\n📊 2. ANALYSE DE LA COHÉRENCE PEOPLE.ROLES ↔ USER_ROLES');
  print('=' * 50);
  
  // Récupérer toutes les données
  final personsSnapshot = await firestore
      .collection('people')
      .where('isActive', isEqualTo: true)
      .get();
  
  final userRolesSnapshot = await firestore
      .collection('user_roles')
      .where('isActive', isEqualTo: true)
      .get();
  
  // Construire les maps pour comparaison
  Map<String, List<String>> peopleRoles = {};
  Map<String, List<String>> userRolesMap = {};
  
  // Analyser people.roles
  for (final personDoc in personsSnapshot.docs) {
    final personData = personDoc.data();
    final rolesList = personData['roles'];
    
    if (rolesList != null && rolesList is List) {
      peopleRoles[personDoc.id] = List<String>.from(rolesList);
    }
  }
  
  // Analyser user_roles
  for (final userRoleDoc in userRolesSnapshot.docs) {
    final userRoleData = userRoleDoc.data();
    final userId = userRoleData['userId'] as String?;
    final roleIds = userRoleData['roleIds'];
    
    if (userId != null && roleIds != null && roleIds is List) {
      userRolesMap[userId] = List<String>.from(roleIds);
    }
  }
  
  // Comparer les deux systèmes
  int consistentPersons = 0;
  int inconsistentPersons = 0;
  int peopleOnlyPersons = 0;
  int userRolesOnlyPersons = 0;
  
  final allPersonIds = {...peopleRoles.keys, ...userRolesMap.keys};
  
  for (final personId in allPersonIds) {
    final personRoles = peopleRoles[personId] ?? [];
    final userRoles = userRolesMap[personId] ?? [];
    
    final personRolesSet = personRoles.toSet();
    final userRolesSet = userRoles.toSet();
    
    if (personRoles.isEmpty && userRoles.isEmpty) {
      continue; // Pas de rôles dans les deux systèmes
    } else if (personRoles.isNotEmpty && userRoles.isEmpty) {
      peopleOnlyPersons++;
    } else if (personRoles.isEmpty && userRoles.isNotEmpty) {
      userRolesOnlyPersons++;
    } else if (personRolesSet.difference(userRolesSet).isEmpty && 
               userRolesSet.difference(personRolesSet).isEmpty) {
      consistentPersons++;
    } else {
      inconsistentPersons++;
      
      if (inconsistentPersons <= 5) { // Afficher les 5 premiers exemples
        final person = personsSnapshot.docs.firstWhere((doc) => doc.id == personId).data();
        final fullName = '${person['firstName'] ?? ''} ${person['lastName'] ?? ''}';
        
        print('INCOHÉRENCE: $fullName');
        print('  people.roles: $personRoles');
        print('  user_roles: $userRoles');
        print('  Différences: people only: ${personRolesSet.difference(userRolesSet)}');
        print('              user_roles only: ${userRolesSet.difference(personRolesSet)}');
        print('');
      }
    }
  }
  
  print('RÉSULTATS DE COHÉRENCE:');
  print('Personnes cohérentes: $consistentPersons');
  print('Personnes incohérentes: $inconsistentPersons');
  print('Rôles seulement dans people: $peopleOnlyPersons');
  print('Rôles seulement dans user_roles: $userRolesOnlyPersons');
  
  final totalWithRoles = consistentPersons + inconsistentPersons + peopleOnlyPersons + userRolesOnlyPersons;
  if (totalWithRoles > 0) {
    print('Pourcentage de cohérence: ${(consistentPersons / totalWithRoles * 100).toStringAsFixed(1)}%');
  }
}

Future<void> _analyzeRoleAssignmentPatterns(FirebaseFirestore firestore) async {
  print('\n📊 3. ANALYSE DES PATTERNS D\'ASSIGNATION');
  print('=' * 50);
  
  // Analyser les timestamps de création/modification
  final personsSnapshot = await firestore
      .collection('people')
      .where('isActive', isEqualTo: true)
      .get();
  
  Map<String, int> modificationSources = {};
  Map<String, int> rolesFrequency = {};
  List<DateTime> modificationTimes = [];
  
  for (final personDoc in personsSnapshot.docs) {
    final personData = personDoc.data();
    
    // Analyser la source de modification
    final lastModifiedBy = personData['lastModifiedBy'] as String?;
    if (lastModifiedBy != null) {
      modificationSources[lastModifiedBy] = (modificationSources[lastModifiedBy] ?? 0) + 1;
    }
    
    // Analyser les rôles les plus fréquents
    final rolesList = personData['roles'];
    if (rolesList != null && rolesList is List) {
      for (final role in rolesList) {
        rolesFrequency[role] = (rolesFrequency[role] ?? 0) + 1;
      }
    }
    
    // Analyser les timestamps
    final updatedAt = personData['updatedAt'];
    if (updatedAt != null) {
      if (updatedAt is Timestamp) {
        modificationTimes.add(updatedAt.toDate());
      }
    }
  }
  
  print('SOURCES DE MODIFICATION:');
  final sortedSources = modificationSources.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  for (final entry in sortedSources.take(10)) {
    print('  ${entry.key}: ${entry.value} modifications');
  }
  
  print('\nRÔLES LES PLUS FRÉQUENTS:');
  final sortedRoles = rolesFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  for (final entry in sortedRoles.take(10)) {
    print('  "${entry.key}": ${entry.value} assignations');
  }
  
  // Analyser les patterns temporels
  if (modificationTimes.isNotEmpty) {
    modificationTimes.sort();
    
    print('\nPATTERNS TEMPORELS:');
    print('  Première modification: ${modificationTimes.first}');
    print('  Dernière modification: ${modificationTimes.last}');
    print('  Total modifications: ${modificationTimes.length}');
    
    // Analyser les pics d'activité
    final modificationsPerHour = <DateTime, int>{};
    for (final time in modificationTimes) {
      final hourKey = DateTime(time.year, time.month, time.day, time.hour);
      modificationsPerHour[hourKey] = (modificationsPerHour[hourKey] ?? 0) + 1;
    }
    
    final topHours = modificationsPerHour.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (topHours.isNotEmpty) {
      print('\nHEURES DE PICS D\'ACTIVITÉ:');
      for (final entry in topHours.take(5)) {
        print('  ${entry.key}: ${entry.value} modifications');
      }
    }
  }
}

/// Suggestions pour améliorer la prévention des doublons
void printPreventionSuggestions() {
  print('\n💡 SUGGESTIONS D\'AMÉLIORATION');
  print('=' * 50);
  
  print('''
1. AMÉLIORER LA PRÉVENTION CÔTÉ CODE:
   - Utiliser Set<String> au lieu de List<String> pour les rôles
   - Ajouter validation avant chaque assignation de rôle
   - Implémenter des transactions atomiques pour les mises à jour
   
2. AMÉLIORER LA DÉTECTION:
   - Ajouter un trigger Firestore pour détecter les doublons
   - Créer un job de maintenance quotidien
   - Ajouter des logs d'audit pour tracer les assignations
   
3. AMÉLIORER L'INTERFACE UTILISATEUR:
   - Afficher un message de confirmation avant assignation
   - Désactiver les boutons pendant les opérations en cours
   - Ajouter une indication visuelle des rôles déjà assignés
   
4. AMÉLIORER LA COHÉRENCE:
   - Synchroniser automatiquement people.roles et user_roles
   - Utiliser une seule source de vérité pour les rôles
   - Implémenter des tests d'intégrité périodiques
''');
}