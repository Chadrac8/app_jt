import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pepite_or_model.dart';
import '../../services/pepite_or_firebase_service.dart';
import '../../shared/widgets/custom_card.dart';
import '../../../theme.dart';

class PepiteOrFormPage extends StatefulWidget {
  final PepiteOrModel? pepite;

  const PepiteOrFormPage({super.key, this.pepite});

  @override
  State<PepiteOrFormPage> createState() => _PepiteOrFormPageState();
}

class _PepiteOrFormPageState extends State<PepiteOrFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _themeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  List<CitationModel> _citations = [];
  bool _isLoading = false;
  bool _estPubliee = false;

  @override
  void initState() {
    super.initState();
    if (widget.pepite != null) {
      _chargerPepite();
    } else {
      _ajouterCitationVide();
    }
  }

  void _chargerPepite() {
    final pepite = widget.pepite!;
    _themeController.text = pepite.theme;
    _descriptionController.text = pepite.description;
    _tagsController.text = pepite.tags.join(', ');
    _citations = List.from(pepite.citations);
    _estPubliee = pepite.estPubliee;
  }

  @override
  void dispose() {
    _themeController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pepite != null ? 'Modifier la Pépite' : 'Nouvelle Pépite d\'Or',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.white100,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: AppTheme.white100,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sauvegarder,
            child: Text(
              'Sauvegarder',
              style: GoogleFonts.poppins(
                color: AppTheme.white100,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoGeneraleSection(),
                    const SizedBox(height: 24),
                    _buildCitationsSection(),
                    const SizedBox(height: 24),
                    _buildOptionsPublication(),
                    const SizedBox(height: 32),
                    _buildBoutonsSauvegarde(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoGeneraleSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations générales',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: AppTheme.fontSemiBold,
                color: const Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _themeController,
              decoration: InputDecoration(
                labelText: 'Thème de la pépite',
                hintText: 'Ex: La foi, L\'espoir, La persévérance...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                prefixIcon: const Icon(Icons.auto_awesome),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le thème est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez brièvement le contenu de cette pépite...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (séparés par des virgules)',
                hintText: 'foi, espoir, bible, prière...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                prefixIcon: const Icon(Icons.tag),
                helperText: 'Les tags aident à organiser et rechercher vos pépites',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationsSection() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Citations (${_citations.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: AppTheme.fontSemiBold,
                    color: const Color(0xFF8B4513),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _ajouterCitationVide,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: AppTheme.white100,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_citations.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.format_quote, size: 48, color: AppTheme.grey400),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune citation ajoutée',
                      style: GoogleFonts.poppins(color: AppTheme.grey600),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _ajouterCitationVide,
                      child: const Text('Ajouter une citation'),
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _citations.length,
                onReorder: _reorderCitations,
                itemBuilder: (context, index) {
                  return _buildCitationCard(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationCard(int index) {
    final citation = _citations[index];
    
    return Card(
      key: ValueKey(citation.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      fontWeight: AppTheme.fontBold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Citation ${index + 1}',
                    style: GoogleFonts.poppins(
                      fontWeight: AppTheme.fontSemiBold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _supprimerCitation(index),
                  icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                  tooltip: 'Supprimer cette citation',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: citation.texte,
              decoration: InputDecoration(
                labelText: 'Texte de la citation',
                hintText: 'Saisissez le texte de la citation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              maxLines: 4,
              onChanged: (value) => _modifierCitation(index, texte: value),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le texte de la citation est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: citation.auteur,
                    decoration: InputDecoration(
                      labelText: 'Auteur',
                      hintText: 'Nom de l\'auteur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    onChanged: (value) => _modifierCitation(index, auteur: value),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'auteur est requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: citation.reference,
                    decoration: InputDecoration(
                      labelText: 'Référence (optionnel)',
                      hintText: 'Livre, verset...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      prefixIcon: const Icon(Icons.book),
                    ),
                    onChanged: (value) => _modifierCitation(index, reference: value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsPublication() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options de publication',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: AppTheme.fontSemiBold,
                color: const Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Publier immédiatement',
                style: GoogleFonts.poppins(fontWeight: AppTheme.fontMedium),
              ),
              subtitle: Text(
                _estPubliee 
                    ? 'Cette pépite sera visible par tous les membres'
                    : 'Cette pépite restera en brouillon',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              value: _estPubliee,
              onChanged: (value) {
                setState(() {
                  _estPubliee = value;
                });
              },
              activeColor: const Color(0xFF8B4513),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonsSauvegarde() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sauvegarder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: AppTheme.white100,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                    ),
                  )
                : Text(
                    widget.pepite != null ? 'Modifier' : 'Créer',
                    style: GoogleFonts.poppins(fontWeight: AppTheme.fontSemiBold),
                  ),
          ),
        ),
      ],
    );
  }

  void _ajouterCitationVide() {
    setState(() {
      _citations.add(CitationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        texte: '',
        auteur: '',
        reference: '',
        ordre: _citations.length,
      ));
    });
  }

  void _supprimerCitation(int index) {
    setState(() {
      _citations.removeAt(index);
      // Réordonner les citations restantes
      for (int i = 0; i < _citations.length; i++) {
        _citations[i] = _citations[i].copyWith(ordre: i);
      }
    });
  }

  void _modifierCitation(int index, {String? texte, String? auteur, String? reference}) {
    setState(() {
      _citations[index] = _citations[index].copyWith(
        texte: texte,
        auteur: auteur,
        reference: reference,
      );
    });
  }

  void _reorderCitations(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final citation = _citations.removeAt(oldIndex);
      _citations.insert(newIndex, citation);
      
      // Mettre à jour l'ordre
      for (int i = 0; i < _citations.length; i++) {
        _citations[i] = _citations[i].copyWith(ordre: i);
      }
    });
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_citations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une citation'),
          backgroundColor: AppTheme.orangeStandard,
        ),
      );
      return;
    }

    // Vérifier que toutes les citations ont du contenu
    for (int i = 0; i < _citations.length; i++) {
      if (_citations[i].texte.trim().isEmpty || _citations[i].auteur.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La citation ${i + 1} est incomplète'),
            backgroundColor: AppTheme.orangeStandard,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final pepite = PepiteOrModel(
        id: widget.pepite?.id ?? '',
        theme: _themeController.text.trim(),
        description: _descriptionController.text.trim(),
        citations: _citations,
        dateCreation: widget.pepite?.dateCreation ?? DateTime.now(),
        datePublication: _estPubliee 
            ? (widget.pepite?.datePublication ?? DateTime.now())
            : null,
        auteur: widget.pepite?.auteur ?? '',
        nomAuteur: widget.pepite?.nomAuteur ?? '',
        estPubliee: _estPubliee,
        estFavorite: widget.pepite?.estFavorite ?? false,
        nbVues: widget.pepite?.nbVues ?? 0,
        nbPartages: widget.pepite?.nbPartages ?? 0,
        tags: tags,
        imageUrl: widget.pepite?.imageUrl,
      );

      if (widget.pepite != null) {
        await PepiteOrFirebaseService.modifierPepiteOr(pepite);
      } else {
        await PepiteOrFirebaseService.creerPepiteOr(pepite);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.pepite != null 
                  ? 'Pépite modifiée avec succès'
                  : 'Pépite créée avec succès',
            ),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
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
