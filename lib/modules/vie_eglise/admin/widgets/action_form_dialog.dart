import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';  
import '../../../../../theme.dart';
import '../../models/pour_vous_action.dart';
import '../../models/action_group.dart';
import '../../models/action_categories.dart';
import '../../models/action_types.dart';class ActionFormDialog extends StatefulWidget {
  final PourVousAction? action;
  final List<ActionGroup> groups;
  final Function(PourVousAction) onSave;

  const ActionFormDialog({
    Key? key,
    this.action,
    required this.groups,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ActionFormDialog> createState() => _ActionFormDialogState();
}

class _ActionFormDialogState extends State<ActionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _targetModuleController = TextEditingController();
  final TextEditingController _targetPageController = TextEditingController();
  final TextEditingController _externalUrlController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  
  String _selectedCategory = 'general';
  String _selectedActionType = 'navigation';
  String _selectedIconName = 'auto_awesome';
  String _selectedIconColor = '#2196F3';
  String? _selectedGroupId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.action != null) {
      final action = widget.action!;
      _titleController.text = action.title;
      _descriptionController.text = action.description;
      _selectedCategory = action.category ?? 'general';
      _selectedActionType = action.actionType;
      _targetModuleController.text = action.targetModule ?? '';
      _targetPageController.text = action.targetRoute ?? '';
      _externalUrlController.text = '';
      _selectedIconName = 'auto_awesome';
      _selectedIconColor = action.color ?? '#2196F3';
      _selectedGroupId = action.groupId;
      _isActive = action.isActive;
      _orderController.text = action.order.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetModuleController.dispose();
    _targetPageController.dispose();
    _externalUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  widget.action == null ? Icons.add : Icons.edit,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  widget.action == null ? 'Nouvelle action' : 'Modifier l\'action',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
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
            const Divider(),
            
            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Informations de base
                      _buildSectionTitle('Informations de base'),
                      const SizedBox(height: AppTheme.spaceSmall),
                      
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Titre *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Le titre est requis';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: TextFormField(
                              controller: _orderController,
                              decoration: const InputDecoration(
                                labelText: 'Ordre',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final order = int.tryParse(value);
                                  if (order == null || order < 0) {
                                    return 'Ordre invalide';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La description est requise';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Catégorie',
                                border: OutlineInputBorder(),
                              ),
                              items: ActionCategories.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(ActionCategories.labels[category] ?? category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value!);
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: _selectedGroupId,
                              decoration: const InputDecoration(
                                labelText: 'Groupe',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Aucun groupe'),
                                ),
                                ...widget.groups.map((group) {
                                  return DropdownMenuItem(
                                    value: group.id,
                                    child: Text(group.name),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedGroupId = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Configuration de l'action
                      _buildSectionTitle('Configuration de l\'action'),
                      const SizedBox(height: AppTheme.spaceSmall),
                      
                      DropdownButtonFormField<String>(
                        initialValue: _selectedActionType,
                        decoration: const InputDecoration(
                          labelText: 'Type d\'action',
                          border: OutlineInputBorder(),
                        ),
                        items: ActionTypes.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(ActionTypes.labels[type] ?? type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedActionType = value!);
                        },
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      // Champs conditionnels selon le type d'action
                      if (_selectedActionType == 'navigation') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _targetModuleController,
                                decoration: const InputDecoration(
                                  labelText: 'Module cible',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ex: appointments, forms',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Expanded(
                              child: TextFormField(
                                controller: _targetPageController,
                                decoration: const InputDecoration(
                                  labelText: 'Page cible',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ex: member_appointments',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_selectedActionType == 'external') ...[
                        TextFormField(
                          controller: _externalUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL externe *',
                            border: OutlineInputBorder(),
                            hintText: 'https://example.com',
                          ),
                          validator: _selectedActionType == 'external' 
                              ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'L\'URL est requise';
                                  }
                                  final uri = Uri.tryParse(value);
                                  if (uri == null || !uri.isAbsolute) {
                                    return 'URL invalide';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ] else if (_selectedActionType == 'form') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _targetModuleController,
                                decoration: const InputDecoration(
                                  labelText: 'Module du formulaire *',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ex: forms, contact',
                                ),
                                validator: _selectedActionType == 'form'
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Le module est requis';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSmall),
                            Expanded(
                              child: TextFormField(
                                controller: _targetPageController,
                                decoration: const InputDecoration(
                                  labelText: 'Page du formulaire *',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ex: baptism_request',
                                ),
                                validator: _selectedActionType == 'form'
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'La page est requise';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Apparence
                      _buildSectionTitle('Apparence'),
                      const SizedBox(height: AppTheme.spaceSmall),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildIconSelector(),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: _buildColorSelector(),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      SwitchListTile(
                        title: const Text('Action active'),
                        subtitle: const Text('L\'action sera visible pour les membres'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                FilledButton(
                  onPressed: _saveAction,
                  child: Text(widget.action == null ? 'Créer' : 'Modifier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: AppTheme.fontSize16,
        fontWeight: AppTheme.fontSemiBold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildIconSelector() {
    final icons = {
      'auto_awesome': Icons.auto_awesome,
      'water_drop_rounded': Icons.water_drop_rounded,
      'group_rounded': Icons.group_rounded,
      'calendar_today_rounded': Icons.calendar_today_rounded,
      'help_rounded': Icons.help_rounded,
      'mic_rounded': Icons.mic_rounded,
      'record_voice_over_rounded': Icons.record_voice_over_rounded,
      'school_rounded': Icons.school_rounded,
      'book_rounded': Icons.book_rounded,
      'church_rounded': Icons.church_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'person_rounded': Icons.person_rounded,
      'volunteer_activism_rounded': Icons.volunteer_activism_rounded,
      'diversity_3_rounded': Icons.diversity_3_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icône',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.grey300),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall),
            child: Row(
              children: icons.entries.map((entry) {
                final isSelected = _selectedIconName == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceXSmall),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIconName = entry.key),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : null,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: isSelected ? Border.all(color: AppTheme.primaryColor) : null,
                      ),
                      child: Icon(
                        entry.value,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.grey600,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    final colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FF9800', // Orange
      '#9C27B0', // Purple
      '#E91E63', // Pink
      '#607D8B', // Blue Grey
      '#3F51B5', // Indigo
      '#795548', // Brown
      '#F44336', // Red
      '#009688', // Teal
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.grey300),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall),
            child: Row(
              children: colors.map((colorHex) {
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedIconColor == colorHex;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spaceXSmall),
                  child: InkWell(
                    onTap: () => setState(() => _selectedIconColor = colorHex),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: isSelected 
                            ? Border.all(color: AppTheme.textPrimaryColor, width: 2)
                            : Border.all(color: AppTheme.grey300),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconFromName(String iconName) {
    const iconMap = {
      'auto_awesome': Icons.auto_awesome,
      'water_drop_rounded': Icons.water_drop_rounded,
      'group_rounded': Icons.group_rounded,
      'calendar_today_rounded': Icons.calendar_today_rounded,
      'help_rounded': Icons.help_rounded,
      'mic_rounded': Icons.mic_rounded,
      'record_voice_over_rounded': Icons.record_voice_over_rounded,
      'school_rounded': Icons.school_rounded,
      'book_rounded': Icons.book_rounded,
      'church_rounded': Icons.church_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'person_rounded': Icons.person_rounded,
      'volunteer_activism_rounded': Icons.volunteer_activism_rounded,
      'diversity_3_rounded': Icons.diversity_3_rounded,
    };
    return iconMap[iconName] ?? Icons.auto_awesome;
  }

  void _saveAction() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final order = int.tryParse(_orderController.text) ?? 0;

    // Obtenir l'icône sélectionnée
    final selectedIcon = _getIconFromName(_selectedIconName);
    
    final action = PourVousAction(
      id: widget.action?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: selectedIcon,
      iconCodePoint: selectedIcon.codePoint.toString(),
      actionType: _selectedActionType,
      targetModule: _targetModuleController.text.trim().isNotEmpty 
          ? _targetModuleController.text.trim() 
          : null,
      targetRoute: _targetPageController.text.trim().isNotEmpty 
          ? _targetPageController.text.trim() 
          : null,
      actionData: _externalUrlController.text.trim().isNotEmpty 
          ? {'externalUrl': _externalUrlController.text.trim()}
          : null,
      isActive: _isActive,
      order: order,
      createdAt: widget.action?.createdAt ?? now,
      updatedAt: now,
      color: _selectedIconColor,
      groupId: _selectedGroupId,
      category: _selectedCategory,
    );

    widget.onSave(action);
    Navigator.of(context).pop();
  }
}