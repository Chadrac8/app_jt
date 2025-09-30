import 'package:flutter/material.dart';
import '../../../../theme.dart';

class RoleSettingsDialog extends StatefulWidget {
  const RoleSettingsDialog({super.key});

  @override
  State<RoleSettingsDialog> createState() => _RoleSettingsDialogState();
}

class _RoleSettingsDialogState extends State<RoleSettingsDialog> {
  bool _enableNotifications = true;
  bool _autoAssignRoles = false;
  bool _strictPermissionCheck = true;
  int _roleExpirationDays = 365;
  String _defaultRoleColor = '#4CAF50';

  final List<String> _availableColors = [
    '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
    '#F44336', '#795548', '#607D8B', '#E91E63',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paramètres des rôles',
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
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Notifications
                    _buildSection(
                      'Notifications',
                      Icons.notifications,
                      [
                        SwitchListTile(
                          title: const Text('Notifications activées'),
                          subtitle: const Text('Recevoir des notifications lors des changements de rôles'),
                          value: _enableNotifications,
                          onChanged: (value) => setState(() => _enableNotifications = value),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Section Automatisation
                    _buildSection(
                      'Automatisation',
                      Icons.auto_mode,
                      [
                        SwitchListTile(
                          title: const Text('Attribution automatique'),
                          subtitle: const Text('Attribuer automatiquement des rôles aux nouveaux utilisateurs'),
                          value: _autoAssignRoles,
                          onChanged: (value) => setState(() => _autoAssignRoles = value),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Section Sécurité
                    _buildSection(
                      'Sécurité',
                      Icons.security,
                      [
                        SwitchListTile(
                          title: const Text('Vérification stricte des permissions'),
                          subtitle: const Text('Appliquer une vérification stricte des permissions'),
                          value: _strictPermissionCheck,
                          onChanged: (value) => setState(() => _strictPermissionCheck = value),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Durée d\'expiration par défaut (jours)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Slider(
                          value: _roleExpirationDays.toDouble(),
                          min: 30,
                          max: 730,
                          divisions: 23,
                          label: '$_roleExpirationDays jours',
                          onChanged: (value) => setState(() => _roleExpirationDays = value.round()),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Section Apparence
                    _buildSection(
                      'Apparence',
                      Icons.palette,
                      [
                        Text(
                          'Couleur par défaut des nouveaux rôles',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _availableColors.map((color) {
                            final isSelected = _defaultRoleColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _defaultRoleColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                                  border: isSelected
                                      ? Border.all(color: AppTheme.black100, width: 3)
                                      : Border.all(color: AppTheme.grey300!),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: AppTheme.white100)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Sauvegarder les paramètres
                    _saveSettings();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Paramètres sauvegardés avec succès'),
                        backgroundColor: AppTheme.greenStandard,
                      ),
                    );
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
  }
}
