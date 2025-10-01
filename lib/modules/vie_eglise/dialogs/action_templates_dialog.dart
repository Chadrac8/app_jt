import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../services/pour_vous_action_service.dart';
import 'action_form_dialog.dart';
import '../../../theme.dart';

class ActionTemplatesDialog extends StatefulWidget {
  const ActionTemplatesDialog({Key? key}) : super(key: key);

  @override
  State<ActionTemplatesDialog> createState() => _ActionTemplatesDialogState();
}

class _ActionTemplatesDialogState extends State<ActionTemplatesDialog> {
  final PourVousActionService _actionService = PourVousActionService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Templates prédéfinis
  final List<Map<String, dynamic>> _predefinedTemplates = [
    {
      'title': 'Contacter un pasteur',
      'description': 'Prendre rendez-vous ou poser une question à l\'équipe pastorale',
      'actionType': 'contact',
      'icon': Icons.person,
      'color': '#4A90E2',
      'category': 'Relation pasteurs',
    },
    {
      'title': 'Demander une prière',
      'description': 'Partager une demande de prière avec la communauté',
      'actionType': 'form',
      'icon': Icons.favorite,
      'color': '#BD10E0',
      'category': 'Vie spirituelle',
    },
    {
      'title': 'S\'inscrire au service',
      'description': 'Participer activement aux services dominicaux',
      'actionType': 'form',
      'icon': Icons.church,
      'color': '#FF6B35',
      'category': 'Services',
    },
    {
      'title': 'Rejoindre un groupe',
      'description': 'Intégrer un groupe de croissance spirituelle',
      'actionType': 'navigation',
      'icon': Icons.group,
      'color': '#50E3C2',
      'category': 'Communauté',
    },
    {
      'title': 'Proposer une amélioration',
      'description': 'Suggérer des idées pour améliorer l\'église',
      'actionType': 'form',
      'icon': Icons.lightbulb,
      'color': '#F5A623',
      'category': 'Amélioration',
    },
    {
      'title': 'Demander des informations',
      'description': 'Obtenir plus d\'informations sur l\'église',
      'actionType': 'contact',
      'icon': Icons.info,
      'color': '#9013FE',
      'category': 'Information',
    },
    {
      'title': 'Témoigner',
      'description': 'Partager votre témoignage avec la communauté',
      'actionType': 'form',
      'icon': Icons.record_voice_over,
      'color': '#FF5722',
      'category': 'Témoignage',
    },
    {
      'title': 'Faire un don',
      'description': 'Contribuer financièrement à l\'œuvre de l\'église',
      'actionType': 'external',
      'icon': Icons.volunteer_activism,
      'color': '#795548',
      'category': 'Contribution',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildSearchBar(),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.dashboard_customize,
          color: AppTheme.primaryColor,
          size: 28,
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Text(
            'Templates d\'actions',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: AppTheme.textSecondaryColor,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Rechercher un template...',
        hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondaryColor),
        prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildTabs() {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppTheme.primaryColor, // Couleur primaire cohérente
              child: TabBar(
                labelColor: AppTheme.onPrimaryColor, // Texte blanc
                unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
                labelStyle: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
                unselectedLabelStyle: GoogleFonts.poppins(),
                indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text('Prédéfinis'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark, size: 16),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text('Mes templates'),
                    ],
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPredefinedTemplates(),
                  _buildSavedTemplates(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedTemplates() {
    final filteredTemplates = _predefinedTemplates.where((template) {
      if (_searchQuery.isEmpty) return true;
      return template['title'].toString().toLowerCase().contains(_searchQuery) ||
             template['description'].toString().toLowerCase().contains(_searchQuery) ||
             template['category'].toString().toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredTemplates.isEmpty) {
      return _buildEmptyState('Aucun template trouvé');
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = filteredTemplates[index];
        return _buildTemplateCard(template, isPredefined: true);
      },
    );
  }

  Widget _buildSavedTemplates() {
    return StreamBuilder<List<PourVousAction>>(
      stream: _actionService.getAllActions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Erreur lors du chargement');
        }

        final actions = snapshot.data ?? [];
        // Pour le moment, on affiche toutes les actions comme templates potentiels
        // Dans une vraie implémentation, on ajouterait une propriété isTemplate
        final templates = actions;
        
        final filteredTemplates = templates.where((template) {
          if (_searchQuery.isEmpty) return true;
          return template.title.toLowerCase().contains(_searchQuery) ||
                 template.description.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredTemplates.isEmpty) {
          return _buildEmptyState(
            _searchQuery.isEmpty 
                ? 'Aucun template sauvegardé\n\nUtilisez l\'option "Sauvegarder comme template" lors de la création d\'une action.'
                : 'Aucun template trouvé'
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: filteredTemplates.length,
          itemBuilder: (context, index) {
            final template = filteredTemplates[index];
            return _buildSavedTemplateCard(template);
          },
        );
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, {bool isPredefined = false}) {
    final Color cardColor = Color(int.parse(template['color'].replaceFirst('#', '0xFF')));
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withOpacity(0.1),
                cardColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      template['icon'],
                      color: cardColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      template['category'],
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize10,
                        color: cardColor,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                template['title'],
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  template['description'],
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppTheme.space12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _useTemplate(template),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Utiliser',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.white100,
                          fontWeight: AppTheme.fontMedium,
                        ),
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

  Widget _buildSavedTemplateCard(PourVousAction template) {
    Color cardColor = AppTheme.primaryColor;
    if (template.color != null) {
      try {
        cardColor = Color(int.parse(template.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        cardColor = AppTheme.primaryColor;
      }
    }
    
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cardColor.withOpacity(0.1),
              cardColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    template.icon,
                    color: cardColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'use':
                        _useSavedTemplate(template);
                        break;
                      case 'edit':
                        _editTemplate(template);
                        break;
                      case 'delete':
                        _deleteTemplate(template);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'use',
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow, size: 16),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text('Utiliser', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 16),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text('Modifier', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: AppTheme.errorColor),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text('Supprimer', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              template.title,
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.textPrimaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Expanded(
              child: Text(
                template.description,
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize12,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ElevatedButton(
              onPressed: () => _useSavedTemplate(template),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(double.infinity, 32),
              ),
              child: Text(
                'Utiliser',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize12,
                  color: AppTheme.white100,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _useTemplate(Map<String, dynamic> template) {
    Navigator.of(context).pop();
    
    // Créer une action basée sur le template
    final newAction = PourVousAction(
      id: '',
      title: template['title'],
      description: template['description'],
      actionType: template['actionType'],
      icon: template['icon'],
      iconCodePoint: template['icon'].codePoint.toString(),
      color: template['color'],
      isActive: true,
      order: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    showDialog(
      context: context,
      builder: (context) => ActionFormDialog(
        action: newAction,
      ),
    );
  }

  void _useSavedTemplate(PourVousAction template) {
    Navigator.of(context).pop();
    
    showDialog(
      context: context,
      builder: (context) => ActionFormDialog(
        action: template,
      ),
    );
  }

  void _editTemplate(PourVousAction template) {
    showDialog(
      context: context,
      builder: (context) => ActionFormDialog(action: template),
    );
  }

  void _deleteTemplate(PourVousAction template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le template',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le template "${template.title}" ?',
          style: GoogleFonts.poppins(),
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
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _actionService.deleteAction(template.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Template supprimé',
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(color: AppTheme.surfaceColor),
            ),
          ),
        ],
      ),
    );
  }
}
