import 'package:flutter/material.dart';
import '../models/event_recurrence_model.dart';
import '../services/event_recurrence_service.dart';
import '../theme.dart';

class EditEventInstanceForm extends StatefulWidget {
  final EventInstanceModel instance;
  final VoidCallback? onSaved;

  const EditEventInstanceForm({
    Key? key,
    required this.instance,
    this.onSaved,
  }) : super(key: key);

  @override
  State<EditEventInstanceForm> createState() => _EditEventInstanceFormState();
}

class _EditEventInstanceFormState extends State<EditEventInstanceForm> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _date;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.instance.overrideData['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.instance.overrideData['description'] ?? '');
    _date = widget.instance.actualDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final override = RecurrenceOverride(
      originalDate: widget.instance.originalDate,
      newDate: _date,
      title: _titleController.text,
      description: _descriptionController.text,
      location: widget.instance.overrideData['location'],
      startTime: widget.instance.overrideData['startTime'],
      endTime: widget.instance.overrideData['endTime'],
      customFields: widget.instance.overrideData['customFields'] ?? {},
    );
    await EventRecurrenceService.modifyOccurrence(
      widget.instance.recurrenceId!,
      widget.instance.originalDate,
      override,
    );
    setState(() => _isLoading = false);
    if (widget.onSaved != null) widget.onSaved!();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'occurrence'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date de l\'occurrence'),
              subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                    ),
                    onPressed: _save,
                  ),
          ],
        ),
      ),
    );
  }
}
