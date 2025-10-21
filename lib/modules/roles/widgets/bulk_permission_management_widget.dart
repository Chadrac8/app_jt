import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission_model.dart';
import '../providers/permission_provider.dart';
import '../services/advanced_roles_permissions_service.dart';
import '../../../../theme.dart';

/// Widget avancé pour la gestion des permissions et assignations en masse
class BulkPermissionManagementWidget extends StatefulWidget {
  const BulkPermissionManagementWidget({super.key});

  @override
  State<BulkPermissionManagementWidget> createState() => _BulkPermissionManagementWidgetState();
}

class _BulkPermissionManagementWidgetState extends State<BulkPermissionManagementWidget>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // États pour les opérations en masse
  final List<String> _selectedUsers = [];
  final List<String> _selectedRoles = [];
  
  // États des filtres
  String _searchQuery = '';
  String _selectedModule = '';
  PermissionLevel? _selectedLevel;
  bool _showOnlyActive = true;
  
  // État de chargement
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    final provider = Provider.of<PermissionProvider>(context, listen: false);
    await provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBulkAssignmentTab(),
                _buildBulkRevocationTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Gestion Avancée des Permissions'),
      actions: [
        IconButton(
          onPressed: _showHelpDialog,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Aide',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export_report',
              child: Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text('Rapport d\'analyse'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bulk_cleanup',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text('Nettoyage automatique'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'audit_log',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text('Journal d\'audit'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.group_add),
            text: 'Assignations',
          ),
          Tab(
            icon: Icon(Icons.group_remove),
            text: 'Révocations',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'Analyses',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres et Recherche',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            Row(
              children: [
                // Barre de recherche
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: AppTheme.space12),
                
                // Filtre par module
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedModule.isEmpty ? null : _selectedModule,
                    decoration: const InputDecoration(
                      labelText: 'Module',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Tous les modules'),
                      ),
                      ...AppModule.allModules.map((module) {
                        return DropdownMenuItem(
                          value: module.id,
                          child: Text(module.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedModule = value ?? '';
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: AppTheme.space12),
                
                // Filtre par niveau de permission
                Expanded(
                  child: DropdownButtonFormField<PermissionLevel>(
                    initialValue: _selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'Niveau',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tous les niveaux'),
                      ),
                      ...PermissionLevel.values.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Text(level.displayName),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLevel = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            Row(
              children: [
                FilterChip(
                  label: const Text('Actifs seulement'),
                  selected: _showOnlyActive,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyActive = selected;
                    });
                  },
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                ActionChip(
                  label: const Text('Réinitialiser filtres'),
                  avatar: const Icon(Icons.clear, size: 16),
                  onPressed: _resetFilters,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkAssignmentTab() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredRoles = _getFilteredRoles(provider.roles);
        
        return Column(
          children: [
            // Section de sélection des rôles
            Card(
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélection des Rôles à Assigner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filteredRoles.map((role) {
                        final isSelected = _selectedRoles.contains(role.id);
                        return FilterChip(
                          label: Text(role.name),
                          avatar: Icon(
                            _parseIcon(role.icon),
                            size: 16,
                            color: isSelected 
                                ? Colors.white 
                                : _parseColor(role.color),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedRoles.add(role.id);
                              } else {
                                _selectedRoles.remove(role.id);
                              }
                            });
                          },
                          selectedColor: _parseColor(role.color),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Section de sélection des utilisateurs
            _buildUserSelectionSection(),
            
            // Boutons d'action
            if (_selectedRoles.isNotEmpty && _selectedUsers.isNotEmpty)
              _buildBulkAssignmentActions(),
          ],
        );
      },
    );
  }

  Widget _buildBulkRevocationTab() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Révocation en Masse',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    
                    // Options de révocation
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _revokeExpiredRoles,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Révoquer les rôles expirés'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _revokeInactiveRoles,
                            icon: const Icon(Icons.person_off),
                            label: const Text('Révoquer des utilisateurs inactifs'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.space12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showBulkRevocationDialog,
                            icon: const Icon(Icons.group_remove),
                            label: const Text('Révocation sélective'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showRoleTransferDialog,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Transfert de rôles'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            _buildRevocationHistory(),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques générales
          _buildStatsOverview(),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Graphiques et analyses
          _buildPermissionAnalysis(),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Recommandations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildUserSelectionSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélection des Utilisateurs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            // Barre de recherche d'utilisateurs
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rechercher des utilisateurs...',
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            // Liste des utilisateurs sélectionnés
            if (_selectedUsers.isNotEmpty) ...[
              Text(
                'Utilisateurs sélectionnés (${_selectedUsers.length})',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedUsers.map((userId) {
                  return Chip(
                    label: Text('Utilisateur $userId'), // TODO: Récupérer le nom réel
                    onDeleted: () {
                      setState(() {
                        _selectedUsers.remove(userId);
                      });
                    },
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.grey300),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Center(
                  child: Text(
                    'Aucun utilisateur sélectionné\nUtilisez la barre de recherche pour trouver des utilisateurs',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.grey500),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBulkAssignmentActions() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions d\'Assignation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performBulkAssignment,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.group_add),
                    label: Text(_isLoading 
                        ? 'Assignation...' 
                        : 'Assigner les rôles'
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewBulkAssignment,
                    icon: const Icon(Icons.preview),
                    label: const Text('Aperçu des changements'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Consumer<PermissionProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vue d\'Ensemble',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Rôles Totaux',
                        '${provider.roles.length}',
                        Icons.admin_panel_settings,
                        AppTheme.blueStandard,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _buildStatCard(
                        'Permissions',
                        '${provider.permissions.length}',
                        Icons.security,
                        AppTheme.greenStandard,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _buildStatCard(
                        'Assignations',
                        '${provider.roles.length * 2}', // Estimation des assignations
                        Icons.people,
                        AppTheme.orangeStandard,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _buildStatCard(
                        'Modules',
                        '${provider.permissionsByModule.keys.length}',
                        Icons.apps,
                        AppTheme.pinkStandard,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyse des Permissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            const Text(
              'Graphiques et analyses détaillées à implémenter',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            
            // TODO: Implémenter des graphiques avec des packages comme fl_chart
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommandations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            _buildRecommendationItem(
              'Rôles inutilisés',
              'Certains rôles ne sont assignés à aucun utilisateur',
              Icons.info,
              AppTheme.blueStandard,
              () => _showUnusedRoles(),
            ),
            
            _buildRecommendationItem(
              'Permissions redondantes',
              'Optimisez les permissions en regroupant les rôles similaires',
              Icons.warning,
              AppTheme.orangeStandard,
              () => _showRedundantPermissions(),
            ),
            
            _buildRecommendationItem(
              'Audit de sécurité',
              'Vérifiez les permissions d\'accès sensibles',
              Icons.security,
              AppTheme.redStandard,
              () => _showSecurityAudit(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildRevocationHistory() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des Révocations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            const Text(
              'Historique des révocations récentes à implémenter',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButtons() {
    if (_tabController.index == 0) {
      return FloatingActionButton.extended(
        onPressed: _showQuickAssignDialog,
        icon: const Icon(Icons.flash_on),
        label: const Text('Assignation rapide'),
      );
    }
    return null;
  }

  // Méthodes utilitaires
  
  List<Role> _getFilteredRoles(List<Role> roles) {
    var filtered = roles;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((role) =>
          role.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          role.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_showOnlyActive) {
      filtered = filtered.where((role) => role.isActive).toList();
    }
    
    return filtered;
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return AppTheme.blueStandard;
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'edit': return Icons.edit;
      case 'visibility': return Icons.visibility;
      case 'security': return Icons.security;
      default: return Icons.admin_panel_settings;
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedModule = '';
      _selectedLevel = null;
      _showOnlyActive = true;
    });
  }

  void _searchUsers(String query) {
    // TODO: Implémenter la recherche d'utilisateurs
    // Pour l'instant, on simule en ajoutant des utilisateurs de test
    if (query.length >= 3) {
      setState(() {
        _selectedUsers.clear();
        _selectedUsers.addAll(['user1', 'user2', 'user3']); // Simulation
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_report':
        _exportAnalyticsReport();
        break;
      case 'bulk_cleanup':
        _performBulkCleanup();
        break;
      case 'audit_log':
        _showAuditLog();
        break;
    }
  }

  // Actions des méthodes
  
  Future<void> _performBulkAssignment() async {
    setState(() => _isLoading = true);
    
    try {
      for (final userId in _selectedUsers) {
        for (final roleId in _selectedRoles) {
          await AdvancedRolesPermissionsService.assignRoleToUser(
            userId,
            roleId,
            assignedBy: 'current_user_id',
          );
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assignation réussie: ${_selectedRoles.length} rôles assignés à ${_selectedUsers.length} utilisateurs',
          ),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
      
      // Réinitialiser les sélections
      setState(() {
        _selectedUsers.clear();
        _selectedRoles.clear();
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'assignation: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _previewBulkAssignment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aperçu des Assignations'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rôles à assigner: ${_selectedRoles.length}'),
              Text('Utilisateurs concernés: ${_selectedUsers.length}'),
              Text('Total d\'assignations: ${_selectedRoles.length * _selectedUsers.length}'),
              const SizedBox(height: AppTheme.spaceMedium),
              const Text(
                'Cette action créera de nouvelles assignations de rôles. '
                'Voulez-vous continuer ?',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkAssignment();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _revokeExpiredRoles() async {
    try {
      final count = await AdvancedRolesPermissionsService.cleanupExpiredRoles();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count rôles expirés révoqués'),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  void _revokeInactiveRoles() {
    // TODO: Implémenter la révocation des rôles d'utilisateurs inactifs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en cours de développement'),
      ),
    );
  }

  void _showBulkRevocationDialog() {
    // TODO: Implémenter le dialogue de révocation sélective
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dialogue de révocation sélective à implémenter'),
      ),
    );
  }

  void _showRoleTransferDialog() {
    // TODO: Implémenter le dialogue de transfert de rôles
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dialogue de transfert de rôles à implémenter'),
      ),
    );
  }

  void _showQuickAssignDialog() {
    // TODO: Implémenter l'assignation rapide
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assignation rapide à implémenter'),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide - Gestion Avancée'),
        content: const SingleChildScrollView(
          child: Text(
            'Cette interface permet de gérer les permissions en masse:\n\n'
            '• Onglet Assignations: Assigner plusieurs rôles à plusieurs utilisateurs\n'
            '• Onglet Révocations: Révoquer des rôles en masse ou par critères\n'
            '• Onglet Analyses: Visualiser les statistiques et recommandations\n\n'
            'Utilisez les filtres pour affiner vos selections.'
          ),
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

  void _exportAnalyticsReport() {
    // TODO: Implémenter l'export du rapport d'analyse
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export du rapport d\'analyse à implémenter'),
      ),
    );
  }

  void _performBulkCleanup() {
    // TODO: Implémenter le nettoyage en masse
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nettoyage automatique à implémenter'),
      ),
    );
  }

  void _showAuditLog() {
    // TODO: Implémenter l'affichage du journal d'audit
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journal d\'audit à implémenter'),
      ),
    );
  }

  void _showUnusedRoles() {
    // TODO: Implémenter l'affichage des rôles inutilisés
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affichage des rôles inutilisés à implémenter'),
      ),
    );
  }

  void _showRedundantPermissions() {
    // TODO: Implémenter l'affichage des permissions redondantes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyse des permissions redondantes à implémenter'),
      ),
    );
  }

  void _showSecurityAudit() {
    // TODO: Implémenter l'audit de sécurité
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audit de sécurité à implémenter'),
      ),
    );
  }
}