import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/push_notification_service.dart';
import '../../services/notification_dev_service.dart';

class NotificationDiagnosticsPage extends StatefulWidget {
  const NotificationDiagnosticsPage({Key? key}) : super(key: key);

  @override
  State<NotificationDiagnosticsPage> createState() => _NotificationDiagnosticsPageState();
}

class _NotificationDiagnosticsPageState extends State<NotificationDiagnosticsPage> {
  bool _isLoading = false;
  String _diagnosticsResult = '';
  int _totalUsers = 0;
  int _usersWithTokens = 0;
  List<String> _recentUsers = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagnostics')),
        body: const Center(
          child: Text('Cette page n\'est disponible qu\'en mode développement'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics Notifications'),
        backgroundColor: Colors.orange,
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
                      'État du Système',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          PushNotificationService.isInitialized 
                            ? Icons.check_circle 
                            : Icons.error,
                          color: PushNotificationService.isInitialized 
                            ? Colors.green 
                            : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Service Push: ${PushNotificationService.isInitialized ? "Initialisé" : "Non initialisé"}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          PushNotificationService.currentToken != null 
                            ? Icons.check_circle 
                            : Icons.warning,
                          color: PushNotificationService.currentToken != null 
                            ? Colors.green 
                            : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Token actuel: ${PushNotificationService.currentToken != null ? "Présent" : "Absent"}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques Utilisateurs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Total utilisateurs: $_totalUsers'),
                    Text('Avec tokens FCM: $_usersWithTokens'),
                    Text('Taux de couverture: ${_totalUsers > 0 ? ((_usersWithTokens / _totalUsers) * 100).toStringAsFixed(1) : 0}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runDiagnostics,
                    child: _isLoading 
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text('Rafraîchir Diagnostics'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTestTokens,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Créer Tokens Test'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _ensureTokensAndSendTest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Configurer & Tester'),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logs de Diagnostic',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _diagnosticsResult.isEmpty 
                              ? 'Aucun diagnostic exécuté...' 
                              : _diagnosticsResult,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _diagnosticsResult = 'Exécution des diagnostics...\n';
    });

    try {
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('=== DIAGNOSTICS NOTIFICATIONS ===');
      buffer.writeln('Heure: ${DateTime.now()}');
      buffer.writeln();

      // Vérifier les utilisateurs
      buffer.writeln('1. Analyse des utilisateurs...');
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('people')
          .get();
      
      _totalUsers = usersSnapshot.docs.length;
      buffer.writeln('   Total utilisateurs: $_totalUsers');

      if (_totalUsers > 0) {
        final recentUserIds = usersSnapshot.docs
            .take(5)
            .map((doc) => doc.id)
            .toList();
        _recentUsers = recentUserIds;
        
        buffer.writeln('   Échantillon d\'IDs: ${recentUserIds.join(", ")}');
      }

      // Vérifier les tokens FCM
      buffer.writeln();
      buffer.writeln('2. Analyse des tokens FCM...');
      final tokensSnapshot = await FirebaseFirestore.instance
          .collection('fcm_tokens')
          .get();
      
      _usersWithTokens = tokensSnapshot.docs.length;
      buffer.writeln('   Total tokens FCM: $_usersWithTokens');

      if (tokensSnapshot.docs.isNotEmpty) {
        final sampleToken = tokensSnapshot.docs.first;
        final tokenData = sampleToken.data();
        buffer.writeln('   Exemple de token: ${tokenData['token']?.toString().substring(0, 20)}...');
        buffer.writeln('   Plateforme: ${tokenData['platform']}');
        buffer.writeln('   Actif: ${tokenData['isActive']}');
      }

      // Vérifier les notifications existantes
      buffer.writeln();
      buffer.writeln('3. Analyse des notifications...');
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('rich_notifications')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      buffer.writeln('   Notifications récentes: ${notificationsSnapshot.docs.length}');

      // Recommandations
      buffer.writeln();
      buffer.writeln('=== RECOMMANDATIONS ===');
      
      if (_usersWithTokens == 0) {
        buffer.writeln('⚠️  PROBLÈME: Aucun token FCM trouvé!');
        buffer.writeln('   Solution: Créer des tokens de test ou vérifier l\'initialisation');
      } else if (_usersWithTokens < _totalUsers * 0.5) {
        buffer.writeln('⚠️  ATTENTION: Faible couverture de tokens');
        buffer.writeln('   Seulement ${((_usersWithTokens / _totalUsers) * 100).toStringAsFixed(1)}% des utilisateurs ont des tokens');
      } else {
        buffer.writeln('✅ Bonne couverture de tokens FCM');
      }

      setState(() {
        _diagnosticsResult = buffer.toString();
      });

    } catch (e) {
      setState(() {
        _diagnosticsResult += '\nERREUR lors du diagnostic: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestTokens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_recentUsers.isEmpty) {
        setState(() {
          _diagnosticsResult += '\nAucun utilisateur trouvé pour créer les tokens de test';
        });
        return;
      }

      await PushNotificationService.createTestTokensForUsers(_recentUsers);
      
      setState(() {
        _diagnosticsResult += '\n✅ Tokens de test créés pour ${_recentUsers.length} utilisateurs';
      });

      // Rafraîchir les diagnostics
      await _runDiagnostics();

    } catch (e) {
      setState(() {
        _diagnosticsResult += '\nERREUR lors de la création des tokens: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _ensureTokensAndSendTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        _diagnosticsResult += '\n🔧 Configuration automatique des tokens...';
      });

      // S'assurer que les tokens existent
      await NotificationDevService.ensureDevTokensExist();
      
      setState(() {
        _diagnosticsResult += '\n✅ Tokens configurés!';
      });

      // Attendre un peu pour que les tokens soient bien enregistrés
      await Future.delayed(const Duration(seconds: 1));

      // Envoyer une notification de test
      setState(() {
        _diagnosticsResult += '\n📤 Envoi de la notification de test...';
      });

      await NotificationDevService.sendTestNotification();

      setState(() {
        _diagnosticsResult += '\n✅ Notification de test envoyée avec succès!';
        _diagnosticsResult += '\n📱 Vérifiez votre appareil pour la notification push';
      });

      // Rafraîchir les diagnostics
      await Future.delayed(const Duration(seconds: 1));
      await _runDiagnostics();

    } catch (e) {
      setState(() {
        _diagnosticsResult += '\n❌ ERREUR lors du test: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
