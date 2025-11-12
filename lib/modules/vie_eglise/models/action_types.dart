/// Classe utilitaire pour gérer les types d'actions
class ActionTypes {
  // Liste des types d'actions disponibles
  static const List<String> values = [
    'navigation',
    'form',
    'external',
    'contact',
    'info',
  ];

  // Labels des types d'actions
  static const Map<String, String> labels = {
    'navigation': 'Navigation dans l\'app',
    'form': 'Formulaire',
    'external': 'Lien externe',
    'contact': 'Contact',
    'info': 'Information',
  };

  // Descriptions des types d'actions
  static const Map<String, String> descriptions = {
    'navigation': 'Navigation vers une page de l\'application',
    'form': 'Formulaire à remplir',
    'external': 'Lien vers un site externe',
    'contact': 'Action de contact (email, téléphone)',
    'info': 'Affichage d\'informations',
  };

  /// Obtenir le label d'un type d'action
  static String getLabel(String type) {
    return labels[type] ?? type;
  }

  /// Obtenir la description d'un type d'action
  static String getDescription(String type) {
    return descriptions[type] ?? '';
  }

  /// Vérifier si un type d'action existe
  static bool exists(String type) {
    return values.contains(type);
  }

  /// Obtenir le type d'action par défaut
  static String get defaultType => 'navigation';
}