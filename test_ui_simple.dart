import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';
import 'lib/modules/bible/services/thematic_passage_service.dart';
import 'lib/modules/bible/widgets/add_passage_dialog.dart';
import 'lib/modules/bible/widgets/theme_creation_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const PassageTestApp());
}

class PassageTestApp extends StatelessWidget {
  const PassageTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Interface Passages',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PassageTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PassageTestScreen extends StatefulWidget {
  const PassageTestScreen({Key? key}) : super(key: key);

  @override
  State<PassageTestScreen> createState() => _PassageTestScreenState();
}

class _PassageTestScreenState extends State<PassageTestScreen> {
  String? _testThemeId;
  String _statusText = 'Prêt pour les tests...';
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _statusText = 'Utilisateur connecté: ${_currentUser!.uid}';
      } else {
        _statusText = 'Aucun utilisateur connecté - Test de l\'authentification automatique';
      }
    });
  }

  Future<void> _createTestTheme() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Création du thème de test...';
    });

    try {
      _testThemeId = await ThematicPassageService.createTheme(
        name: 'Test UI ${DateTime.now().millisecondsSinceEpoch}',
        description: 'Thème de test pour l\'interface utilisateur',
        color: Colors.blue,
        icon: Icons.star,
        isPublic: false,
      );

      setState(() {
        _statusText = 'Thème de test créé: $_testThemeId';
        _currentUser = FirebaseAuth.instance.currentUser;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Erreur création thème: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddPassageDialog() {
    if (_testThemeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Créez d\'abord un thème de test'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddPassageDialog(
        themeId: _testThemeId!,
        themeName: 'Thème de test',
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          _statusText = 'Passage ajouté avec succès via l\'interface!';
        });
      } else {
        setState(() {
          _statusText = 'Ajout de passage annulé ou échoué';
        });
      }
    });
  }

  void _showCreateThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => const ThemeCreationDialog(),
    ).then((result) {
      if (result == true) {
        setState(() {
          _statusText = 'Nouveau thème créé depuis l\'interface!';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Interface Passages Bibliques'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // État de l'authentification
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _currentUser != null ? Colors.green[50] : Colors.orange[50],
                border: Border.all(
                  color: _currentUser != null ? Colors.green : Colors.orange,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentUser != null ? Icons.check_circle : Icons.warning,
                        color: _currentUser != null ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'État de l\'authentification',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentUser != null ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_currentUser != null 
                    ? 'Connecté: ${_currentUser!.uid}' 
                    : 'Non connecté - L\'authentification sera automatique'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Tests de l\'interface utilisateur:',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Boutons de test
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createTestTheme,
                  icon: const Icon(Icons.add),
                  label: const Text('1. Créer thème test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showAddPassageDialog,
                  icon: const Icon(Icons.library_books),
                  label: const Text('2. Dialog ajout passage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCreateThemeDialog,
                  icon: const Icon(Icons.create),
                  label: const Text('3. Dialog création thème'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const LinearProgressIndicator(),

            const SizedBox(height: 20),

            // Zone de statut
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'État des tests:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions de test:',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Créez un thème de test'),
                  const Text('2. Utilisez le dialog d\'ajout de passage'),
                  const Text('3. Testez les références: Jean 3:16, Matthieu 5:3-5, etc.'),
                  const Text('4. Observez les messages d\'erreur s\'il y en a'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
