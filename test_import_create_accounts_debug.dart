import 'dart:io';
import 'package:csv/csv.dart';
import 'lib/modules/personnes/services/person_import_export_service.dart';

/// Script de diagnostic pour tester la configuration d'import avec création de comptes
void main() async {
  print('=== DIAGNOSTIC CONFIGURATION IMPORT ===\n');
  
  // Créer un fichier CSV de test
  await createTestCSV();
  
  // Service pour référence (non utilisé dans ce diagnostic)
  // final service = PersonImportExportService();
  
  // Configuration avec création de comptes activée
  final config = ImportExportConfig(
    createUserAccounts: true,
    validateEmails: true,
    validatePhones: false,
    allowDuplicateEmail: false,
    updateExisting: false,
  );
  
  print('Configuration d\'import testée:');
  print('- createUserAccounts: ${config.createUserAccounts}');
  print('- validateEmails: ${config.validateEmails}');
  print('- allowDuplicateEmail: ${config.allowDuplicateEmail}');
  print('- updateExisting: ${config.updateExisting}');
  print('');
  
  // Vérification du fichier CSV créé
  try {
    final csvContent = await File('test_personnes_comptes.csv').readAsString();
    final csvRows = const CsvToListConverter().convert(csvContent);
    
    print('Contenu du fichier CSV de test:');
    for (int i = 0; i < csvRows.length && i < 6; i++) {
      print('Ligne $i: ${csvRows[i]}');
    }
    print('');
    
    // Compter les emails valides
    int emailsValides = 0;
    for (int i = 1; i < csvRows.length; i++) { // Skip header
      if (csvRows[i].length > 2 && csvRows[i][2].toString().isNotEmpty && csvRows[i][2].toString().contains('@')) {
        emailsValides++;
      }
    }
    
    print('Analyse du fichier:');
    print('- Total personnes: ${csvRows.length - 1}');
    print('- Personnes avec email valide: $emailsValides');
    print('- Configuration createUserAccounts: ${config.createUserAccounts}');
    print('');
    
    if (config.createUserAccounts && emailsValides > 0) {
      print('✅ ATTENDU: Les $emailsValides personnes avec email devraient avoir des comptes utilisateurs créés');
    } else if (!config.createUserAccounts) {
      print('❌ CONFIGURATION: createUserAccounts est à false - aucun compte ne sera créé');
    } else {
      print('⚠️  ATTENTION: Aucune personne avec email valide trouvée');
    }
    
    print('\n=== GUIDE DE TEST ===');
    print('1. Ouvrez l\'application Flutter');
    print('2. Allez dans le module Personnes');
    print('3. Cliquez sur Import/Export');
    print('4. Allez dans l\'onglet Import');
    print('5. ✅ COCHEZ la case "Créer des comptes utilisateurs"');
    print('6. Sélectionnez le fichier: test_personnes_comptes.csv');
    print('7. Vérifiez dans les logs si vous voyez:');
    print('   - "Création de la personne avec compte utilisateur: [email]"');
    print('   - Au lieu de: "Création de la personne sans compte utilisateur: [nom]"');
    
  } catch (e, stackTrace) {
    print('Erreur lors de l\'analyse: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('\nFichier de test prêt: test_personnes_comptes.csv');
  print('(Ne sera pas supprimé pour permettre le test dans l\'app)');
}

/// Créer un fichier CSV de test avec des personnes ayant des emails
Future<void> createTestCSV() async {
  final csvData = [
    ['firstName', 'lastName', 'email', 'phone'],
    ['Jean', 'Dupont', 'jean.dupont@example.com', '0123456789'],
    ['Marie', 'Martin', 'marie.martin@example.com', '0123456790'],
    ['Pierre', 'Durand', 'pierre.durand@example.com', '0123456791'],
    ['Sophie', 'Bernard', '', '0123456792'], // Sans email
    ['Luc', 'Moreau', 'luc.moreau@example.com', '0123456793'],
  ];
  
  final csvString = const ListToCsvConverter().convert(csvData);
  await File('test_personnes_comptes.csv').writeAsString(csvString);
  
  print('Fichier CSV de test créé avec ${csvData.length - 1} personnes.');
  print('Personnes avec email: 4');
  print('Personnes sans email: 1');
  print('');
}