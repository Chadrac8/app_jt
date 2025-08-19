import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../services/pour_vous_action_service.dart';

class PourVousTab extends StatefulWidget {
  const PourVousTab({Key? key}) : super(key: key);

  @override
  State<PourVousTab> createState() => _PourVousTabState();
}

class _PourVousTabState extends State<PourVousTab> {
  final PourVousActionService _actionService = PourVousActionService();
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
    
    await _actionService.ensureDefaultActionsExist();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              return _buildActionCard(actions[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.volunteer_activism,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pour vous',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Actions disponibles dans votre communauté',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(PourVousAction action) {
    final color = action.color != null 
        ? Color(int.parse(action.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleActionTap(action),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  color.withOpacity(0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      action.icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Flèche
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les actions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Réessayer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune action disponible',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les actions seront bientôt disponibles',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
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
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
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
      case 'chant_special':
        _showSongForm();
        break;
      case 'infos_eglise':
        _showChurchInfo();
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
      content: 'Formulaire de demande de baptême à implémenter',
    );
  }

  void _showQuestionForm() {
    _showFormDialog(
      title: 'Question au pasteur',
      content: 'Formulaire de question au pasteur à implémenter',
    );
  }

  void _showIdeaForm() {
    _showFormDialog(
      title: 'Proposer une idée',
      content: 'Formulaire de proposition d\'idée à implémenter',
    );
  }

  void _showSongForm() {
    _showFormDialog(
      title: 'Chant spécial',
      content: 'Formulaire de proposition de chant à implémenter',
    );
  }

  void _showChurchInfo() {
    _showFormDialog(
      title: 'Informations sur l\'église',
      content: 'Page d\'informations sur l\'église à implémenter',
    );
  }

  void _showFormDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Fonctionnalité en développement',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'La fonctionnalité "$feature" sera bientôt disponible.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Compris',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
