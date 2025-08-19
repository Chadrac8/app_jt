import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';

class TaskCreateEditModal extends StatefulWidget {
  final TaskModel? task;

  const TaskCreateEditModal({super.key, this.task});

  @override
  State<TaskCreateEditModal> createState() => _TaskCreateEditModalState();
}

class _TaskCreateEditModalState extends State<TaskCreateEditModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedPriority = 'medium';
  String _selectedStatus = 'todo';
  DateTime? _dueDate;
  String? _selectedCategory;
  int? _estimatedHours;
  String? _location;
  List<String> _tags = [];

  final List<String> _priorities = ['low', 'medium', 'high'];
  final List<String> _statuses = ['todo', 'in_progress', 'completed'];
  final List<String> _categories = [
    'Administration',
    'Technique',
    'Événements',
    'Ministère',
    'Maintenance',
    'Communication',
    'Formation',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedPriority = widget.task!.priority;
      _selectedStatus = widget.task!.status;
      _dueDate = widget.task!.dueDate;
      _selectedCategory = widget.task!.category;
      _estimatedHours = widget.task!.estimatedHours;
      _location = widget.task!.location;
      _tags = List.from(widget.task!.tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildPriorityField(),
                    const SizedBox(height: 16),
                    _buildStatusField(),
                    const SizedBox(height: 16),
                    _buildDueDateField(),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                    const SizedBox(height: 16),
                    _buildEstimatedHoursField(),
                    const SizedBox(height: 16),
                    _buildLocationField(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.task == null ? 'Créer une tâche' : 'Modifier la tâche',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Titre de la tâche',
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Le titre est obligatoire';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priorité',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _priorities.map((priority) {
            final isSelected = _selectedPriority == priority;
            return ChoiceChip(
              label: Text(_getPriorityLabel(priority)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedPriority = priority);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statut',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _statuses.map((status) {
            final isSelected = _selectedStatus == status;
            return ChoiceChip(
              label: Text(_getStatusLabel(status)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedStatus = status);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateField() {
    return InkWell(
      onTap: _selectDueDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date d\'échéance',
          labelStyle: GoogleFonts.poppins(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _dueDate != null
              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
              : 'Sélectionner une date',
          style: GoogleFonts.poppins(
            color: _dueDate != null ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Catégorie',
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category, style: GoogleFonts.poppins()),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildEstimatedHoursField() {
    return TextFormField(
      initialValue: _estimatedHours?.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Heures estimées',
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixText: 'h',
      ),
      onChanged: (value) {
        _estimatedHours = int.tryParse(value);
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      initialValue: _location,
      decoration: InputDecoration(
        labelText: 'Lieu',
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.location_on),
      ),
      onChanged: (value) => _location = value,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              widget.task == null ? 'Créer' : 'Modifier',
              style: GoogleFonts.poppins(),
            ),
          ),
        ),
      ],
    );
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low':
        return 'Faible';
      case 'medium':
        return 'Moyenne';
      case 'high':
        return 'Élevée';
      default:
        return priority;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      default:
        return status;
    }
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implémenter la sauvegarde de la tâche
      Navigator.of(context).pop(true);
    }
  }
}
