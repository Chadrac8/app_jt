import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'scripts/quick_recurrence_fix.dart';

/// FIX RAPIDE - Corrige les événements récurrents immédiatement
/// 
/// EXÉCUTEZ :
/// flutter run -t lib/fix_calendar_now.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fix Calendrier - Récurrence',
      theme: ThemeData.dark(useMaterial3: true),
      home: const FixPage(),
    );
  }
}

class FixPage extends StatefulWidget {
  const FixPage({super.key});

  @override
  State<FixPage> createState() => _FixPageState();
}

class _FixPageState extends State<FixPage> {
  bool _isRunning = false;
  bool _isCompleted = false;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runFix() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _logs.clear();
    });

    // Utiliser le callback pour capturer les logs
    QuickRecurrenceFix.onLog = (message) {
      setState(() {
        _logs.add(message);
      });
      // Auto-scroll
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    };

    try {
      await QuickRecurrenceFix.fixNow();
      setState(() {
        _logs.add('\n✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅');
        _logs.add('➜ Allez vérifier le calendrier maintenant !');
        _isCompleted = true;
      });
    } catch (e) {
      setState(() {
        _logs.add('\n❌ ERREUR : $e');
      });
    } finally {
      QuickRecurrenceFix.onLog = null;
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('🔧 Fix Rapide - Calendrier Récurrence'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Message d'alerte
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepOrange, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.deepOrange, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'FIX RAPIDE DES OCCURRENCES',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ce script va :\n'
                    '• Diagnostiquer tous les événements récurrents\n'
                    '• Corriger ceux qui ont un problème\n'
                    '• Créer des récurrences par défaut si nécessaire\n\n'
                    '⏱️ Durée : ~10 secondes\n'
                    '✅ Sûr : Détecte les événements déjà OK',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton FIX
            SizedBox(
              height: 70,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runFix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted ? Colors.green : Colors.deepOrange,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: _isRunning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'CORRECTION EN COURS...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCompleted ? Icons.check_circle : Icons.build_circle,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isCompleted ? 'FIX TERMINÉ !' : 'LANCER LE FIX MAINTENANT',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Console de logs
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[800]!, width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.terminal, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Console de Diagnostic',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                '📋 Cliquez sur le bouton pour démarrer...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                Color textColor = Colors.green[300]!;
                                if (log.contains('❌')) {
                                  textColor = Colors.red[300]!;
                                } else if (log.contains('⚠️')) {
                                  textColor = Colors.orange[300]!;
                                } else if (log.contains('✅')) {
                                  textColor = Colors.green[400]!;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: SelectableText(
                                    log,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      color: textColor,
                                      height: 1.4,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
