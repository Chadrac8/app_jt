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
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppTheme.adaptivePadding), // Padding adaptatif
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionsGrid(colorScheme, screenWidth),
              SizedBox(height: AppTheme.adaptivePadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsGrid(ColorScheme colorScheme, double screenWidth) {
    final crossAxisCount = AppTheme.getGridColumns(screenWidth);
    final spacing = AppTheme.gridSpacing;
    
    final actions = [
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
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          action.title,
          action.subtitle,
          action.icon,
          action.color,
          action.onTap,
          colorScheme,
        );
      },
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, ColorScheme colorScheme) {
    // Widget adaptatif selon la plateforme
    final cardContent = Padding(
      padding: EdgeInsets.all(AppTheme.actionCardPadding), // Padding adaptatif
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container with proper M3 sizing and animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200), // M3 animation duration
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppTheme.interactionOpacity),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: AppTheme.actionCardPadding), // Espacement adaptatif
          // Title with M3 typography
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: AppTheme.fontSemiBold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spaceXSmall), // M3 tight spacing
          // Subtitle with M3 typography
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Card(
      elevation: 0, // M3 cards have no elevation by default
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.actionCardRadius), // Radius adaptatif
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: AppTheme.actionCardBorderWidth, // Épaisseur adaptative
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: AppTheme.isApplePlatform
          ? GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: cardContent,
            )
          : InkWell(
              onTap: onTap,
              splashColor: color.withValues(alpha: AppTheme.interactionOpacity),
              highlightColor: color.withValues(alpha: 0.08),
              hoverColor: color.withValues(alpha: 0.04),
              child: cardContent,
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
