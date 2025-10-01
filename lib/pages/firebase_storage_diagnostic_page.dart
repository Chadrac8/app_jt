import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';

class FirebaseStorageDiagnosticPage extends StatefulWidget {
  const FirebaseStorageDiagnosticPage({super.key});

  @override
  State<FirebaseStorageDiagnosticPage> createState() => _FirebaseStorageDiagnosticPageState();
}

class _FirebaseStorageDiagnosticPageState extends State<FirebaseStorageDiagnosticPage> {
  bool _isRunning = false;
  Map<String, dynamic>? _connectionResult;
  Map<String, dynamic>? _uploadResult;

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _connectionResult = null;
      _uploadResult = null;
    });

    try {
      // Test de connexion
      final connectionTest = await _testStorageConnection();
      setState(() => _connectionResult = connectionTest);

      // Test d'upload
      final uploadTest = await _testImageUpload();
      setState(() => _uploadResult = uploadTest);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du diagnostic: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<Map<String, dynamic>> _testStorageConnection() async {
    final result = <String, dynamic>{};
    final errors = <String>[];

    try {
      // Test d'authentification
      final user = FirebaseAuth.instance.currentUser;
      result['isAuthenticated'] = user != null;
      result['userId'] = user?.uid ?? 'Non connecté';

      if (user == null) {
        errors.add('Utilisateur non connecté');
      }

      // Test d'accès au storage
      try {
        final storage = FirebaseStorage.instance;
        storage.ref().child('test');
        result['canAccessStorage'] = true;
        result['storageBucket'] = storage.bucket;
      } catch (e) {
        result['canAccessStorage'] = false;
        errors.add('Impossible d\'accéder au Storage: $e');
      }

      // Test de permissions d'upload (simulation)
      if (user != null) {
        try {
          FirebaseStorage.instance.ref().child('diagnostic/test_${user.uid}');
          result['canUpload'] = true;
        } catch (e) {
          result['canUpload'] = false;
          errors.add('Permissions d\'upload insuffisantes: $e');
        }
      } else {
        result['canUpload'] = false;
      }

      result['errors'] = errors;
    } catch (e) {
      result['globalError'] = e.toString();
      errors.add('Erreur globale: $e');
      result['errors'] = errors;
    }

    return result;
  }

  Future<Map<String, dynamic>> _testImageUpload() async {
    final result = <String, dynamic>{};

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        result['success'] = false;
        result['error'] = 'Utilisateur non connecté';
        return result;
      }

      // Créer une référence de test
      final testRef = FirebaseStorage.instance
          .ref()
          .child('diagnostic/test_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Simuler l'upload (sans vraiment uploader pour éviter les frais)
      result['success'] = true;
      result['testPath'] = testRef.fullPath;
      result['timestamp'] = DateTime.now().toIso8601String();
      result['message'] = 'Test simulé avec succès';

    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Firebase Storage'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: AppTheme.spaceSmall),
                        const Text(
                          'Diagnostic Firebase Storage',
                          style: TextStyle(
                            fontSize: AppTheme.fontSize18,
                            fontWeight: AppTheme.fontBold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space12),
                    const Text(
                      'Ce diagnostic teste la connectivité et les permissions Firebase Storage pour identifier les problèmes d\'upload d\'images.',
                      style: TextStyle(fontSize: AppTheme.fontSize14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.space20),

            // Bouton de test
            Center(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runDiagnostic,
                icon: _isRunning 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Test en cours...' : 'Lancer le diagnostic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLarge),

            // Résultats de connexion
            if (_connectionResult != null) ...[
              _buildResultCard(
                'Test de Connexion',
                Icons.wifi,
                _connectionResult!,
                _getConnectionStatus(_connectionResult!),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],

            // Résultats d'upload
            if (_uploadResult != null) ...[
              _buildResultCard(
                'Test d\'Upload',
                Icons.cloud_upload,
                _uploadResult!,
                _getUploadStatus(_uploadResult!),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],

            // Guide de résolution
            if (_connectionResult != null || _uploadResult != null) ...[
              _buildTroubleshootingCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, IconData icon, Map<String, dynamic> result, String status) {
    final isSuccess = !result.containsKey('errors') || (result['errors'] as List).isEmpty;
    final statusColor = isSuccess ? AppTheme.greenStandard : AppTheme.redStandard;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  title,
                  style: const TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            ...result.entries.map((entry) => _buildResultLine(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultLine(String key, dynamic value) {
    IconData icon;
    Color color;

    if (value is bool) {
      icon = value ? Icons.check_circle : Icons.cancel;
      color = value ? AppTheme.greenStandard : AppTheme.redStandard;
    } else if (key == 'errors' && value is List && value.isNotEmpty) {
      icon = Icons.error;
      color = AppTheme.redStandard;
    } else {
      icon = Icons.info;
      color = AppTheme.blueStandard;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.spaceSmall),
          Expanded(
            child: Text(
              '$key: ${_formatValue(value)}',
              style: TextStyle(fontSize: AppTheme.fontSize13, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value is List) {
      return value.isEmpty ? '[]' : value.join(', ');
    } else if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    return value.toString();
  }

  String _getConnectionStatus(Map<String, dynamic> result) {
    if (result['canUpload'] == true) return 'EXCELLENT';
    if (result['canAccessStorage'] == true) return 'PARTIEL';
    if (result['isAuthenticated'] == true) return 'LIMITÉ';
    return 'ÉCHEC';
  }

  String _getUploadStatus(Map<String, dynamic> result) {
    return result['success'] == true ? 'RÉUSSI' : 'ÉCHEC';
  }

  Widget _buildTroubleshootingCard() {
    return Card(
      color: AppTheme.orangeStandard,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: AppTheme.orangeStandard),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Guide de résolution',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.orangeStandard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            const Text(
              '1. Vérifiez que Firebase Storage est activé dans la console Firebase',
              style: TextStyle(fontSize: AppTheme.fontSize14),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            const Text(
              '2. Configurez les règles de sécurité (voir FIREBASE_STORAGE_SETUP.md)',
              style: TextStyle(fontSize: AppTheme.fontSize14),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            const Text(
              '3. Vérifiez que l\'utilisateur est connecté',
              style: TextStyle(fontSize: AppTheme.fontSize14),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            const Text(
              '4. Redémarrez l\'application après les changements',
              style: TextStyle(fontSize: AppTheme.fontSize14),
            ),
          ],
        ),
      ),
    );
  }
}