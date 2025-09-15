import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/person_model.dart';
import 'profile_image_cache_service.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String personsCollection = 'persons';

  /// Vérifie et crée automatiquement un profil utilisateur lors de l'inscription
  static Future<PersonModel?> ensureUserProfile(User firebaseUser) async {
    try {
      print('🔍 Vérification du profil pour ${firebaseUser.email} (UID: ${firebaseUser.uid})');
      
      // Vérifier si une fiche existe déjà avec cet UID
      PersonModel? existingPerson = await getPersonByUid(firebaseUser.uid);
      
      if (existingPerson != null) {
        print('✅ Profil existant trouvé pour ${firebaseUser.email}');
        // Mettre à jour les informations si nécessaire (email, photo)
        return await _updateUserProfileFromAuth(existingPerson, firebaseUser);
      }

      print('🆕 Création d\'un nouveau profil pour ${firebaseUser.email}');
      // Créer une nouvelle fiche personne
      return await _createUserProfileFromAuth(firebaseUser);
    } catch (e) {
      print('❌ Erreur lors de la création/mise à jour du profil utilisateur: $e');
      rethrow; // Rethrow pour permettre au AuthWrapper de gérer l'erreur
    }
  }

  /// Récupère une personne par son UID Firebase
  static Future<PersonModel?> getPersonByUid(String uid) async {
    try {
      // D'abord essayer de récupérer directement avec l'UID comme ID du document
      final doc = await _firestore
          .collection(personsCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return PersonModel.fromFirestore(doc);
      }

      // Fallback: chercher par champ uid (pour les anciens documents)
      final querySnapshot = await _firestore
          .collection(personsCollection)
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('Aucun profil trouvé pour UID: $uid');
        return null;
      }

      return PersonModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Erreur lors de la récupération du profil par UID: $e');
      return null;
    }
  }

  /// Récupère le profil de l'utilisateur connecté
  static Future<PersonModel?> getCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return await getPersonByUid(currentUser.uid);
  }

  /// Stream du profil de l'utilisateur connecté
  static Stream<PersonModel?> getCurrentUserProfileStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection(personsCollection)
        .where('uid', isEqualTo: currentUser.uid)
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      return PersonModel.fromFirestore(querySnapshot.docs.first);
    });
  }

  /// Met à jour le profil de l'utilisateur connecté
  static Future<void> updateCurrentUserProfile(PersonModel person) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    if (person.uid != currentUser.uid) {
      throw Exception('Tentative de modification d\'un profil non autorisé');
    }

    try {
      // Mettre à jour Firestore
      await _firestore.collection(personsCollection).doc(person.id).update({
        ...person.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': currentUser.uid,
      });

      // Mettre à jour Firebase Auth si l'image de profil ou le nom a changé
      bool needsAuthUpdate = false;
      final Map<String, String?> authUpdates = {};

      // Vérifier si l'image de profil a changé
      if (person.profileImageUrl != currentUser.photoURL) {
        authUpdates['photoURL'] = person.profileImageUrl;
        needsAuthUpdate = true;
      }

      // Vérifier si le nom complet a changé
      if (person.fullName != currentUser.displayName) {
        authUpdates['displayName'] = person.fullName;
        needsAuthUpdate = true;
      }

      // Effectuer la mise à jour Firebase Auth si nécessaire
      if (needsAuthUpdate) {
        await currentUser.updateDisplayName(authUpdates['displayName']);
        if (authUpdates['photoURL'] != null) {
          await currentUser.updatePhotoURL(authUpdates['photoURL']);
        }
        
        // Recharger les données utilisateur pour synchroniser
        await currentUser.reload();
      }

      // Mettre à jour le cache local de l'image de profil
      if (person.profileImageUrl != null) {
        await ProfileImageCacheService.cacheProfileImageUrl(person.id, person.profileImageUrl!);
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  /// Vérifie si l'utilisateur connecté peut modifier ce profil
  static bool canEditProfile(PersonModel person) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    
    return person.uid == currentUser.uid;
  }

  /// Crée une nouvelle fiche personne à partir des informations Firebase Auth
  static Future<PersonModel> _createUserProfileFromAuth(User firebaseUser) async {
    // Extraire le prénom et nom à partir du displayName si disponible
    String firstName = '';
    String lastName = '';
    
    if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
      final nameParts = firebaseUser.displayName!.trim().split(' ');
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.skip(1).join(' ');
      }
    }

    // Si pas de nom, utiliser l'email comme base
    if (firstName.isEmpty) {
      final emailParts = firebaseUser.email?.split('@') ?? [];
      if (emailParts.isNotEmpty) {
        firstName = emailParts.first;
      } else {
        firstName = 'Utilisateur';
      }
    }

    final now = DateTime.now();
    
    // Créer le document avec l'UID comme ID
    final personData = PersonModel(
      id: firebaseUser.uid, // Utiliser l'UID comme ID du document
      uid: firebaseUser.uid,
      firstName: firstName,
      lastName: lastName,
      email: firebaseUser.email ?? '',
      profileImageUrl: firebaseUser.photoURL,
      roles: ['membre'], // Rôle par défaut
      isActive: true,
      createdAt: now,
      updatedAt: now,
      lastModifiedBy: firebaseUser.uid,
    );

    await _firestore
        .collection(personsCollection)
        .doc(firebaseUser.uid)
        .set(personData.toFirestore());

    print('Profil utilisateur créé pour ${firebaseUser.email} avec UID: ${firebaseUser.uid}');
    return personData;
  }

  /// Met à jour une fiche existante avec les nouvelles informations de Firebase Auth
  static Future<PersonModel> _updateUserProfileFromAuth(
    PersonModel existingPerson, 
    User firebaseUser
  ) async {
    bool needsUpdate = false;
    final updates = <String, dynamic>{};

    // Mettre à jour l'email si différent
    if (existingPerson.email != firebaseUser.email && firebaseUser.email != null) {
      updates['email'] = firebaseUser.email;
      needsUpdate = true;
    }

    // Mettre à jour la photo de profil si différente
    if (existingPerson.profileImageUrl != firebaseUser.photoURL) {
      updates['profileImageUrl'] = firebaseUser.photoURL;
      needsUpdate = true;
    }

    // Mettre à jour le nom si vide et disponible dans Firebase Auth
    if ((existingPerson.firstName.isEmpty || existingPerson.lastName.isEmpty) && 
        firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
      final nameParts = firebaseUser.displayName!.trim().split(' ');
      if (existingPerson.firstName.isEmpty) {
        updates['firstName'] = nameParts.first;
        needsUpdate = true;
      }
      if (existingPerson.lastName.isEmpty && nameParts.length > 1) {
        updates['lastName'] = nameParts.skip(1).join(' ');
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      updates['lastModifiedBy'] = firebaseUser.uid;

      await _firestore
          .collection(personsCollection)
          .doc(existingPerson.id)
          .update(updates);

      print('Profil utilisateur mis à jour pour ${firebaseUser.email}');
      
      // Retourner le profil mis à jour
      return existingPerson.copyWith(
        email: updates['email'] ?? existingPerson.email,
        profileImageUrl: updates['profileImageUrl'] ?? existingPerson.profileImageUrl,
        firstName: updates['firstName'] ?? existingPerson.firstName,
        lastName: updates['lastName'] ?? existingPerson.lastName,
        updatedAt: DateTime.now(),
        lastModifiedBy: firebaseUser.uid,
      );
    }

    return existingPerson;
  }

  /// Supprime le profil de l'utilisateur connecté
  static Future<void> deleteCurrentUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    final profile = await getCurrentUserProfile();
    if (profile != null) {
      await _firestore
          .collection(personsCollection)
          .doc(profile.id)
          .delete();
    }
  }

  /// Vérifie si un email est déjà utilisé par un autre utilisateur
  static Future<bool> isEmailAlreadyUsed(String email, {String? excludeUid}) async {
    try {
      var query = _firestore
          .collection(personsCollection)
          .where('email', isEqualTo: email.toLowerCase());

      final querySnapshot = await query.get();
      
      if (excludeUid != null) {
        // Exclure l'utilisateur actuel de la vérification
        return querySnapshot.docs.any((doc) => 
          (doc.data()['uid'] as String?) != excludeUid
        );
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification de l\'email: $e');
      return false;
    }
  }
}