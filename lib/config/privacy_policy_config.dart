class PrivacyPolicyConfig {
  static const String version = "1.0";
  static const String lastUpdated = "2025-08-25";
  static const String effectiveDate = "2025-08-25";
  
  // URLs
  static const String privacyPolicyUrl = "https://jubile-tabernacle.fr/privacy-policy";
  static const String contactEmail = "privacy@jubile-tabernacle.fr";
  static const String supportEmail = "support@jubile-tabernacle.fr";
  
  // Textes pour l'application
  static const String shortDescription = 
    "Nous respectons votre vie privée et ne collectons que les informations "
    "nécessaires pour vous offrir une expérience spirituelle personnalisée.";
  
  static const String dataCollectionSummary = 
    "• Informations de compte (nom, email)\n"
    "• Contenus que vous partagez (prières, témoignages)\n"
    "• Données d'utilisation pour améliorer l'application\n"
    "• Aucune vente de données à des tiers";
  
  static const String userRightsSummary = 
    "Vous pouvez à tout moment :\n"
    "• Consulter vos données\n"
    "• Corriger vos informations\n"
    "• Supprimer votre compte\n"
    "• Exporter vos données\n"
    "• Nous contacter pour toute question";
  
  // Paramètres de confidentialité par défaut
  static const Map<String, bool> defaultPrivacySettings = {
    'shareTestimonies': false,
    'receiveNotifications': true,
    'analyticsOptIn': true,
    'locationSharing': false,
    'publicProfile': false,
  };
  
  // Types de données collectées (pour les stores)
  static const List<String> dataTypesCollected = [
    'Nom et prénom',
    'Adresse e-mail',
    'Contenu généré (prières, témoignages)',
    'Préférences utilisateur',
    'Données d\'usage anonymisées',
  ];
  
  // Types de données NON collectées
  static const List<String> dataTypesNotCollected = [
    'Localisation précise',
    'Contacts téléphoniques',
    'Photos et vidéos',
    'Informations bancaires',
    'Données de santé',
    'Historique de navigation web',
  ];
  
  // Bases légales RGPD
  static const Map<String, String> legalBases = {
    'accountManagement': 'Exécution du contrat',
    'notifications': 'Consentement',
    'analytics': 'Intérêt légitime',
    'security': 'Intérêt légitime',
    'legalCompliance': 'Obligation légale',
  };
  
  // Durées de conservation
  static const Map<String, String> retentionPeriods = {
    'activeAccounts': 'Tant que le compte est actif',
    'deletedAccounts': '30 jours après suppression',
    'legalRequirements': 'Maximum 3 ans si requis par la loi',
    'analytics': '26 mois (données anonymisées)',
  };
  
  // Informations pour les mineurs
  static const int minimumAge = 13;
  static const String minorPolicyText = 
    "Cette application est destinée aux utilisateurs de 13 ans et plus. "
    "Nous ne collectons pas sciemment d'informations personnelles "
    "d'enfants de moins de 13 ans.";
  
  // Services tiers utilisés
  static const List<Map<String, String>> thirdPartyServices = [
    {
      'name': 'Firebase (Google)',
      'purpose': 'Hébergement et base de données',
      'dataShared': 'Données utilisateur nécessaires au fonctionnement',
      'privacyPolicy': 'https://policies.google.com/privacy',
    },
    {
      'name': 'HelloAsso',
      'purpose': 'Traitement des dons',
      'dataShared': 'Informations de transaction uniquement',
      'privacyPolicy': 'https://www.helloasso.com/confidentialite',
    },
  ];
  
  // Textes pour les dialogues de consentement
  static const Map<String, String> consentTexts = {
    'notifications': 'Acceptez-vous de recevoir des notifications pour rester '
                    'informé des nouveaux contenus spirituels et des annonces importantes ?',
    'analytics': 'Acceptez-vous que nous utilisions des données d\'usage anonymisées '
                'pour améliorer l\'application ?',
    'testimonies': 'Souhaitez-vous que vos témoignages puissent être partagés '
                  'publiquement pour encourager la communauté ? (Vous pouvez '
                  'modifier ce paramètre à tout moment)',
  };
  
  // URLs pour exercer les droits
  static const Map<String, String> rightsUrls = {
    'dataAccess': '$privacyPolicyUrl#access',
    'dataCorrection': '$privacyPolicyUrl#correction',
    'dataDeletion': '$privacyPolicyUrl#deletion',
    'dataExport': '$privacyPolicyUrl#export',
    'complaint': 'https://www.cnil.fr/fr/plaintes',
  };
}

// Fonctions utilitaires pour la gestion de la confidentialité
class PrivacyHelper {
  
  /// Vérifie si l'utilisateur a donné son consentement pour un type de données
  static bool hasConsent(String dataType) {
    // À implémenter avec SharedPreferences ou Firebase
    return false;
  }
  
  /// Enregistre le consentement de l'utilisateur
  static Future<void> setConsent(String dataType, bool hasConsent) async {
    // À implémenter avec SharedPreferences ou Firebase
  }
  
  /// Génère un export des données utilisateur
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    // À implémenter avec la base de données
    return {};
  }
  
  /// Supprime complètement les données d'un utilisateur
  static Future<void> deleteAllUserData(String userId) async {
    // À implémenter avec la base de données
  }
  
  /// Vérifie si l'utilisateur a l'âge minimum requis
  static bool isAgeCompliant(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      return age - 1 >= PrivacyPolicyConfig.minimumAge;
    }
    return age >= PrivacyPolicyConfig.minimumAge;
  }
}
