import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../services/dashboard_firebase_service.dart';
import '../../theme.dart';

class DashboardDiagnosticWidget extends StatefulWidget {
  const DashboardDiagnosticWidget({Key? key}) : super(key: key);

  @override
  State<DashboardDiagnosticWidget> createState() => _DashboardDiagnosticWidgetState();
}

class _DashboardDiagnosticWidgetState extends State<DashboardDiagnosticWidget> {
  Map<String, dynamic> _diagnosticData = {};
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _diagnosticData = {};
    });

    final Map<String, dynamic> results = {};

    try {
      // Test 1: Vérifier l'authentification
      final currentUser = AuthService.currentUser;
      results['auth'] = {
        'status': currentUser != null ? 'OK' : 'ERROR',
        'user': currentUser?.email ?? 'Non connecté',
        'uid': currentUser?.uid ?? 'N/A',
      };

      // Test 2: Vérifier les widgets configurés
      try {
        final hasWidgets = await DashboardFirebaseService.hasConfiguredWidgets();
        results['widgets_configured'] = {
          'status': 'OK',
          'hasWidgets': hasWidgets,
        };
      } catch (e) {
        results['widgets_configured'] = {
          'status': 'ERROR',
          'error': e.toString(),
        };
      }

      // Test 3: Essayer de récupérer les widgets
      try {
        final widgets = await DashboardFirebaseService.getDashboardWidgets();
        results['widgets_fetch'] = {
          'status': 'OK',
          'count': widgets.length,
          'widgets': widgets.map((w) => {'id': w.id, 'title': w.title, 'type': w.type}).toList(),
        };
      } catch (e) {
        results['widgets_fetch'] = {
          'status': 'ERROR',
          'error': e.toString(),
        };
      }

      // Test 4: Vérifier les préférences
      try {
        final prefs = await DashboardFirebaseService.getDashboardPreferences();
        results['preferences'] = {
          'status': 'OK',
          'data': prefs,
        };
      } catch (e) {
        results['preferences'] = {
          'status': 'ERROR',
          'error': e.toString(),
        };
      }

      // Test 5: Essayer d'initialiser les widgets par défaut
      if (currentUser != null) {
        try {
          await DashboardFirebaseService.initializeDefaultWidgets();
          results['init_default'] = {
            'status': 'OK',
            'message': 'Widgets par défaut initialisés',
          };
        } catch (e) {
          results['init_default'] = {
            'status': 'ERROR',
            'error': e.toString(),
          };
        }
      }

    } catch (e) {
      results['general_error'] = {
        'status': 'ERROR',
        'error': e.toString(),
      };
    }

    setState(() {
      _isRunning = false;
      _diagnosticData = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Dashboard'),
        backgroundColor: AppTheme.orangeStandard,
        foregroundColor: AppTheme.white100,
        actions: [
          IconButton(
            onPressed: _isRunning ? null : _runDiagnostic,
            icon: _isRunning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isRunning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppTheme.spaceMedium),
                  Text('Diagnostic en cours...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résultats du Diagnostic',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMedium),
                        ..._diagnosticData.entries.map((entry) => _buildDiagnosticItem(entry.key, entry.value)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour au Dashboard'),
                ),
              ],
            ),
    );
  }

  Widget _buildDiagnosticItem(String key, dynamic value) {
    final bool isOk = value['status'] == 'OK';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: isOk ? AppTheme.grey50 : AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: isOk ? AppTheme.grey200 : AppTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle : Icons.error,
                color: isOk ? AppTheme.grey600 : AppTheme.grey600,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                _getTestName(key),
                style: TextStyle(
                  fontWeight: AppTheme.fontBold,
                  color: isOk ? AppTheme.grey800 : AppTheme.grey800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            _formatDiagnosticData(value),
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey700,
            ),
          ),
        ],
      ),
    );
  }

  String _getTestName(String key) {
    switch (key) {
      case 'auth':
        return 'Authentification';
      case 'widgets_configured':
        return 'Widgets configurés';
      case 'widgets_fetch':
        return 'Récupération des widgets';
      case 'preferences':
        return 'Préférences';
      case 'init_default':
        return 'Initialisation par défaut';
      default:
        return key;
    }
  }

  String _formatDiagnosticData(dynamic data) {
    final StringBuffer buffer = StringBuffer();
    
    if (data is Map) {
      data.forEach((key, value) {
        if (key != 'status') {
          buffer.writeln('$key: $value');
        }
      });
    }
    
    return buffer.toString().trim();
  }
}
