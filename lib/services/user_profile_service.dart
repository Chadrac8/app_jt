import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import '../models/person_model.dart';

/// Service minimal pour la gestion des profils utilisateur
/// Ce service fait le pont entre Firebase Auth et FirebaseService
class UserProfileService {
  
  /// Assure qu'un profil utilisateur existe pour l'utilisateur Firebase Auth donné
  static Future<void> ensureUserProfile(User user) async {
    try {
      print('🔄 UserProfileService: Vérification/création du profil pour ${user.uid}');
      
      // Attendre que le token d'authentification soit prêt
      await user.getIdToken(true);
      
      // Petit délai pour s'assurer que les règles Firestore ont le token
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier si le profil existe déjà
      final existingProfile = await FirebaseService.getPersonByUid(user.uid);
      
      if (existingProfile != null) {
        print('✅ UserProfileService: Profil existant trouvé pour ${user.uid}');
        return;
      }
      
      // Créer un nouveau profil basique depuis Firebase Auth
      print('🔧 UserProfileService: Création d\'un nouveau profil pour ${user.uid}');
      
      final newProfile = PersonModel(
        id: '', // Sera défini par Firestore
        uid: user.uid,
        firstName: user.displayName?.split(' ').first ?? 'Utilisateur',
        lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
        email: user.email ?? '',
        phone: user.phoneNumber,
        profileImageUrl: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      
      await FirebaseService.createPersonWithId(user.uid, newProfile);
      print('✅ UserProfileService: Profil créé avec succès pour ${user.uid}');
      
    } catch (e) {
      print('❌ UserProfileService: Erreur lors de la création du profil: $e');
      // Ne pas faire échouer l'authentification pour une erreur de profil
    }
  }
  
  /// Récupère le profil de l'utilisateur actuellement connecté
  static Future<PersonModel?> getCurrentUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ UserProfileService: Aucun utilisateur connecté');
        return null;
      }
      
      final profile = await FirebaseService.getPersonByUid(currentUser.uid);
      
      if (profile == null) {
        print('⚠️ UserProfileService: Profil non trouvé pour ${currentUser.uid}');
        // Essayer de créer le profil automatiquement
        await ensureUserProfile(currentUser);
        return await FirebaseService.getPersonByUid(currentUser.uid);
      }
      
      return profile;
    } catch (e) {
      print('❌ UserProfileService: Erreur lors de la récupération du profil: $e');
      return null;
    }
  }
  
  /// Retourne un stream du profil utilisateur actuel
  static Stream<PersonModel?> getCurrentUserProfileStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }
    
    return FirebaseService.getPersonStreamByUid(currentUser.uid);
  }
  
  /// Met à jour le profil de l'utilisateur actuel
  static Future<void> updateCurrentUserProfile(PersonModel person) async {
    try {
      await FirebaseService.updatePerson(person);
      print('✅ UserProfileService: Profil mis à jour avec succès');
    } catch (e) {
      print('❌ UserProfileService: Erreur lors de la mise à jour du profil: $e');
      throw e;
    }
  }
  
  /// Vérifie si l'utilisateur peut éditer le profil donné
  static bool canEditProfile(PersonModel person) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    // L'utilisateur peut éditer son propre profil
    return person.uid == currentUser.uid;
  }
}