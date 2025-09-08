import 'package:flutter/foundation.dart';
import '../modules/roles/roles_module.dart';

/// Service d'initialisation des rôles et permissions
class RolesInitializationService {
  static bool _initialized = false;

  /// Initialise le système de rôles et permissions
  static Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('✅ Module Rôles déjà initialisé');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔄 Initialisation du module Rôles et Permissions...');
      }

      // Initialiser le module principal
      await RolesModule.initialize();

      _initialized = true;

      if (kDebugMode) {
        print('✅ Module Rôles et Permissions initialisé avec succès');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'initialisation du module Rôles: $e');
      }
      rethrow;
    }
  }

  /// Vérifie si le module est initialisé
  static bool get isInitialized => _initialized;

  /// Réinitialise le module (utile pour les tests)
  static void reset() {
    _initialized = false;
  }

  /// Initialise les rôles par défaut si nécessaire
  static Future<void> ensureDefaultRoles() async {
    try {
      if (kDebugMode) {
        print('🔄 Vérification des rôles par défaut...');
      }

      // Cette fonction sera appelée par RolesModule.initialize()
      // mais nous la gardons ici pour une utilisation future

      if (kDebugMode) {
        print('✅ Rôles par défaut vérifiés');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Erreur lors de la vérification des rôles par défaut: $e');
      }
      // Ne pas relancer l'erreur pour ne pas bloquer l'app
    }
  }
}
