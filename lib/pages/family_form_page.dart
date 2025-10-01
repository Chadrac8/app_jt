import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/family_service.dart';
import '../services/firebase_service.dart';
import '../../theme.dart';

class FamilyFormPage extends StatefulWidget {
  final FamilyModel? family;

  const FamilyFormPage({Key? key, this.family}) : super(key: key);

  @override
  State<FamilyFormPage> createState() => _FamilyFormPageState();
}

class _FamilyFormPageState extends State<FamilyFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _homePhoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  FamilyStatus _selectedStatus = FamilyStatus.active;
  String? _selectedHeadOfFamily;
  List<String> _tags = [];
  List<PersonModel> _availablePersons = [];
  List<PersonModel> _selectedMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadAvailablePersons();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _homePhoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.family != null) {
      final family = widget.family!;
      _nameController.text = family.name;
      _addressController.text = family.address ?? '';
      _cityController.text = family.city ?? '';
      _stateController.text = family.state ?? '';
      _zipCodeController.text = family.zipCode ?? '';
      _countryController.text = family.country ?? '';
      _homePhoneController.text = family.homePhone ?? '';
      
      // Handle emergency contacts - use first one if available
      if (family.emergencyContacts.isNotEmpty) {
        _emergencyContactController.text = family.emergencyContacts.first.name;
        _emergencyPhoneController.text = family.emergencyContacts.first.phone;
      }
      
      _notesController.text = family.notes ?? '';
      _selectedStatus = family.status;
      _selectedHeadOfFamily = family.headOfFamilyId;
      _tags = List.from(family.tags);
    }
  }

  Future<void> _loadAvailablePersons() async {
    try {
      final persons = await FirebaseService.getPersonsStream().first;
      setState(() {
        _availablePersons = persons;
        
        // Si on modifie une famille, charger ses membres
        if (widget.family != null) {
          _selectedMembers = persons
              .where((p) => widget.family!.memberIds.contains(p.id))
              .toList();
        }
      });
    } catch (e) {
      print('Error loading persons: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.family == null ? 'Nouvelle Famille' : 'Modifier Famille'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveFamily,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildAddressSection(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildContactSection(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildMembersSection(),
            const SizedBox(height: AppTheme.spaceLarge),
            _buildAdditionalInfoSection(),
            const SizedBox(height: AppTheme.spaceXLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la famille',
                prefixIcon: Icon(Icons.family_restroom),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom de la famille est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            DropdownButtonFormField<FamilyStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Statut',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
              items: FamilyStatus.values.map((status) => DropdownMenuItem(
                value: status,
                child: Text(_getStatusLabel(status)),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
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
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'Région',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Code postal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Pays',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
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
            TextFormField(
              controller: _homePhoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone domicile',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(
                labelText: 'Contact d\'urgence',
                prefixIcon: Icon(Icons.emergency),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone d\'urgence',
                prefixIcon: Icon(Icons.phone_in_talk),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Membres de la famille',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showPersonSelector,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            if (_selectedMembers.isNotEmpty) ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedMembers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final member = _selectedMembers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.profileImageUrl != null
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl == null
                          ? Text(member.displayInitials)
                          : null,
                    ),
                    title: Text(member.fullName),
                    subtitle: member.id == _selectedHeadOfFamily
                        ? const Text('Chef de famille', style: TextStyle(color: AppTheme.primaryColor))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (member.id != _selectedHeadOfFamily)
                          IconButton(
                            icon: const Icon(Icons.star_border),
                            onPressed: () => _setAsHead(member.id),
                            tooltip: 'Définir comme chef de famille',
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeMember(member),
                          tooltip: 'Retirer de la famille',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceXLarge),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      'Aucun membre ajouté',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'Ajoutez des personnes à cette famille',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations supplémentaires',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Étiquettes',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                    )),
                ActionChip(
                  label: const Text('+ Ajouter'),
                  onPressed: _showAddTagDialog,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonSelector() async {
    final availablePersons = _availablePersons
        .where((p) => !_selectedMembers.any((m) => m.id == p.id))
        .toList();

    final selectedPersons = await showDialog<List<PersonModel>>(
      context: context,
      builder: (context) => _PersonSelectorDialog(
        availablePersons: availablePersons,
        selectedPersons: [],
      ),
    );

    if (selectedPersons != null) {
      setState(() {
        _selectedMembers.addAll(selectedPersons);
        // Si c'est le premier membre et qu'il n'y a pas de chef, le définir comme chef
        if (_selectedHeadOfFamily == null && _selectedMembers.isNotEmpty) {
          _selectedHeadOfFamily = _selectedMembers.first.id;
        }
      });
    }
  }

  void _removeMember(PersonModel member) {
    setState(() {
      _selectedMembers.removeWhere((m) => m.id == member.id);
      if (_selectedHeadOfFamily == member.id) {
        _selectedHeadOfFamily = _selectedMembers.isNotEmpty ? _selectedMembers.first.id : null;
      }
    });
  }

  void _setAsHead(String personId) {
    setState(() {
      _selectedHeadOfFamily = personId;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAddTagDialog() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une étiquette'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom de l\'étiquette',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  Future<void> _saveFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create emergency contacts list
      List<EmergencyContact> emergencyContacts = [];
      if (_emergencyContactController.text.trim().isNotEmpty && 
          _emergencyPhoneController.text.trim().isNotEmpty) {
        emergencyContacts.add(EmergencyContact(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _emergencyContactController.text.trim(),
          phone: _emergencyPhoneController.text.trim(),
          relationship: 'Emergency Contact', // Default relationship
          isPrimary: true,
        ));
      }
      
      final familyData = FamilyModel(
        id: widget.family?.id ?? '',
        name: _nameController.text.trim(),
        headOfFamilyId: _selectedHeadOfFamily,
        memberIds: _selectedMembers.map((m) => m.id).toList(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty ? null : _zipCodeController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        homePhone: _homePhoneController.text.trim().isEmpty ? null : _homePhoneController.text.trim(),
        emergencyContacts: emergencyContacts,
        status: _selectedStatus,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.family?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.family == null) {
        // Créer nouvelle famille
        final familyId = await FamilyService.createFamily(familyData);
        
        // Ajouter les membres à la famille
        for (final member in _selectedMembers) {
          await FamilyService.addPersonToFamily(
            member.id,
            familyId,
            role: member.id == _selectedHeadOfFamily ? FamilyRole.head : FamilyRole.other,
          );
        }
      } else {
        // Mettre à jour famille existante
        await FamilyService.updateFamily(familyData);
        
        // Gérer les changements de membres
        final currentMemberIds = widget.family!.memberIds;
        final newMemberIds = _selectedMembers.map((m) => m.id).toList();
        
        // Retirer les anciens membres
        for (final oldMemberId in currentMemberIds) {
          if (!newMemberIds.contains(oldMemberId)) {
            await FamilyService.removePersonFromFamily(oldMemberId, widget.family!.id);
          }
        }
        
        // Ajouter les nouveaux membres
        for (final newMemberId in newMemberIds) {
          if (!currentMemberIds.contains(newMemberId)) {
            await FamilyService.addPersonToFamily(
              newMemberId,
              widget.family!.id,
              role: newMemberId == _selectedHeadOfFamily ? FamilyRole.head : FamilyRole.other,
            );
          }
        }
        
        // Mettre à jour le chef de famille si changé
        if (_selectedHeadOfFamily != widget.family!.headOfFamilyId && _selectedHeadOfFamily != null) {
          await FamilyService.setFamilyHead(widget.family!.id, _selectedHeadOfFamily!);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.family == null ? 'Famille créée avec succès' : 'Famille mise à jour'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
}

class _PersonSelectorDialog extends StatefulWidget {
  final List<PersonModel> availablePersons;
  final List<PersonModel> selectedPersons;

  const _PersonSelectorDialog({
    required this.availablePersons,
    required this.selectedPersons,
  });

  @override
  State<_PersonSelectorDialog> createState() => _PersonSelectorDialogState();
}

class _PersonSelectorDialogState extends State<_PersonSelectorDialog> {
  late List<PersonModel> _selectedPersons;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _selectedPersons = List.from(widget.selectedPersons);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPersons = widget.availablePersons.where((person) {
      if (_searchTerm.isEmpty) return true;
      return person.fullName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
             person.email.toLowerCase().contains(_searchTerm.toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Sélectionner des personnes'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher...',
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
              child: ListView.builder(
                itemCount: filteredPersons.length,
                itemBuilder: (context, index) {
                  final person = filteredPersons[index];
                  final isSelected = _selectedPersons.any((p) => p.id == person.id);
                  
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedPersons.add(person);
                        } else {
                          _selectedPersons.removeWhere((p) => p.id == person.id);
                        }
                      });
                    },
                    title: Text(person.fullName),
                    subtitle: Text(person.email),
                    secondary: CircleAvatar(
                      backgroundImage: person.profileImageUrl != null
                          ? NetworkImage(person.profileImageUrl!)
                          : null,
                      child: person.profileImageUrl == null
                          ? Text(person.displayInitials)
                          : null,
                    ),
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
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedPersons),
          child: Text('Ajouter (${_selectedPersons.length})'),
        ),
      ],
    );
  }
}