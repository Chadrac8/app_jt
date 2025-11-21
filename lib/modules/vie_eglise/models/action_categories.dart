/// Classe utilitaire pour gérer les catégories d'actions
class ActionCategories {
  // Liste des catégories disponibles
  static const List<String> values = [
    'seigneur',
    'pasteur', 
    'culte',
    'formation',
    'communaute',
    'general',
  ];

  // Labels des catégories
  static const Map<String, String> labels = {
    'seigneur': 'Seigneur',
    'pasteur': 'Pasteur',
    'culte': 'Culte',
    'formation': 'Formation',
    'communaute': 'Communauté',
    'general': 'Général',
  };

  // Descriptions des catégories
  static const Map<String, String> descriptions = {
    'seigneur': 'Actions liées au Seigneur et à la spiritualité',
    'pasteur': 'Actions liées au pasteur et au conseil pastoral',
    'culte': 'Actions liées aux cultes et célébrations',
    'formation': 'Actions liées à la formation et l\'apprentissage',
    'communaute': 'Actions liées à la vie communautaire',
    'general': 'Actions générales et diverses',
  };

  /// Obtenir le label d'une catégorie
  static String getLabel(String category) {
    return labels[category] ?? category;
  }

  /// Obtenir la description d'une catégorie
  static String getDescription(String category) {
    return descriptions[category] ?? '';
  }

  /// Vérifier si une catégorie existe
  static bool exists(String category) {
    return values.contains(category);
  }

  /// Obtenir la catégorie par défaut
  static String get defaultCategory => 'general';
}