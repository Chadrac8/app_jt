import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../models/prayer_model.dart';
import '../../../services/prayers_firebase_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../auth/auth_service.dart';

/// Vue du formulaire de demande de prière - Material Design 3
/// Respecte les guidelines MD3 et le thème de l'application
class PrayerRequestFormView extends StatefulWidget {
  final PrayerModel? prayer; // Pour l'édition

  const PrayerRequestFormView({
    super.key,
    this.prayer,
  });

  @override
  State<PrayerRequestFormView> createState() => _PrayerRequestFormViewState();
}

class _PrayerRequestFormViewState extends State<PrayerRequestFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  PrayerType _selectedType = PrayerType.request;
  bool _isAnonymous = false;
  bool _isLoading = false;
  bool get _isEditing => widget.prayer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.prayer!.title;
      _contentController.text = widget.prayer!.content;
      _selectedType = widget.prayer!.type;
      _isAnonymous = widget.prayer!.isAnonymous;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Récupérer les informations de l'utilisateur connecté
      final currentUser = AuthService.currentUser;
      final userProfile = await UserProfileService.getCurrentUserProfile();
      
      String authorName;
      String authorId;
      
      if (_isAnonymous) {
        authorName = 'Anonyme';
        authorId = currentUser?.uid ?? 'anonymous';
      } else {
        // Utiliser le profil utilisateur s'il existe, sinon fallback sur Firebase Auth
        if (userProfile != null) {
          authorName = '${userProfile.firstName} ${userProfile.lastName}'.trim();
          if (authorName.isEmpty) {
            authorName = (userProfile.email?.isNotEmpty == true) ? userProfile.email! : 'Utilisateur';
          }
        } else {
          // Fallback sur les données Firebase Auth
          authorName = currentUser?.displayName ?? 
                      currentUser?.email ?? 
                      'Utilisateur';
        }
        authorId = currentUser?.uid ?? 'unknown_user';
      }

      final prayer = PrayerModel(
        id: _isEditing ? widget.prayer!.id : '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        category: _getTypeLabel(_selectedType),
        authorName: authorName,
        authorId: authorId,
        isAnonymous: _isAnonymous,
        createdAt: _isEditing ? widget.prayer!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isApproved: true, // À adapter selon la logique de modération
        isArchived: false,
        prayerCount: _isEditing ? widget.prayer!.prayerCount : 0,
      );

      if (_isEditing) {
        await PrayersFirebaseService.updatePrayer(prayer);
      } else {
        await PrayersFirebaseService.createPrayer(prayer);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        _showSuccessSnackBar(_isEditing ? 'Prière modifiée avec succès' : 'Prière ajoutée avec succès');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppTheme.onSuccess,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppTheme.onSuccess,
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.onError,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppTheme.onError,
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier la prière' : 'Nouvelle demande',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize20,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onPrimaryColor),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _submitForm,
              child: Text(
                _isEditing ? 'MODIFIER' : 'PUBLIER',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.onPrimaryColor,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildTitleField(),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildContentField(),
              const SizedBox(height: AppTheme.spaceLarge),
              _buildAnonymousOption(),
              const SizedBox(height: AppTheme.spaceXLarge),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de prière',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Wrap(
          spacing: AppTheme.spaceSmall,
          children: PrayerType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getTypeIcon(type),
                    size: 18,
                    color: isSelected 
                        ? AppTheme.onPrimaryContainer
                        : _getTypeColor(type),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    _getTypeLabel(type),
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: isSelected 
                          ? AppTheme.onPrimaryContainer
                          : AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedType = type);
                }
              },
              backgroundColor: AppTheme.surface,
              selectedColor: AppTheme.primaryContainer,
              side: BorderSide(
                color: isSelected 
                    ? AppTheme.primaryContainer
                    : AppTheme.outline.withOpacity(0.3),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Titre (optionnel)',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          controller: _titleController,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            color: AppTheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Donnez un titre à votre prière...',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: AppTheme.fontSize16,
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: AppTheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: AppTheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppTheme.spaceLarge),
          ),
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre prière *',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          controller: _contentController,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize16,
            color: AppTheme.onSurface,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: 'Partagez votre demande de prière, action de grâce ou témoignage...',
            hintStyle: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: AppTheme.fontSize16,
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: AppTheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: AppTheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(AppTheme.spaceLarge),
          ),
          maxLines: 8,
          maxLength: 1000,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez saisir votre prière';
            }
            if (value.trim().length < 10) {
              return 'Votre prière doit contenir au moins 10 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAnonymousOption() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off,
            color: AppTheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publier anonymement',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Votre nom ne sera pas affiché publiquement',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value),
            activeThumbColor: AppTheme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _submitForm,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          disabledBackgroundColor: AppTheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: AppTheme.onSurface.withOpacity(0.38),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.onPrimaryColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Text(
                    _isEditing ? 'Modification...' : 'Publication...',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize16,
                      fontWeight: AppTheme.fontSemiBold,
                    ),
                  ),
                ],
              )
            : Text(
                _isEditing ? 'Modifier la prière' : 'Publier la prière',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
      ),
    );
  }

  IconData _getTypeIcon(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return Icons.volunteer_activism;
      case PrayerType.thanksgiving:
        return Icons.celebration;
      case PrayerType.testimony:
        return Icons.auto_awesome;
    }
  }

  Color _getTypeColor(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return AppTheme.primaryColor;
      case PrayerType.thanksgiving:
        return AppTheme.secondaryColor;
      case PrayerType.testimony:
        return AppTheme.tertiaryColor;
    }
  }

  String _getTypeLabel(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return 'Demande';
      case PrayerType.thanksgiving:
        return 'Action de grâce';
      case PrayerType.testimony:
        return 'Témoignage';
    }
  }
}
