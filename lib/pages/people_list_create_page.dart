import 'package:flutter/material.dart';
import '../services/people_lists_firebase_service.dart';
import 'fields_suggestion_helper.dart';
import '../../theme.dart';


class PeopleListCreatePage extends StatefulWidget {
  final String? initialName;
  final List<Map<String, dynamic>>? initialFilters;
  final String? listId;
  const PeopleListCreatePage({Key? key, this.initialName, this.initialFilters, this.listId}) : super(key: key);

  @override
  State<PeopleListCreatePage> createState() => _PeopleListCreatePageState();
}

class _PeopleListCreatePageState extends State<PeopleListCreatePage> {
  Future<void> _loadSuggestions() async {
    final tags = await FieldsSuggestionHelper.getAllTags();
    final roles = await FieldsSuggestionHelper.getAllRoles();
    setState(() {
      _allTags = tags;
      _allRoles = roles;
    });
  }
  List<String> _allTags = [];
  List<String> _allRoles = [];
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  List<Map<String, dynamic>> _filters = [];
  bool _isSaving = false;
  List<Map<String, dynamic>> _fieldSuggestions = [];

  @override
  void initState() {
    super.initState();
    _name = widget.initialName ?? '';
    _filters = widget.initialFilters != null ? List<Map<String, dynamic>>.from(widget.initialFilters!) : [];
    _loadFieldSuggestions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuggestions());
  }

  Future<void> _loadFieldSuggestions() async {
    final fields = await FieldsSuggestionHelper.getAllFields();
    setState(() {
      _fieldSuggestions = fields;
    });
  }

  void _addFilter() {
    setState(() {
      // Par défaut, le premier filtre n'a pas de connecteur, les suivants "AND"
      _filters.add({
        'field': '',
        'operator': '==',
        'value': '',
        'logic': _filters.isEmpty ? null : 'AND',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [Icon(Icons.add, color: AppTheme.greenStandard), SizedBox(width: AppTheme.spaceSmall), Text('Filtre ajouté')],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFilter(int index) {
    setState(() {
      _filters.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [Icon(Icons.remove, color: AppTheme.redStandard), SizedBox(width: AppTheme.spaceSmall), Text('Filtre supprimé')],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveList() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSaving = true);
    bool isEdit = widget.listId != null;
    if (isEdit) {
      await PeopleListsFirebaseService.updateListById(widget.listId!, _name, _filters);
    } else {
      await PeopleListsFirebaseService.createList(_name, _filters);
    }
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isEdit ? Icons.check_circle : Icons.add, color: isEdit ? AppTheme.greenStandard : AppTheme.blueStandard),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(isEdit ? 'Liste modifiée' : 'Liste créée'),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pop(context, true);
  }

  List<String> _getOperatorsForType(String type) {
    switch (type) {
      case 'select':
      case 'multiselect':
        return ['==', '!=', 'in', 'not in', 'contains', 'not contains'];
      case 'boolean':
        return ['==', '!='];
      case 'date':
        return [
          '==', '!=', '<', '<=', '>', '>=', 'between', 'not between',
          'isToday', 'isBeforeToday', 'isAfterToday', 'isThisMonth', 'isThisYear'
        ];
      case 'number':
        return ['==', '!=', '<', '<=', '>', '>=', 'between', 'not between'];
      case 'text':
      default:
        return [
          '==', '!=', 'contains', 'not contains', 'startsWith', 'endsWith', 'isEmpty', 'isNotEmpty', 'matches'
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listId != null ? 'Éditer la liste' : 'Créer une liste'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nom de la liste', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppTheme.spaceSmall),
                        TextFormField(
                          initialValue: _name,
                          decoration: const InputDecoration(hintText: 'Ex: Membres actifs', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
                          onSaved: (v) => _name = v!.trim(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLarge),
                Text('Filtres', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppTheme.spaceSmall),
                ..._filters.asMap().entries.map((entry) {
                  final i = entry.key;
                  final filter = entry.value;
                  final selectedField = _fieldSuggestions.firstWhere(
                    (f) => f['name'] == filter['field'],
                    orElse: () => {},
                  );
                  final fieldType = selectedField['type'] ?? 'text';
                  final fieldOptions = selectedField['options'] ?? [];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: DropdownButton<String>(
                                value: filter['logic'] ?? 'AND',
                                items: const [
                                  DropdownMenuItem(value: 'AND', child: Text('ET')),
                                  DropdownMenuItem(value: 'OR', child: Text('OU')),
                                  DropdownMenuItem(value: 'NOT', child: Text('NON')),
                                ],
                                onChanged: (v) => setState(() => filter['logic'] = v),
                                underline: Container(),
                              ),
                            ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: filter['field'].toString().isNotEmpty ? filter['field'] : null,
                              items: _fieldSuggestions.map((f) => DropdownMenuItem<String>(
                                value: f['name']?.toString() ?? '',
                                child: Text(f['label']?.toString() ?? f['name']?.toString() ?? ''),
                              )).toList(),
                              onChanged: (v) => setState(() => filter['field'] = v ?? ''),
                              decoration: const InputDecoration(labelText: 'Champ'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: filter['operator'],
                              items: _getOperatorsForType(fieldType)
                                  .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
                                  .toList(),
                              onChanged: (v) => setState(() => filter['operator'] = v ?? '=='),
                              decoration: const InputDecoration(labelText: 'Opérateur'),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: fieldType == 'select' || fieldType == 'multiselect'
                                ? Autocomplete<String>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      List<String> options = (fieldOptions as List).map((o) => o.toString()).toList();
                                      if (filter['field'] == 'tags') {
                                        options = {...options, ..._allTags}.toList();
                                      } else if (filter['field'] == 'roles') {
                                        options = {...options, ..._allRoles}.toList();
                                      }
                                      if (textEditingValue.text == '') {
                                        return options;
                                      }
                                      return options.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    initialValue: TextEditingValue(text: filter['value'] ?? ''),
                                    onSelected: (v) => setState(() => filter['value'] = v),
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: const InputDecoration(labelText: 'Valeur'),
                                        onChanged: (v) => filter['value'] = v,
                                      );
                                    },
                                  )
                                : fieldType == 'boolean'
                                    ? DropdownButtonFormField<String>(
                                        value: filter['value'],
                                        items: const [
                                          DropdownMenuItem(value: 'true', child: Text('Oui')),
                                          DropdownMenuItem(value: 'false', child: Text('Non')),
                                        ],
                                        onChanged: (v) => setState(() => filter['value'] = v ?? ''),
                                        decoration: const InputDecoration(labelText: 'Valeur'),
                                      )
                                    : fieldType == 'date'
                                        ? TextFormField(
                                            readOnly: true,
                                            controller: TextEditingController(text: filter['value'] ?? ''),
                                            decoration: const InputDecoration(labelText: 'Valeur (date)'),
                                            onTap: () async {
                                              final picked = await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(1900),
                                                lastDate: DateTime(2100),
                                              );
                                              if (picked != null) {
                                                setState(() => filter['value'] = picked.toIso8601String().split('T').first);
                                              }
                                            },
                                          )
                                        : TextFormField(
                                            decoration: const InputDecoration(labelText: 'Valeur'),
                                            initialValue: filter['value'],
                                            onChanged: (v) => filter['value'] = v,
                                          ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeFilter(i),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addFilter,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un filtre'),
                ),
                const SizedBox(height: AppTheme.spaceXLarge),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: AppTheme.fontBold),
                    ),
                    onPressed: _isSaving ? null : _saveList,
                    child: _isSaving
                        ? const CircularProgressIndicator(color: AppTheme.white100)
                        : Text(widget.listId != null ? 'Enregistrer les modifications' : 'Créer la liste'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
