import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pepite_or_model.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

class PepiteFormDialog extends StatefulWidget {
  final PepiteOrModel? pepite; // null = création, non-null = édition

  const PepiteFormDialog({
    Key? key,
    this.pepite,
  }) : super(key: key);

  @override
  State<PepiteFormDialog> createState() => _PepiteFormDialogState();
}

class _PepiteFormDialogState extends State<PepiteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _themeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<CitationController> _citationsControllers = [];
  bool _estPubliee = false;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.pepite != null) {
      _initializeFromPepite();
    } else {
      _addCitation(); // Commencer avec une citation vide
    }
  }

  void _initializeFromPepite() {
    final pepite = widget.pepite!;
    _themeController.text = pepite.theme;
    _descriptionController.text = pepite.description;
    _estPubliee = pepite.estPubliee;
    _tags.addAll(pepite.tags);
    
    for (var citation in pepite.citations) {
      _citationsControllers.add(CitationController(
        texteController: TextEditingController(text: citation.texte),
        auteurController: TextEditingController(text: citation.auteur),
        referenceController: TextEditingController(text: citation.reference ?? ''),
      ));
    }
    
    if (_citationsControllers.isEmpty) {
      _addCitation();
    }
  }

  void _addCitation() {
    setState(() {
      _citationsControllers.add(CitationController(
        texteController: TextEditingController(),
        auteurController: TextEditingController(),
        referenceController: TextEditingController(),
      ));
    });
  }

  void _removeCitation(int index) {
    if (_citationsControllers.length > 1) {
      setState(() {
        _citationsControllers[index].dispose();
        _citationsControllers.removeAt(index);
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  void dispose() {
    _themeController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    for (var controller in _citationsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.space12),
                Text(
                  widget.pepite == null ? 'Nouvelle Pépite d\'Or' : 'Modifier la Pépite',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize24,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thème
                      Text(
                        'Thème de la pépite',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      TextFormField(
                        controller: _themeController,
                        decoration: InputDecoration(
                          hintText: 'Ex: La Foi, L\'Amour de Dieu...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le thème est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space20),
                      
                      // Description
                      Text(
                        'Description',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Description courte de la pépite...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space20),
                      
                      // Citations
                      Row(
                        children: [
                          Text(
                            'Citations de William Branham',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize16,
                              fontWeight: AppTheme.fontSemiBold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addCitation,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.white100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),
                      
                      // Liste des citations
                      ...List.generate(_citationsControllers.length, (index) {
                        return _buildCitationCard(index);
                      }),
                      
                      const SizedBox(height: AppTheme.space20),
                      
                      // Tags
                      Text(
                        'Tags',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: InputDecoration(
                                hintText: 'Ajouter un tag...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                ),
                              ),
                              onFieldSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          IconButton(
                            onPressed: _addTag,
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.white100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space12),
                      
                      // Affichage des tags
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              onDeleted: () => _removeTag(tag),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              deleteIconColor: AppTheme.primaryColor,
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: AppTheme.space20),
                      
                      // Publication
                      CheckboxListTile(
                        title: Text(
                          'Publier immédiatement',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                        subtitle: Text(
                          'La pépite sera visible par tous les utilisateurs',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize14,
                            color: AppTheme.grey600,
                          ),
                        ),
                        value: _estPubliee,
                        onChanged: (value) {
                          setState(() {
                            _estPubliee = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            const SizedBox(height: AppTheme.spaceLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePepite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Text(widget.pepite == null ? 'Créer' : 'Modifier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationCard(int index) {
    final controller = _citationsControllers[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.grey300!),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Citation ${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              if (_citationsControllers.length > 1)
                IconButton(
                  onPressed: () => _removeCitation(index),
                  icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          
          // Texte de la citation
          TextFormField(
            controller: controller.texteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Texte de la citation',
              hintText: 'Saisissez le texte de la citation...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le texte de la citation est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space12),
          
          // Auteur/Brochure
          TextFormField(
            controller: controller.auteurController,
            decoration: InputDecoration(
              labelText: 'Titre de la brochure',
              hintText: 'Ex: La Foi Parfaite, Le Message de l\'Heure...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre de la brochure est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.space12),
          
          // Référence (optionnel)
          TextFormField(
            controller: controller.referenceController,
            decoration: InputDecoration(
              labelText: 'Référence (optionnel)',
              hintText: 'Page, paragraphe, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePepite() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Créer les citations
    final citations = _citationsControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      
      return CitationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString() + index.toString(),
        texte: controller.texteController.text.trim(),
        auteur: controller.auteurController.text.trim(),
        reference: controller.referenceController.text.trim().isEmpty 
            ? null 
            : controller.referenceController.text.trim(),
        ordre: index,
      );
    }).toList();

    // Créer la pépite
    final pepite = PepiteOrModel(
      id: widget.pepite?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      theme: _themeController.text.trim(),
      description: _descriptionController.text.trim(),
      citations: citations,
      dateCreation: widget.pepite?.dateCreation ?? DateTime.now(),
      datePublication: _estPubliee ? DateTime.now() : null,
      auteur: widget.pepite?.auteur ?? '', // Sera rempli par le service
      nomAuteur: widget.pepite?.nomAuteur ?? '', // Sera rempli par le service
      estPubliee: _estPubliee,
      tags: _tags,
    );

    Navigator.pop(context, pepite);
  }
}

class CitationController {
  final TextEditingController texteController;
  final TextEditingController auteurController;
  final TextEditingController referenceController;

  CitationController({
    required this.texteController,
    required this.auteurController,
    required this.referenceController,
  });

  void dispose() {
    texteController.dispose();
    auteurController.dispose();
    referenceController.dispose();
  }
}
