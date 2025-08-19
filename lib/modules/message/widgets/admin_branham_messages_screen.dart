import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/branham_message.dart';
import '../../../shared/theme/app_theme.dart';
import '../services/admin_branham_messages_service.dart';

class AdminBranhamMessagesScreen extends StatefulWidget {
  const AdminBranhamMessagesScreen({Key? key}) : super(key: key);

  @override
  State<AdminBranhamMessagesScreen> createState() => _AdminBranhamMessagesScreenState();
}

class _AdminBranhamMessagesScreenState extends State<AdminBranhamMessagesScreen> {
  List<BranhamMessage> _messages = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final messages = await AdminBranhamMessagesService.getAllMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        title: Text(
          'Administration - Prédications',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une prédication...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune prédication trouvée.\nCommencez par en ajouter une !',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMessages.length,
                        itemBuilder: (context, index) {
                          final message = _filteredMessages[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                message.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              subtitle: Text(
                                '${message.formattedDate} • ${message.location}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteMessage(message.id);
                                  } else if (value == 'edit') {
                                    _showEditDialog(message);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit, color: Colors.blue),
                                      title: Text('Modifier'),
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                      dense: true,
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  List<BranhamMessage> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    
    return _messages.where((message) {
      return message.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             message.location.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteMessage(String id) async {
    final bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette prédication ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await AdminBranhamMessagesService.deleteMessage(id);
      if (success) {
        _loadMessages();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prédication supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _showAddDialog() {
    _showAddEditDialog();
  }

  void _showEditDialog(BranhamMessage message) {
    _showAddEditDialog(message: message);
  }

  void _showAddEditDialog({BranhamMessage? message}) {
    final isEditing = message != null;
    final titleController = TextEditingController(text: message?.title ?? '');
    final locationController = TextEditingController(text: message?.location ?? '');
    final pdfUrlController = TextEditingController(text: message?.pdfUrl ?? '');
    final audioUrlController = TextEditingController(text: message?.audioUrl ?? '');
    
    DateTime selectedDate = message?.publishDate ?? DateTime.now();
    int durationMinutes = message?.durationMinutes ?? 90;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Modifier la prédication' : 'Ajouter une prédication'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lieu *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Durée: ${durationMinutes ~/ 60}h ${durationMinutes % 60}min'),
                      Slider(
                        value: durationMinutes.toDouble(),
                        min: 15,
                        max: 240,
                        divisions: 45,
                        onChanged: (value) => setState(() => durationMinutes = value.round()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pdfUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Lien PDF',
                      border: OutlineInputBorder(),
                      hintText: 'https://exemple.com/document.pdf',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: audioUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Lien Audio',
                      border: OutlineInputBorder(),
                      hintText: 'https://exemple.com/audio.mp3',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs obligatoires (*)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final messageData = BranhamMessage(
                  id: message?.id ?? '',
                  title: titleController.text.trim(),
                  date: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  location: locationController.text.trim(),
                  durationMinutes: durationMinutes,
                  pdfUrl: pdfUrlController.text.trim(),
                  audioUrl: audioUrlController.text.trim(),
                  streamUrl: audioUrlController.text.trim(),
                  language: 'Français',
                  publishDate: selectedDate,
                  series: ['Messages de William Branham'],
                );

                bool success;
                if (isEditing) {
                  success = await AdminBranhamMessagesService.updateMessage(message.id, messageData);
                } else {
                  final id = await AdminBranhamMessagesService.addMessage(messageData);
                  success = id != null;
                }

                if (success) {
                  Navigator.of(context).pop();
                  _loadMessages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Prédication modifiée avec succès' : 'Prédication ajoutée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 'Erreur lors de la modification' : 'Erreur lors de l\'ajout'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Modifier' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
