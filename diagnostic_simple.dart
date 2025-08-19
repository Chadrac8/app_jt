import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import des services et widgets nécessaires
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const DiagnosticApp());
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostic Passages',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DiagnosticScreen(),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  String _status = 'Initialisation...';
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      // Vérifier Firebase
      setState(() {
        _status = 'Vérification de Firebase...';
      });
      
      // Vérifier l'authentification
      _user = FirebaseAuth.instance.currentUser;
      
      if (_user == null) {
        setState(() {
          _status = 'Tentative de connexion anonyme...';
        });
        
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        _user = userCredential.user;
      }
      
      setState(() {
        _status = _user != null 
          ? 'Connecté: ${_user!.uid}' 
          : 'Échec de connexion';
      });
      
    } catch (e) {
      setState(() {
        _status = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Simple'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnostic de base:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _checkFirebaseStatus,
              child: const Text('Retester Firebase'),
            ),
            
            const SizedBox(height: 20),
            
            if (_user != null) ...[
              const Text(
                'Test réussi! Firebase et l\'authentification fonctionnent.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vous pouvez maintenant tester l\'ajout de passages dans l\'application principale.',
              ),
            ] else ...[
              const Text(
                'Problème détecté. Vérifiez la configuration Firebase.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
