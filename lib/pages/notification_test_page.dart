import 'package:flutter/material.dart';
import '../services/push_notification_service.dart';
import '../services/notification_integration_service.dart';
import '../theme.dart';

/// Service de test pour les notifications push
class NotificationTestService {
  /// Test d'envoi de notification simple
  static Future<void> testSimpleNotification() async {
    try {
      final currentToken = PushNotificationService.currentToken;
      if (currentToken == null) {
        throw Exception('Token FCM non disponible');
      }

      await PushNotificationService.sendNotificationToUser(
        userId: 'test_user',
        title: '🧪 Test de notification',
        body: 'Ceci est un test des notifications push',
        data: {
          'type': 'test',
          'action': 'simple_test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Test de notification simple réussi');
    } catch (e) {
      debugPrint('❌ Erreur lors du test de notification: $e');
      rethrow;
    }
  }

  /// Test de notification de rendez-vous
  static Future<void> testAppointmentNotification() async {
    try {
      await NotificationIntegrationService.notifyNewAppointment(
        responsableId: 'test_responsable',
        membreName: 'Jean Dupont',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        motif: 'Consultation pastorale',
      );

      debugPrint('✅ Test de notification de rendez-vous réussi');
    } catch (e) {
      debugPrint('❌ Erreur lors du test de notification de rendez-vous: $e');
      rethrow;
    }
  }

  /// Test de notification d'étude biblique
  static Future<void> testBibleStudyNotification() async {
    try {
      await NotificationIntegrationService.notifyNewBibleStudy(
        userIds: ['test_user_1', 'test_user_2'],
        title: 'L\'amour de Dieu',
        description: 'Étude sur 1 Jean 4:7-21',
        authorName: 'Pasteur Martin',
      );

      debugPrint('✅ Test de notification d\'étude biblique réussi');
    } catch (e) {
      debugPrint('❌ Erreur lors du test de notification d\'étude biblique: $e');
      rethrow;
    }
  }

  /// Test de notification urgente
  static Future<void> testUrgentNotification() async {
    try {
      await NotificationIntegrationService.notifyUrgentMessage(
        userIds: ['test_user'],
        title: 'Message urgent',
        message: 'Réunion d\'urgence à 14h en salle de conférence',
      );

      debugPrint('✅ Test de notification urgente réussi');
    } catch (e) {
      debugPrint('❌ Erreur lors du test de notification urgente: $e');
      rethrow;
    }
  }

  /// Test de notification de bienvenue
  static Future<void> testWelcomeNotification() async {
    try {
      await NotificationIntegrationService.notifyWelcomeNewMember(
        userId: 'test_new_user',
        firstName: 'Marie',
      );

      debugPrint('✅ Test de notification de bienvenue réussi');
    } catch (e) {
      debugPrint('❌ Erreur lors du test de notification de bienvenue: $e');
      rethrow;
    }
  }

  /// Vérifie l'état du service de notifications
  static Map<String, dynamic> checkNotificationStatus() {
    return {
      'isInitialized': PushNotificationService.isInitialized,
      'currentToken': PushNotificationService.currentToken != null,
      'tokenPreview': PushNotificationService.currentToken?.substring(0, 20) ?? 'Aucun',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Page de test et de configuration des notifications push
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _notificationStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    setState(() {
      _notificationStatus = NotificationTestService.checkNotificationStatus();
    });
  }

  Future<void> _runTest(String testName, Future<void> Function() testFunction) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Exécution du test: $testName...';
    });

    try {
      await testFunction();
      setState(() {
        _statusMessage = '✅ Test réussi: $testName';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Test échoué: $testName - $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Test Notifications Push'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkStatus,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildTestButtons(),
            const SizedBox(height: 20),
            _buildStatusMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'État du service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_notificationStatus != null) ...[
              _buildStatusItem(
                'Service initialisé',
                _notificationStatus!['isInitialized'],
              ),
              _buildStatusItem(
                'Token FCM disponible',
                _notificationStatus!['currentToken'],
              ),
              const SizedBox(height: 8),
              Text(
                'Token: ${_notificationStatus!['tokenPreview']}...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dernière vérification: ${_formatTime(_notificationStatus!['timestamp'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tests disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildTestButton(
              'Test simple',
              'Envoie une notification de test basique',
              Icons.notifications,
              () => _runTest('Test simple', NotificationTestService.testSimpleNotification),
            ),
            _buildTestButton(
              'Test rendez-vous',
              'Notification de nouveau rendez-vous',
              Icons.calendar_today,
              () => _runTest('Test rendez-vous', NotificationTestService.testAppointmentNotification),
            ),
            _buildTestButton(
              'Test étude biblique',
              'Notification de nouvelle étude',
              Icons.book,
              () => _runTest('Test étude biblique', NotificationTestService.testBibleStudyNotification),
            ),
            _buildTestButton(
              'Test urgent',
              'Notification urgente',
              Icons.priority_high,
              () => _runTest('Test urgent', NotificationTestService.testUrgentNotification),
            ),
            _buildTestButton(
              'Test bienvenue',
              'Notification de bienvenue',
              Icons.waving_hand,
              () => _runTest('Test bienvenue', NotificationTestService.testWelcomeNotification),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, String subtitle, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        onTap: _isLoading ? null : onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    if (_statusMessage.isEmpty) return const SizedBox.shrink();

    return Card(
      color: _statusMessage.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _statusMessage.startsWith('✅') ? Icons.check_circle : Icons.error,
              color: _statusMessage.startsWith('✅') ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _statusMessage.startsWith('✅') ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
