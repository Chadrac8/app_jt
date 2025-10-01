import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';
import '../../../theme.dart';

class AdminSermonsTab extends StatefulWidget {
  const AdminSermonsTab({Key? key}) : super(key: key);

  @override
  State<AdminSermonsTab> createState() => _AdminSermonsTabState();
}

class _AdminSermonsTabState extends State<AdminSermonsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildSermonsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSermonForm(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: AppTheme.white100),
        label: Text(
          'Ajouter un sermon',
          style: GoogleFonts.poppins(
            color: AppTheme.white100,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Sermons',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize24,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      'Ajoutez et gérez les sermons de l\'église',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuickStats(),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          // Barre de recherche
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un sermon...',
              hintStyle: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.primaryColor,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.grey500),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
              filled: true,
              fillColor: AppTheme.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<Sermon>>(
      stream: SermonService.getSermons(),
      builder: (context, snapshot) {
        final sermons = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              Text(
                '${sermons.length}',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize24,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'Sermons',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize12,
                  color: AppTheme.primaryColor,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSermonsList() {
    return StreamBuilder<List<Sermon>>(
      stream: _searchQuery.isNotEmpty
          ? SermonService.searchSermons(_searchQuery)
          : SermonService.getSermons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.redStandard,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Erreur lors du chargement',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        final sermons = snapshot.data ?? [];

        if (sermons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 64,
                  color: AppTheme.grey500,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Aucun sermon',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  'Commencez par ajouter votre premier sermon',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          itemCount: sermons.length,
          itemBuilder: (context, index) {
            final sermon = sermons[index];
            return _buildSermonCard(sermon);
          },
        );
      },
    );
  }

  Widget _buildSermonCard(Sermon sermon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sermon.titre,
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        'Par ${sermon.orateur} • ${DateFormat('dd/MM/yyyy').format(sermon.date)}',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showSermonForm(context, sermon: sermon);
                        break;
                      case 'duplicate':
                        _duplicateSermon(sermon);
                        break;
                      case 'delete':
                        _deleteSermon(sermon);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Modifier',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Dupliquer',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18, color: AppTheme.redStandard),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Supprimer',
                            style: GoogleFonts.poppins(color: AppTheme.redStandard),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (sermon.description != null && sermon.description!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space12),
              Text(
                sermon.description!,
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppTheme.spaceMedium),

            // Statuts
            Row(
              children: [
                _buildStatusChip(
                  'Lien YouTube',
                  sermon.lienYoutube != null && sermon.lienYoutube!.isNotEmpty,
                  Icons.play_arrow,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                _buildStatusChip(
                  'Notes',
                  sermon.notes != null && sermon.notes!.isNotEmpty,
                  Icons.notes,
                ),
                if (sermon.duree > 0) ...[
                  const SizedBox(width: AppTheme.spaceSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.grey500,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      '${sermon.duree} min',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            if (sermon.tags.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sermon.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize11,
                      color: AppTheme.primaryColor,
                      fontWeight: AppTheme.fontMedium,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isComplete, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isComplete
            ? AppTheme.greenStandard.withOpacity(0.1)
            : AppTheme.orangeStandard.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.warning,
            size: 14,
            color: isComplete ? AppTheme.greenStandard : AppTheme.orangeStandard,
          ),
          const SizedBox(width: AppTheme.spaceXSmall),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize12,
              color: isComplete ? AppTheme.greenStandard : AppTheme.orangeStandard,
              fontWeight: AppTheme.fontMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showSermonForm(BuildContext context, {Sermon? sermon}) {
    showDialog(
      context: context,
      builder: (context) => SermonFormDialog(sermon: sermon),
    );
  }

  void _duplicateSermon(Sermon sermon) {
    final duplicatedSermon = sermon.copyWith(
      id: '',
      titre: '${sermon.titre} (Copie)',
      date: DateTime.now(),
      createdAt: null,
      updatedAt: null,
    );
    _showSermonForm(context, sermon: duplicatedSermon);
  }

  void _deleteSermon(Sermon sermon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le sermon',
          style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le sermon "${sermon.titre}" ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () async {
              final success = await SermonService.deleteSermon(sermon.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Sermon supprimé avec succès'
                          : 'Erreur lors de la suppression',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: success ? AppTheme.greenStandard : AppTheme.redStandard,
                  ),
                );
              }
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(color: AppTheme.redStandard),
            ),
          ),
        ],
      ),
    );
  }
}

class SermonFormDialog extends StatefulWidget {
  final Sermon? sermon;

  const SermonFormDialog({Key? key, this.sermon}) : super(key: key);

  @override
  State<SermonFormDialog> createState() => _SermonFormDialogState();
}

class _SermonFormDialogState extends State<SermonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _orateurController = TextEditingController();
  final _lienYoutubeController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dureeController = TextEditingController();
  final _tagsController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sermon != null) {
      _titreController.text = widget.sermon!.titre;
      _orateurController.text = widget.sermon!.orateur;
      _lienYoutubeController.text = widget.sermon!.lienYoutube ?? '';
      _notesController.text = widget.sermon!.notes ?? '';
      _descriptionController.text = widget.sermon!.description ?? '';
      _dureeController.text = widget.sermon!.duree.toString();
      _tagsController.text = widget.sermon!.tags.join(', ');
      _selectedDate = widget.sermon!.date;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _orateurController.dispose();
    _lienYoutubeController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _dureeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.sermon == null ? 'Ajouter un sermon' : 'Modifier le sermon',
        style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                TextFormField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre du sermon *',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le titre est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Orateur
                TextFormField(
                  controller: _orateurController,
                  decoration: InputDecoration(
                    labelText: 'Orateur *',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'orateur est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date du sermon *',
                      labelStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Durée
                TextFormField(
                  controller: _dureeController,
                  decoration: InputDecoration(
                    labelText: 'Durée (minutes)',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Lien YouTube
                TextFormField(
                  controller: _lienYoutubeController,
                  decoration: InputDecoration(
                    labelText: 'Lien YouTube',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Tags
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (séparés par des virgules)',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    hintText: 'ex: foi, espoir, amour',
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes du sermon',
                    labelStyle: GoogleFonts.poppins(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    hintText: 'Utilisez # pour les titres, - pour les listes',
                  ),
                  maxLines: 6,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: GoogleFonts.poppins(),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSermon,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.white100,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.white100,
                  ),
                )
              : Text(
                  widget.sermon == null ? 'Ajouter' : 'Modifier',
                  style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
                ),
        ),
      ],
    );
  }

  Future<void> _saveSermon() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final sermon = Sermon(
        id: widget.sermon?.id ?? '',
        titre: _titreController.text.trim(),
        orateur: _orateurController.text.trim(),
        date: _selectedDate,
        lienYoutube: _lienYoutubeController.text.trim().isEmpty
            ? null
            : _lienYoutubeController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        duree: int.tryParse(_dureeController.text) ?? 0,
        tags: tags,
        createdAt: widget.sermon?.createdAt,
      );

      bool success;
      if (widget.sermon == null) {
        final id = await SermonService.addSermon(sermon);
        success = id != null;
      } else {
        success = await SermonService.updateSermon(widget.sermon!.id, sermon);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? widget.sermon == null
                      ? 'Sermon ajouté avec succès'
                      : 'Sermon modifié avec succès'
                  : 'Erreur lors de la sauvegarde',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: success ? AppTheme.greenStandard : AppTheme.redStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la sauvegarde: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.redStandard,
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
}
