import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';
import '../services/people_module_service.dart';
import '../services/roles_firebase_service.dart';

/// Service de synchronisation bidirectionnelle entre l'authentification et le module Personnes
class AuthPersonSyncService {
  static final PeopleModuleService _peopleService = PeopleModuleService();
  
  /// Cache pour l'ID du rôle "Membre"
  static String? _memberRoleId;
  
  /// Obtenir l'ID du rôle "Membre" (avec cache)
  static Future<String?> _getMemberRoleId() async {
    if (_memberRoleId != null) return _memberRoleId;
    
    try {
      final roles = await RolesFirebaseService.getRolesStream(activeOnly: true).first;
      for (final role in roles) {
        if (role.name.toLowerCase() == 'membre') {
          _memberRoleId = role.id;
          break;
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération du rôle Membre: $e');
    }
    
    return _memberRoleId;
  }
  
  /// 1. Inscription utilisateur → Création automatique dans le module Personnes
  /// À appeler après la création d'un compte Firebase Auth
  static Future<void> onUserRegistered(User user, {
    String? firstName,
    String? lastName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🔄 Synchronisation: Création personne pour utilisateur ${user.email}');
      
      // Vérifier si la personne existe déjà dans le module Personnes
      final existingPerson = await _peopleService.findByEmail(user.email!);
      if (existingPerson != null) {
        print('ℹ️ Personne existe déjà dans le module Personnes');
        return;
      }
      
      // Extraire nom et prénom depuis l'email si non fournis
      String userFirstName = firstName ?? _extractFirstNameFromEmail(user.email!);
      String userLastName = lastName ?? _extractLastNameFromEmail(user.email!);
      
      // Obtenir le rôle "Membre"
      final memberRoleId = await _getMemberRoleId();
      List<String> roles = [];
      if (memberRoleId != null) {
        roles.add(memberRoleId);
      }
      
      // Créer la personne dans le module Personnes
      final newPerson = PersonModel.fromImport(
        firstName: userFirstName,
        lastName: userLastName,
        email: user.email!,
        phone: additionalData?['phone'],
        country: additionalData?['country'] ?? 'France',
        birthDate: additionalData?['birthDate'],
        gender: additionalData?['gender'],
        maritalStatus: additionalData?['maritalStatus'],
        address: additionalData?['address'],
        additionalAddress: additionalData?['additionalAddress'],
        zipCode: additionalData?['zipCode'],
        city: additionalData?['city'],
        roles: roles,
        customFields: additionalData?['customFields'] ?? {},
        isActive: true,
      );
      
      await _peopleService.create(newPerson);
      print('✅ Personne créée automatiquement dans le module Personnes');
      
    } catch (e) {
      print('❌ Erreur lors de la création automatique de la personne: $e');
      // Ne pas faire échouer l'inscription si la création de la personne échoue
    }
  }
  
  /// 2. Création personne → Création automatique d'identifiants de connexion
  /// À appeler après la création d'une personne dans le module Personnes
  static Future<User?> onPersonCreated(PersonModel person, {
    String? password,
    bool createAuthAccount = false,
    bool forceCreate = false, // Nouveau paramètre pour forcer la création
    String? personId, // ID de la personne créée pour établir le lien
  }) async {
    if (!createAuthAccount || person.email == null || person.email!.trim().isEmpty) {
      return null;
    }
    
    try {
      print('🔄 Synchronisation: Création compte auth pour ${person.email}');
      
      // Pour l'import, on essaie toujours de créer le compte
      // Si le compte existe déjà, Firebase renverra une erreur email-already-in-use
      print('🔄 Tentative de création du compte Firebase Auth...');
      
      // Générer un mot de passe temporaire si non fourni
      final userPassword = password ?? generateTemporaryPassword();
      
      // Créer le compte Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: person.email!,
        password: userPassword,
      );
      
      // Mettre à jour le nom d'affichage
      await userCredential.user?.updateDisplayName('${person.firstName} ${person.lastName}');
      
      // Envoyer un email de réinitialisation du mot de passe
      if (password == null) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: person.email!);
        print('📧 Email de réinitialisation du mot de passe envoyé');
      }
      
      print('✅ Compte utilisateur créé automatiquement');
      
      // NOUVEAU : Établir le lien bidirectionnel
      if (personId != null && userCredential.user != null) {
        print('🔄 Établissement du lien bidirectionnel...');
        await _linkPersonToUser(personId, userCredential.user!.uid);
        print('✅ Lien établi entre PersonModel ID: $personId ↔ Firebase Auth UID: ${userCredential.user!.uid}');
      } else {
        print('⚠️ Impossible d\'établir le lien : personId=$personId, user=${userCredential.user?.uid}');
      }
      
      return userCredential.user;
      
    } catch (e) {
      // Vérifier si l'erreur est due à un email déjà utilisé
      if (e.toString().contains('email-already-in-use')) {
        print('ℹ️ Email déjà utilisé - compte existant confirmé pour ${person.email}');
        
        // NOUVEAU : Si compte existe, essayer de lier avec la personne
        if (personId != null) {
          print('🔄 Tentative de liaison avec le compte existant...');
          try {
            // Récupérer l'UID du compte existant via signInWithEmailAndPassword temporaire
            final uid = await _getExistingUserUidBySignIn(person.email!);
            if (uid != null) {
              await _linkPersonToUser(personId, uid);
              print('✅ Lien établi avec le compte existant - UID: $uid');
            } else {
              print('⚠️ Impossible de récupérer l\'UID du compte existant');
            }
          } catch (linkError) {
            print('❌ Erreur lors de la liaison avec compte existant: $linkError');
            print('⚠️ Compte existant non lié à la personne');
          }
        }
        
        print('⚠️ Aucun compte utilisateur créé (compte existant ou erreur)');
        return null; // Compte existe déjà
      } else {
        print('❌ Erreur lors de la création automatique du compte: $e');
        return null;
      }
    }
  }
  
  /// Extraire le prénom depuis l'email (partie avant le @)
  static String _extractFirstNameFromEmail(String email) {
    final localPart = email.split('@').first;
    final parts = localPart.split(RegExp(r'[\.\-_]'));
    return parts.isNotEmpty ? _capitalize(parts.first) : 'Utilisateur';
  }
  
  /// Extraire le nom depuis l'email
  static String _extractLastNameFromEmail(String email) {
    final localPart = email.split('@').first;
    final parts = localPart.split(RegExp(r'[\.\-_]'));
    return parts.length > 1 ? _capitalize(parts.last) : '';
  }
  
  /// Capitaliser la première lettre
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Récupérer l'UID d'un utilisateur existant en essayant une connexion temporaire
  static Future<String?> _getExistingUserUidBySignIn(String email) async {
    try {
      // Utiliser un mot de passe temporaire commun pour essayer la connexion
      // Note: Cette méthode ne marchera que si on connaît le mot de passe
      // Alternative: utiliser les fonctions Firebase Admin (côté serveur)
      
      // Pour l'instant, cherchons dans les PersonModel existantes
      final querySnapshot = await FirebaseFirestore.instance
          .collection('persons')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final personData = querySnapshot.docs.first.data();
        final existingUid = personData['uid'] as String?;
        
        if (existingUid != null && existingUid.isNotEmpty) {
          print('🔍 UID trouvé dans PersonModel existante: $existingUid');
          return existingUid;
        }
      }
      
      print('🔍 Aucun UID trouvé pour l\'email $email');
      return null;
      
    } catch (e) {
      print('❌ Erreur lors de la recherche de l\'UID existant: $e');
      return null;
    }
  }  /// Générer un mot de passe temporaire
  static String generateTemporaryPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(12, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
  }
  
  /// Lier une personne à un utilisateur Firebase Auth (méthode privée)
  static Future<void> _linkPersonToUser(String personId, String userUid) async {
    try {
      print('🔄 Mise à jour de la PersonModel avec UID: $userUid');
      
      // Mettre à jour la PersonModel avec l'UID Firebase Auth
      await FirebaseFirestore.instance
          .collection('persons')
          .doc(personId)
          .update({'uid': userUid});
      
      print('✅ PersonModel mise à jour avec UID Firebase Auth');
      
    } catch (e) {
      print('❌ Erreur lors de la liaison PersonModel-User: $e');
      throw e;
    }
  }

  /// Synchroniser une personne existante avec un compte utilisateur
  static Future<void> linkPersonToUser(String personId, String userId) async {
    try {
      // Cette méthode peut être utilisée pour lier manuellement
      // une personne existante à un compte utilisateur existant
      print('🔗 Liaison personne $personId avec utilisateur $userId');
      await _linkPersonToUser(personId, userId);
    } catch (e) {
      print('❌ Erreur lors de la liaison: $e');
    }
  }
}

/// Extension pour ajouter firstOrNull si pas disponible
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}