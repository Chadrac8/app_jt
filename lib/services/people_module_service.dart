import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/services/base_firebase_service.dart';
import '../models/person_model.dart';
import 'auth_person_sync_service.dart';

/// Service pour la gestion des personnes
class PeopleModuleService extends BaseFirebaseService<PersonModel> {
  @override
  String get collectionName => 'persons';

  @override
  PersonModel fromFirestore(DocumentSnapshot doc) {
    return PersonModel.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(PersonModel person) {
    return person.toFirestore();
  }

  /// Initialiser le service
  Future<void> initialize() async {
    // Initialisation spécifique au service des personnes
    print('Service People initialisé');
  }

  /// Nettoyer le service
  Future<void> dispose() async {
    // Nettoyage spécifique au service des personnes
    print('Service People nettoyé');
  }

  /// Créer une nouvelle personne avec validation d'email unique
  @override
  Future<String> create(PersonModel person) async {
    try {
      // Vérifier les doublons d'email
      if (person.email != null && person.email!.trim().isNotEmpty) {
        final existing = await findByEmail(person.email!);
        if (existing != null) {
          throw Exception('Une personne avec cet email existe déjà: ${person.email}');
        }
      }
      
      // Appeler la méthode parent pour créer
      final personId = await super.create(person);
      
      // 🆕 Synchronisation automatique : Proposer la création d'un compte utilisateur
      // (optionnel - peut être désactivé par défaut)
      if (person.email != null && person.email!.trim().isNotEmpty) {
        // Cette ligne peut être désactivée si vous ne voulez pas créer automatiquement des comptes
        // await AuthPersonSyncService.onPersonCreated(person, createAuthAccount: true);
        print('📝 Personne créée. Pour créer un compte utilisateur, appelez AuthPersonSyncService.onPersonCreated()');
      }
      
      return personId;
    } catch (e) {
      throw Exception('Erreur lors de la création de la personne: $e');
    }
  }
  
  /// Créer une personne avec création automatique de compte utilisateur
  Future<String> createWithAuthAccount(PersonModel person, {String? password}) async {
    try {
      print('🔄 PeopleModuleService.createWithAuthAccount appelée');
      print('   Email: ${person.email}');
      print('   Nom: ${person.firstName} ${person.lastName}');
      
      // Créer la personne
      final personId = await create(person);
      print('✅ Personne créée avec ID: $personId');
      
            // Créer le compte utilisateur
      if (person.email != null && person.email!.trim().isNotEmpty) {
        print('🔄 Appel AuthPersonSyncService.onPersonCreated...');
        final user = await AuthPersonSyncService.onPersonCreated(
          person, 
          password: password, 
          createAuthAccount: true,
          personId: personId, // Passer l'ID de la personne créée
        );
        if (user != null) {
          print('✅ Compte utilisateur créé avec succès pour: ${person.email}');
        } else {
          print('⚠️ Aucun compte utilisateur créé (peut-être existe déjà)');
        }
      } else {
        print('❌ Pas d\'email valide, aucun compte utilisateur créé');
      }
      
      return personId;
    } catch (e) {
      print('❌ Erreur dans createWithAuthAccount: $e');
      throw Exception('Erreur lors de la création de la personne avec compte: $e');
    }
  }

  /// Mettre à jour une personne avec validation d'email unique
  @override
  Future<void> update(String id, PersonModel person) async {
    try {
      // Vérifier les doublons d'email (exclure la personne actuelle)
      if (person.email != null && person.email!.trim().isNotEmpty) {
        final existing = await findByEmail(person.email!);
        if (existing != null && existing.id != id) {
          throw Exception('Une personne avec cet email existe déjà: ${person.email}');
        }
      }
      
      // Appeler la méthode parent pour mettre à jour
      await super.update(id, person);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la personne: $e');
    }
  }

  /// Rechercher des personnes par nom
  @override
  Future<List<PersonModel>> search(String query) async {
    if (query.isEmpty) return [];

    try {
      final querySnapshot = await collection
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThan: query + '\uf8ff')
          .get();

      final firstNameResults = querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();

      final lastNameQuery = await collection
          .where('lastName', isGreaterThanOrEqualTo: query)
          .where('lastName', isLessThan: query + '\uf8ff')
          .get();

      final lastNameResults = lastNameQuery.docs
          .map((doc) => fromFirestore(doc))
          .toList();

      // Combiner et dédupliquer les résultats
      final combined = <String, PersonModel>{};
      for (final person in firstNameResults) {
        combined[person.id] = person;
      }
      for (final person in lastNameResults) {
        combined[person.id] = person;
      }

      return combined.values.toList();
    } catch (e) {
      print('Erreur lors de la recherche de personnes: $e');
      return [];
    }
  }

