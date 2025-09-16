import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/pages/event_form_page.dart';
import 'lib/theme.dart';

/// Programme de test pour vérifier le sélecteur de responsables dans le formulaire d'événement
class TestEventFormResponsibleSelector extends StatelessWidget {
  const TestEventFormResponsibleSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test - Sélecteur Responsables Événement',
      theme: AppTheme.lightTheme,
      home: const TestEventFormPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestEventFormPage extends StatelessWidget {
  const TestEventFormPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test - Sélecteur Responsables'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test du Sélecteur de Responsables',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ce test permet de vérifier que le sélecteur de responsables fonctionne correctement dans le formulaire d\'événement.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EventFormPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Nouveau Événement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Instructions de Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTestInstruction(
                      '1.',
                      'Cliquez sur "Nouveau Événement" pour ouvrir le formulaire',
                    ),
                    _buildTestInstruction(
                      '2.',
                      'Faites défiler jusqu\'à la section "Responsables"',
                    ),
                    _buildTestInstruction(
                      '3.',
                      'Cliquez sur le champ "Sélectionner les responsables de l\'événement"',
                    ),
                    _buildTestInstruction(
                      '4.',
                      'Vérifiez que le dialogue de sélection s\'ouvre avec la liste des personnes',
                    ),
                    _buildTestInstruction(
                      '5.',
                      'Testez la recherche en tapant un nom dans le champ de recherche',
                    ),
                    _buildTestInstruction(
                      '6.',
                      'Sélectionnez une ou plusieurs personnes avec les cases à cocher',
                    ),
                    _buildTestInstruction(
                      '7.',
                      'Cliquez sur "Sélectionner" pour confirmer votre choix',
                    ),
                    _buildTestInstruction(
                      '8.',
                      'Vérifiez que les personnes sélectionnées s\'affichent dans le formulaire',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Fonctionnalités Testées',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeature('✅ Affichage de la liste des personnes'),
                    _buildFeature('✅ Recherche par nom, email ou téléphone'),
                    _buildFeature('✅ Sélection multiple avec cases à cocher'),
                    _buildFeature('✅ Affichage des personnes sélectionnées avec avatars'),
                    _buildFeature('✅ Compteur de sélection'),
                    _buildFeature('✅ Intégration dans le formulaire d\'événement'),
                    _buildFeature('✅ Mise à jour du state du formulaire'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInstruction(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        feature,
        style: TextStyle(
          fontSize: 14,
          color: Colors.green.shade700,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation de Firebase: $e');
  }
  
  runApp(const TestEventFormResponsibleSelector());
}