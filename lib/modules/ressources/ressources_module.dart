import 'package:flutter/material.dart';
import 'views/ressources_member_view.dart';
import 'views/ressources_admin_view.dart';

/// Module Ressources - Rassemblement des différentes ressources spirituelles
class RessourcesModule {
  static const String moduleId = 'ressources';
  static const String moduleName = 'Ressources';
  static const String moduleDescription = 'Rassemblement des différentes ressources spirituelles et de l\'église';
  static const IconData moduleIcon = Icons.library_books;

  /// Routes du module
  static Map<String, WidgetBuilder> get routes => {
    '/member/ressources': (context) => const RessourcesMemberView(),
    '/admin/ressources': (context) => const RessourcesAdminView(),
  };

  /// Widget pour l'interface membre
  static Widget get memberWidget => const RessourcesMemberView();

  /// Widget pour l'interface admin
  static Widget get adminWidget => const RessourcesAdminView();

  /// Configuration du module
  static Map<String, dynamic> get moduleConfig => {
    'features': [
      'Ressources personnalisables',
      'Bible interactive',
      'Messages du temps de la fin',
      'Cantiques',
      'Ressources Jubilé Tabernacle',
      'Images de couverture',
      'Redirections configurables',
      'Gestion des accès',
      'Organisation par catégories',
      'Interface responsive',
    ],
    'default_resources': [
      'La Bible',
      'Le Message du temps de la fin',
      'Cantiques',
      'Jubilé Tabernacle',
    ],
    'supported_redirects': [
      'Routes internes Flutter',
      'URLs externes',
      'Deep links',
    ],
    'categories': [
      'spiritual',
      'worship',
      'church',
      'education',
      'media',
      'general',
    ],
  };
}
