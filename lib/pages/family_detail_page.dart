import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/family_service.dart';
import '../../theme.dart';
import 'family_form_page.dart';
import 'person_form_page.dart';

class FamilyDetailPage extends StatefulWidget {
  final String familyId;

  const FamilyDetailPage({Key? key, required this.familyId}) : super(key: key);

  @override
  State<FamilyDetailPage> createState() => _FamilyDetailPageState();
}

class _FamilyDetailPageState extends State<FamilyDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  FamilyModel? _family;
  List<PersonModel> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFamilyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final family = await FamilyService.getFamily(widget.familyId);
      final members = await FamilyService.getFamilyMembers(widget.familyId);

      setState(() {
        _family = family;
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_family == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Famille introuvable')),
        body: const Center(
          child: Text('Cette famille n\'existe pas ou a été supprimée.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_family!.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Infos'),
            Tab(icon: Icon(Icons.people), text: 'Membres'),
            Tab(icon: Icon(Icons.history), text: 'Activité'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Modifier'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'add_member',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Ajouter membre'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: AppTheme.redStandard),
                  title: Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildMembersTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        children: [
          _buildFamilyHeader(),
          const SizedBox(height: AppTheme.spaceLarge),
          _buildInfoCard(),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildAddressCard(),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildContactCard(),
          if (_family!.notes != null) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            _buildNotesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _getStatusColor(_family!.status).withOpacity(0.2),
              child: _family!.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        _family!.photoUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.family_restroom, size: 40, color: _getStatusColor(_family!.status)),
                      ),
                    )
                  : Icon(Icons.family_restroom, size: 40, color: _getStatusColor(_family!.status)),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _family!.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_family!.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Text(
                _getStatusLabel(_family!.status),
                style: TextStyle(
                  color: _getStatusColor(_family!.status),
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  '${_members.length} membre${_members.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            if (_family!.tags.isNotEmpty) ...[
              Text(
                'Étiquettes',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _family!.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: AppTheme.fontSize12)),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                )).toList(),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
            ],
            _buildInfoRow('Créée le', _formatDate(_family!.createdAt)),
            _buildInfoRow('Modifiée le', _formatDate(_family!.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    if (_family!.fullAddress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adresse',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Text(
                    _family!.fullAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    final hasContact = _family!.homePhone != null ||
                      _family!.emergencyContact != null ||
                      _family!.emergencyPhone != null;

    if (!hasContact) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            if (_family!.homePhone != null) ...[
              _buildContactRow(
                Icons.phone,
                'Téléphone domicile',
                _family!.homePhone!,
              ),
              const SizedBox(height: AppTheme.space12),
            ],
            if (_family!.emergencyContact != null) ...[
              _buildContactRow(
                Icons.emergency,
                'Contact d\'urgence',
                _family!.emergencyContact!,
              ),
              const SizedBox(height: AppTheme.space12),
            ],
            if (_family!.emergencyPhone != null) ...[
              _buildContactRow(
                Icons.phone_in_talk,
                'Téléphone d\'urgence',
                _family!.emergencyPhone!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              _family!.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucun membre',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Ajoutez des personnes à cette famille',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ElevatedButton.icon(
              onPressed: () => _handleMenuAction('add_member'),
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter un membre'),
            ),
          ],
        ),
      );
    }

    final parents = _family!.getParents(_members);
    final children = _family!.getChildren(_members);
    final others = _members.where((m) => 
        m.familyRole != FamilyRole.parent && 
        m.familyRole != FamilyRole.head && 
        m.familyRole != FamilyRole.child).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      children: [
        if (parents.isNotEmpty) ...[
          _buildMemberSection('Parents', parents),
          const SizedBox(height: AppTheme.spaceMedium),
        ],
        if (children.isNotEmpty) ...[
          _buildMemberSection('Enfants', children),
          const SizedBox(height: AppTheme.spaceMedium),
        ],
        if (others.isNotEmpty) ...[
          _buildMemberSection('Autres membres', others),
        ],
      ],
    );
  }

  Widget _buildMemberSection(String title, List<PersonModel> members) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final member = members[index];
                return _buildMemberTile(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(PersonModel member) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: member.profileImageUrl != null
                ? NetworkImage(member.profileImageUrl!)
                : null,
            child: member.profileImageUrl == null
                ? Text(member.displayInitials)
                : null,
          ),
          if (member.id == _family!.headOfFamilyId)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.white100, width: 2),
                ),
                padding: const EdgeInsets.all(AppTheme.space2),
                child: const Icon(
                  Icons.star,
                  size: 12,
                  color: AppTheme.white100,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        member.fullName,
        style: const TextStyle(fontWeight: AppTheme.fontMedium),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (member.id == _family!.headOfFamilyId)
            const Text(
              'Chef de famille',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
          if (member.birthDate != null)
            Text(
              'Né(e) le ${_formatDate(member.birthDate!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (member.phone != null)
            Text(
              member.phone!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleMemberAction(value, member),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: ListTile(
              leading: Icon(Icons.visibility),
              title: Text('Voir profil'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (member.id != _family!.headOfFamilyId)
            const PopupMenuItem(
              value: 'set_head',
              child: ListTile(
                leading: Icon(Icons.star),
                title: Text('Définir comme chef'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const PopupMenuItem(
            value: 'remove',
            child: ListTile(
              leading: Icon(Icons.remove_circle, color: AppTheme.redStandard),
              title: Text('Retirer de la famille', style: TextStyle(color: AppTheme.redStandard)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      onTap: () => _viewMemberProfile(member),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.grey500,
          ),
          SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Historique d\'activité',
            style: TextStyle(fontSize: AppTheme.fontSize18, fontWeight: AppTheme.fontBold),
          ),
          SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Fonctionnalité en cours de développement',
            style: TextStyle(color: AppTheme.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: AppTheme.fontMedium,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: AppTheme.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editFamily();
        break;
      case 'add_member':
        _addMember();
        break;
      case 'delete':
        _deleteFamily();
        break;
    }
  }

  void _handleMemberAction(String action, PersonModel member) {
    switch (action) {
      case 'view':
        _viewMemberProfile(member);
        break;
      case 'set_head':
        _setAsHead(member);
        break;
      case 'remove':
        _removeMember(member);
        break;
    }
  }

  void _editFamily() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyFormPage(family: _family),
      ),
    );

    if (result == true) {
      _loadFamilyData();
    }
  }

  void _addMember() {
    // TODO: Implémenter l'ajout de membre
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité en cours de développement')),
    );
  }

  void _deleteFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Supprimer la famille'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la famille "${_family!.name}" ?\n\n'
          'Cette action supprimera également tous les liens familiaux des membres.',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FamilyService.deleteFamily(_family!.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Famille "${_family!.name}" supprimée'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _viewMemberProfile(PersonModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonFormPage(person: member),
      ),
    );
  }

  void _setAsHead(PersonModel member) async {
    try {
      await FamilyService.setFamilyHead(_family!.id, member.id);
      _loadFamilyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.fullName} est maintenant chef de famille'),
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

  void _removeMember(PersonModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: const Text('Retirer de la famille'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer ${member.fullName} de cette famille ?',
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
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FamilyService.removePersonFromFamily(member.id, _family!.id);
        _loadFamilyData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.fullName} retiré de la famille'),
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

  String _getStatusLabel(FamilyStatus status) {
    switch (status) {
      case FamilyStatus.member:
        return 'Membre';
      case FamilyStatus.visitor:
        return 'Visiteur';
      case FamilyStatus.attendee:
        return 'Participant';
      case FamilyStatus.inactive:
        return 'Inactif';
      case FamilyStatus.inactive_member:
        return 'Ex-membre';
      default:
        return 'Actif';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}