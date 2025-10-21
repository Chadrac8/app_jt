import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/role.dart';
import '../models/permission.dart';
import '../providers/role_provider.dart';
import '../../../../theme.dart';

class RoleCreationDialog extends StatefulWidget {
  final Role? role; // null pour création, non-null pour édition
  
  const RoleCreationDialog({
    super.key,
    this.role,
  });

  @override
  State<RoleCreationDialog> createState() => _RoleCreationDialogState();
}

class _RoleCreationDialogState extends State<RoleCreationDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<String> _selectedPermissions = [];
  bool _isActive = true;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _initializeAnimations();
    _initializeForm();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
  }
  
  void _initializeForm() {
    if (widget.role != null) {
      _nameController.text = widget.role!.name;
      _descriptionController.text = widget.role!.description;
      _selectedPermissions = List<String>.from(widget.role!.permissions);
      _isActive = widget.role!.isActive;
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(
            maxHeight: 700,
            maxWidth: 600,
          ),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppTheme.spaceLarge),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: AppTheme.spaceLarge),
                      _buildPermissionsSection(),
                      const SizedBox(height: AppTheme.spaceLarge),
                      _buildStatusSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            widget.role == null ? Icons.add_circle : Icons.edit,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.role == null ? 'Créer un rôle' : 'Modifier le rôle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              Text(
                widget.role == null 
                    ? 'Définir un nouveau rôle avec ses permissions'
                    : 'Modifier les détails et permissions du rôle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grey600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de base',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du rôle *',
            hintText: 'Ex: Modérateur, Contributeur...',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du rôle est requis';
            }
            if (value.trim().length < 2) {
              return 'Le nom doit contenir au moins 2 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description *',
            hintText: 'Décrivez le rôle et ses responsabilités...',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            if (value.trim().length < 10) {
              return 'La description doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Permissions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: AppTheme.fontBold,
                ),
              ),
              const Spacer(),
              Text(
                '${_selectedPermissions.length} sélectionnée(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Consumer<RoleProvider>(
                builder: (context, roleProvider, child) {
                  final permissionsByModule = roleProvider.permissionsByModule;
                  
                  if (permissionsByModule.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: permissionsByModule.keys.length,
                    itemBuilder: (context, index) {
                      final module = permissionsByModule.keys.elementAt(index);
                      final permissions = permissionsByModule[module]!;
                      
                      return _buildModulePermissions(module, permissions);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulePermissions(String module, List<Permission> permissions) {
    final modulePermissionIds = permissions.map((p) => p.id).toList();
    final selectedInModule = _selectedPermissions.where((id) => 
        modulePermissionIds.contains(id)).toList();
    
    return ExpansionTile(
      title: Text(
        module,
        style: const TextStyle(fontWeight: AppTheme.fontBold),
      ),
      subtitle: Text(
        '${selectedInModule.length}/${permissions.length} sélectionnées',
        style: TextStyle(
          color: selectedInModule.length == permissions.length 
              ? AppTheme.grey600
              : AppTheme.grey600,
        ),
      ),
      trailing: Checkbox(
        value: selectedInModule.length == permissions.length 
            ? true 
            : selectedInModule.isEmpty 
                ? false 
                : null,
        tristate: true,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              // Sélectionner toutes les permissions du module
              for (final permission in permissions) {
                if (!_selectedPermissions.contains(permission.id)) {
                  _selectedPermissions.add(permission.id);
                }
              }
            } else {
              // Désélectionner toutes les permissions du module
              _selectedPermissions.removeWhere((id) => 
                  modulePermissionIds.contains(id));
            }
          });
        },
      ),
      children: permissions.map((permission) => 
          _buildPermissionTile(permission)).toList(),
    );
  }

  Widget _buildPermissionTile(Permission permission) {
    final isSelected = _selectedPermissions.contains(permission.id);
    
    return CheckboxListTile(
      title: Text(permission.name),
      subtitle: Text(
        permission.description,
        style: TextStyle(
          fontSize: AppTheme.fontSize12,
          color: AppTheme.grey600,
        ),
      ),
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _selectedPermissions.add(permission.id);
          } else {
            _selectedPermissions.remove(permission.id);
          }
        });
      },
      dense: true,
    );
  }

  Widget _buildStatusSection() {
    return Row(
      children: [
        Text(
          'Statut',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Switch(
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        Text(
          _isActive ? 'Actif' : 'Inactif',
          style: TextStyle(
            color: _isActive ? AppTheme.grey600 : AppTheme.grey600,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRole,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.role == null ? 'Créer' : 'Modifier'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une permission'),
          backgroundColor: AppTheme.orangeStandard,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      
      final role = Role(
        id: widget.role?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        permissions: _selectedPermissions,
        isActive: _isActive,
        createdAt: widget.role?.createdAt,
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.role == null) {
        success = await roleProvider.createRole(role);
      } else {
        success = await roleProvider.updateRole(widget.role!.id, role);
      }

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.role == null 
                  ? 'Rôle créé avec succès' 
                  : 'Rôle modifié avec succès',
            ),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      } else if (mounted) {
        final error = roleProvider.error ?? 'Une erreur est survenue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
