import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/pour_vous_action.dart';
import '../services/pour_vous_action_service.dart';
import '../dialogs/action_form_dialog.dart';
import '../dialogs/group_management_dialog.dart';
import '../dialogs/action_templates_dialog.dart';

class AdminPourVousTab extends StatefulWidget {
  const AdminPourVousTab({Key? key}) : super(key: key);

  @override
  State<AdminPourVousTab> createState() => _AdminPourVousTabState();
}

class _AdminPourVousTabState extends State<AdminPourVousTab> {
  final PourVousActionService _actionService = PourVousActionService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingWidget() : _buildContent()),
        ]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: _showGroupManagementDialog,
            backgroundColor: AppTheme.warningColor,
            heroTag: "groups",
            child: Icon(Icons.group, size: 20, color: AppTheme.surfaceColor),
            tooltip: 'Gérer les groupes'),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: _showTemplatesDialog,
            backgroundColor: AppTheme.primaryColor,
            heroTag: "templates",
            child: Icon(Icons.list, size: 20, color: AppTheme.surfaceColor),
            tooltip: 'Actions suggérées'),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _showAddActionDialog,
            backgroundColor: AppTheme.primaryColor,
            heroTag: "add",
            child: Icon(Icons.add, color: AppTheme.surfaceColor),
            tooltip: 'Créer une action'),
        ]));
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textTertiaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppTheme.primaryColor,
                size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gestion des actions "Pour vous"',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor))),
              // Boutons d'actions rapides
              IconButton(
                icon: const Icon(Icons.file_download),
                onPressed: _exportActions,
                tooltip: 'Exporter',
                color: AppTheme.primaryColor),
              IconButton(
                icon: const Icon(Icons.file_upload),
                onPressed: _importActions,
                tooltip: 'Importer',
                color: AppTheme.primaryColor),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshActions,
                tooltip: 'Actualiser',
                color: AppTheme.primaryColor),
            ]),
          const SizedBox(height: 8),
          Text(
            'Configurez les actions disponibles pour les membres',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 16),
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une action...',
              hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondaryColor),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      })
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.textTertiaryColor.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            style: GoogleFonts.poppins()),
        ]));
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    return StreamBuilder<List<PourVousAction>>(
      stream: _actionService.getAllActions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        final allActions = snapshot.data ?? [];
        
        // Filtrer les actions selon la recherche
        final filteredActions = _searchQuery.isEmpty
            ? allActions
            : allActions.where((action) {
                return action.title.toLowerCase().contains(_searchQuery) ||
                       action.description.toLowerCase().contains(_searchQuery) ||
                       action.actionType.toLowerCase().contains(_searchQuery);
              }).toList();

        if (filteredActions.isEmpty) {
          return _searchQuery.isNotEmpty 
              ? _buildNoResultsWidget()
              : _buildEmptyWidget();
        }

        return Column(
          children: [
            _buildStatsCard(allActions),
            if (_searchQuery.isNotEmpty) _buildSearchResultsHeader(filteredActions.length, allActions.length),
            Expanded(
              child: _buildActionsList(filteredActions)),
          ]);
      });
  }

  Widget _buildStatsCard(List<PourVousAction> actions) {
    final activeCount = actions.where((a) => a.isActive).length;
    final inactiveCount = actions.length - activeCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textTertiaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1)),
        ]),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              actions.length.toString(),
              Icons.list,
              AppTheme.primaryColor)),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.textTertiaryColor.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Actives',
              activeCount.toString(),
              Icons.check_circle,
              AppTheme.successColor)),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.textTertiaryColor.withOpacity(0.3)),
          Expanded(
            child: _buildStatItem(
              'Inactives',
              inactiveCount.toString(),
              Icons.pause_circle,
              AppTheme.warningColor)),
        ]));
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: AppTheme.fontBold,
            color: color)),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondaryColor)),
      ]);
  }

  Widget _buildSearchResultsHeader(int filteredCount, int totalCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
      child: Row(
        children: [
          Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$filteredCount résultat${filteredCount > 1 ? 's' : ''} sur $totalCount action${totalCount > 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.primaryColor,
                fontWeight: AppTheme.fontMedium))),
        ]));
  }

  Widget _buildActionsList(List<PourVousAction> actions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(action, index);
      });
  }

  Widget _buildActionCard(PourVousAction action, int index) {
    final color = action.color != null 
        ? Color(int.parse(action.color!.replaceFirst('#', '0xFF')))
        : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
          child: Icon(
            action.icon,
            color: color,
            size: 24)),
        title: Text(
          action.title,
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              action.description,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: action.isActive 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  child: Text(
                    action.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: AppTheme.fontSemiBold,
                      color: action.isActive 
                          ? AppTheme.successColor
                          : AppTheme.warningColor))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  child: Text(
                    action.actionType,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.primaryColor))),
              ]),
          ]),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                action.isActive ? Icons.pause : Icons.play_arrow,
                color: action.isActive ? AppTheme.warningColor : AppTheme.successColor),
              onPressed: () => _toggleActionStatus(action),
              tooltip: action.isActive ? 'Désactiver' : 'Activer'),
            IconButton(
              icon: Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () => _showEditActionDialog(action),
              tooltip: 'Modifier'),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppTheme.textSecondaryColor),
              onSelected: (value) {
                switch (value) {
                  case 'preview':
                    _previewAction(action);
                    break;
                  case 'duplicate':
                    _duplicateAction(action);
                    break;
                  case 'delete':
                    _confirmDeleteAction(action);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 20),
                      const SizedBox(width: 8),
                      Text('Prévisualiser', style: GoogleFonts.poppins()),
                    ])),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 20),
                      const SizedBox(width: 8),
                      Text('Dupliquer', style: GoogleFonts.poppins()),
                    ])),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Text('Supprimer', style: GoogleFonts.poppins(color: AppTheme.errorColor)),
                    ])),
              ]),
          ])));
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
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center),
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
            'Aucune action configurée',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Utilisez les templates pour créer des actions prédéfinies',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: AppTheme.fontMedium)),
              ])),
        ]));
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier votre recherche',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondaryColor)),
        ]));
  }

  // Actions et méthodes de gestion
  Future<void> _toggleActionStatus(PourVousAction action) async {
    final success = await _actionService.toggleActionStatus(action.id, !action.isActive);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action.isActive ? 'Action désactivée' : 'Action activée',
            style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primaryColor));
    }
  }

  void _confirmDeleteAction(PourVousAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer l\'action',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold)),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${action.title}" ?',
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: AppTheme.textSecondaryColor))),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteAction(action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(color: AppTheme.surfaceColor))),
        ]));
  }

  Future<void> _deleteAction(PourVousAction action) async {
    final success = await _actionService.deleteAction(action.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Action supprimée',
            style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primaryColor));
    }
  }

  void _previewAction(PourVousAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Prévisualisation',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: AppTheme.fontSemiBold)),
            const SizedBox(height: 8),
            Text(
              action.description,
              style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Text(
              'Type: ${action.actionType}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondaryColor)),
          ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: GoogleFonts.poppins(color: AppTheme.primaryColor))),
        ]));
  }

  void _duplicateAction(PourVousAction action) {
    _showEditActionDialog(action, isDuplicate: true);
  }

  void _showAddActionDialog() {
    _showEditActionDialog(null);
  }

  void _showEditActionDialog(PourVousAction? action, {bool isDuplicate = false}) {
    showDialog(
      context: context,
      builder: (context) => ActionFormDialog(
        action: action,
        isDuplicate: isDuplicate,
      ),
    );
  }

  void _showGroupManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => const GroupManagementDialog(),
    );
  }

  void _showTemplatesDialog() {
    showDialog(
      context: context,
      builder: (context) => const ActionTemplatesDialog(),
    );
  }

  void _exportActions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exporter les actions',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez le format d\'export :',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text('JSON', style: GoogleFonts.poppins()),
              subtitle: Text('Format de données structurées', style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () => _performExport('json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text('CSV', style: GoogleFonts.poppins()),
              subtitle: Text('Tableau compatible Excel', style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () => _performExport('csv'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _performExport(String format) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export $format en cours... Cette fonctionnalité sera bientôt disponible',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _importActions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Importer des actions',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Importez des actions depuis :',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text('Fichier JSON', style: GoogleFonts.poppins()),
              subtitle: Text('Importer depuis un fichier de données', style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () => _performImport('file'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text('Templates en ligne', style: GoogleFonts.poppins()),
              subtitle: Text('Bibliothèque de templates prédéfinis', style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () => _performImport('online'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _performImport(String source) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Import depuis $source en cours... Cette fonctionnalité sera bientôt disponible',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _refreshActions() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulation d'actualisation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Actions actualisées',
              style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryColor));
      }
    });
  }
}
