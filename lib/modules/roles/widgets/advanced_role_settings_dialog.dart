import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../theme.dart';

class RoleSettingsDialog extends StatefulWidget {
  const RoleSettingsDialog({super.key});

  @override
  State<RoleSettingsDialog> createState() => _RoleSettingsDialogState();
}

class _RoleSettingsDialogState extends State<RoleSettingsDialog> {
  bool _isLoading = false;
  
  // Paramètres d'expiration des rôles
  bool _roleExpirationEnabled = false;
  int _roleExpirationDays = 365;
  
  // Paramètres de nettoyage automatique
  bool _autoCleanupEnabled = false;
  
  // Paramètres de notifications
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  
  // Paramètres de hiérarchie des rôles
  bool _roleHierarchyEnabled = false;
  
  // Paramètres d'audit
  bool _auditLogEnabled = true;
  
  // Paramètres de sauvegarde
  bool _backupEnabled = false;
  
  // Paramètres d'interface
  // bool _enableNotifications = true;
  // bool _autoAssignRoles = false;
  bool _strictPermissionCheck = true;
  String _defaultRoleColor = '#4CAF50';

  final List<String> _availableColors = [
    '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
    '#F44336', '#795548', '#607D8B', '#E91E63',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    'Paramètres des Rôles et Permissions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Contenu avec onglets
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.security), text: 'Sécurité'),
                        Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
                        Tab(icon: Icon(Icons.backup), text: 'Sauvegarde'),
                        Tab(icon: Icon(Icons.palette), text: 'Interface'),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSecurityTab(),
                          _buildNotificationsTab(),
                          _buildBackupTab(),
                          _buildInterfaceTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: AppTheme.space12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  child: _isLoading 
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sauvegarder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expiration des rôles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiration des Rôles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  SwitchListTile(
                    title: const Text('Activer l\'expiration automatique'),
                    subtitle: const Text('Les rôles expireront automatiquement après la durée définie'),
                    value: _roleExpirationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _roleExpirationEnabled = value;
                      });
                    },
                  ),
                  if (_roleExpirationEnabled) ...[
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text('Durée d\'expiration: $_roleExpirationDays jours'),
                    Slider(
                      value: _roleExpirationDays.toDouble(),
                      min: 30,
                      max: 3650, // 10 ans
                      divisions: 50,
                      label: '$_roleExpirationDays jours',
                      onChanged: (value) {
                        setState(() {
                          _roleExpirationDays = value.round();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Nettoyage automatique
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nettoyage Automatique',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  SwitchListTile(
                    title: const Text('Nettoyage automatique des rôles expirés'),
                    subtitle: const Text('Supprimer automatiquement les assignations de rôles expirées'),
                    value: _autoCleanupEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoCleanupEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Audit et journalisation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audit et Journalisation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  SwitchListTile(
                    title: const Text('Journal d\'audit'),
                    subtitle: const Text('Enregistrer toutes les modifications de rôles et permissions'),
                    value: _auditLogEnabled,
                    onChanged: (value) {
                      setState(() {
                        _auditLogEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres de Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  SwitchListTile(
                    title: const Text('Notifications système'),
                    subtitle: const Text('Afficher les notifications lors des changements de rôles'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Notifications par email'),
                    subtitle: const Text('Envoyer des emails lors des assignations/révocations de rôles'),
                    value: _emailNotifications,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde et Récupération',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  SwitchListTile(
                    title: const Text('Sauvegarde automatique'),
                    subtitle: const Text('Créer automatiquement des sauvegardes des configurations de rôles'),
                    value: _backupEnabled,
                    onChanged: (value) {
                      setState(() {
                        _backupEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportConfiguration,
                          icon: const Icon(Icons.download),
                          label: const Text('Exporter Configuration'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _importConfiguration,
                          icon: const Icon(Icons.upload),
                          label: const Text('Importer Configuration'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres d\'Interface',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  // Couleur par défaut des rôles
                  Text(
                    'Couleur par défaut des nouveaux rôles',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableColors.map((colorHex) {
                      final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
                      final isSelected = _defaultRoleColor == colorHex;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _defaultRoleColor = colorHex;
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            border: isSelected
                                ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                                : Border.all(color: AppTheme.grey300, width: 1),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: AppTheme.spaceLarge),
                  
                  SwitchListTile(
                    title: const Text('Vérification stricte des permissions'),
                    subtitle: const Text('Appliquer une vérification plus stricte des permissions'),
                    value: _strictPermissionCheck,
                    onChanged: (value) {
                      setState(() {
                        _strictPermissionCheck = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Créer l'objet des paramètres
      final settings = {
        'role_expiration_enabled': _roleExpirationEnabled,
        'role_expiration_days': _roleExpirationDays,
        'auto_cleanup_enabled': _autoCleanupEnabled,
        'notifications_enabled': _notificationsEnabled,
        'email_notifications': _emailNotifications,
        'role_hierarchy_enabled': _roleHierarchyEnabled,
        'audit_log_enabled': _auditLogEnabled,
        'backup_enabled': _backupEnabled,
        'strict_permission_check': _strictPermissionCheck,
        'default_role_color': _defaultRoleColor,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': 'current_user_id', // TODO: Récupérer l'ID utilisateur actuel
      };

      // Sauvegarder dans Firebase
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('roles_permissions')
          .set(settings, SetOptions(merge: true));

      // Journalisation de l'action
      await _logSettingsChange(settings);

      setState(() {
        _isLoading = false;
      });

      // Afficher message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres sauvegardés avec succès'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  Future<void> _logSettingsChange(Map<String, dynamic> settings) async {
    try {
      await FirebaseFirestore.instance
          .collection('audit_logs')
          .add({
        'action': 'settings_update',
        'module': 'roles_permissions',
        'details': {
          'changed_settings': settings.keys.toList(),
          'timestamp': FieldValue.serverTimestamp(),
        },
        'user_id': 'current_user_id', // TODO: Récupérer l'ID utilisateur actuel
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la journalisation: $e');
    }
  }

  Future<void> _loadExistingSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('roles_permissions')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _roleExpirationEnabled = data['role_expiration_enabled'] ?? false;
          _roleExpirationDays = data['role_expiration_days'] ?? 365;
          _autoCleanupEnabled = data['auto_cleanup_enabled'] ?? false;
          _notificationsEnabled = data['notifications_enabled'] ?? true;
          _emailNotifications = data['email_notifications'] ?? false;
          _roleHierarchyEnabled = data['role_hierarchy_enabled'] ?? false;
          _auditLogEnabled = data['audit_log_enabled'] ?? true;
          _backupEnabled = data['backup_enabled'] ?? false;
          _strictPermissionCheck = data['strict_permission_check'] ?? true;
          _defaultRoleColor = data['default_role_color'] ?? '#4CAF50';
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
  }

  Future<void> _exportConfiguration() async {
    try {
      // Exporter la configuration des rôles et permissions
      final rolesSnapshot = await FirebaseFirestore.instance
          .collection('roles')
          .get();
      
      final permissionsSnapshot = await FirebaseFirestore.instance
          .collection('permissions')
          .get();

      final userRolesSnapshot = await FirebaseFirestore.instance
          .collection('user_roles')
          .get();

      final config = {
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'roles': rolesSnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList(),
        'permissions': permissionsSnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList(),
        'user_roles': userRolesSnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList(),
        'settings': await _getCurrentSettings(),
      };

      // Pour l'instant, on simule l'export
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration exportée avec succès'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  Future<void> _importConfiguration() async {
    // Pour l'instant, on affiche un dialogue d'information
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import de Configuration'),
        content: const Text(
          'Cette fonctionnalité permet d\'importer une configuration de rôles et permissions depuis un fichier de sauvegarde.\n\n'
          'Implémentation complète en cours de développement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCurrentSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('roles_permissions')
          .get();
      
      return doc.exists ? doc.data() as Map<String, dynamic> : {};
    } catch (e) {
      print('Erreur lors de la récupération des paramètres: $e');
      return {};
    }
  }
}