  /// Rechercher par email
  Future<PersonModel?> findByEmail(String email) async {
    try {
      final querySnapshot = await collection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la recherche par email: $e');
      return null;
    }
  }

  /// Rechercher par téléphone
  Future<PersonModel?> findByPhone(String phone) async {
    try {
      final querySnapshot = await collection
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la recherche par telephone: $e');
      return null;
    }
  }

  /// Obtenir les personnes par rôle
  Future<List<PersonModel>> getByRole(String role) async {
    try {
      final querySnapshot = await collection
          .where('roles', arrayContains: role)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la recherche par role: $e');
      return [];
    }
  }

  /// Obtenir les anniversaires du mois
  Future<List<PersonModel>> getBirthdaysThisMonth() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final querySnapshot = await collection
          .where('birthDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('birthDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la recherche des anniversaires: $e');
      return [];
    }
  }

  /// Statistiques des personnes
  Future<Map<String, int>> getStatistics() async {
    try {
      final allPeople = await getAll();
      final activePeople = allPeople.where((p) => p.isActive).toList();
      
      return {
        'total': allPeople.length,
        'actives': activePeople.length,
        'inactives': allPeople.length - activePeople.length,
        'withEmail': activePeople.where((p) => p.email != null && p.email!.isNotEmpty).length,
        'withPhone': activePeople.where((p) => p.phone != null && p.phone!.isNotEmpty).length,
        'withBirthDate': activePeople.where((p) => p.birthDate != null).length,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {};
    }
  }

  /// Mettre à jour le rôle d'une personne
  Future<bool> updateRole(String personId, String role, bool add) async {
    try {
      final person = await getById(personId);
      if (person == null) return false;

      List<String> roles = List.from(person.roles);
      if (add) {
        if (!roles.contains(role)) {
          roles.add(role);
        }
      } else {
        roles.remove(role);
      }

      final updatedPerson = person.copyWith(
        roles: roles,
        updatedAt: DateTime.now(),
      );

      await update(personId, updatedPerson);
      return true;
    } catch (e) {
      print('Erreur lors de la mise a jour du role: $e');
      return false;
    }
  }

  /// Importer des personnes depuis une liste
  Future<int> importPeople(List<Map<String, dynamic>> peopleData) async {
    int imported = 0;
    
    for (final data in peopleData) {
      try {
        final person = PersonModel.fromImport(
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'],
          phone: data['phone'],
          birthDate: data['birthDate'] != null ? DateTime.tryParse(data['birthDate']) : null,
          address: data['address'],
          roles: List<String>.from(data['roles'] ?? []),
          customFields: Map<String, dynamic>.from(data['customFields'] ?? {}),
        );

        final personId = await create(person);
        if (personId.isNotEmpty) imported++;
      } catch (e) {
        print('Erreur lors de l importation d une personne: $e');
      }
    }

    return imported;
  }

  /// Exporter toutes les personnes
  Future<List<Map<String, dynamic>>> exportPeople() async {
    try {
      final people = await getAll();
      return people.map((person) => person.toImportExportFormat()).toList();
    } catch (e) {
      print('Erreur lors de l exportation: $e');
      return [];
    }
  }
}