import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../../../theme.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';

class AdminSermonsTab extends StatefulWidget {
  const AdminSermonsTab({Key? key}) : super(key: key);

  @override
  State<AdminSermonsTab> createState() => _AdminSermonsTabState();
}

class _AdminSermonsTabState extends State<AdminSermonsTab> {
  bool _isLoading = true;
  List<Sermon> _sermons = [];
  List<Sermon> _filteredSermons = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSermons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSermons() {
    SermonService.getSermons().listen((sermons) {
      if (mounted) {
        setState(() {
          _sermons = sermons;
          _filteredSermons = sermons;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Erreur lors du chargement des sermons');
      }
    });
  }

  void _filterSermons(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSermons = _sermons;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredSermons = _sermons.where((sermon) {
          return sermon.titre.toLowerCase().contains(lowerQuery) ||
                 sermon.orateur.toLowerCase().contains(lowerQuery) ||
                 sermon.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSermonDialog(context),
        backgroundColor: AppTheme.primaryColor,
        icon: Icon(Icons.add, color: AppTheme.surfaceColor),
        label: Text(
          'Ajouter',
          style: GoogleFonts.poppins(
            color: AppTheme.surfaceColor,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        tooltip: 'Ajouter un sermon',
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)));
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        const SizedBox(height: AppTheme.spaceMedium),
        _buildStatsCards(),
        const SizedBox(height: AppTheme.space20),
        Expanded(
          child: _filteredSermons.isEmpty 
              ? _buildEmptyState() 
              : _buildSermonsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.textTertiaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Administration - Sermons',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Gérez les sermons et prédications de votre église',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMedium,
        AppTheme.spaceMedium,
        AppTheme.spaceMedium,
        0,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSermons,
        decoration: InputDecoration(
          hintText: 'Rechercher un sermon, orateur ou tag...',
          hintStyle: GoogleFonts.poppins(
            color: AppTheme.textSecondaryColor,
            fontSize: AppTheme.fontSize14,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textSecondaryColor),
                  onPressed: () {
                    _searchController.clear();
                    _filterSermons('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.space12,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: AppTheme.fontSize14,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final sermonsWithVideo = _sermons.where((s) => s.lienYoutube?.isNotEmpty == true).length;
    final sermonsWithNotes = _sermons.where((s) => s.notes?.isNotEmpty == true).length;
    final totalDuration = _sermons.fold<int>(0, (sum, s) => sum + s.duree);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              '${_sermons.length}',
              Icons.library_music,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: _buildStatCard(
              'Avec vidéo',
              '$sermonsWithVideo',
              Icons.videocam,
              AppTheme.greenStandard,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: _buildStatCard(
              'Avec notes',
              '$sermonsWithNotes',
              Icons.notes,
              AppTheme.orangeStandard,
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: _buildStatCard(
              'Durée totale',
              '${totalDuration}min',
              Icons.access_time,
              AppTheme.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize20,
              fontWeight: AppTheme.fontBold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.textSecondaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSermonsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      itemCount: _filteredSermons.length,
      itemBuilder: (context, index) {
        final sermon = _filteredSermons[index];
        return _buildSermonCard(sermon);
      },
    );
  }

  Widget _buildSermonCard(Sermon sermon) {
    final hasVideo = sermon.lienYoutube?.isNotEmpty == true;
    final hasNotes = sermon.notes?.isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      color: AppTheme.surfaceColor,
      child: InkWell(
        onTap: () => _showSermonDialog(context, sermon: sermon),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec date et badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yy').format(sermon.date),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasVideo)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.greenStandard.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.videocam,
                        size: 14,
                        color: AppTheme.greenStandard,
                      ),
                    ),
                  const SizedBox(width: 4),
                  if (hasNotes)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeStandard.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.notes,
                        size: 14,
                        color: AppTheme.orangeStandard,
                      ),
                    ),
                  const Spacer(),
                  // Menu d'actions
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondaryColor,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showSermonDialog(context, sermon: sermon);
                      } else if (value == 'delete') {
                        _confirmDelete(sermon);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Modifier',
                              style: GoogleFonts.poppins(
                                fontSize: AppTheme.fontSize14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: AppTheme.redStandard),
                            const SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: GoogleFonts.poppins(
                                fontSize: AppTheme.fontSize14,
                                color: AppTheme.redStandard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              // Titre
              Text(
                sermon.titre,
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Orateur et durée
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sermon.orateur,
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sermon.duree > 0) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${sermon.duree}min',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
              // Description si disponible
              if (sermon.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  sermon.description!,
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize13,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Tags si disponibles
              if (sermon.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: sermon.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: AppTheme.fontMedium,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music,
            size: 64,
            color: AppTheme.textTertiaryColor,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Aucun sermon trouvé'
                : 'Aucun sermon ajouté',
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Ajoutez des sermons pour enrichir\nl\'expérience des membres',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: AppTheme.spaceLarge),
            ElevatedButton.icon(
              onPressed: () => _showSermonDialog(context),
              icon: Icon(Icons.add, color: AppTheme.surfaceColor),
              label: Text(
                'Ajouter un sermon',
                style: GoogleFonts.poppins(
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.surfaceColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSermonDialog(BuildContext context, {Sermon? sermon}) {
    showDialog(
      context: context,
      builder: (context) => _SermonDialog(sermon: sermon),
    );
  }

  void _confirmDelete(Sermon sermon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          'Supprimer le sermon',
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${sermon.titre}" ?\n\nCette action est irréversible.',
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await SermonService.deleteSermon(sermon.id);
              if (success) {
                _showSuccess('Sermon supprimé avec succès');
              } else {
                _showError('Erreur lors de la suppression du sermon');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redStandard,
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppTheme.greenStandard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppTheme.redStandard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
      ),
    );
  }
}

/// Dialog pour ajouter/modifier un sermon
class _SermonDialog extends StatefulWidget {
  final Sermon? sermon;

  const _SermonDialog({this.sermon});

  @override
  State<_SermonDialog> createState() => _SermonDialogState();
}

class _SermonDialogState extends State<_SermonDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titreController;
  late TextEditingController _orateurController;
  late TextEditingController _youtubeController;
  late TextEditingController _notesController;
  late TextEditingController _descriptionController;
  late TextEditingController _dureeController;
  late TextEditingController _tagsController;
  late TextEditingController _infographiesController;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isUploadingImages = false;
  List<String> _uploadedImageUrls = [];

  @override
  void initState() {
    super.initState();
    final sermon = widget.sermon;
    _titreController = TextEditingController(text: sermon?.titre ?? '');
    _orateurController = TextEditingController(text: sermon?.orateur ?? '');
    _youtubeController = TextEditingController(text: sermon?.lienYoutube ?? '');
    _notesController = TextEditingController(text: sermon?.notes ?? '');
    _descriptionController = TextEditingController(text: sermon?.description ?? '');
    _dureeController = TextEditingController(
      text: sermon != null && sermon.duree > 0 ? sermon.duree.toString() : '',
    );
    _tagsController = TextEditingController(
      text: sermon?.tags.join(', ') ?? '',
    );
    _infographiesController = TextEditingController(
      text: sermon?.infographiesUrls.join('\n') ?? '',
    );
    _uploadedImageUrls = List.from(sermon?.infographiesUrls ?? []);
    _selectedDate = sermon?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _orateurController.dispose();
    _youtubeController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _dureeController.dispose();
    _tagsController.dispose();
    _infographiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sermon != null;

    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Modifier le sermon' : 'Ajouter un sermon',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize18,
                        fontWeight: AppTheme.fontSemiBold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _titreController,
                        label: 'Titre du sermon *',
                        icon: Icons.title,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir un titre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      _buildTextField(
                        controller: _orateurController,
                        label: 'Orateur *',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez saisir le nom de l\'orateur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      // Date
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date du sermon *',
                            labelStyle: GoogleFonts.poppins(
                              color: AppTheme.textSecondaryColor,
                              fontSize: AppTheme.fontSize14,
                            ),
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSmall,
                              ),
                            ),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize14,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      _buildTextField(
                        controller: _dureeController,
                        label: 'Durée (minutes)',
                        icon: Icons.access_time,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      _buildTextField(
                        controller: _youtubeController,
                        label: 'Lien YouTube',
                        icon: Icons.video_library,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Notes',
                        icon: Icons.notes,
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      _buildTextField(
                        controller: _tagsController,
                        label: 'Tags (séparés par des virgules)',
                        icon: Icons.label,
                        helperText: 'Ex: Évangélisation, Foi, Prière',
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      
                      // Section Schémas et infographies
                      _buildInfographiesSection(),
                    ],
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.textTertiaryColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondaryColor,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSermon,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isEditing ? Icons.save : Icons.add,
                            color: Colors.white,
                          ),
                    label: Text(
                      isEditing ? 'Enregistrer' : 'Ajouter',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: AppTheme.fontSize14,
        color: AppTheme.textPrimaryColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperStyle: GoogleFonts.poppins(
          fontSize: AppTheme.fontSize12,
          color: AppTheme.textSecondaryColor,
        ),
        labelStyle: GoogleFonts.poppins(
          color: AppTheme.textSecondaryColor,
          fontSize: AppTheme.fontSize14,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          borderSide: BorderSide(color: AppTheme.redStandard),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildInfographiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec bouton d'ajout
        Row(
          children: [
            Icon(Icons.image, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Schémas et infographies',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isUploadingImages ? null : _pickImagesFromGallery,
              icon: _isUploadingImages
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.add_photo_alternate, size: 18),
              label: Text(
                _isUploadingImages ? 'Upload...' : 'Galerie',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize12,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        
        // Grille d'aperçu des images
        if (_uploadedImageUrls.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _uploadedImageUrls.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return _buildImagePreview(url, index);
              }).toList(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aucune image ajoutée. Cliquez sur "Galerie" pour ajouter des schémas.',
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppTheme.space12),
        
        // Option pour ajouter des URLs manuellement
        _buildTextField(
          controller: _infographiesController,
          label: 'Ou collez des URLs (optionnel, une par ligne)',
          icon: Icons.link,
          maxLines: 3,
          helperText: 'URLs complètes d\'images hébergées',
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }

  Widget _buildImagePreview(String url, int index) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall - 2),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppTheme.textSecondaryColor,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.redStandard,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
            onPressed: () {
              setState(() {
                _uploadedImageUrls.removeAt(index);
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isEmpty) return;

      setState(() {
        _isUploadingImages = true;
      });

      // Upload chaque image vers Firebase Storage
      for (final image in images) {
        final url = await _uploadImageToFirebase(image);
        if (url != null) {
          setState(() {
            _uploadedImageUrls.add(url);
          });
        }
      }

      setState(() {
        _isUploadingImages = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${images.length} image(s) ajoutée(s) avec succès',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppTheme.greenStandard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ajout des images: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppTheme.redStandard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToFirebase(XFile image) async {
    try {
      final file = File(image.path);
      if (!await file.exists()) {
        print('❌ File does not exist: ${image.path}');
        return null;
      }
      
      // Créer un nom unique pour le fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(image.path);
      final fileName = 'sermon_infographie_$timestamp$ext';
      
      // Upload vers Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('sermons_infographies')
          .child(fileName);
      
      print('⬆️ Uploading image to Firebase Storage...');
      final uploadTask = await storageRef.putFile(file);
      
      // Récupérer l'URL publique
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveSermon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse tags
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Combiner les images uploadées et les URLs manuelles
      final manualUrls = _infographiesController.text
          .split('\n')
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty && url.startsWith('http'))
          .toList();
      
      final infographiesUrls = [
        ..._uploadedImageUrls,
        ...manualUrls,
      ];

      // Parse durée
      final duree = int.tryParse(_dureeController.text) ?? 0;

      final sermon = Sermon(
        id: widget.sermon?.id ?? '',
        titre: _titreController.text.trim(),
        orateur: _orateurController.text.trim(),
        date: _selectedDate,
        lienYoutube: _youtubeController.text.trim().isEmpty
            ? null
            : _youtubeController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        duree: duree,
        tags: tags,
        infographiesUrls: infographiesUrls,
        createdAt: widget.sermon?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (widget.sermon == null) {
        // Ajouter
        final id = await SermonService.addSermon(sermon);
        success = id != null;
      } else {
        // Modifier
        success = await SermonService.updateSermon(sermon.id, sermon);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.sermon == null
                    ? 'Sermon ajouté avec succès'
                    : 'Sermon modifié avec succès',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppTheme.greenStandard,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
          );
        } else {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de l\'enregistrement du sermon',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppTheme.redStandard,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppTheme.redStandard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        );
      }
    }
  }
}
