import '../models/person_model.dart';

class DonationUrlHelper {
  /// Construit une URL HelloAsso (base, sans préremplissage URL)
  /// Le préremplissage se fait via JavaScript dans la WebView
  static String buildPrefilledUrl(String baseUrl, PersonModel? user) {
    // Retourne l'URL de base - le préremplissage se fait via JavaScript
    return baseUrl;
  }

  /// Génère le code JavaScript pour préremplir les champs HelloAsso
  static String generatePrefillScript(PersonModel? user) {
    if (user == null) return '';

    final script = StringBuffer();
    script.writeln('(function() {');
    script.writeln('  console.log("Préremplissage des champs HelloAsso...");');
    script.writeln('  ');
    script.writeln('  function fillField(selectors, value) {');
    script.writeln('    if (!value) return;');
    script.writeln('    for (const selector of selectors) {');
    script.writeln('      const field = document.querySelector(selector);');
    script.writeln('      if (field) {');
    script.writeln('        field.value = value;');
    script.writeln('        field.dispatchEvent(new Event("input", { bubbles: true }));');
    script.writeln('        field.dispatchEvent(new Event("change", { bubbles: true }));');
    script.writeln('        console.log("Champ rempli:", selector, "=", value);');
    script.writeln('        break;');
    script.writeln('      }');
    script.writeln('    }');
    script.writeln('  }');
    script.writeln('  ');
    script.writeln('  function tryFillFields() {');
    
    // Prénom
    if (user.firstName.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[name*=\\"firstName\\"]",');
      script.writeln('      "input[name*=\\"prenom\\"]",');
      script.writeln('      "input[placeholder*=\\"Prénom\\"]",');
      script.writeln('      "input[placeholder*=\\"First name\\"]",');
      script.writeln('      "input[id*=\\"firstName\\"]",');
      script.writeln('      "input[id*=\\"prenom\\"]"');
      script.writeln('    ], "${user.firstName}");');
    }
    
    // Nom
    if (user.lastName.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[name*=\\"lastName\\"]",');
      script.writeln('      "input[name*=\\"nom\\"]",');
      script.writeln('      "input[placeholder*=\\"Nom\\"]",');
      script.writeln('      "input[placeholder*=\\"Last name\\"]",');
      script.writeln('      "input[id*=\\"lastName\\"]",');
      script.writeln('      "input[id*=\\"nom\\"]"');
      script.writeln('    ], "${user.lastName}");');
    }
    
    // Email
    if (user.email != null && user.email!.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[type=\\"email\\"]",');
      script.writeln('      "input[name*=\\"email\\"]",');
      script.writeln('      "input[placeholder*=\\"email\\"]",');
      script.writeln('      "input[placeholder*=\\"E-mail\\"]",');
      script.writeln('      "input[id*=\\"email\\"]"');
      script.writeln('    ], "${user.email}");');
    }
    
    // Téléphone
    if (user.phone != null && user.phone!.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[type=\\"tel\\"]",');
      script.writeln('      "input[name*=\\"phone\\"]",');
      script.writeln('      "input[name*=\\"telephone\\"]",');
      script.writeln('      "input[placeholder*=\\"Téléphone\\"]",');
      script.writeln('      "input[placeholder*=\\"Phone\\"]",');
      script.writeln('      "input[id*=\\"phone\\"]",');
      script.writeln('      "input[id*=\\"telephone\\"]"');
      script.writeln('    ], "${user.phone}");');
    }
    
    // Adresse
    if (user.address != null && user.address!.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[name*=\\"address\\"]",');
      script.writeln('      "input[name*=\\"adresse\\"]",');
      script.writeln('      "input[placeholder*=\\"Adresse\\"]",');
      script.writeln('      "input[placeholder*=\\"Address\\"]",');
      script.writeln('      "input[id*=\\"address\\"]",');
      script.writeln('      "input[id*=\\"adresse\\"]",');
      script.writeln('      "textarea[name*=\\"address\\"]",');
      script.writeln('      "textarea[name*=\\"adresse\\"]"');
      script.writeln('    ], "${user.address}");');
    }
    
    // Ville
    if (user.city != null && user.city!.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[name*=\\"city\\"]",');
      script.writeln('      "input[name*=\\"ville\\"]",');
      script.writeln('      "input[placeholder*=\\"Ville\\"]",');
      script.writeln('      "input[placeholder*=\\"City\\"]",');
      script.writeln('      "input[id*=\\"city\\"]",');
      script.writeln('      "input[id*=\\"ville\\"]"');
      script.writeln('    ], "${user.city}");');
    }
    
    // Code postal
    if (user.zipCode != null && user.zipCode!.isNotEmpty) {
      script.writeln('    fillField([');
      script.writeln('      "input[name*=\\"zipCode\\"]",');
      script.writeln('      "input[name*=\\"postal\\"]",');
      script.writeln('      "input[name*=\\"cp\\"]",');
      script.writeln('      "input[placeholder*=\\"Code postal\\"]",');
      script.writeln('      "input[placeholder*=\\"Zip\\"]",');
      script.writeln('      "input[id*=\\"zip\\"]",');
      script.writeln('      "input[id*=\\"postal\\"]"');
      script.writeln('    ], "${user.zipCode}");');
    }
    
    script.writeln('  }');
    script.writeln('  ');
    script.writeln('  // Essayer immédiatement');
    script.writeln('  tryFillFields();');
    script.writeln('  ');
    script.writeln('  // Réessayer après un délai pour les champs chargés dynamiquement');
    script.writeln('  setTimeout(tryFillFields, 1000);');
    script.writeln('  setTimeout(tryFillFields, 2000);');
    script.writeln('  setTimeout(tryFillFields, 3000);');
    script.writeln('  ');
    script.writeln('  console.log("Script de préremplissage chargé");');
    script.writeln('})();');
    
    return script.toString();
  }

  /// Construit une URL préremplie spécifiquement pour un type de donation
  static String buildDonationTypeUrl(String baseUrl, PersonModel? user, String donationType) {
    String url = buildPrefilledUrl(baseUrl, user);
    
    // Ajouter des paramètres spécifiques selon le type de donation
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    switch (donationType.toLowerCase()) {
      case 'dîme':
        queryParams['type_don'] = 'dime';
        queryParams['commentaire'] = 'Dîme mensuelle';
        break;
      case 'offrande':
        queryParams['type_don'] = 'offrande';
        queryParams['commentaire'] = 'Offrande libre';
        break;
      case 'loyer de l\'église':
      case 'loyer':
        queryParams['type_don'] = 'loyer';
        queryParams['commentaire'] = 'Participation au loyer de l\'église';
        break;
      case 'achat du local':
      case 'achat':
        queryParams['type_don'] = 'achat_local';
        queryParams['commentaire'] = 'Contribution pour l\'achat du local';
        break;
    }
    
    return uri.replace(queryParameters: queryParams).toString();
  }
}