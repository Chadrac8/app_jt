import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/thematic_passage_model.dart';
import '../services/thematic_passage_service.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

class ThemeCreationDialog extends StatefulWidget {
  final BiblicalTheme? themeToEdit;
  
  const ThemeCreationDialog({
    Key? key,
    this.themeToEdit,
  }) : super(key: key);

  @override
  State<ThemeCreationDialog> createState() => _ThemeCreationDialogState();
}

class _ThemeCreationDialogState extends State<ThemeCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  Color _selectedColor = AppTheme.blueStandard;
  IconData _selectedIcon = Icons.bookmark;
  bool _isPublic = false;
  bool _isLoading = false;

  final List<Color> _availableColors = [
    AppTheme.blueStandard,
    AppTheme.greenStandard,
    AppTheme.orangeStandard,
    AppTheme.primaryColor,
    AppTheme.redStandard,
    AppTheme.secondaryColor,
    AppTheme.pinkStandard,
    AppTheme.secondaryColor,
    AppTheme.warningColor,
    AppTheme.warningColor,
    AppTheme.infoColor,
    AppTheme.successColor,
  ];

  final List<IconData> _availableIcons = [
    Icons.bookmark,
    Icons.favorite,
    Icons.star,
    Icons.lightbulb,
    Icons.healing,
    Icons.security,
    Icons.family_restroom,
    Icons.handshake,
    Icons.volunteer_activism,
    Icons.psychology,
    Icons.auto_awesome,
    Icons.celebration,
    Icons.emoji_nature,
    Icons.spa,
    Icons.self_improvement,
    Icons.brightness_high,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.themeToEdit != null) {
      _nameController.text = widget.themeToEdit!.name;
      _descriptionController.text = widget.themeToEdit!.description;
      _selectedColor = widget.themeToEdit!.color;
      _selectedIcon = widget.themeToEdit!.icon;
      _isPublic = widget.themeToEdit!.isPublic;
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
    final theme = Theme.of(context);
    final isEditing = widget.themeToEdit != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      _selectedIcon,
                      color: _selectedColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: Text(
                      isEditing ? 'Modifier le thème' : 'Nouveau thème',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize20,
                        fontWeight: AppTheme.fontBold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spaceLarge),
              
              // Nom du thème
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom du thème',
                  hintText: 'Ex: Amour de Dieu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  prefixIcon: Icon(_selectedIcon),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du thème est requis';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.spaceMedium),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez le thème et son objectif...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La description est requise';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.space20),
              
              // Sélection de couleur
              Text(
                'Couleur du thème',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black100.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: AppTheme.white100,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: AppTheme.space20),
              
              // Sélection d'icône
              Text(
                'Icône du thème',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Container(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.2)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: isSelected
                              ? Border.all(color: _selectedColor, width: 2)
                              : Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? _selectedColor : theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: AppTheme.space20),
              
              // Thème public
              SwitchListTile(
                title: Text(
                  'Thème public',
                  style: GoogleFonts.inter(
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
                subtitle: Text(
                  'Visible par tous les utilisateurs',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: _selectedColor,
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: AppTheme.spaceLarge),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.inter(fontWeight: AppTheme.fontSemiBold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTheme,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: AppTheme.white100,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                              ),
                            )
                          : Text(
                              isEditing ? 'Modifier' : 'Créer',
                              style: GoogleFonts.inter(fontWeight: AppTheme.fontSemiBold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTheme() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (widget.themeToEdit != null) {
        // Modifier le thème existant
        await ThematicPassageService.updateTheme(
          themeId: widget.themeToEdit!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
          isPublic: _isPublic,
        );
      } else {
        // Créer un nouveau thème
        await ThematicPassageService.createTheme(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          color: _selectedColor,
          icon: _selectedIcon,
          isPublic: _isPublic,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.themeToEdit != null
                  ? 'Thème modifié avec succès'
                  : 'Thème créé avec succès',
            ),
            backgroundColor: _selectedColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        String actionMessage;
        
        if (e.toString().contains('Connexion requise') || 
            e.toString().contains('authentification anonyme') ||
            e.toString().contains('admin-restricted-operation')) {
          errorMessage = 'Authentification requise';
          actionMessage = 'L\'authentification anonyme n\'est pas activée. Contactez l\'administrateur pour l\'activer dans Firebase Console.';
        } else {
          errorMessage = 'Erreur lors de l\'opération';
          actionMessage = e.toString();
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: AppTheme.redStandard),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(errorMessage),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(actionMessage),
                const SizedBox(height: AppTheme.spaceMedium),
                const Text(
                  'Solutions possibles:',
                  style: TextStyle(fontWeight: AppTheme.fontBold),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                const Text('• Activez l\'authentification anonyme dans Firebase'),
                const Text('• Connectez-vous avec un compte utilisateur'),
                const Text('• Contactez l\'administrateur de l\'application'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
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
