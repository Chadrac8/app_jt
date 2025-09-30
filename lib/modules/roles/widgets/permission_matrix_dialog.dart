import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../providers/permission_provider.dart';
import '../../../../theme.dart';

class PermissionMatrixDialog extends StatefulWidget {
  const PermissionMatrixDialog({super.key});

  @override
  State<PermissionMatrixDialog> createState() => _PermissionMatrixDialogState();
}

class _PermissionMatrixDialogState extends State<PermissionMatrixDialog> {
  String _selectedModule = '';
  bool _showOnlyActiveRoles = true;
  bool _showOnlySystemRoles = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildMatrix(),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.grid_view, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Matrice des Permissions',
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
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Sélection de module
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedModule.isEmpty ? null : _selectedModule,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par module',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Tous les modules'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Tous les modules'),
                      ),
                      ...AppModule.allModules.map((module) {
                        return DropdownMenuItem(
                          value: module.id,
                          child: Row(
                            children: [
                              Icon(_getModuleIcon(module.icon), size: 20),
                              const SizedBox(width: 8),
                              Text(module.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedModule = value ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Filtres de rôles
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    title: const Text('Rôles actifs seulement'),
                    value: _showOnlyActiveRoles,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyActiveRoles = value ?? true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    title: const Text('Rôles système seulement'),
                    value: _showOnlySystemRoles,
                    onChanged: (value) {
                      setState(() {
                        _showOnlySystemRoles = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        final roles = _getFilteredRoles(provider.roles);
        final permissions = _getFilteredPermissions(provider.permissions);
        
        if (roles.isEmpty || permissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_alt_off, size: 64, color: AppTheme.grey400),
                const SizedBox(height: 16),
                Text(
                  'Aucune donnée correspondant aux filtres',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return Card(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 60,
                dataRowHeight: 48,
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 200,
                      child: Text(
                        'Permission',
                        style: TextStyle(fontWeight: AppTheme.fontBold),
                      ),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Module',
                      style: TextStyle(fontWeight: AppTheme.fontBold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Niveau',
                      style: TextStyle(fontWeight: AppTheme.fontBold),
                    ),
                  ),
                  ...roles.map((role) {
                    return DataColumn(
                      label: SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _parseColor(role.color).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _parseIcon(role.icon),
                                color: _parseColor(role.color),
                                size: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role.name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: AppTheme.fontBold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
                rows: permissions.map((permission) {
                  final module = AppModule.findById(permission.module);
                  
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                permission.name,
                                style: const TextStyle(fontWeight: AppTheme.fontMedium),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                permission.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.grey600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getModuleIcon(module?.icon ?? ''),
                              size: 16,
                              color: AppTheme.grey600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              module?.name ?? permission.module,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPermissionLevelColor(permission.level).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPermissionLevelIcon(permission.level),
                                size: 12,
                                color: _getPermissionLevelColor(permission.level),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                permission.level.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: AppTheme.fontBold,
                                  color: _getPermissionLevelColor(permission.level),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...roles.map((role) {
                        final hasPermission = role.hasPermission(permission.id);
                        
                        return DataCell(
                          Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: hasPermission
                                    ? AppTheme.grey100
                                    : AppTheme.grey100,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                border: Border.all(
                                  color: hasPermission
                                      ? AppTheme.grey400
                                      : AppTheme.grey300!,
                                ),
                              ),
                              child: Icon(
                                hasPermission ? Icons.check : Icons.close,
                                size: 16,
                                color: hasPermission
                                    ? AppTheme.grey700
                                    : AppTheme.grey500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _exportMatrix,
          icon: const Icon(Icons.download),
          label: const Text('Exporter'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _printMatrix,
          icon: const Icon(Icons.print),
          label: const Text('Imprimer'),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  List<Role> _getFilteredRoles(List<Role> roles) {
    var filtered = roles;
    
    if (_showOnlyActiveRoles) {
      filtered = filtered.where((role) => role.isActive).toList();
    }
    
    if (_showOnlySystemRoles) {
      filtered = filtered.where((role) => role.isSystemRole).toList();
    }
    
    return filtered;
  }

  List<Permission> _getFilteredPermissions(List<Permission> permissions) {
    var filtered = permissions;
    
    if (_selectedModule.isNotEmpty) {
      filtered = filtered.where((perm) => perm.module == _selectedModule).toList();
    }
    
    // Trier par module puis par niveau
    filtered.sort((a, b) {
      final moduleCompare = a.module.compareTo(b.module);
      if (moduleCompare != 0) return moduleCompare;
      return a.level.index.compareTo(b.level.index);
    });
    
    return filtered;
  }

  void _exportMatrix() async {
    try {
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      final roles = _getFilteredRoles(provider.roles);
      final permissions = _getFilteredPermissions(provider.permissions);
      
      // Créer le contenu CSV
      final csvContent = _generateMatrixCSV(roles, permissions);
      
      // Copier dans le presse-papiers
      await Clipboard.setData(ClipboardData(text: csvContent));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matrice des permissions exportée dans le presse-papiers (format CSV)'),
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
  
  String _generateMatrixCSV(List<Role> roles, List<Permission> permissions) {
    final buffer = StringBuffer();
    
    // En-têtes
    buffer.write('Permission,Module,Niveau');
    for (final role in roles) {
      buffer.write(',${role.name}');
    }
    buffer.writeln();
    
    // Lignes de permissions
    for (final permission in permissions) {
      final module = AppModule.findById(permission.module);
      buffer.write('${permission.name},${module?.name ?? permission.module},${permission.level.displayName}');
      
      for (final role in roles) {
        final hasPermission = role.hasPermission(permission.id);
        buffer.write(',${hasPermission ? "✓" : "✗"}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  void _printMatrix() async {
    try {
      final provider = Provider.of<PermissionProvider>(context, listen: false);
      final roles = _getFilteredRoles(provider.roles);
      final permissions = _getFilteredPermissions(provider.permissions);
      
      // Créer le contenu d'impression formaté
      final printContent = _generatePrintableMatrix(roles, permissions);
      
      // Afficher le dialogue d'aperçu d'impression
      await _showPrintPreview(printContent);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la préparation d\'impression: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }
  
  String _generatePrintableMatrix(List<Role> roles, List<Permission> permissions) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    
    // En-tête du document
    buffer.writeln('MATRICE DES PERMISSIONS - JUBILÉ TABERNACLE');
    buffer.writeln('Généré le $dateStr');
    buffer.writeln('=' * 80);
    buffer.writeln();
    
    // Statistiques
    buffer.writeln('STATISTIQUES:');
    buffer.writeln('- Rôles: ${roles.length}');
    buffer.writeln('- Permissions: ${permissions.length}');
    buffer.writeln('- Modules concernés: ${permissions.map((p) => p.module).toSet().length}');
    buffer.writeln();
    
    // Matrice détaillée
    buffer.writeln('MATRICE DÉTAILLÉE:');
    buffer.writeln('-' * 80);
    
    // Grouper par module
    final permissionsByModule = <String, List<Permission>>{};
    for (final permission in permissions) {
      permissionsByModule.putIfAbsent(permission.module, () => []).add(permission);
    }
    
    for (final moduleId in permissionsByModule.keys) {
      final module = AppModule.findById(moduleId);
      buffer.writeln('MODULE: ${module?.name ?? moduleId}');
      buffer.writeln();
      
      // En-têtes des rôles
      buffer.write('${'Permission'.padRight(30)}');
      for (final role in roles) {
        buffer.write(role.name.padRight(12));
      }
      buffer.writeln();
      buffer.writeln('-' * (30 + (roles.length * 12)));
      
      // Permissions pour ce module
      for (final permission in permissionsByModule[moduleId]!) {
        buffer.write(permission.name.length > 30 
          ? '${permission.name.substring(0, 27)}...'
          : permission.name.padRight(30));
        
        for (final role in roles) {
          final hasPermission = role.hasPermission(permission.id);
          buffer.write((hasPermission ? '✓' : '✗').padRight(12));
        }
        buffer.writeln();
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
  
  Future<void> _showPrintPreview(String content) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.print),
              SizedBox(width: 8),
              Text('Aperçu d\'impression'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contenu copié dans le presse-papiers pour impression'),
                    backgroundColor: AppTheme.greenStandard,
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier'),
            ),
          ],
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'security': return Icons.security;
      case 'person': return Icons.person;
      case 'group': return Icons.group;
      case 'manage_accounts': return Icons.manage_accounts;
      case 'verified_user': return Icons.verified_user;
      case 'shield': return Icons.shield;
      default: return Icons.person;
    }
  }

  IconData _getModuleIcon(String iconName) {
    switch (iconName) {
      case 'dashboard': return Icons.dashboard;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'event': return Icons.event;
      case 'church': return Icons.church;
      case 'task': return Icons.task;
      case 'article': return Icons.article;
      case 'monetization_on': return Icons.monetization_on;
      case 'music_note': return Icons.music_note;
      case 'menu_book': return Icons.menu_book;
      case 'description': return Icons.description;
      case 'web': return Icons.web;
      case 'favorite': return Icons.favorite;
      case 'settings': return Icons.settings;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      default: return Icons.extension;
    }
  }

  IconData _getPermissionLevelIcon(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read: return Icons.visibility;
      case PermissionLevel.write: return Icons.edit;
      case PermissionLevel.create: return Icons.add;
      case PermissionLevel.delete: return Icons.delete;
      case PermissionLevel.admin: return Icons.admin_panel_settings;
    }
  }

  Color _getPermissionLevelColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read: return AppTheme.blueStandard;
      case PermissionLevel.write: return AppTheme.greenStandard;
      case PermissionLevel.create: return AppTheme.orangeStandard;
      case PermissionLevel.delete: return AppTheme.redStandard;
      case PermissionLevel.admin: return Colors.purple;
    }
  }
}
