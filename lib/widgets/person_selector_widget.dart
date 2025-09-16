import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/firebase_service.dart';
import '../theme.dart';

/// Widget réutilisable pour sélectionner des personnes
class PersonSelectorWidget extends StatefulWidget {
  final List<String> selectedPersonIds;
  final Function(List<String>) onSelectionChanged;
  final String label;
  final String hint;
  final bool multiSelect;
  final int? maxSelection;

  const PersonSelectorWidget({
    Key? key,
    required this.selectedPersonIds,
    required this.onSelectionChanged,
    this.label = 'Personnes',
    this.hint = 'Sélectionner des personnes',
    this.multiSelect = true,
    this.maxSelection,
  }) : super(key: key);

  @override
  State<PersonSelectorWidget> createState() => _PersonSelectorWidgetState();
}

class _PersonSelectorWidgetState extends State<PersonSelectorWidget> {
  List<PersonModel> _selectedPersons = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedPersons();
  }

  @override
  void didUpdateWidget(PersonSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPersonIds != widget.selectedPersonIds) {
      _loadSelectedPersons();
    }
  }

  Future<void> _loadSelectedPersons() async {
    if (widget.selectedPersonIds.isEmpty) {
      setState(() {
        _selectedPersons = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final persons = <PersonModel>[];
      for (final id in widget.selectedPersonIds) {
        final person = await FirebaseService.getPerson(id);
        if (person != null) {
          persons.add(person);
        }
      }
      setState(() {
        _selectedPersons = persons;
      });
    } catch (e) {
      print('Erreur lors du chargement des personnes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showPersonSelector() async {
    final selectedPersons = await showDialog<List<PersonModel>>(
      context: context,
      builder: (context) => PersonSelectorDialog(
        selectedPersonIds: widget.selectedPersonIds,
        multiSelect: widget.multiSelect,
        maxSelection: widget.maxSelection,
      ),
    );

    if (selectedPersons != null) {
      final selectedIds = selectedPersons.map((p) => p.id).toList();
      widget.onSelectionChanged(selectedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showPersonSelector,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Chargement...'),
                    ],
                  )
                : _selectedPersons.isEmpty
                    ? Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: AppTheme.textTertiaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.hint,
                            style: TextStyle(
                              color: AppTheme.textTertiaryColor,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedPersons.length > 3) ...[
                            Text(
                              '${_selectedPersons.length} personne(s) sélectionnée(s)',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _selectedPersons.take(3).map((person) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundImage: person.profileImageUrl != null
                                      ? NetworkImage(person.profileImageUrl!)
                                      : null,
                                  child: person.profileImageUrl == null
                                      ? Text(
                                          person.displayInitials,
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                ),
                                label: Text(
                                  person.fullName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                          if (_selectedPersons.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '... et ${_selectedPersons.length - 3} autre(s)',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}

/// Dialog pour sélectionner des personnes
class PersonSelectorDialog extends StatefulWidget {
  final List<String> selectedPersonIds;
  final bool multiSelect;
  final int? maxSelection;

  const PersonSelectorDialog({
    Key? key,
    required this.selectedPersonIds,
    this.multiSelect = true,
    this.maxSelection,
  }) : super(key: key);

  @override
  State<PersonSelectorDialog> createState() => _PersonSelectorDialogState();
}

class _PersonSelectorDialogState extends State<PersonSelectorDialog> {
  List<PersonModel> _allPersons = [];
  List<PersonModel> _filteredPersons = [];
  List<PersonModel> _selectedPersons = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersons() async {
    try {
      final persons = await FirebaseService.getAllPersons();
      setState(() {
        _allPersons = persons;
        _filteredPersons = persons;
        _selectedPersons = persons
            .where((p) => widget.selectedPersonIds.contains(p.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des personnes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPersons(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
      if (searchTerm.isEmpty) {
        _filteredPersons = _allPersons;
      } else {
        _filteredPersons = _allPersons.where((person) {
          return person.fullName.toLowerCase().contains(searchTerm.toLowerCase()) ||
                 person.email.toLowerCase().contains(searchTerm.toLowerCase()) ||
                 (person.phone?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  void _toggleSelection(PersonModel person) {
    setState(() {
      final isSelected = _selectedPersons.any((p) => p.id == person.id);
      
      if (isSelected) {
        _selectedPersons.removeWhere((p) => p.id == person.id);
      } else {
        if (widget.multiSelect) {
          // Vérifier la limite de sélection
          if (widget.maxSelection == null || _selectedPersons.length < widget.maxSelection!) {
            _selectedPersons.add(person);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vous ne pouvez sélectionner que ${widget.maxSelection} personne(s) maximum'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Sélection unique
          _selectedPersons = [person];
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.multiSelect ? 'Sélectionner des personnes' : 'Sélectionner une personne'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par nom, email ou téléphone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _filterPersons,
            ),
            
            const SizedBox(height: 16),
            
            // Compteur de sélection
            if (widget.multiSelect && _selectedPersons.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedPersons.length} personne(s) sélectionnée(s)' +
                      (widget.maxSelection != null ? ' / ${widget.maxSelection}' : ''),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Liste des personnes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPersons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchTerm.isEmpty ? Icons.people_outline : Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchTerm.isEmpty
                                    ? 'Aucune personne trouvée'
                                    : 'Aucun résultat pour "$_searchTerm"',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPersons.length,
                          itemBuilder: (context, index) {
                            final person = _filteredPersons[index];
                            final isSelected = _selectedPersons.any((p) => p.id == person.id);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(person),
                              title: Text(
                                person.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (person.email.isNotEmpty)
                                    Text(person.email),
                                  if (person.phone?.isNotEmpty == true)
                                    Text(person.phone!),
                                ],
                              ),
                              secondary: CircleAvatar(
                                backgroundImage: person.profileImageUrl != null
                                    ? NetworkImage(person.profileImageUrl!)
                                    : null,
                                child: person.profileImageUrl == null
                                    ? Text(person.displayInitials)
                                    : null,
                              ),
                              activeColor: AppTheme.primaryColor,
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
          onPressed: _selectedPersons.isNotEmpty
              ? () => Navigator.pop(context, _selectedPersons)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            widget.multiSelect
                ? 'Sélectionner (${_selectedPersons.length})'
                : 'Sélectionner',
          ),
        ),
      ],
    );
  }
}