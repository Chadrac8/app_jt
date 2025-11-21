import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/person_model.dart';
import '../services/events_firebase_service.dart';

/// Dialog pour assigner rapidement des équipes à un événement de service
/// Style Planning Center avec recherche et sélection rapide
class QuickAssignDialog extends StatefulWidget {
  final EventModel event;
  
  const QuickAssignDialog({
    super.key,
    required this.event,
  });

  @override
  State<QuickAssignDialog> createState() => _QuickAssignDialogState();
}

class _QuickAssignDialogState extends State<QuickAssignDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<PersonModel> _allPeople = [];
  List<PersonModel> _filteredPeople = [];
  final Set<String> _selectedPersonIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedPersonIds.addAll(widget.event.responsibleIds);
    _loadPeople();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('people')
          .where('status', isEqualTo: 'active')
          .orderBy('firstName')
          .get();
      
      final people = snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc))
          .toList();
      
      setState(() {
        _allPeople = people;
        _filteredPeople = people;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPeople(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPeople = _allPeople;
      } else {
        _filteredPeople = _allPeople.where((person) {
          final searchLower = query.toLowerCase();
          return person.firstName.toLowerCase().contains(searchLower) ||
                 person.lastName.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  void _togglePerson(String personId) {
    setState(() {
      if (_selectedPersonIds.contains(personId)) {
        _selectedPersonIds.remove(personId);
      } else {
        _selectedPersonIds.add(personId);
      }
    });
  }

  Future<void> _save() async {
    try {
      // Mettre à jour l'événement avec les nouveaux responsibles
      final updatedEvent = widget.event.copyWith(
        responsibleIds: _selectedPersonIds.toList(),
        updatedAt: DateTime.now(),
      );
      
      await EventsFirebaseService.updateEvent(updatedEvent);
      
      if (mounted) {
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigner des bénévoles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Compteur de sélection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedPersonIds.length} bénévole(s) sélectionné(s)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un bénévole...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterPeople('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterPeople,
            ),
            
            const SizedBox(height: 16),
            
            // Liste des personnes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPeople.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun bénévole trouvé',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPeople.length,
                          itemBuilder: (context, index) {
                            final person = _filteredPeople[index];
                            final isSelected = _selectedPersonIds.contains(person.id);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) => _togglePerson(person.id),
                              title: Text(
                                '${person.firstName} ${person.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: person.roles.isNotEmpty
                                  ? Text(person.roles.join(', '))
                                  : null,
                              secondary: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(
                                  '${person.firstName[0]}${person.lastName[0]}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
