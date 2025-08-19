import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/push_notification_service.dart';

/// Widget de diagnostic pour les notifications push
class NotificationDiagnosticWidget extends StatefulWidget {
  const NotificationDiagnosticWidget({super.key});

  @override
  State<NotificationDiagnosticWidget> createState() => _NotificationDiagnosticWidgetState();
}

class _NotificationDiagnosticWidgetState extends State<NotificationDiagnosticWidget> {
  String _status = 'Initialisation...';
  bool _isLoading = true;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    debugPrint('DIAGNOSTIC: $message');
  }

  Future<void> _runDiagnostic() async {
    _addLog('Démarrage du diagnostic...');
    
    try {
      // Vérifier l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Erreur: Aucun utilisateur connecté';
          _isLoading = false;
        });
        _addLog('Aucun utilisateur connecté');
        return;
      }
      
      _addLog('Utilisateur connecté: ${user.email}');

      // Vérifier si le service est initialisé
      if (!PushNotificationService.isInitialized) {
        _addLog('Service non initialisé, initialisation...');
        await PushNotificationService.initialize();
      }

      // Vérifier le token actuel
      final currentToken = PushNotificationService.currentToken;
      if (currentToken == null || currentToken.isEmpty) {
        _addLog('Aucun token FCM trouvé');
        setState(() {
          _status = 'Problème: Aucun token FCM';
        });
      } else {
        _addLog('Token FCM présent: ${currentToken.substring(0, 20)}...');
        
        // Vérifier le token en base
        final tokenDoc = await FirebaseFirestore.instance
            .collection('fcm_tokens')
            .doc(user.uid)
            .get();
            
        if (tokenDoc.exists) {
          final tokenData = tokenDoc.data();
          _addLog('Token en base: ${tokenData?['token']?.substring(0, 20) ?? 'vide'}...');
          _addLog('Platform: ${tokenData?['platform'] ?? 'inconnue'}');
          _addLog('Actif: ${tokenData?['isActive'] ?? false}');
        } else {
          _addLog('Aucun token en base de données');
        }
        
        setState(() {
          _status = 'Token présent';
        });
      }

      setState(() {
        _isLoading = false;
      });
      
      _addLog('Diagnostic terminé');
      
    } catch (e) {
      _addLog('Erreur pendant le diagnostic: $e');
      setState(() {
        _status = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanAndRegenerate() async {
    setState(() {
      _isLoading = true;
      _status = 'Nettoyage et régénération...';
      _logs.clear();
    });

    try {
      _addLog('Nettoyage des tokens invalides...');
      await PushNotificationService.cleanInvalidTokens();
      
      _addLog('Attente de 3 secondes...');
      await Future.delayed(const Duration(seconds: 3));
      
      _addLog('Nouvelle tentative de diagnostic...');
      await _runDiagnostic();
      
    } catch (e) {
      _addLog('Erreur lors du nettoyage: $e');
      setState(() {
        _status = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: _status.startsWith('Erreur') 
                                  ? Colors.red 
                                  : _status.startsWith('Problème')
                                      ? Colors.orange
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runDiagnostic,
                  child: const Text('Relancer diagnostic'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _cleanAndRegenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Nettoyer & Régénérer'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Logs:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
