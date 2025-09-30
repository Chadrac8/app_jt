import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/role_template_model.dart';
import '../models/permission_model.dart';
import '../providers/role_template_provider.dart';
import '../providers/permission_provider.dart';
import '../../../../theme.dart';

/// Dialog de création/édition de template de rôle
class RoleTemplateFormDialog extends StatefulWidget {
  final RoleTemplate? template;
  final String? initialCategory;

  const RoleTemplateFormDialog({
    super.key,
    this.template,
    this.initialCategory,
  });

  @override
  State<RoleTemplateFormDialog> createState() => _RoleTemplateFormDialogState();
}

class _RoleTemplateFormDialogState extends State<RoleTemplateFormDialog>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs de base
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // État du formulaire
  String _selectedCategory = 'member';
  String _selectedIcon = 'admin_panel_settings';
  String _selectedColor = '#2196F3';
  List<String> _selectedPermissions = [];
  Map<String, dynamic> _configuration = {};
  bool _isLoading = false;

  // Données pour les icônes et couleurs
  static const Map<String, IconData> _availableIcons = {
    'admin_panel_settings': Icons.admin_panel_settings,
    'supervisor_account': Icons.supervisor_account,
    'verified_user': Icons.verified_user,
    'edit': Icons.edit,
    'church': Icons.church,
    'account_balance': Icons.account_balance,
    'event': Icons.event,
    'person': Icons.person,
    'visibility': Icons.visibility,
    'security': Icons.security,
    'group': Icons.group,
    'work': Icons.work,
    'school': Icons.school,
    'music_note': Icons.music_note,
    'book': Icons.book,
    'favorite': Icons.favorite,
  };

  static const List<String> _availableColors = [
    '#2196F3', // Bleu
    '#4CAF50', // Vert
    '#FF9800', // Orange
    '#F44336', // Rouge
    '#9C27B0', // Violet
    '#607D8B', // Bleu-gris
    '#795548', // Marron
    '#FF5722', // Rouge-orange
    '#3F51B5', // Indigo
    '#009688', // Teal
    '#FFC107', // Ambre
    '#E91E63', // Pink
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    if (widget.template != null) {
      _loadExistingTemplate();
    } else if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadExistingTemplate() {
    final template = widget.template!;
    _nameController.text = template.name;
    _descriptionController.text = template.description;
    _selectedCategory = template.category;
    _selectedIcon = template.iconName;
    _selectedColor = template.colorCode;
    _selectedPermissions = List.from(template.permissionIds);
    _configuration = Map.from(template.configuration);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.template != null ? 'Modifier Template' : 'Nouveau Template'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.info), text: 'Informations'),
                Tab(icon: Icon(Icons.security), text: 'Permissions'),
                Tab(icon: Icon(Icons.settings), text: 'Configuration'),
                Tab(icon: Icon(Icons.preview), text: 'Aperçu'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInformationTab(),
              _buildPermissionsTab(),
              _buildConfigurationTab(),
              _buildPreviewTab(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildInformationTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de Base',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Nom du template
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du template *',
                helperText: 'Nom descriptif et unique pour le template',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Le nom est obligatoire';
                }
                if (value!.length < 3) {
                  return 'Le nom doit contenir au moins 3 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                helperText: 'Description détaillée du rôle et de ses responsabilités',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'La description est obligatoire';
                }
                if (value!.length < 10) {
                  return 'La description doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Catégorie
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie *',
                helperText: 'Catégorie principale du template',
                border: OutlineInputBorder(),
              ),
              items: TemplateCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'La catégorie est obligatoire';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Apparence',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Sélection d'icône
            Text(
              'Icône',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.entries.map((entry) {
                final isSelected = _selectedIcon == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = entry.key;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      entry.value,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Sélection de couleur
            Text(
              'Couleur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((colorCode) {
                final isSelected = _selectedColor == colorCode;
                final color = Color(int.parse('FF${colorCode.substring(1)}', radix: 16));
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorCode;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected 
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final permissionsByModule = provider.permissionsByModule;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Permissions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text('${_selectedPermissions.length} sélectionnées'),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez les permissions qui seront incluses dans ce template de rôle.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Actions rapides
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedPermissions.clear();
                      });
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Tout désélectionner'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedPermissions.clear();
                        _selectedPermissions.addAll(provider.permissions.map((p) => p.id));
                      });
                    },
                    icon: const Icon(Icons.select_all),
                    label: const Text('Tout sélectionner'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Liste des permissions par module
              ...permissionsByModule.entries.map((entry) {
                final moduleId = entry.key;
                final modulePermissions = entry.value;
                final selectedCount = modulePermissions
                    .where((p) => _selectedPermissions.contains(p.id))
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      _getModuleName(moduleId),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$selectedCount/${modulePermissions.length} permissions sélectionnées'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: modulePermissions.map((permission) {
                            final isSelected = _selectedPermissions.contains(permission.id);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(permission.name),
                              subtitle: Text(permission.description),
                              secondary: _getPermissionLevelIcon(permission.level),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected ?? false) {
                                    _selectedPermissions.add(permission.id);
                                  } else {
                                    _selectedPermissions.remove(permission.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Avancée',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paramètres spécifiques pour ce template de rôle.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Nombre maximum d'utilisateurs
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre max d\'utilisateurs',
                    helperText: 'Laissez vide ou -1 pour illimité',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: (_configuration['maxUsers'] as int?)?.toString() ?? '',
                  onChanged: (value) {
                    _configuration['maxUsers'] = value.isEmpty ? null : int.tryParse(value) ?? -1;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Modules restreints
          Text(
            'Modules Restreints',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppTheme.fontMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Modules auxquels ce rôle ne devrait pas avoir accès.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          
          // TODO: Implémenter la sélection de modules restreints
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Sélection de modules restreints à implémenter',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Options diverses
          CheckboxListTile(
            title: const Text('Requiert une approbation'),
            subtitle: const Text('L\'assignation de ce rôle nécessite une validation'),
            value: _configuration['requireApproval'] ?? false,
            onChanged: (value) {
              setState(() {
                _configuration['requireApproval'] = value ?? false;
              });
            },
          ),
          
          CheckboxListTile(
            title: const Text('Expiration automatique'),
            subtitle: const Text('Ce rôle expire automatiquement après une période'),
            value: _configuration['autoExpiry'] ?? false,
            onChanged: (value) {
              setState(() {
                _configuration['autoExpiry'] = value ?? false;
                if (value == true && _configuration['expiryDays'] == null) {
                  _configuration['expiryDays'] = 365;
                }
              });
            },
          ),
          
          if (_configuration['autoExpiry'] == true) ...[
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Durée d\'expiration (jours)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              initialValue: (_configuration['expiryDays'] as int?)?.toString() ?? '365',
              onChanged: (value) {
                _configuration['expiryDays'] = int.tryParse(value) ?? 365;
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Audit requis'),
            subtitle: const Text('Toutes les actions avec ce rôle sont auditées'),
            value: _configuration['auditRequired'] ?? false,
            onChanged: (value) {
              setState(() {
                _configuration['auditRequired'] = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    // Créer un template temporaire pour l'aperçu
    final previewTemplate = RoleTemplate(
      id: 'preview',
      name: _nameController.text.isNotEmpty ? _nameController.text : 'Nom du template',
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : 'Description du template',
      category: _selectedCategory,
      permissionIds: _selectedPermissions,
      configuration: _configuration,
      iconName: _selectedIcon,
      colorCode: _selectedColor,
      createdAt: DateTime.now(),
      createdBy: 'current_user',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu du Template',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voici à quoi ressemblera votre template une fois créé.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Card d'aperçu du template
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: previewTemplate.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: previewTemplate.color.withOpacity(0.3)),
                        ),
                        child: Icon(previewTemplate.iconData, color: previewTemplate.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previewTemplate.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              TemplateCategory.fromId(previewTemplate.category).displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(previewTemplate.description),
                  const SizedBox(height: 16),
                  
                  // Informations sur les permissions
                  Row(
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${previewTemplate.permissionIds.length} permission(s)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  
                  if (_configuration.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._configuration.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text('${entry.value}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résumé des validations
          Card(
            color: _isFormValid() ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isFormValid() ? Icons.check_circle : Icons.error,
                        color: _isFormValid() ? AppTheme.success : AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFormValid() ? 'Template valide' : 'Template invalide',
                        style: TextStyle(
                          fontWeight: AppTheme.fontBold,
                          color: _isFormValid() ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._getValidationMessages().map((message) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            message.startsWith('✓') ? Icons.check : Icons.close,
                            size: 16,
                            color: message.startsWith('✓') ? AppTheme.success : AppTheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(message.substring(2))),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          if (widget.template != null && !widget.template!.isSystemTemplate)
            TextButton.icon(
              onPressed: _isLoading ? null : _deleteTemplate,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: (_isFormValid() && !_isLoading) ? _saveTemplate : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.template != null ? 'Modifier' : 'Créer'),
          ),
        ],
      ),
    );
  }

  String _getModuleName(String moduleId) {
    // TODO: Récupérer le nom réel du module depuis un service
    switch (moduleId) {
      case 'users': return 'Utilisateurs';
      case 'content': return 'Contenu';
      case 'events': return 'Événements';
      case 'reports': return 'Rapports';
      case 'settings': return 'Paramètres';
      default: return moduleId.toUpperCase();
    }
  }

  Widget _getPermissionLevelIcon(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.read:
        return Icon(Icons.visibility, color: AppTheme.info, size: 16);
      case PermissionLevel.write:
        return Icon(Icons.edit, color: AppTheme.warning, size: 16);
      case PermissionLevel.create:
        return Icon(Icons.add_circle, color: AppTheme.success, size: 16);
      case PermissionLevel.delete:
        return Icon(Icons.delete, color: AppTheme.error, size: 16);
      case PermissionLevel.admin:
        return Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor, size: 16);
    }
  }

  bool _isFormValid() {
    return _nameController.text.isNotEmpty &&
           _descriptionController.text.isNotEmpty &&
           _selectedPermissions.isNotEmpty;
  }

  List<String> _getValidationMessages() {
    final messages = <String>[];
    
    if (_nameController.text.isNotEmpty) {
      messages.add('✓ Nom renseigné');
    } else {
      messages.add('✗ Nom requis');
    }
    
    if (_descriptionController.text.isNotEmpty) {
      messages.add('✓ Description renseignée');
    } else {
      messages.add('✗ Description requise');
    }
    
    if (_selectedPermissions.isNotEmpty) {
      messages.add('✓ ${_selectedPermissions.length} permission(s) sélectionnée(s)');
    } else {
      messages.add('✗ Au moins une permission requise');
    }
    
    return messages;
  }

  Future<void> _saveTemplate() async {
    if (!_isFormValid()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<RoleTemplateProvider>(context, listen: false);
      
      final template = RoleTemplate(
        id: widget.template?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        permissionIds: _selectedPermissions,
        configuration: _configuration,
        iconName: _selectedIcon,
        colorCode: _selectedColor,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        createdBy: widget.template?.createdBy ?? 'current_user_id',
        updatedAt: widget.template != null ? DateTime.now() : null,
        updatedBy: widget.template != null ? 'current_user_id' : null,
      );

      if (widget.template != null) {
        await provider.updateTemplate(template);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template modifié avec succès')),
          );
        }
      } else {
        final templateId = await provider.createTemplate(template);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Template créé avec succès (ID: $templateId)')),
          );
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTemplate() async {
    if (widget.template == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le template "${widget.template!.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<RoleTemplateProvider>(context, listen: false);
      await provider.deleteTemplate(widget.template!.id, 'current_user_id');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template supprimé avec succès')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}