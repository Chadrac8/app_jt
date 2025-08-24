import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../models/action_group.dart';
import '../services/pour_vous_action_service.dart';
import '../services/action_group_service.dart';

class PourVousTab extends StatefulWidget {
  const PourVousTab({Key? key}) : super(key: key);

  @override
  State<PourVousTab> createState() => _PourVousTabState();
}

class _PourVousTabState extends State<PourVousTab> {
  final PourVousActionService _actionService = PourVousActionService();
  final ActionGroupService _groupService = ActionGroupService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeActions();
  }

  Future<void> _initializeActions() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    
    // Les actions par défaut ne sont plus créées automatiquement
    // Elles doivent être configurées par l'administrateur
    print('📝 Note: Les actions "Pour vous" doivent être configurées par l\'administrateur');
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.textTertiaryColor.withOpacity(0.05),
      body: _isLoading
          ? _buildLoadingWidget()
          : _buildContent());
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    return StreamBuilder<List<PourVousAction>>(
      stream: _actionService.getActiveActions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        final actions = snapshot.data ?? [];

        if (actions.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _initializeActions();
          },
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildGroupedActionsView(actions)));
      });
  }

  Widget _buildGroupedActionsView(List<PourVousAction> actions) {
    return StreamBuilder<List<ActionGroup>>(
      stream: _groupService.getActiveGroups(),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (groupSnapshot.hasError) {
          print('Erreur lors du chargement des groupes: ${groupSnapshot.error}');
          // En cas d'erreur, afficher toutes les actions sans groupement
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withOpacity(0.3))),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Les groupes ne sont pas disponibles. Affichage de toutes les actions.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.warningColor))),
                  ])),
              ...actions.map((action) => _buildActionCard(action)).toList(),
            ]);
        }

        final groups = groupSnapshot.data ?? [];
        
        if (groups.isEmpty) {
          // Si aucun groupe n'existe, afficher toutes les actions sans groupement
          return Column(
            children: actions.map((action) => _buildActionCard(action)).toList());
        }

        // Grouper les actions par groupe
        final groupedActions = <ActionGroup, List<PourVousAction>>{};
        final ungroupedActions = <PourVousAction>[];

        // Initialiser tous les groupes (même vides)
        for (final group in groups) {
          groupedActions[group] = [];
        }

        // Répartir les actions dans leurs groupes
        for (final action in actions) {
          if (action.groupId != null && action.groupId!.isNotEmpty) {
            final group = groups.firstWhere(
              (g) => g.id == action.groupId,
              orElse: () => ActionGroup(
                id: 'unknown',
                name: 'Autres',
                description: 'Actions non catégorisées',
                icon: Icons.folder_outlined,
                iconCodePoint: Icons.folder_outlined.codePoint.toString(),
                order: 999,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now()));
            
            if (groupedActions.containsKey(group)) {
              groupedActions[group]!.add(action);
            } else {
              ungroupedActions.add(action);
            }
          } else {
            ungroupedActions.add(action);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Afficher les groupes avec leurs actions
            ...groupedActions.entries.map((entry) {
              final group = entry.key;
              final groupActions = entry.value;
              
              // Ne pas afficher les groupes vides
              if (groupActions.isEmpty) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildGroupSection(group.name, groupActions, group));
            }).toList(),
            
            // Afficher les actions non groupées s'il y en a
            if (ungroupedActions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildGroupSection('Autres', ungroupedActions, null)),
            
            // Espace final pour éviter que le dernier élément soit collé au bas
            const SizedBox(height: 20),
          ]);
      });
  }

  Widget _buildGroupSection(String title, List<PourVousAction> actions, [ActionGroup? group]) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: 0),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0),
        ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: actions.isNotEmpty,
            backgroundColor: AppTheme.surfaceColor,
            collapsedBackgroundColor: AppTheme.surfaceColor,
            tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            childrenPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D29),
                letterSpacing: -0.4,
                height: 1.2)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group?.description != null && group!.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        group.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textTertiaryColor.withOpacity(0.6),
                          height: 1.3))),
                  Text(
                    actions.isEmpty 
                        ? 'Bientôt disponible' 
                        : '${actions.length} action${actions.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: actions.isEmpty 
                          ? AppTheme.textTertiaryColor.withOpacity(0.6)
                          : AppTheme.primaryColor.withOpacity(0.7))),
                ])),
            leading: Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: actions.isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.textTertiaryColor.withOpacity(0.4),
                          AppTheme.textTertiaryColor.withOpacity(0.3),
                        ])
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: group?.color != null
                            ? [
                                Color(int.parse(group!.color!.replaceFirst('#', '0xFF'))),
                                Color(int.parse(group.color!.replaceFirst('#', '0xFF'))).withOpacity(0.8),
                              ]
                            : [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: actions.isEmpty
                        ? AppTheme.textTertiaryColor.withOpacity(0.15)
                        : (group?.color != null
                            ? Color(int.parse(group!.color!.replaceFirst('#', '0xFF'))).withOpacity(0.25)
                            : AppTheme.primaryColor.withOpacity(0.25)),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
                ]),
              child: Icon(
                group?.icon ?? _getGroupIcon(title),
                color: AppTheme.surfaceColor,
                size: 22)),
            trailing: Icon(
              Icons.keyboard_arrow_down,
              color: actions.isEmpty ? AppTheme.textTertiaryColor.withOpacity(0.4) : AppTheme.primaryColor,
              size: 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.textTertiaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24))),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: actions.isEmpty
                    ? _buildEmptyGroupContent(title)
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.75),
                        itemCount: actions.length,
                        itemBuilder: (context, index) {
                          return _buildActionCard(actions[index]);
                        })),
            ]))));
  }

  Widget _buildEmptyGroupContent(String groupTitle) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.2), width: 1.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.textTertiaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16)),
            child: Icon(
              _getGroupIcon(groupTitle),
              size: 32,
              color: AppTheme.textTertiaryColor.withOpacity(0.4))),
          const SizedBox(height: 16),
          Text(
            'Fonctionnalités bientôt disponibles',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textTertiaryColor.withOpacity(0.6)),
            textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Cette section sera enrichie prochainement',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textTertiaryColor.withOpacity(0.5)),
            textAlign: TextAlign.center),
        ]));
  }

  IconData _getGroupIcon(String groupTitle) {
    switch (groupTitle) {
      case 'Relation avec les pasteurs':
        return Icons.people;
      case 'Participer aux services':
        return Icons.church;
      case 'Amélioration de l\'église':
        return Icons.lightbulb;
      case 'Vie spirituelle':
        return Icons.favorite;
      case 'En savoir plus sur l\'église':
        return Icons.info;
      default:
        return Icons.folder;
    }
  }

  Widget _buildActionCard(PourVousAction action) {
    final color = action.color != null 
        ? Color(int.parse(action.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _handleActionTap(action),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.surfaceColor,
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: 0),
            ]),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône ou image d'arrière-plan en haut avec design moderne
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    gradient: action.backgroundImageUrl == null 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              color.withOpacity(0.8),
                            ])
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0),
                    ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: action.backgroundImageUrl == null
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color,
                                  color.withOpacity(0.8),
                                ])),
                            child: Icon(
                              action.icon,
                              color: AppTheme.surfaceColor,
                              size: 28))
                        : Stack(
                            children: [
                              Image.network(
                                action.backgroundImageUrl!,
                                height: 64,
                                width: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback vers l'icône en cas d'erreur
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          color,
                                          color.withOpacity(0.8),
                                        ])),
                                    child: Icon(
                                      action.icon,
                                      color: AppTheme.surfaceColor,
                                      size: 28));
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          color.withOpacity(0.3),
                                          color.withOpacity(0.1),
                                        ])),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white))));
                                }),
                              // Overlay subtil pour améliorer la lisibilité
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ]))),
                            ]))),
                const SizedBox(height: 14),
                // Titre et description avec Flexible
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action.title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1D29),
                          height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Text(
                        action.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                          height: 1.35),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    ])),
              ])))));
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les actions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8))),
            child: Text(
              'Réessayer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        ]));
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Aucune action disponible',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Text(
            'Les actions seront bientôt disponibles',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor)),
        ]));
  }

  void _handleActionTap(PourVousAction action) {
    switch (action.actionType) {
      case 'navigation':
        _handleNavigation(action);
        break;
      case 'form':
        _handleForm(action);
        break;
      case 'external':
        _handleExternal(action);
        break;
      default:
        _showNotImplementedDialog(action.title);
    }
  }

  void _handleNavigation(PourVousAction action) {
    if (action.targetModule != null) {
      switch (action.targetModule) {
        case 'rendez_vous':
          // Navigation vers le module rendez-vous avec préservation du contexte
          _navigateToModuleWithContext('rendez_vous', action.title);
          break;
        case 'groupes':
          // Navigation vers le module groupes avec préservation du contexte
          _navigateToModuleWithContext('groupes', action.title);
          break;
        case 'mur_priere':
          // Navigation vers le module mur de prière avec préservation du contexte
          _navigateToModuleWithContext('mur_priere', action.title);
          break;
        case 'bible':
          // Navigation vers le module Bible
          _navigateToBottomNavModule(0, action.title); // Index 0 pour Bible
          break;
        case 'message':
          // Navigation vers le module Le Message
          _navigateToBottomNavModule(1, action.title); // Index 1 pour Le Message
          break;
        default:
          _showNotImplementedDialog(action.targetModule!);
      }
    } else {
      _showNotImplementedDialog(action.title);
    }
  }

  void _navigateToModuleWithContext(String targetModule, String actionTitle) {
    // Pour l'instant, affiche un message d'information
    // TODO: Implémenter la navigation réelle avec préservation du contexte
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigation vers $targetModule depuis "$actionTitle"',
          style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppTheme.surfaceColor,
          onPressed: () {})));
  }

  void _navigateToBottomNavModule(int moduleIndex, String actionTitle) {
    // Navigation vers les modules de la barre de navigation principale
    // Nous devons remonter à la racine et changer l'index de navigation
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // Déclencher un changement d'onglet dans la BottomNavigationBar
    // Ceci nécessite une communication avec le widget parent (MainPage)
    _showNavigationMessage(moduleIndex, actionTitle);
  }

  void _showNavigationMessage(int moduleIndex, String actionTitle) {
    final moduleName = moduleIndex == 0 ? 'Bible' : 'Le Message';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirection vers $moduleName depuis "$actionTitle"',
          style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Aller',
          textColor: AppTheme.surfaceColor,
          onPressed: () {
            // TODO: Implémenter la navigation réelle vers le module
            // Pour l'instant, afficher un message
            _showNotImplementedDialog('Navigation vers $moduleName');
          })));
  }

  void _handleForm(PourVousAction action) {
    switch (action.id) {
      case 'bapteme':
        _showBaptismForm();
        break;
      case 'question_pasteur':
        _showQuestionForm();
        break;
      case 'proposer_idee':
        _showIdeaForm();
        break;
      case 'signaler_probleme':
        _showProblemReportForm();
        break;
      case 'chant_special':
        _showSongForm();
        break;
      case 'infos_eglise':
        _showChurchInfo();
        break;
      case 'historique_eglise':
        _showChurchHistory();
        break;
      case 'photos_eglise':
        _showChurchPhotos();
        break;
      default:
        _showNotImplementedDialog(action.title);
    }
  }

  void _handleExternal(PourVousAction action) {
    _showNotImplementedDialog('Lien externe: ${action.title}');
  }

  void _showBaptismForm() {
    _showFormDialog(
      title: 'Demande de baptême',
      content: 'Formulaire de demande de baptême à implémenter');
  }

  void _showQuestionForm() {
    _showFormDialog(
      title: 'Question au pasteur',
      content: 'Formulaire de question au pasteur à implémenter');
  }

  void _showIdeaForm() {
    _showFormDialog(
      title: 'Proposer une idée',
      content: 'Formulaire de proposition d\'idée à implémenter');
  }

  void _showProblemReportForm() {
    _showFormDialog(
      title: 'Signaler un problème',
      content: 'Formulaire de signalement de problème à implémenter');
  }

  void _showSongForm() {
    _showFormDialog(
      title: 'Chant spécial',
      content: 'Formulaire de proposition de chant à implémenter');
  }

  void _showChurchInfo() {
    _showFormDialog(
      title: 'Informations sur l\'église',
      content: 'Page d\'informations sur l\'église à implémenter');
  }

  void _showChurchHistory() {
    _showFormDialog(
      title: 'Historique de l\'église',
      content: 'Page d\'historique de l\'église à implémenter');
  }

  void _showChurchPhotos() {
    _showFormDialog(
      title: 'Photos de l\'église',
      content: 'Galerie de photos de l\'église à implémenter');
  }

  void _showFormDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          content,
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor))),
        ]));
  }

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Fonctionnalité en développement',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'La fonctionnalité "$feature" sera bientôt disponible.',
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Compris',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor))),
        ]));
  }
}
