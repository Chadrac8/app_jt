import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/action_group.dart';
import '../services/action_group_service.dart';
import '../../../theme.dart';

class GroupFormDialog extends StatefulWidget {
  final ActionGroup? group;
  final bool isDuplicate;

  const GroupFormDialog({
    Key? key,
    this.group,
    this.isDuplicate = false,
  }) : super(key: key);

  @override
  State<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends State<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ActionGroupService _groupService = ActionGroupService();

  IconData _selectedIcon = Icons.folder;
  Color _selectedColor = AppTheme.primaryColor;
  bool _isActive = true;
  int _order = 0;
  bool _isLoading = false;

  final List<IconData> _availableIcons = [
    Icons.folder,
    Icons.church,
    Icons.volunteer_activism,
    Icons.self_improvement,
    Icons.chat_bubble,
    Icons.group,
    Icons.favorite,
    Icons.star,
    Icons.school,
    Icons.event,
    Icons.contact_phone,
    Icons.email,
    Icons.calendar_month,
    Icons.library_books,
    Icons.music_note,
    Icons.home,
    Icons.settings,
    Icons.notifications,
    Icons.help,
    Icons.info,
  ];

  final List<Color> _availableColors = [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    AppTheme.successColor,
    AppTheme.warningColor,
    AppTheme.errorColor,
    AppTheme.primaryColor,
    AppTheme.orangeStandard,
    AppTheme.secondaryColor,
    AppTheme.secondaryColor,
    AppTheme.pinkStandard,
    AppTheme.infoColor,
    AppTheme.warningColor,
    AppTheme.successColor,
    AppTheme.tertiaryColor,
    AppTheme.grey500,
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.group != null) {
      final group = widget.group!;
      _nameController.text = widget.isDuplicate ? '${group.name} (Copie)' : group.name;
      _descriptionController.text = group.description;
      _selectedIcon = group.icon;
      _isActive = widget.isDuplicate ? true : group.isActive;
      _order = widget.isDuplicate ? 0 : group.order;
      
      if (group.color != null) {
        try {
          _selectedColor = Color(int.parse(group.color!.replaceFirst('#', '0xFF')));
        } catch (e) {
          _selectedColor = AppTheme.primaryColor;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isDuplicate 
            ? 'Dupliquer le groupe'
            : widget.group == null 
                ? 'Créer un groupe'
                : 'Modifier le groupe',
        style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildAppearanceSection(),
                const SizedBox(height: AppTheme.spaceLarge),
                _buildAdvancedSection(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: GoogleFonts.poppins(color: AppTheme.textSecondaryColor),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.white100,
                  ),
                )
              : Text(
                  widget.group == null || widget.isDuplicate ? 'Créer' : 'Modifier',
                  style: GoogleFonts.poppins(color: AppTheme.surfaceColor),
                ),
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
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nom du groupe *',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom du groupe est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description *',
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La description est requise';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apparence',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Text(
          'Icône',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableIcons.length,
            itemBuilder: (context, index) {
              final icon = _availableIcons[index];
              final isSelected = icon == _selectedIcon;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = icon;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.primaryColor
                          : AppTheme.textTertiaryColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Couleur',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _availableColors.length,
            itemBuilder: (context, index) {
              final color = _availableColors[index];
              final isSelected = color == _selectedColor;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: isSelected ? AppTheme.black100 : AppTheme.grey500,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options avancées',
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _order.toString(),
                decoration: InputDecoration(
                  labelText: 'Ordre d\'affichage',
                  labelStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                style: GoogleFonts.poppins(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _order = int.tryParse(value) ?? 0;
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: SwitchListTile(
                title: Text(
                  'Groupe actif',
                  style: GoogleFonts.poppins(fontSize: AppTheme.fontSize14),
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

      if (widget.group == null || widget.isDuplicate) {
        // Créer un nouveau groupe
        final newGroup = ActionGroup(
          id: '', // Sera généré par Firestore
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          iconCodePoint: _selectedIcon.codePoint.toString(),
          color: colorHex,
          isActive: _isActive,
          order: _order,
          createdAt: now,
          updatedAt: now,
        );

        await _groupService.createGroup(newGroup);
      } else {
        // Modifier le groupe existant
        final updatedGroup = widget.group!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          icon: _selectedIcon,
          iconCodePoint: _selectedIcon.codePoint.toString(),
          color: colorHex,
          isActive: _isActive,
          order: _order,
          updatedAt: now,
        );

        await _groupService.updateGroup(widget.group!.id, updatedGroup);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.group == null || widget.isDuplicate 
                  ? 'Groupe créé avec succès'
                  : 'Groupe modifié avec succès',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
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
