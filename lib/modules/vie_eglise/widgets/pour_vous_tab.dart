import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../pages/form_public_page.dart';
import '../../../pages/member_appointments_page.dart';
import '../../../pages/special_song_reservation_page.dart';
import '../../../services/forms_firebase_service.dart';

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> actions;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.actions,
  });
}

class PourVousTab extends StatefulWidget {
  const PourVousTab({Key? key}) : super(key: key);

  @override
  State<PourVousTab> createState() => _PourVousTabState();
}

class _PourVousTabState extends State<PourVousTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(colorScheme),
                const SizedBox(height: 32),
                _buildActionsGrid(colorScheme),
                const SizedBox(height: 32),
                _buildQuickAccessSection(colorScheme),
                const SizedBox(height: 24),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pour Vous',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre espace personnel d\'engagement',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Explorez les moyens de vous impliquer davantage dans la vie de l\'église',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(ColorScheme colorScheme) {
    final actions = [
      _ActionItem(
        title: 'Relation avec le Seigneur',
        subtitle: 'Baptême, équipes de service',
        icon: Icons.church_rounded,
        color: colorScheme.primary,
        actions: ['Baptême d\'eau', 'Rejoindre une équipe'],
      ),
      _ActionItem(
        title: 'Relation avec le pasteur',
        subtitle: 'Rendez-vous, questions',
        icon: Icons.person_rounded,
        color: colorScheme.secondary,
        actions: ['Prendre rendez-vous', 'Poser une question'],
      ),
      _ActionItem(
        title: 'Participation au culte',
        subtitle: 'Chant spécial, témoignage',
        icon: Icons.music_note_rounded,
        color: colorScheme.tertiary,
        actions: ['Chant spécial', 'Partager un témoignage'],
      ),
      _ActionItem(
        title: 'Amélioration continue',
        subtitle: 'Idées, signalements',
        icon: Icons.lightbulb_rounded,
        color: colorScheme.error,
        actions: ['Proposer une idée', 'Signaler un problème'],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Domaines d\'engagement',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 3.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _buildActionCard(actions[index], colorScheme),
        ),
      ],
    );
  }

  Widget _buildActionCard(_ActionItem action, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showActionBottomSheet(action, colorScheme),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    action.icon,
                    color: action.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        action.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accès rapide',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                'Mes rendez-vous',
                'Gérer mes RDV',
                Icons.calendar_today_rounded,
                colorScheme.primary,
                () => _navigateToAppointments(),
                colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickAccessCard(
                'Chant spécial',
                'Réserver une date',
                Icons.music_note_rounded,
                colorScheme.tertiary,
                () => _navigateToSpecialSong(),
                colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActionBottomSheet(_ActionItem action, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          action.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              itemCount: action.actions.length,
              itemBuilder: (context, index) => _buildBottomSheetAction(
                action.actions[index],
                action.color,
                colorScheme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetAction(String actionTitle, Color actionColor, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _handleActionTap(actionTitle);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActionIcon(actionTitle),
                    color: actionColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    actionTitle,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String actionTitle) {
    switch (actionTitle) {
      case 'Baptême d\'eau':
        return Icons.water_drop_rounded;
      case 'Rejoindre une équipe':
        return Icons.groups_rounded;
      case 'Prendre rendez-vous':
        return Icons.calendar_today_rounded;
      case 'Poser une question':
        return Icons.help_rounded;
      case 'Chant spécial':
        return Icons.music_note_rounded;
      case 'Partager un témoignage':
        return Icons.record_voice_over_rounded;
      case 'Proposer une idée':
        return Icons.lightbulb_rounded;
      case 'Signaler un problème':
        return Icons.report_rounded;
      default:
        return Icons.arrow_forward_rounded;
    }
  }

  void _navigateToSpecialSong() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const SpecialSongReservationPage(),
      ),
    );
    
    if (result == true) {
      _showSuccessMessage('Réservation confirmée avec succès !');
    }
  }

  void _handleActionTap(String actionTitle) async {
    switch (actionTitle) {
      // Relation avec Le Seigneur
      case 'Baptême d\'eau':
        await _navigateToForm('bapteme-eau', 'Demande de baptême d\'eau');
        break;
      case 'Equipes':
        await _navigateToForm('rejoindre-equipe', 'Rejoindre une équipe');
        break;
      
      // Relation avec le pasteur
      case 'Rendez-vous':
        _navigateToAppointments();
        break;
      case 'Questions':
        await _navigateToForm('questions-pasteur', 'Questions pour le pasteur');
        break;
      
      // Participation au culte
      case 'Chant spécial':
        // Rediriger vers la page de réservation spécialisée
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const SpecialSongReservationPage(),
          ),
        );
        
        if (result == true) {
          _showSuccessMessage('Réservation confirmée avec succès !');
        }
        break;
      case 'Témoignage':
        await _navigateToForm('temoignage', 'Partager un témoignage');
        break;
      
      // Amélioration
      case 'Proposer une idée':
        await _navigateToForm('proposition-idee', 'Proposer une idée');
        break;
      case 'Signaler un disfonctionnement':
        await _navigateToForm('signaler-dysfonctionnement', 'Signaler un problème');
        break;
      
      default:
        _showNotImplementedMessage(actionTitle);
    }
  }

  Future<void> _navigateToForm(String formSlug, String formTitle) async {
    try {
      // Chercher le formulaire par titre exact
      final forms = await FormsFirebaseService.getFormsStream(
        statusFilter: 'publie',
        limit: 50,
      ).first;

      // Filtrer par titre exact (case insensitive)
      final matchingForms = forms.where((form) => 
        form.title.toLowerCase() == formTitle.toLowerCase()
      ).toList();

      if (matchingForms.isNotEmpty) {
        // Naviguer vers le formulaire existant
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => FormPublicPage(formId: matchingForms.first.id),
          ),
        );

        if (result == true) {
          _showSuccessMessage('Formulaire soumis avec succès !');
        }
      } else {
        // Formulaire non trouvé, proposer de le créer
        _showFormNotFoundDialog(formTitle, formSlug);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'accès au formulaire: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MemberAppointmentsPage(),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showNotImplementedMessage(String actionTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Action "$actionTitle" - À implémenter',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFormNotFoundDialog(String formTitle, String formSlug) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Formulaire non disponible',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
        ),
        content: Text(
          'Le formulaire "$formTitle" n\'est pas encore configuré. Un administrateur doit le créer dans le module Formulaires.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestFormCreation(formTitle, formSlug);
            },
            child: Text(
              'Demander la création',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _requestFormCreation(String formTitle, String formSlug) {
    // TODO: Envoyer une demande de création de formulaire aux administrateurs
    // Ceci pourrait être implémenté via un système de notifications ou d'emails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demande de création du formulaire "$formTitle" envoyée aux administrateurs.',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
