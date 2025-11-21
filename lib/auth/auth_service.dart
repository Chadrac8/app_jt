import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../services/auth_person_sync_service.dart';
import '../models/person_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // Sign in anonymously
  static Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      return result;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }



  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Ensure user profile exists
      if (result.user != null) {
        try {
          await UserProfileService.ensureUserProfile(result.user!);
          print('✅ Profil utilisateur vérifié pour ${result.user!.email}');
        } catch (profileError) {
          print('⚠️ Erreur lors de la vérification du profil: $profileError');
          // Ne pas échouer l'authentification si le profil ne peut pas être vérifié
        }
      }
      
      return result;
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow; // Rethrow pour que l'UI puisse gérer l'erreur spécifique
    }
  }

  // Create account with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user profile automatically
      if (result.user != null) {
        try {
          await UserProfileService.ensureUserProfile(result.user!);
          print('✅ Profil utilisateur créé pour ${result.user!.email}');
          
          // 🆕 Synchronisation automatique : Créer la personne dans le module Personnes
          await AuthPersonSyncService.onUserRegistered(result.user!);
          
        } catch (profileError) {
          print('⚠️ Erreur lors de la création du profil: $profileError');
          // Ne pas échouer l'authentification si le profil ne peut pas être créé
        }
      }
      
      return result;
    } catch (e) {
      print('Error creating user with email and password: $e');
      rethrow; // Rethrow pour que l'UI puisse gérer l'erreur spécifique
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Reset password
  static Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  // Get current user profile
  static Future<PersonModel?> getCurrentUserProfile() async {
    final profile = await UserProfileService.getCurrentUserProfile();
    _updateProfileCache(profile);
    return profile;
  }

  // Get current user profile stream
  static Stream<PersonModel?> getCurrentUserProfileStream() {
    return UserProfileService.getCurrentUserProfileStream();
  }

  // Update current user profile
  static Future<void> updateCurrentUserProfile(PersonModel person) async {
    return await UserProfileService.updateCurrentUserProfile(person);
  }

  // Create user account for existing person
  static Future<User?> createAccountForPerson({
    required String email,
    required String firstName,
    required String lastName,
    String? password,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Générer un mot de passe temporaire si non fourni
      final userPassword = password ?? AuthPersonSyncService.generateTemporaryPassword();
      
      // Créer le compte
      final result = await createUserWithEmailAndPassword(email, userPassword);
      
      if (result?.user != null) {
        // Mettre à jour le nom d'affichage
        await result!.user!.updateDisplayName('$firstName $lastName');
        
        // Envoyer email de réinitialisation si mot de passe temporaire
        if (password == null) {
          await resetPassword(email);
        }
        
        // Synchroniser avec données additionnelles
        await AuthPersonSyncService.onUserRegistered(
          result.user!,
          firstName: firstName,
          lastName: lastName,
          additionalData: additionalData,
        );
      }
      
      return result?.user;
    } catch (e) {
      print('Erreur lors de la création du compte pour la personne: $e');
      return null;
    }
  }

  // Check if current user can edit a profile
  static bool canEditProfile(PersonModel person) {
    return UserProfileService.canEditProfile(person);
  }

  // Get error message from FirebaseAuthException
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Un compte existe déjà avec cet email.';
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'invalid-email':
          return 'Adresse email invalide.';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';
        default:
          return error.message ?? 'Une erreur s\'est produite.';
      }
    }
    return 'Une erreur s\'est produite.';
  }

  // Check if current user has a specific role
  static bool hasRole(String role) {
    if (currentUser == null) return false;
    
    try {
      // This should be called asynchronously in a real app, but for simplicity
      // we'll create a synchronous version that checks cached data
      return _getCachedUserRoles().contains(role.toLowerCase());
    } catch (e) {
      print('Error checking role: $e');
      return false;
    }
  }

  // Check if current user has a specific permission
  static bool hasPermission(String permission) {
    if (currentUser == null) return false;
    
    try {
      final roles = _getCachedUserRoles();
      
      // Admin has all permissions
      if (roles.contains('admin')) return true;
      
      // Check specific permissions based on roles
      switch (permission) {
        case 'blog_create':
        case 'blog_manage':
          return roles.any((role) => ['admin', 'pastor', 'communication_manager', 'blogger'].contains(role));
        case 'reports_manage':
        case 'reports_create':
          return roles.any((role) => ['admin', 'pastor', 'communication_manager'].contains(role));
        case 'automation_manage':
        case 'automation_create':
          return roles.any((role) => ['admin', 'pastor', 'communication_manager'].contains(role));
        case 'users_manage':
          return roles.any((role) => ['admin', 'pastor'].contains(role));
        case 'events_manage':
          return roles.any((role) => ['admin', 'pastor', 'event_manager'].contains(role));
        case 'groups_manage':
          return roles.any((role) => ['admin', 'pastor', 'group_leader'].contains(role));
        default:
          return false;
      }
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  // Get cached user roles (this should be implemented with proper caching)
  static List<String> _getCachedUserRoles() {
    try {
      // Try to get from a simple in-memory cache
      // This is a simplified approach - in production you'd want proper caching
      if (_cachedUserProfile != null) {
        return _cachedUserProfile!.roles.map((r) => r.toLowerCase()).toList();
      }
      
      // Fallback to basic email check for demo
      if (currentUser?.email?.contains('admin') == true) {
        return ['admin'];
      }
      return ['member']; // Default role
    } catch (e) {
      print('Error getting cached roles: $e');
      return ['member'];
    }
  }

  // Simple cache for user profile (in production, use proper state management)
  static PersonModel? _cachedUserProfile;

  // Update cache when profile is loaded
  static void _updateProfileCache(PersonModel? profile) {
    _cachedUserProfile = profile;
  }

  // Async version to get current user roles
  static Future<List<String>> getCurrentUserRoles() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.roles ?? ['member'];
    } catch (e) {
      print('Error getting user roles: $e');
      return ['member'];
    }
  }

  // Check if user has any of the specified roles
  static bool hasAnyRole(List<String> roles) {
    return roles.any((role) => hasRole(role));
  }

  // Check if user has all of the specified roles
  static bool hasAllRoles(List<String> roles) {
    return roles.every((role) => hasRole(role));
  }
}