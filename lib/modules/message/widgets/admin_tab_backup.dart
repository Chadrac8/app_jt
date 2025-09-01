import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/branham_message.dart';
import '../../../models/pepite_or_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../services/admin_branham_messages_service.dart';
import '../../../services/pepite_or_firebase_service.dart';
import 'pepite_form_dialog.dart';

class AdminTab extends StatefulWidget {
  const AdminTab({Key? key}) : super(key: key);

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> with SingleTickerProviderStateMixin {
  List<BranhamMessage> _messages = [];
  List<PepiteOrModel> _pepites = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les messages
      final messages = await AdminBranhamMessagesService.getAllMessages();
      
      // Charger les pépites - récupérer toutes les pépites (publiées et non publiées) pour l'admin
      final pepites = await PepiteOrFirebaseService.obtenirPepitesOrParPage(
        limite: 1000, // Limite élevée pour récupérer toutes les pépites
        seulementPubliees: false, // Récupérer toutes les pépites pour l'admin
      );
      
      setState(() {
        _messages = messages;
        _pepites = pepites;
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header avec titre et onglets
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administration',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'Gérez vos prédications et pépites d\'or',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                        ),
                        onPressed: _loadData,
                        tooltip: 'Actualiser',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Onglets
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppTheme.primaryColor,
                    indicatorWeight: 3,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.library_books),
                        text: 'Prédications',
                      ),
                      Tab(
                        icon: Icon(Icons.auto_awesome),
                        text: 'Pépites d\'Or',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMessagesTab(),
                  _buildPepitesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
          // Stats rapides
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${_messages.length}',
                    Icons.library_books,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avec PDF',
                    '${_messages.where((m) => m.pdfUrl.isNotEmpty).length}',
                    Icons.picture_as_pdf,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Avec Audio',
                    '${_messages.where((m) => m.audioUrl.isNotEmpty).length}',
                    Icons.audiotrack,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          // Liste des prédications
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _messages.isEmpty 
                                ? 'Aucune prédication trouvée'
                                : 'Aucun résultat pour "${_searchQuery}"',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _messages.isEmpty 
                                ? 'Commencez par ajouter votre première prédication'
                                : 'Essayez un autre terme de recherche',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${message.formattedDate} • ${message.location}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (message.pdfUrl.isNotEmpty) ...[
                                        Icon(Icons.picture_as_pdf, size: 14, color: Colors.red),
                                        const SizedBox(width: 4),
                                      ],
                                      if (message.audioUrl.isNotEmpty) ...[
                                        Icon(Icons.audiotrack, size: 14, color: Colors.orange),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        '${message.formattedDuration}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
