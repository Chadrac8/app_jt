import 'package:flutter/material.dart';
import '../models/person_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../services/bulk_actions_service.dart';
import '../../theme.dart';

class PeopleListDetailPage extends StatefulWidget {
  final String listId;
  final String listName;
  // TODO: Passer le modèle complet si besoin

  const PeopleListDetailPage({Key? key, required this.listId, required this.listName}) : super(key: key);

  @override
  State<PeopleListDetailPage> createState() => _PeopleListDetailPageState();
}

class _PeopleListDetailPageState extends State<PeopleListDetailPage> {
  final BulkActionsService _bulkActionsService = BulkActionsService();
  final List<String> _standardFields = [
    'firstName', 'lastName', 'email', 'phone', 'gender', 'roles', 'tags',
  ];
  Set<String> get _allFields => {
    ..._standardFields,
    ...filteredPersons.expand((p) => p.customFields.keys)
  };
  final List<String> _operators = ['==', '<', '>', 'contains'];
  int? _selectedIndex;
  Set<String> _selectedPersonIds = {};
  List<Map<String, dynamic>> filters = [];
  List<PersonModel> filteredPersons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.listId == 'anniversaires_aujourdhui') {
      filters = [
        {
          'field': 'birthDate',
          'operator': 'isToday',
          'value': null,
        }
      ];
      _applyFilters();
    } else {
      _loadListAndResults();
    }
  }

  Future<void> _loadListAndResults() async {
    setState(() => _isLoading = true);
    // Charger la liste et ses filtres
    final doc = await FirebaseFirestore.instance.collection('people_lists').doc(widget.listId).get();
    if (doc.exists) {
      final data = doc.data()!;
      filters = List<Map<String, dynamic>>.from(data['filters'] ?? []);
    }
    await _applyFilters();
    setState(() => _isLoading = false);
  }

  Future<void> _applyFilters() async {
    // Récupère toutes les personnes (ou un sous-ensemble large)
    final snap = await FirebaseFirestore.instance.collection('persons').get();
    final allPersons = snap.docs.map((doc) => PersonModel.fromFirestore(doc)).toList();

    DateTime now = DateTime.now();

    bool isBirthdayToday(DateTime? birthDate) {
      if (birthDate == null) return false;
      return birthDate.day == now.day && birthDate.month == now.month;
    }

    bool isThisMonth(DateTime? birthDate) {
      if (birthDate == null) return false;
      return birthDate.month == now.month && birthDate.year == now.year;
    }

    bool isThisYear(DateTime? birthDate) {
      if (birthDate == null) return false;
      return birthDate.year == now.year;
    }

    bool matchesAllFilters(PersonModel person) {
      bool evalFilter(Map<String, dynamic> filter) {
        final field = filter['field'] as String;
        final op = filter['operator'] as String;
        final value = filter['value'];
        dynamic fieldValue;
        if (field == 'age') {
          fieldValue = person.age;
        } else if (field == 'birthDate') {
          fieldValue = person.birthDate;
        } else if (field.startsWith('customFields.')) {
          final key = field.replaceFirst('customFields.', '');
          fieldValue = person.customFields[key];
        } else {
          fieldValue = person.toFirestore()[field];
        }
        switch (op) {
          case '==':
            return fieldValue == value;
          case '!=':
            return fieldValue != value;
          case '<':
            return fieldValue is Comparable && value is Comparable ? fieldValue.compareTo(value) < 0 : false;
          case '<=':
            return fieldValue is Comparable && value is Comparable ? fieldValue.compareTo(value) <= 0 : false;
          case '>':
            return fieldValue is Comparable && value is Comparable ? fieldValue.compareTo(value) > 0 : false;
          case '>=':
            return fieldValue is Comparable && value is Comparable ? fieldValue.compareTo(value) >= 0 : false;
          case 'contains':
            if (fieldValue is String && value is String) {
              return fieldValue.toLowerCase().contains(value.toLowerCase());
            } else if (fieldValue is Iterable) {
              return fieldValue.contains(value);
            }
            return false;
          case 'not contains':
            if (fieldValue is String && value is String) {
              return !fieldValue.toLowerCase().contains(value.toLowerCase());
            } else if (fieldValue is Iterable) {
              return !fieldValue.contains(value);
            }
            return false;
          case 'in':
            if (value is Iterable) {
              return value.contains(fieldValue);
            }
            return false;
          case 'not in':
            if (value is Iterable) {
              return !value.contains(fieldValue);
            }
            return false;
          case 'startsWith':
            if (fieldValue is String && value is String) {
              return fieldValue.toLowerCase().startsWith(value.toLowerCase());
            }
            return false;
          case 'endsWith':
            if (fieldValue is String && value is String) {
              return fieldValue.toLowerCase().endsWith(value.toLowerCase());
            }
            return false;
          case 'isEmpty':
            if (fieldValue is String) return fieldValue.isEmpty;
            if (fieldValue is Iterable) return fieldValue.isEmpty;
            return false;
          case 'isNotEmpty':
            if (fieldValue is String) return fieldValue.isNotEmpty;
            if (fieldValue is Iterable) return fieldValue.isNotEmpty;
            return false;
          case 'between':
            if (field == 'age' && value is List && value.length == 2) {
              return fieldValue != null && fieldValue >= value[0] && fieldValue <= value[1];
            }
            if (fieldValue is Comparable && value is List && value.length == 2) {
              return fieldValue.compareTo(value[0]) >= 0 && fieldValue.compareTo(value[1]) <= 0;
            }
            return false;
          case 'not between':
            if (field == 'age' && value is List && value.length == 2) {
              return fieldValue != null && (fieldValue < value[0] || fieldValue > value[1]);
            }
            if (fieldValue is Comparable && value is List && value.length == 2) {
              return fieldValue.compareTo(value[0]) < 0 || fieldValue.compareTo(value[1]) > 0;
            }
            return false;
          case 'matches':
            if (fieldValue is String && value is String) {
              try {
                return RegExp(value, caseSensitive: false).hasMatch(fieldValue);
              } catch (_) {
                return false;
              }
            }
            return false;
          // Opérateurs avancés pour les dates
          case 'isToday':
            if (field == 'birthDate') {
              return isBirthdayToday(fieldValue);
            }
            if (fieldValue is DateTime) {
              return fieldValue.day == now.day && fieldValue.month == now.month && fieldValue.year == now.year;
            }
            return false;
          case 'isBeforeToday':
            if (fieldValue is DateTime) {
              return fieldValue.isBefore(DateTime(now.year, now.month, now.day));
            }
            return false;
          case 'isAfterToday':
            if (fieldValue is DateTime) {
              return fieldValue.isAfter(DateTime(now.year, now.month, now.day));
            }
            return false;
          case 'isThisMonth':
            if (field == 'birthDate') {
              return isThisMonth(fieldValue);
            }
            if (fieldValue is DateTime) {
              return fieldValue.month == now.month && fieldValue.year == now.year;
            }
            return false;
          case 'isThisYear':
            if (field == 'birthDate') {
              return isThisYear(fieldValue);
            }
            if (fieldValue is DateTime) {
              return fieldValue.year == now.year;
            }
            return false;
          default:
            return false;
        }
      }

      // Logique imbriquée linéaire (chaque filtre a un connecteur logique avec le précédent)
      bool result = filters.isNotEmpty ? evalFilter(filters[0]) : true;
      for (int i = 1; i < filters.length; i++) {
        final logic = filters[i]['logic'] ?? 'AND';
        final filterResult = evalFilter(filters[i]);
        if (logic == 'AND') {
          result = result && filterResult;
        } else if (logic == 'OR') {
          result = result || filterResult;
        } else if (logic == 'NOT') {
          result = result && !filterResult;
        }
      }
      return result;
    }

    filteredPersons = allPersons.where(matchesAllFilters).toList();
    setState(() {});
  }

  void _addFilter() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedField = _allFields.isNotEmpty ? _allFields.first : '';
        String selectedOperator = _operators.first;
        String value = '';
        return AlertDialog(
          title: const Text('Ajouter un filtre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedField,
                items: _allFields.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => selectedField = v ?? '',
                decoration: const InputDecoration(labelText: 'Champ'),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedOperator,
                items: _operators.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => selectedOperator = v ?? '==',
                decoration: const InputDecoration(labelText: 'Opérateur'),
              ),
              TextFormField(
                onChanged: (v) => value = v,
                decoration: const InputDecoration(labelText: 'Valeur'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  filters.add({'field': selectedField, 'operator': selectedOperator, 'value': value});
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _removeFilter(int index) {
    setState(() {
      filters.removeAt(index);
    });
    _applyFilters();
  }

  void _exportCSV() {
    // Exporter filteredPersons en CSV (champs standards + customFields)
    if (filteredPersons.isEmpty) return;
    final headers = <String>{
      'firstName', 'lastName', 'email', 'phone', 'gender', 'roles', 'tags',
      ...filteredPersons.expand((p) => p.customFields.keys)
    };
    final rows = [
      headers.toList(),
      ...filteredPersons.map((p) => headers.map((h) {
        if (p.toFirestore().containsKey(h)) {
          return p.toFirestore()[h]?.toString() ?? '';
        } else if (p.customFields.containsKey(h)) {
          return p.customFields[h]?.toString() ?? '';
        } else {
          return '';
        }
      }).toList()),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    _saveAndShareCSV(csv);
  }

  Future<void> _saveAndShareCSV(String csv) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/liste_personnes.csv');
    await file.writeAsString(csv);
    // Partage natif du fichier CSV
    await Share.shareXFiles([XFile(file.path)], text: 'Export CSV de la liste : ${widget.listName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exporté et prêt à être partagé : ${file.path}')),
    );
  }


  Future<void> _handleBulkAction(String action) async {
    final selectedPersons = filteredPersons.where((p) => _selectedPersonIds.contains(p.id)).toList();
    if (selectedPersons.isEmpty) return;
    if (action == 'tag') {
      String? tag;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ajouter un tag'),
            content: TextFormField(
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Tag'),
              onChanged: (v) => tag = v.trim(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (tag != null && tag!.isNotEmpty) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      );
      if (tag != null && tag!.isNotEmpty) {
        setState(() => _isLoading = true);
        final result = await _bulkActionsService.addTag(people: selectedPersons, tag: tag!);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.success ? 'Tag ajouté à ${result.successCount}/${result.totalCount} personnes.' : 'Erreur: ${result.errors.join(", ")}')),
        );
        await _applyFilters();
      }
    } else if (action == 'message') {
      // Structure pour envoyer un message (à adapter selon votre infra)
      String? message;
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Envoyer un message'),
            content: TextFormField(
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
              onChanged: (v) => message = v.trim(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (message != null && message!.isNotEmpty) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      );
      if (message != null && message!.isNotEmpty) {
        setState(() => _isLoading = true);
        final result = await _bulkActionsService.sendMessage(people: selectedPersons, message: message!);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.success ? 'Message envoyé à ${result.successCount}/${result.totalCount} personnes.' : 'Erreur: ${result.errors.join(", ")}')),
        );
      }
    }
    else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer les personnes sélectionnées ?'),
          content: const Text('Cette action est irréversible. Confirmez-vous la suppression de toutes les personnes sélectionnées ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _isLoading = true);
        final result = await _bulkActionsService.deletePersons(people: selectedPersons);
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.success ? 'Supprimé ${result.successCount}/${result.totalCount} personnes.' : 'Erreur: ${result.errors.join(", ")}')),
        );
        await _applyFilters();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBirthdayList = widget.listId == 'anniversaires_aujourdhui';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Hero(
              tag: 'list_avatar_${widget.listId}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      isBirthdayList
                          ? AppTheme.primaryColor.withOpacity(0.18)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.18),
                      isBirthdayList
                          ? AppTheme.warningColor.withOpacity(0.32)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  isBirthdayList ? Icons.cake : Icons.list,
                  color: isBirthdayList ? AppTheme.pinkStandard : AppTheme.blueStandard,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                widget.listName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: AppTheme.fontBold,
                  color: isBirthdayList ? AppTheme.pinkStandard : null,
                ),
              ),
            ),
            if (isBirthdayList)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.cake, color: AppTheme.pinkStandard, size: 28),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exporter CSV',
            onPressed: _exportCSV,
          ),
          if (_selectedPersonIds.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Actions groupées',
              onSelected: (action) async {
                await _handleBulkAction(action);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.greenStandard),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            action == 'tag'
                                ? 'Action tag terminée !'
                                : action == 'message'
                                    ? 'Message envoyé !'
                                    : 'Action terminée.',
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'tag', child: Text('Ajouter un tag')),
                const PopupMenuItem(value: 'message', child: Text('Envoyer un message')),
                const PopupMenuItem(value: 'delete', child: Text('Supprimer les personnes sélectionnées')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFilter,
        icon: const Icon(Icons.filter_alt),
        label: const Text('Ajouter un filtre'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                children: [
                  if (isBirthdayList)
                    Card(
                      elevation: 3,
                      color: AppTheme.pinkStandard.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Icon(Icons.cake, color: AppTheme.pinkStandard, size: 32),
                            const SizedBox(width: AppTheme.spaceMedium),
                            Expanded(
                              child: Text(
                                "🎉 Voici toutes les personnes dont c'est l'anniversaire aujourd'hui !",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.pinkStandard, fontWeight: AppTheme.fontBold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.filter_alt, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: AppTheme.spaceSmall),
                                Text('Filtres actifs', style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceSmall),
                            if (filters.isEmpty)
                              Text('Aucun filtre appliqué.', style: Theme.of(context).textTheme.bodyMedium),
                            ...filters.asMap().entries.map((entry) {
                              final i = entry.key;
                              final filter = entry.value;
                              return Dismissible(
                                key: ValueKey('filter_$i'),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _removeFilter(i),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  color: AppTheme.redStandard.withOpacity(0.15),
                                  child: const Icon(Icons.delete, color: AppTheme.redStandard),
                                ),
                                child: Card(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: const Icon(Icons.tune),
                                    title: Text('${filter['field']}'),
                                    subtitle: Text('Opérateur: ${filter['operator']} | Valeur: ${filter['value']}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _removeFilter(i),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space18),
                  Row(
                    children: [
                      Icon(Icons.people, color: isBirthdayList ? AppTheme.pinkStandard : Theme.of(context).colorScheme.primary),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        isBirthdayList ? 'Anniversaires du jour' : 'Résultats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isBirthdayList ? AppTheme.pinkStandard : null,
                          fontWeight: isBirthdayList ? AppTheme.fontBold : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  if (filteredPersons.isEmpty)
                    Card(
                      color: isBirthdayList ? AppTheme.pinkStandard.withOpacity(0.08) : Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            isBirthdayList
                                ? "Aucun anniversaire aujourd'hui."
                                : 'Aucun résultat pour ces filtres.',
                            style: TextStyle(color: isBirthdayList ? AppTheme.pinkStandard : null),
                          ),
                        ),
                      ),
                    )
                  else
                    AnimatedList(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      initialItemCount: filteredPersons.length,
                      itemBuilder: (context, index, animation) {
                        final person = filteredPersons[index];
                        final selected = _selectedPersonIds.contains(person.id);
                        return SizeTransition(
                          sizeFactor: animation,
                          child: Card(
                            elevation: selected ? 6 : 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            color: isBirthdayList ? AppTheme.pinkStandard.withOpacity(0.06) : null,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedPersonIds.remove(person.id);
                                  } else {
                                    _selectedPersonIds.add(person.id);
                                  }
                                });
                              },
                              child: ListTile(
                                leading: Hero(
                                  tag: 'avatar_${person.id}',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeInOut,
                                    width: selected ? 54 : 44,
                                    height: selected ? 54 : 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? (isBirthdayList ? AppTheme.pinkStandard : Theme.of(context).colorScheme.primary)
                                            : Colors.transparent,
                                        width: selected ? 3 : 0,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: (isBirthdayList ? AppTheme.pinkStandard : Theme.of(context).colorScheme.primary).withOpacity(0.18),
                                                blurRadius: 12,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: person.profileImageUrl != null && person.profileImageUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              person.profileImageUrl!,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Stack(
                                            children: [
                                              Center(
                                                child: Text(
                                                  person.displayInitials,
                                                  style: TextStyle(
                                                    fontWeight: AppTheme.fontBold,
                                                    color: isBirthdayList ? AppTheme.pinkStandard : AppTheme.blueStandard,
                                                    fontSize: AppTheme.fontSize20,
                                                  ),
                                                ),
                                              ),
                                              if (person.roles.isNotEmpty)
                                                Positioned(
                                                  bottom: 2,
                                                  right: 2,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(AppTheme.space2),
                                                    decoration: BoxDecoration(
                                                      color: isBirthdayList ? AppTheme.pinkStandard : Theme.of(context).colorScheme.secondary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.star, size: 12, color: AppTheme.white100),
                                                  ),
                                                ),
                                              if (person.tags.isNotEmpty)
                                                Positioned(
                                                  top: 2,
                                                  right: 2,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(AppTheme.space2),
                                                    decoration: BoxDecoration(
                                                      color: isBirthdayList ? AppTheme.pinkStandard : AppTheme.greenStandard,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.label, size: 12, color: AppTheme.white100),
                                                  ),
                                                ),
                                              if (isBirthdayList && person.birthDate != null)
                                                Positioned(
                                                  bottom: 2,
                                                  left: 2,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(AppTheme.space2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.orangeStandard,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.cake, size: 12, color: AppTheme.white100),
                                                  ),
                                                ),
                                            ],
                                          ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      person.fullName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: isBirthdayList ? AppTheme.pinkStandard : null,
                                        fontWeight: isBirthdayList ? AppTheme.fontBold : null,
                                      ),
                                    ),
                                    if (isBirthdayList && person.age != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Text('(${person.age} ans)', style: TextStyle(color: AppTheme.pinkStandard)),
                                      ),
                                  ],
                                ),
                                subtitle: isBirthdayList && person.birthDate != null
                                    ? Text('Né(e) le ${person.formattedBirthDate}', style: TextStyle(color: AppTheme.pinkStandard))
                                    : Text(person.email ?? ''),
                                trailing: selected
                                    ? const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Checkbox(
                                        value: selected,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              _selectedPersonIds.add(person.id);
                                            } else {
                                              _selectedPersonIds.remove(person.id);
                                            }
                                          });
                                        },
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
          ),
      ),
    );
  }
}
