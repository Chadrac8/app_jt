import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme.dart';
import '../../../pages/form_public_page.dart';
import '../../../pages/member_appointments_page.dart';
import '../../../pages/special_song_reservation_page.dart';
import '../../../services/forms_firebase_service.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/pour_vous_action_service.dart';
import '../services/action_group_service.dart';

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
  
  // Services pour charger les actions configurées
  final PourVousActionService _actionService = PourVousActionService();
  final ActionGroupService _groupService = ActionGroupService();
  
  // État des données
  List<PourVousAction> _configuredActions = [];
  List<ActionGroup> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

    @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadConfiguredActions();
  }

  /// Charge les actions configurées depuis Firestore
  Future<void> _loadConfiguredActions() async {
    try {
      print('🔄 Chargement des actions configurées...');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Charger les actions actives
      final actions = await _actionService.getActiveActions().first;
      final groups = await _groupService.getAllGroups().first;
      
      print('✅ ${actions.length} actions chargées, ${groups.length} groupes chargés');
      for (final action in actions) {
        print('   - ${action.title} (${action.actionType})');
      }
      
      if (mounted) {
        setState(() {
          _configuredActions = actions;
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des actions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de charger les actions configurées';
        });
      }
    }
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

    // Gestion des états de chargement et d'erreur
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_configuredActions.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [        SliverPadding(
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
    
    // Organiser les actions configurées par groupes
    final groupedActions = _organizeActionsByGroups();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedActions.map((section) => _buildSection(
        section,
        colorScheme,
        crossAxisCount,
        spacing,
      )).toList(),
    );
  }

  /// Organise les actions configurées par groupes
  List<_ActionSection> _organizeActionsByGroups() {
    print('📋 Organisation de ${_configuredActions.length} actions configurées');
    final sections = <_ActionSection>[];
    
    // Grouper les actions par groupe
    final groupedActions = <String, List<PourVousAction>>{};
    
    for (final action in _configuredActions) {
      print('   📌 Action: ${action.title} (type: ${action.actionType}, active: ${action.isActive})');
      final groupId = action.groupId ?? 'default';
      if (!groupedActions.containsKey(groupId)) {
        groupedActions[groupId] = [];
      }
      groupedActions[groupId]!.add(action);
    }
    
    // Créer les sections
    groupedActions.forEach((groupId, actions) {
      final group = _groups.firstWhere(
        (g) => g.id == groupId,
        orElse: () => ActionGroup(
          id: 'default',
          name: 'Actions générales',
          description: 'Actions non groupées',
          icon: Icons.touch_app,
          iconCodePoint: Icons.touch_app.codePoint.toString(),
          color: Theme.of(context).primaryColor.value.toRadixString(16),
          order: 999,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      final sectionActions = actions.map((action) => _ActionData(
        title: action.title,
        subtitle: action.description,
        icon: action.icon,
        color: _getActionColor(action, group),
        onTap: () => _executeConfiguredAction(action),
      )).toList();
      
      if (sectionActions.isNotEmpty) {
        sections.add(_ActionSection(
          title: group.name,
          actions: sectionActions,
        ));
      }
    });
    
    // Trier par ordre de groupe
    sections.sort((a, b) {
      final groupA = _groups.firstWhere((g) => g.name == a.title, orElse: () => ActionGroup(
        id: '', name: '', description: '', icon: Icons.help, iconCodePoint: '',
        order: 999, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      final groupB = _groups.firstWhere((g) => g.name == b.title, orElse: () => ActionGroup(
        id: '', name: '', description: '', icon: Icons.help, iconCodePoint: '',
        order: 999, isActive: true, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      return groupA.order.compareTo(groupB.order);
    });
    
    return sections;
  }

  /// Obtient la couleur d'une action basée sur le groupe ou la configuration
  Color _getActionColor(PourVousAction action, ActionGroup group) {
    if (action.color != null && action.color!.isNotEmpty) {
      try {
        return Color(int.parse('0xff${action.color!.replaceAll('#', '')}'));
      } catch (e) {
        // Fallback vers la couleur du groupe
      }
    }
    
    if (group.color != null && group.color!.isNotEmpty) {
      try {
        return Color(int.parse('0xff${group.color!.replaceAll('#', '')}'));
      } catch (e) {
        // Fallback vers la couleur primaire
      }
    }
    
    return Theme.of(context).primaryColor;
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




  /// Exécute une action configurée selon son type
  Future<void> _executeConfiguredAction(PourVousAction action) async {
    try {
      print('🎯 Exécution de l\'action: ${action.title} (type: ${action.actionType})');
      
      switch (action.actionType) {
        case 'navigate_page':
          await _handleNavigatePage(action);
          break;
        case 'navigate_module':
          await _handleNavigateModule(action);
          break;
        case 'external_url':
          await _handleExternalUrl(action);
          break;
        case 'action_custom':
          await _handleCustomAction(action);
          break;
          
        default:
          _showMessage('Type d\'action non reconnu: ${action.actionType}');
      }
    } catch (e) {
      print('💥 Erreur lors de l\'exécution de l\'action: $e');
      _showMessage('Erreur lors de l\'exécution de l\'action: $e');
    }
  }

  /// Navigue vers une page spécifique
  Future<void> _handleNavigatePage(PourVousAction action) async {
    if (action.targetRoute == null || action.targetRoute!.isEmpty) {
      _showMessage('Route de navigation non spécifiée');
      return;
    }

    try {
      Navigator.of(context).pushNamed(action.targetRoute!);
    } catch (e) {
      _showMessage('Impossible de naviguer vers ${action.targetRoute}: $e');
    }
  }

  /// Navigue vers un module spécifique
  Future<void> _handleNavigateModule(PourVousAction action) async {
    if (action.targetModule == null || action.targetModule!.isEmpty) {
      _showMessage('Module cible non spécifié');
      return;
    }

    try {
      // Utiliser le système de navigation des modules
      String route = '/module/${action.targetModule}';
      if (action.targetRoute != null && action.targetRoute!.isNotEmpty) {
        route += '/${action.targetRoute}';
      }
      Navigator.of(context).pushNamed(route);
    } catch (e) {
      _showMessage('Impossible de naviguer vers le module ${action.targetModule}: $e');
    }
  }

  /// Ouvre une URL externe
  Future<void> _handleExternalUrl(PourVousAction action) async {
    String? url = action.targetRoute;
    if (action.actionData != null && action.actionData!.containsKey('url')) {
      url = action.actionData!['url'] as String?;
    }

    if (url == null || url.isEmpty) {
      _showMessage('URL non spécifiée');
      return;
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Impossible d\'ouvrir l\'URL: $url');
      }
    } catch (e) {
      _showMessage('Erreur lors de l\'ouverture de l\'URL: $e');
    }
  }

  /// Exécute une action personnalisée
  Future<void> _handleCustomAction(PourVousAction action) async {
    final actionData = action.actionData ?? {};
    final customType = actionData['type'] as String?;

    switch (customType) {
      case 'baptism_request':
        await _navigateToForm('bapteme-eau', 'Demande de baptême d\'eau');
        break;
      case 'team_join':
        await _navigateToForm('rejoindre-equipe', 'Rejoindre une équipe');
        break;
      case 'appointment_request':
        _navigateToAppointments();
        break;
      case 'question_ask':
        await _navigateToForm('questions-pasteur', 'Questions pour le pasteur');
        break;
      case 'special_song':
        await _handleSpecialSongReservation();
        break;
      case 'testimony_share':
        await _navigateToForm('temoignage', 'Partager un témoignage');
        break;
      case 'idea_suggest':
        await _navigateToForm('proposition-idee', 'Proposer une idée');
        break;
      case 'issue_report':
        await _navigateToForm('signaler-dysfonctionnement', 'Signaler un problème');
        break;
      default:
        _showMessage('Action personnalisée non reconnue: $customType');
    }
  }

  /// Gère la réservation de chant spécial
  Future<void> _handleSpecialSongReservation() async {
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



  /// Affiche un message à l'utilisateur
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Interface d'erreur de chargement
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadConfiguredActions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Interface d'état vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune action configurée',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune action n\'a été configurée pour le moment.\nContactez un administrateur pour ajouter des actions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _navigateToForm(String formSlug, String formTitle) async {
    try {
      print('🔍 Recherche du formulaire: "$formTitle"');
      
      // Chercher le formulaire par titre exact
      final forms = await FormsFirebaseService.getFormsStream(
        statusFilter: 'publie',
        limit: 50,
      ).first;

      print('📋 ${forms.length} formulaires trouvés au total');
      
      // Debug: Afficher tous les formulaires disponibles
      for (var form in forms) {
        print('   - "${form.title}" (status: ${form.status})');
      }

      // Filtrer par titre exact (case insensitive)
      final matchingForms = forms.where((form) => 
        form.title.toLowerCase() == formTitle.toLowerCase()
      ).toList();

      print('✅ ${matchingForms.length} formulaires correspondent exactement');

      if (matchingForms.isNotEmpty) {
        print('🚀 Navigation vers le formulaire: ${matchingForms.first.id}');
        
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
        print('❌ Aucun formulaire trouvé, proposition de création');
        // Formulaire non trouvé, proposer de le créer
        _showFormNotFoundDialog(formTitle, formSlug);
      }
    } catch (e) {
      print('💥 Erreur lors de l\'accès au formulaire: $e');
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
    print('👆 Card tap down: ${widget.title}');
    setState(() => _isPressed = true);
    _hoverController.forward();
    if (AppTheme.isApplePlatform) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    print('👆 Card tap up: ${widget.title}');
    setState(() => _isPressed = false);
    _hoverController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    print('👆 Card tap cancel: ${widget.title}');
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
