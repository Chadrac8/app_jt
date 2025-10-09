import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'scripts/calendar_diagnostic.dart';

/// DIAGNOSTIC CALENDRIER - Pourquoi les occurrences n'apparaissent pas ?
/// 
/// flutter run -t lib/diagnose_calendar.dart -d chrome
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DiagnosticApp());
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diagnostic Calendrier',
      theme: ThemeData.dark(useMaterial3: true),
      home: const DiagnosticPage(),
    );
  }
}

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  bool _isRunning = false;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostic() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    CalendarDiagnostic.onLog = (message) {
      setState(() {
        _logs.add(message);
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    };

    try {
      await CalendarDiagnostic.diagnose();
    } finally {
      CalendarDiagnostic.onLog = null;
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
        title: const Text('🔍 Diagnostic Calendrier'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'DIAGNOSTIC COMPLET',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ce diagnostic va analyser:\n'
                    '• Les événements récurrents dans Firestore\n'
                    '• Le champ recurrence de chaque événement\n'
                    '• Le statut de publication\n'
                    '• La génération des occurrences\n\n'
                    'Vous saurez exactement pourquoi les occurrences n\'apparaissent pas !',
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

            SizedBox(
              height: 70,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runDiagnostic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                            'ANALYSE EN COURS...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'LANCER LE DIAGNOSTIC',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

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
                          Icon(Icons.terminal, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Rapport de Diagnostic',
                            style: TextStyle(
                              color: Colors.blue,
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
                                '📋 Cliquez pour démarrer l\'analyse...',
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
                                Color textColor = Colors.blue[300]!;
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
