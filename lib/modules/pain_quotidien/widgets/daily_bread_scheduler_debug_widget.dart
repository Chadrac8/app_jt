import 'package:flutter/material.dart';
import '../services/daily_bread_scheduler.dart';
import '../../../../theme.dart';

/// Widget de debug pour surveiller et tester le scheduler du pain quotidien
class DailyBreadSchedulerDebugWidget extends StatefulWidget {
  const DailyBreadSchedulerDebugWidget({Key? key}) : super(key: key);

  @override
  State<DailyBreadSchedulerDebugWidget> createState() => _DailyBreadSchedulerDebugWidgetState();
}

class _DailyBreadSchedulerDebugWidgetState extends State<DailyBreadSchedulerDebugWidget> {
  Map<String, dynamic>? _schedulerStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedulerStatus();
  }

  Future<void> _loadSchedulerStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await DailyBreadScheduler.getSchedulerStatus();
      setState(() {
        _schedulerStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur chargement statut: $e');
    }
  }

  Future<void> _forceUpdate() async {
    setState(() => _isLoading = true);
    
    try {
      await DailyBreadScheduler.forceUpdate();
      await _loadSchedulerStatus();
      _showSuccessSnackbar('Mise à jour forcée réussie');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur mise à jour: $e');
    }
  }

  Future<void> _debugTrigger() async {
    setState(() => _isLoading = true);
    
    try {
      await DailyBreadScheduler.debugTriggerUpdate();
      await _loadSchedulerStatus();
      _showSuccessSnackbar('Test déclenché avec succès');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur test: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.greenStandard,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.redStandard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Scheduler Pain Quotidien'),
        backgroundColor: AppTheme.orangeStandard,
        foregroundColor: AppTheme.white100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut du scheduler
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 Statut du Scheduler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_schedulerStatus != null) ...[
                            _buildStatusRow('Actif', _schedulerStatus!['isActive'] ? '✅ Oui' : '❌ Non'),
                            _buildStatusRow('Initialisé', _schedulerStatus!['isInitialized'] ? '✅ Oui' : '❌ Non'),
                            _buildStatusRow('Dernière mise à jour', _formatDate(_schedulerStatus!['lastUpdate'])),
                            _buildStatusRow('Prochaine mise à jour dans', _schedulerStatus!['timeUntilNext6AM'] ?? 'N/A'),
                            _buildStatusRow('Prochaine mise à jour', _formatDate(_schedulerStatus!['nextUpdate'])),
                          ] else ...[
                            const Text('Statut non disponible'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Actions de test
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔧 Actions de Test',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loadSchedulerStatus,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualiser le statut'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.blueStandard,
                                foregroundColor: AppTheme.white100,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _forceUpdate,
                              icon: const Icon(Icons.update),
                              label: const Text('Forcer la mise à jour'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orangeStandard,
                                foregroundColor: AppTheme.white100,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _debugTrigger,
                              icon: const Icon(Icons.bug_report),
                              label: const Text('Test Debug'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.redStandard,
                                foregroundColor: AppTheme.white100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Informations
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ℹ️ Informations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '• Le scheduler se déclenche automatiquement chaque jour à 6h00\n'
                            '• Une vérification minutielle assure qu\'aucune mise à jour n\'est ratée\n'
                            '• Le contenu est récupéré depuis branham.org\n'
                            '• En cas d\'échec, le contenu en cache est conservé\n'
                            '• Les dates de mise à jour sont stockées localement',
                            style: TextStyle(color: AppTheme.grey500),
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

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: AppTheme.fontMedium),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.grey500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Jamais';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Erreur format date';
    }
  }
}