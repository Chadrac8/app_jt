import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/role_template_model.dart';
import '../providers/role_template_provider.dart';
import '../../../../theme.dart';

/// Widget de sélection de template de rôle
class RoleTemplateSelectorWidget extends StatefulWidget {
  final RoleTemplate? selectedTemplate;
  final ValueChanged<RoleTemplate?>? onTemplateSelected;
  final String? category;
  final bool allowMultipleSelection;
  final List<String>? excludeTemplateIds;
  final bool showSystemTemplates;
  final bool showCustomTemplates;

  const RoleTemplateSelectorWidget({
    super.key,
    this.selectedTemplate,
    this.onTemplateSelected,
    this.category,
    this.allowMultipleSelection = false,
    this.excludeTemplateIds,
    this.showSystemTemplates = true,
    this.showCustomTemplates = true,
  });

  @override
  State<RoleTemplateSelectorWidget> createState() => _RoleTemplateSelectorWidgetState();
}

class _RoleTemplateSelectorWidgetState extends State<RoleTemplateSelectorWidget> {
  late RoleTemplateProvider _provider;
  String _searchQuery = '';
  String _selectedCategory = '';
  List<RoleTemplate> _selectedTemplates = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category ?? '';
    
    if (widget.selectedTemplate != null) {
      _selectedTemplates = [widget.selectedTemplate!];
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = Provider.of<RoleTemplateProvider>(context, listen: false);
      if (!_provider.isInitialized) {
        _provider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleTemplateProvider>(
      builder: (context, provider, child) {
        _provider = provider;
        
        if (provider.isLoading && !provider.isInitialized) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final filteredTemplates = _getFilteredTemplates(provider.templates);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchAndFilter(),
                const SizedBox(height: 16),
                _buildTemplatesList(filteredTemplates),
                if (_selectedTemplates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSelectedTemplatesSection(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.admin_panel_settings,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Sélection de Template',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: AppTheme.fontBold,
            color: AppTheme.primaryColor,
          ),
        ),
        const Spacer(),
        if (widget.allowMultipleSelection)
          Chip(
            label: Text('${_selectedTemplates.length} sélectionné(s)'),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Rechercher un template...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Toutes'),
                  ),
                  ...TemplateCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(category.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilterChip(
              label: const Text('Système'),
              selected: widget.showSystemTemplates,
              onSelected: null, // Désactivé car contrôlé par le widget parent
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Personnalisés'),
              selected: widget.showCustomTemplates,
              onSelected: null, // Désactivé car contrôlé par le widget parent
            ),
            const Spacer(),
            if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty)
              ActionChip(
                label: const Text('Effacer'),
                avatar: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = widget.category ?? '';
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplatesList(List<RoleTemplate> templates) {
    if (templates.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Aucun template trouvé',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                'Modifiez vos critères de recherche',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return _buildTemplateListTile(template);
        },
      ),
    );
  }

  Widget _buildTemplateListTile(RoleTemplate template) {
    final isSelected = _selectedTemplates.any((t) => t.id == template.id);
    final isExcluded = widget.excludeTemplateIds?.contains(template.id) ?? false;

    return ListTile(
      enabled: !isExcluded,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isExcluded 
              ? Colors.grey.withOpacity(0.1)
              : template.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExcluded 
                ? Colors.grey.withOpacity(0.3)
                : template.color.withOpacity(0.3),
          ),
        ),
        child: Icon(
          template.iconData, 
          color: isExcluded ? Colors.grey : template.color,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              template.name,
              style: TextStyle(
                fontWeight: isSelected ? AppTheme.fontBold : AppTheme.fontMedium,
                color: isExcluded ? Colors.grey : null,
              ),
            ),
          ),
          if (template.isSystemTemplate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Text(
                'SYS',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.info,
                  fontWeight: AppTheme.fontBold,
                ),
              ),
            ),
          if (isExcluded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Text(
                'EXCLU',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isExcluded ? Colors.grey : null),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                TemplateCategory.fromId(template.category).icon,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                TemplateCategory.fromId(template.category).displayName,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.security,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${template.permissionIds.length} perms',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: widget.allowMultipleSelection
          ? Checkbox(
              value: isSelected,
              onChanged: isExcluded ? null : (selected) {
                _handleTemplateSelection(template, selected ?? false);
              },
            )
          : isSelected 
              ? Icon(Icons.radio_button_checked, color: AppTheme.primaryColor)
              : const Icon(Icons.radio_button_unchecked),
      onTap: isExcluded ? null : () {
        if (widget.allowMultipleSelection) {
          _handleTemplateSelection(template, !isSelected);
        } else {
          _handleTemplateSelection(template, true);
        }
      },
    );
  }

