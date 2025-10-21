import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/action_group.dart';
import '../services/action_group_service.dart';
import 'group_form_dialog.dart';

class GroupManagementDialog extends StatefulWidget {
  const GroupManagementDialog({Key? key}) : super(key: key);

  @override
  State<GroupManagementDialog> createState() => _GroupManagementDialogState();
}

class _GroupManagementDialogState extends State<GroupManagementDialog> {
  final ActionGroupService _groupService = ActionGroupService();
  final TextEditingController _searchController = TextEditingController();
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
            _buildStats(),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(child: _buildGroupsList()),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.folder_outlined,
          color: AppTheme.primaryColor,
          size: 28,
        ),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Text(
            'Gestion des groupes',
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
        hintText: 'Rechercher un groupe...',
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

  Widget _buildStats() {
    return StreamBuilder<List<ActionGroup>>(
      stream: _groupService.getAllGroups(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final groups = snapshot.data!;
        final activeGroups = groups.where((g) => g.isActive).length;
        final inactiveGroups = groups.length - activeGroups;

        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  groups.length.toString(),
                  Icons.folder,
                  AppTheme.primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.textTertiaryColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Actifs',
                  activeGroups.toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.textTertiaryColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Inactifs',
                  inactiveGroups.toString(),
                  Icons.pause_circle,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontSemiBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: AppTheme.fontSize12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList() {
    return StreamBuilder<List<ActionGroup>>(
      stream: _groupService.getAllGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Erreur lors du chargement',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          );
        }

        final allGroups = snapshot.data ?? [];
        final filteredGroups = allGroups.where((group) {
          if (_searchQuery.isEmpty) return true;
          return group.name.toLowerCase().contains(_searchQuery) ||
                 group.description.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty ? Icons.folder_off : Icons.search_off,
                  size: 64,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  _searchQuery.isEmpty 
                      ? 'Aucun groupe trouvé'
                      : 'Aucun résultat pour "$_searchQuery"',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: AppTheme.spaceSmall),
                  TextButton.icon(
                    onPressed: _initializeDefaultGroups,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Créer les groupes par défaut',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredGroups.length,
          itemBuilder: (context, index) {
            final group = filteredGroups[index];
            return _buildGroupCard(group);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(ActionGroup group) {
    Color groupColor = AppTheme.primaryColor;
    if (group.color != null) {
      try {
        groupColor = Color(int.parse(group.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        groupColor = AppTheme.primaryColor;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: groupColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            group.icon,
            color: groupColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: GoogleFonts.poppins(
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            if (!group.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  'Inactif',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.warningColor,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.description,
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            FutureBuilder<int>(
              future: _groupService.countActionsInGroup(group.id),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text(
                  '$count action${count > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.primaryColor,
                    fontWeight: AppTheme.fontMedium,
                  ),
                );
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ordre: ${group.order}',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Créé le ${_formatDate(group.createdAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editGroup(group),
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          'Modifier',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _duplicateGroup(group),
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(
                          'Dupliquer',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleGroupStatus(group),
                        icon: Icon(
                          group.isActive ? Icons.pause : Icons.play_arrow,
                          size: 16,
                        ),
                        label: Text(
                          group.isActive ? 'Désactiver' : 'Activer',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteGroup(group),
                      icon: const Icon(Icons.delete, size: 16),
                      label: Text(
                        'Supprimer',
                        style: GoogleFonts.poppins(),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _initializeDefaultGroups,
            icon: const Icon(Icons.restore),
            label: Text(
              'Groupes par défaut',
              style: GoogleFonts.poppins(),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _createNewGroup,
            icon: const Icon(Icons.add),
            label: Text(
              'Nouveau groupe',
              style: GoogleFonts.poppins(color: AppTheme.surfaceColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _createNewGroup() {
    showDialog(
      context: context,
      builder: (context) => const GroupFormDialog(),
    );
  }

  void _editGroup(ActionGroup group) {
    showDialog(
      context: context,
      builder: (context) => GroupFormDialog(group: group),
    );
  }

  void _duplicateGroup(ActionGroup group) {
    showDialog(
      context: context,
      builder: (context) => GroupFormDialog(
        group: group,
        isDuplicate: true,
      ),
    );
  }

  Future<void> _toggleGroupStatus(ActionGroup group) async {
    try {
      final success = await _groupService.toggleGroupStatus(group.id, !group.isActive);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Statut du groupe modifié',
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
  }

  void _confirmDeleteGroup(ActionGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le groupe',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le groupe "${group.name}" ?\n\nCette action est irréversible.',
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
            onPressed: () {
              Navigator.of(context).pop();
              _deleteGroup(group);
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

  Future<void> _deleteGroup(ActionGroup group) async {
    try {
      final success = await _groupService.deleteGroup(group.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Groupe supprimé',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.errorColor,
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
  }

  Future<void> _initializeDefaultGroups() async {
    try {
      await _groupService.initializeDefaultGroups();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Groupes par défaut initialisés',
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
  }
}
