import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/wb_sermon.dart';
import '../services/wb_sermon_firestore_service.dart';

/// Page pour ajouter ou modifier un sermon William Branham
class AddSermonPage extends StatefulWidget {
  final WBSermon? sermon; // Si non-null, mode édition
  
  const AddSermonPage({super.key, this.sermon});

  @override
  State<AddSermonPage> createState() => _AddSermonPageState();
}

class _AddSermonPageState extends State<AddSermonPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textContentController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _pdfUrlController = TextEditingController();

  String _selectedLanguage = 'fr';
  String? _selectedTranslator = 'VGR';
  final List<String> _selectedSeries = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Si mode édition, pré-remplir les champs
    if (widget.sermon != null) {
      _loadSermonData(widget.sermon!);
    }
  }

  void _loadSermonData(WBSermon sermon) {
    _titleController.text = sermon.title;
    _dateController.text = sermon.date;
    _locationController.text = sermon.location;
    _durationController.text = sermon.durationMinutes?.toString() ?? '';
    _descriptionController.text = sermon.description ?? '';
    _textContentController.text = sermon.textContent ?? '';
    _audioUrlController.text = sermon.audioUrl ?? '';
    _videoUrlController.text = sermon.videoUrl ?? '';
    _pdfUrlController.text = sermon.pdfUrl ?? '';
    _selectedLanguage = sermon.language;
    _selectedTranslator = sermon.translator;
    _selectedSeries.clear();
    _selectedSeries.addAll(sermon.series);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _textContentController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSermon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // En mode édition, garder l'ID existant
      // En mode création, créer l'ID: date + langue + traducteur
      final String sermonId;
      if (widget.sermon != null) {
        sermonId = widget.sermon!.id;
      } else {
        final baseId = _dateController.text.trim();
        final langSuffix = _selectedLanguage.toUpperCase();
        final translatorSuffix = _selectedTranslator ?? '';
        sermonId = translatorSuffix.isNotEmpty 
            ? '$baseId-$translatorSuffix-$langSuffix'
            : '$baseId-$langSuffix';
      }

      final sermon = WBSermon(
        id: sermonId,
        title: _titleController.text.trim(),
        date: _dateController.text.trim(),
        location: _locationController.text.trim(),
        language: _selectedLanguage,
        translator: _selectedTranslator,
        durationMinutes: int.tryParse(_durationController.text) ?? 0,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        textContent: _textContentController.text.trim().isEmpty
            ? null
            : _textContentController.text.trim(),
        audioUrl: _audioUrlController.text.trim().isEmpty 
            ? null 
            : _audioUrlController.text.trim(),
        videoUrl: _videoUrlController.text.trim().isEmpty 
            ? null 
            : _videoUrlController.text.trim(),
        pdfUrl: _pdfUrlController.text.trim().isEmpty 
            ? null 
            : _pdfUrlController.text.trim(),
        series: _selectedSeries,
        publishedDate: widget.sermon?.publishedDate ?? DateTime.now(),
        isFavorite: widget.sermon?.isFavorite ?? false,
      );

      // Créer ou mettre à jour selon le mode
      if (widget.sermon != null) {
        await WBSermonFirestoreService.updateSermon(sermon);
      } else {
        await WBSermonFirestoreService.addSermon(sermon);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.sermon != null 
                ? 'Sermon modifié avec succès' 
                : 'Sermon ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer le succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sermon != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le sermon' : 'Ajouter un sermon'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSermon,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations de base
            _buildSectionHeader('Informations de base'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Le Dieu de cet âge mauvais',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date *',
                hintText: 'Ex: 63-0317E',
                border: OutlineInputBorder(),
                helperText: 'Format: YY-MMDD + E (soir) ou M (matin)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La date est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lieu *',
                hintText: 'Ex: Jeffersonville, IN',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le lieu est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Langue *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedTranslator,
                    decoration: const InputDecoration(
                      labelText: 'Traducteur',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'VGR', child: Text('VGR')),
                      DropdownMenuItem(value: 'SHP', child: Text('SHP')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTranslator = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durée (minutes)',
                hintText: 'Ex: 120',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            
            // Description
            _buildSectionHeader('Description'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description du sermon',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            
            // Texte du sermon
            _buildSectionHeader('Texte du sermon'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _textContentController,
              decoration: const InputDecoration(
                labelText: 'Texte complet (HTML)',
                hintText: 'Collez le texte HTML du sermon ici...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              minLines: 10,
            ),
            const SizedBox(height: 24),
            
            // Ressources
            _buildSectionHeader('Ressources (URLs)'),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _audioUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Audio',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.audiotrack),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Vidéo',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.videocam),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _pdfUrlController,
              decoration: const InputDecoration(
                labelText: 'URL PDF',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.picture_as_pdf),
              ),
            ),
            const SizedBox(height: 24),
            
            // Catégorisation
            _buildSectionHeader('Catégorisation'),
            const SizedBox(height: 16),
            
            _buildSeriesSelector(),
            const SizedBox(height: 32),
            
            // Bouton d'enregistrement
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSermon,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer le sermon'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSeriesSelector() {
    const availableSeries = [
      'Âge de l\'Église',
      'Sept Sceaux',
      'Sept Trompettes',
      'Réveil',
      'Guérison',
      'Foi',
      'Mariage et Divorce',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Séries', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableSeries.map((series) {
            final isSelected = _selectedSeries.contains(series);
            return FilterChip(
              label: Text(series),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSeries.add(series);
                  } else {
                    _selectedSeries.remove(series);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

}