  Widget _buildSelectedTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Templates Sélectionnés',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedTemplates.map((template) {
            return Chip(
              avatar: Icon(template.iconData, size: 16),
              label: Text(template.name),
              backgroundColor: template.color.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                _handleTemplateSelection(template, false);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  List<RoleTemplate> _getFilteredTemplates(List<RoleTemplate> templates) {
    var filtered = templates.where((template) {
      // Filtre par type de template
      if (!widget.showSystemTemplates && template.isSystemTemplate) {
        return false;
      }
      if (!widget.showCustomTemplates && !template.isSystemTemplate) {
        return false;
      }
      
      return true;
    }).toList();

    // Filtre par catégorie
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((template) => 
          template.category == _selectedCategory).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((template) {
        return template.name.toLowerCase().contains(query) ||
               template.description.toLowerCase().contains(query) ||
               template.permissionIds.any((perm) => 
                   perm.toLowerCase().contains(query));
      }).toList();
    }

    // Tri par nom
    filtered.sort((a, b) => a.name.compareTo(b.name));

    return filtered;
  }

  void _handleTemplateSelection(RoleTemplate template, bool selected) {
    setState(() {
      if (widget.allowMultipleSelection) {
        if (selected) {
          if (!_selectedTemplates.any((t) => t.id == template.id)) {
            _selectedTemplates.add(template);
          }
        } else {
          _selectedTemplates.removeWhere((t) => t.id == template.id);
        }
      } else {
        if (selected) {
          _selectedTemplates = [template];
        } else {
          _selectedTemplates = [];
        }
      }
    });

    // Notifier le widget parent
    if (widget.onTemplateSelected != null) {
      if (widget.allowMultipleSelection) {
        // Pour la sélection multiple, on ne notifie que le dernier sélectionné
        widget.onTemplateSelected!(_selectedTemplates.isNotEmpty ? _selectedTemplates.last : null);
      } else {
        widget.onTemplateSelected!(_selectedTemplates.isNotEmpty ? _selectedTemplates.first : null);
      }
    }
  }
}

/// Dialog de sélection de template
class RoleTemplateSelectionDialog extends StatefulWidget {
  final RoleTemplate? initialSelection;
  final String? category;
  final bool allowMultipleSelection;
  final List<String>? excludeTemplateIds;

  const RoleTemplateSelectionDialog({
    super.key,
    this.initialSelection,
    this.category,
    this.allowMultipleSelection = false,
    this.excludeTemplateIds,
  });

  @override
  State<RoleTemplateSelectionDialog> createState() => _RoleTemplateSelectionDialogState();
}

class _RoleTemplateSelectionDialogState extends State<RoleTemplateSelectionDialog> {
  RoleTemplate? _selectedTemplate;
  List<RoleTemplate> _selectedTemplates = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null) {
      _selectedTemplate = widget.initialSelection;
      _selectedTemplates = [widget.initialSelection!];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Sélectionner un Template',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RoleTemplateSelectorWidget(
                selectedTemplate: _selectedTemplate,
                category: widget.category,
                allowMultipleSelection: widget.allowMultipleSelection,
                excludeTemplateIds: widget.excludeTemplateIds,
                onTemplateSelected: (template) {
                  setState(() {
                    _selectedTemplate = template;
                    if (template != null) {
                      if (widget.allowMultipleSelection) {
                        if (!_selectedTemplates.any((t) => t.id == template.id)) {
                          _selectedTemplates.add(template);
                        }
                      } else {
                        _selectedTemplates = [template];
                      }
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedTemplates.isNotEmpty ? () {
                    Navigator.of(context).pop(
                      widget.allowMultipleSelection ? _selectedTemplates : _selectedTemplate,
                    );
                  } : null,
                  child: Text(
                    widget.allowMultipleSelection 
                        ? 'Sélectionner (${_selectedTemplates.length})'
                        : 'Sélectionner',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Méthode utilitaire pour afficher le dialog de sélection
Future<T?> showRoleTemplateSelectionDialog<T>({
  required BuildContext context,
  RoleTemplate? initialSelection,
  String? category,
  bool allowMultipleSelection = false,
  List<String>? excludeTemplateIds,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => RoleTemplateSelectionDialog(
      initialSelection: initialSelection,
      category: category,
      allowMultipleSelection: allowMultipleSelection,
      excludeTemplateIds: excludeTemplateIds,
    ),
  );
}