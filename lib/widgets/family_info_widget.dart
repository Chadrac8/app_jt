import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/family_service.dart';
import '../../theme.dart';
import '../pages/family_detail_page.dart';
import '../pages/family_form_page.dart';

class FamilyInfoWidget extends StatefulWidget {
  final PersonModel person;
  final VoidCallback? onFamilyChanged;

  const FamilyInfoWidget({
    Key? key,
    required this.person,
    this.onFamilyChanged,
  }) : super(key: key);

  @override
  State<FamilyInfoWidget> createState() => _FamilyInfoWidgetState();
}

class _FamilyInfoWidgetState extends State<FamilyInfoWidget> {
  FamilyModel? _family;
  List<PersonModel> _familyMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    if (widget.person.familyId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final family = await FamilyService.getFamily(widget.person.familyId!);
      final members = await FamilyService.getFamilyMembers(widget.person.familyId!);
      
      setState(() {
        _family = family;
        _familyMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading family info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.person.familyId == null) {
      return _buildNoFamilyCard();
    }

    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.family_restroom, color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    'Famille',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    if (_family == null) {
      return _buildNoFamilyCard();
    }

    return _buildFamilyCard();
  }

  Widget _buildNoFamilyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Famille',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: _handleFamilyAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'create',
                      child: ListTile(
                        leading: Icon(Icons.add),
                        title: Text('Créer une famille'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'join',
                      child: ListTile(
                        leading: Icon(Icons.group_add),
                        title: Text('Rejoindre une famille'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Aucune famille',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: AppTheme.fontMedium,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    'Cette personne n\'appartient à aucune famille',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard() {
    final parents = _family!.getParents(_familyMembers);
    final children = _family!.getChildren(_familyMembers);
    final others = _familyMembers.where((m) => 
        m.familyRole != FamilyRole.parent && 
        m.familyRole != FamilyRole.head && 
        m.familyRole != FamilyRole.child).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Famille ${_family!.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: _handleFamilyAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Voir la famille'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Modifier la famille'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app, color: AppTheme.redStandard),
                        title: Text('Quitter la famille', style: TextStyle(color: AppTheme.redStandard)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Statut et rôle de la personne
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_family!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRoleIcon(widget.person.familyRole),
                    size: 16,
                    color: _getStatusColor(_family!.status),
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    _getRoleLabel(widget.person.familyRole),
                    style: TextStyle(
                      color: _getStatusColor(_family!.status),
                      fontWeight: AppTheme.fontMedium,
                      fontSize: AppTheme.fontSize12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Informations de base de la famille
            if (_family!.fullAddress.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      _family!.fullAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
            ],

            if (_family!.homePhone != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    _family!.homePhone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
            ],

            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  '${_familyMembers.length} membre${_familyMembers.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Aperçu des membres
            if (_familyMembers.isNotEmpty) ...[
              Text(
                'Membres de la famille',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: AppTheme.fontMedium,
                    ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              
              if (parents.isNotEmpty) ...[
                _buildMemberPreview('Parents', parents),
                const SizedBox(height: AppTheme.spaceSmall),
              ],
              
              if (children.isNotEmpty) ...[
                _buildMemberPreview('Enfants', children),
                const SizedBox(height: AppTheme.spaceSmall),
              ],
              
              if (others.isNotEmpty) ...[
                _buildMemberPreview('Autres', others),
              ],

              const SizedBox(height: AppTheme.space12),
              
              // Bouton pour voir tous les détails
              Center(
                child: TextButton.icon(
                  onPressed: () => _viewFamilyDetails(),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Voir tous les détails'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberPreview(String title, List<PersonModel> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: AppTheme.fontMedium,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: members.take(3).map((member) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.displayInitials,
                          style: const TextStyle(fontSize: 8),
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  member.firstName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (member.id == _family!.headOfFamilyId) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.star,
                    size: 10,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ],
            ),
          )).toList(),
        ),
        if (members.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '... et ${members.length - 3} autre${members.length - 3 > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  void _handleFamilyAction(String action) {
    switch (action) {
      case 'create':
        _createFamily();
        break;
      case 'join':
        _joinFamily();
        break;
      case 'view':
        _viewFamilyDetails();
        break;
      case 'edit':
        _editFamily();
        break;
      case 'leave':
        _leaveFamily();
        break;
    }
  }

  void _createFamily() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FamilyFormPage(),
      ),
    );

    if (result == true) {
      await _loadFamilyInfo();
      widget.onFamilyChanged?.call();
    }
  }

  void _joinFamily() async {
    try {
      final families = await FamilyService.getFamiliesStream().first;
      
      final selectedFamily = await showDialog<FamilyModel>(
        context: context,
        builder: (context) => _FamilySelectorDialog(families: families),
      );

      if (selectedFamily != null) {
        await FamilyService.addPersonToFamily(
          widget.person.id,
          selectedFamily.id,
          role: FamilyRole.other,
        );
        
        await _loadFamilyInfo();
        widget.onFamilyChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ajouté à la famille ${selectedFamily.name}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _viewFamilyDetails() {
    if (_family != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyDetailPage(familyId: _family!.id),
        ),
      );
    }
  }

  void _editFamily() async {
    if (_family != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyFormPage(family: _family),
        ),
      );

      if (result == true) {
        await _loadFamilyInfo();
        widget.onFamilyChanged?.call();
      }
    }
  }

  void _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Quitter la famille'),
        content: Text(
          'Êtes-vous sûr de vouloir quitter la famille "${_family!.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: AppTheme.white100,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (confirmed == true && _family != null) {
      try {
        await FamilyService.removePersonFromFamily(widget.person.id, _family!.id);
        
        setState(() {
          _family = null;
          _familyMembers = [];
        });
        
        widget.onFamilyChanged?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vous avez quitté la famille'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(FamilyStatus status) {
    switch (status) {
      case FamilyStatus.member:
        return AppTheme.greenStandard;
      case FamilyStatus.visitor:
        return AppTheme.blueStandard;
      case FamilyStatus.attendee:
        return AppTheme.orangeStandard;
      case FamilyStatus.inactive:
        return AppTheme.grey500;
      case FamilyStatus.inactive_member:
        return AppTheme.redStandard;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getRoleIcon(FamilyRole role) {
    switch (role) {
      case FamilyRole.head:
        return Icons.star;
      case FamilyRole.parent:
        return Icons.person;
      case FamilyRole.child:
        return Icons.child_care;
      default:
        return Icons.person_outline;
    }
  }

  String _getRoleLabel(FamilyRole role) {
    switch (role) {
      case FamilyRole.head:
        return 'Chef de famille';
      case FamilyRole.parent:
        return 'Parent';
      case FamilyRole.child:
        return 'Enfant';
      default:
        return 'Membre';
    }
  }
}

class _FamilySelectorDialog extends StatefulWidget {
  final List<FamilyModel> families;

  const _FamilySelectorDialog({required this.families});

  @override
  State<_FamilySelectorDialog> createState() => _FamilySelectorDialogState();
}

class _FamilySelectorDialogState extends State<_FamilySelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final filteredFamilies = widget.families.where((family) {
      if (_searchTerm.isEmpty) return true;
      return family.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
             family.fullAddress.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Rejoindre une famille'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher une famille...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(
              child: filteredFamilies.isEmpty
                  ? const Center(
                      child: Text('Aucune famille trouvée'),
                    )
                  : ListView.builder(
                      itemCount: filteredFamilies.length,
                      itemBuilder: (context, index) {
                        final family = filteredFamilies[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(family.name[0].toUpperCase()),
                          ),
                          title: Text(family.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (family.fullAddress.isNotEmpty)
                                Text(family.fullAddress),
                              Text('${family.memberIds.length} membre${family.memberIds.length > 1 ? 's' : ''}'),
                            ],
                          ),
                          onTap: () => Navigator.pop(context, family),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}