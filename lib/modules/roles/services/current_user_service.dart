import 'package:firebase_auth/firebase_auth.dart';

class CurrentUserService {
  static final CurrentUserService _instance = CurrentUserService._internal();
  factory CurrentUserService() => _instance;
  CurrentUserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère l'ID de l'utilisateur actuellement connecté
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Récupère l'email de l'utilisateur actuellement connecté
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Récupère le nom d'affichage de l'utilisateur actuellement connecté
  String? getCurrentUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  /// Récupère l'utilisateur Firebase actuellement connecté
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Vérifie si un utilisateur est connecté
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream des changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Récupère une représentation string de l'utilisateur actuel pour les logs
  String getCurrentUserString() {
    final user = getCurrentUser();
    if (user == null) return 'Utilisateur anonyme';
    
    return user.displayName ?? user.email ?? user.uid;
  }

  /// Récupère l'ID de l'utilisateur actuel ou une valeur par défaut
  String getCurrentUserIdOrDefault([String defaultValue = 'system']) {
    return getCurrentUserId() ?? defaultValue;
  }

  /// Récupère l'email de l'utilisateur actuel ou une valeur par défaut
  String getCurrentUserEmailOrDefault([String defaultValue = 'system@app.com']) {
    return getCurrentUserEmail() ?? defaultValue;
  }
}
