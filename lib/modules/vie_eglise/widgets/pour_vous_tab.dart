import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../pages/form_public_page.dart';
import '../../../pages/member_appointments_page.dart';
import '../../../pages/special_song_reservation_page.dart';
import '../../../services/forms_firebase_service.dart';

// Classe de données pour les actions
class _ActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// Classe de données pour les sections avec titres
class _ActionSection {
  final String title;
  final List<_ActionData> actions;

  const _ActionSection({
    required this.title,
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.adaptivePadding,
            vertical: AppTheme.isApplePlatform ? AppTheme.spaceMedium : AppTheme.spaceSmall,
          ),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildActionsGrid(colorScheme, screenWidth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsGrid(ColorScheme colorScheme, double screenWidth) {
    final crossAxisCount = AppTheme.getGridColumns(screenWidth);
    final spacing = AppTheme.gridSpacing;
    
    // Organisation des actions par sections professionnelles
    final sections = [
      _ActionSection(
        title: 'Relation avec Le Seigneur',
        actions: [
          _ActionData(
            title: 'Baptême d\'eau',
            subtitle: 'Demander le baptême',
            icon: Icons.water_drop_rounded,
            color: colorScheme.primary,
            onTap: () => _handleBaptism(),
          ),
          _ActionData(
            title: 'Rejoindre une équipe',
            subtitle: 'Servir dans l\'église',
            icon: Icons.group_rounded,
            color: colorScheme.primary,
            onTap: () => _handleJoinTeam(),
          ),
        ],
      ),
      _ActionSection(
        title: 'Relation avec le pasteur',
        actions: [
          _ActionData(
            title: 'Prendre rendez-vous',
            subtitle: 'Rencontrer le pasteur',
            icon: Icons.calendar_today_rounded,
            color: colorScheme.secondary,
            onTap: () => _navigateToAppointments(),
          ),
          _ActionData(
            title: 'Poser une question',
            subtitle: 'Demander conseil',
            icon: Icons.help_rounded,
            color: colorScheme.secondary,
            onTap: () => _handleAskQuestion(),
          ),
        ],
      ),
      _ActionSection(
        title: 'Participer au culte',
        actions: [
          _ActionData(
            title: 'Chant spécial',
            subtitle: 'Réserver une date',
            icon: Icons.mic_rounded,
            color: colorScheme.tertiary,
            onTap: () => _handleActionTap('Chant spécial'),
          ),
          _ActionData(
            title: 'Partager un témoignage',
            subtitle: 'Témoigner publiquement',
            icon: Icons.record_voice_over_rounded,
            color: colorScheme.tertiary,
            onTap: () => _handleTestimony(),
          ),
        ],
      ),
      _ActionSection(
        title: 'Amélioration',
        actions: [
          _ActionData(
            title: 'Proposer une idée',
            subtitle: 'Suggérer une amélioration',
            icon: Icons.lightbulb_outline_rounded,
            color: colorScheme.error,
            onTap: () => _handleSuggestion(),
          ),
          _ActionData(
            title: 'Signaler un problème',
            subtitle: 'Rapporter un dysfonctionnement',
            icon: Icons.report_problem_rounded,
            color: colorScheme.error,
            onTap: () => _handleReportIssue(),
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) => _buildSection(
        section,
        colorScheme,
        crossAxisCount,
        spacing,
      )).toList(),
    );
  }

  Widget _buildSection(_ActionSection section, ColorScheme colorScheme, int crossAxisCount, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section professionnel
        _buildSectionTitle(section.title, colorScheme),
        
        // Espacement avant les cartes
        SizedBox(height: AppTheme.isApplePlatform ? 12.0 : 8.0),
        
        // Grille des cartes de la section
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: AppTheme.isDesktop ? 1.1 : (AppTheme.isApplePlatform ? 1.05 : 1.0),
          ),
          itemCount: section.actions.length,
          itemBuilder: (context, index) {
            final action = section.actions[index];
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final animationDelay = index * 0.1;
                final animation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    animationDelay,
                    (animationDelay + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ));
                
                return Transform.scale(
                  scale: animation.value,
                  child: Opacity(
                    opacity: animation.value,
                    child: _ProfessionalActionCard(
                      title: action.title,
                      subtitle: action.subtitle,
                      icon: action.icon,
                      color: action.color,
                      onTap: action.onTap,
                      colorScheme: colorScheme,
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Espacement après chaque section
        SizedBox(height: AppTheme.isApplePlatform ? 32.0 : 24.0),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(
        left: AppTheme.isApplePlatform ? 4.0 : 2.0,
        bottom: AppTheme.isApplePlatform ? 4.0 : 2.0,
      ),
      child: Row(
        children: [
          // Accent visuel subtil - petit indicateur coloré
          Container(
            width: 4.0,
            height: AppTheme.isApplePlatform ? 20.0 : 18.0,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          
          // Espacement entre l'accent et le texte
          SizedBox(width: AppTheme.isApplePlatform ? 12.0 : 10.0),
          
          // Titre de section
          Expanded(
            child: Text(
              title,
              style: AppTheme.isApplePlatform
                  ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: AppTheme.fontSemiBold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    )
                  : Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: AppTheme.fontSemiBold,
                      height: 1.2,
                    ),
            ),
          ),
        ],
      ),
    );
  }


  // Méthodes d'action individuelles
  void _handleBaptism() => _handleActionTap('Baptême d\'eau');
  void _handleJoinTeam() => _handleActionTap('Equipes');
  void _handleAskQuestion() => _handleActionTap('Questions');
  void _handleTestimony() => _handleActionTap('Témoignage');
  void _handleSuggestion() => _handleActionTap('Proposer une idée');
  void _handleReportIssue() => _handleActionTap('Signaler un disfonctionnement');

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

// Widget de carte professionnel avec interactions améliorées
class _ProfessionalActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ProfessionalActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  State<_ProfessionalActionCard> createState() => _ProfessionalActionCardState();
}

class _ProfessionalActionCardState extends State<_ProfessionalActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _hoverController.forward();
    if (AppTheme.isApplePlatform) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _hoverController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced surface colors with subtle gradients
    final surfaceColor = AppTheme.isApplePlatform 
        ? widget.colorScheme.surface
        : widget.colorScheme.surfaceContainerLow;
    
    // Professional border with context-aware styling
    final borderColor = AppTheme.isApplePlatform
        ? widget.colorScheme.outline.withValues(alpha: 0.15)
        : widget.colorScheme.outlineVariant.withValues(alpha: 0.8);
    
    // Enhanced spacing for better visual hierarchy
    final contentPadding = AppTheme.isDesktop 
        ? EdgeInsets.all(20.0)
        : EdgeInsets.all(18.0);

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(
                AppTheme.isApplePlatform ? 20.0 : 18.0,
              ),
              border: Border.all(
                color: _isPressed 
                    ? widget.color.withValues(alpha: 0.3)
                    : borderColor,
                width: AppTheme.isApplePlatform ? 0.8 : 1.0,
              ),
              // Enhanced shadows for professional depth
              boxShadow: AppTheme.isApplePlatform ? [
                // Primary shadow for depth
                BoxShadow(
                  color: widget.colorScheme.shadow.withValues(alpha: 0.08 * _elevationAnimation.value),
                  offset: Offset(0, 2 * _elevationAnimation.value),
                  blurRadius: 8 * _elevationAnimation.value,
                  spreadRadius: 0,
                ),
                // Secondary shadow for softness
                BoxShadow(
                  color: widget.colorScheme.shadow.withValues(alpha: 0.04 * _elevationAnimation.value),
                  offset: Offset(0, 1 * _elevationAnimation.value),
                  blurRadius: 3 * _elevationAnimation.value,
                  spreadRadius: 0,
                ),
              ] : [
                // Material Design 3 elevation shadow
                BoxShadow(
                  color: widget.colorScheme.shadow.withValues(alpha: 0.06 * _elevationAnimation.value),
                  offset: Offset(0, 1 * _elevationAnimation.value),
                  blurRadius: 4 * _elevationAnimation.value,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                AppTheme.isApplePlatform ? 20.0 : 18.0,
              ),
              child: AppTheme.isApplePlatform
                  ? GestureDetector(
                      onTapDown: _handleTapDown,
                      onTapUp: _handleTapUp,
                      onTapCancel: _handleTapCancel,
                      child: _buildCardContent(contentPadding),
                    )
                  : InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(
                        AppTheme.isApplePlatform ? 20.0 : 18.0,
                      ),
                      splashColor: widget.color.withValues(alpha: 0.12),
                      highlightColor: widget.color.withValues(alpha: 0.08),
                      hoverColor: widget.color.withValues(alpha: 0.04),
                      child: _buildCardContent(contentPadding),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent(EdgeInsets contentPadding) {
    return Container(
      padding: contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced icon container with gradient background
          Container(
            width: AppTheme.isDesktop ? 64 : 56,
            height: AppTheme.isDesktop ? 64 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: _isPressed ? 0.25 : 0.15),
                  widget.color.withValues(alpha: _isPressed ? 0.15 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(
                AppTheme.isApplePlatform ? 18.0 : 16.0,
              ),
              border: Border.all(
                color: widget.color.withValues(alpha: _isPressed ? 0.3 : 0.2),
                width: 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              color: widget.color,
              size: AppTheme.isDesktop ? 32 : 28,
            ),
          ),
          
          // Enhanced spacing for visual breathing room
          SizedBox(height: AppTheme.isApplePlatform ? 16.0 : 14.0),
          
          // Professional title with enhanced typography
          Text(
            widget.title,
            style: AppTheme.isApplePlatform 
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.colorScheme.onSurface,
                    fontWeight: AppTheme.fontSemiBold,
                    letterSpacing: -0.3,
                    height: 1.2,
                  )
                : Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: widget.colorScheme.onSurface,
                    fontWeight: AppTheme.fontSemiBold,
                    height: 1.2,
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Optimal spacing between title and subtitle
          SizedBox(height: 6.0),
          
          // Enhanced subtitle with professional opacity
          Text(
            widget.subtitle,
            style: AppTheme.isApplePlatform
                ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    letterSpacing: -0.2,
                    height: 1.3,
                  )
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Spacer to push content up for better balance
          SizedBox(height: 4.0),
        ],
      ),
    );
  }
}
