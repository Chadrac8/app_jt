import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/bible_verse.dart';

class VerseActionsDialog extends StatefulWidget {
  final BibleVerse verse;
  final Function(Color color) onHighlight;
  final VoidCallback onFavorite;
  final VoidCallback? onRemoveHighlight;
  final Function(String note) onNote;
  final VoidCallback onShare;
  final String? existingNote;
  final bool isHighlighted;
  final bool isFavorite;

  const VerseActionsDialog({
    Key? key,
    required this.verse,
    required this.onHighlight,
    required this.onFavorite,
    this.onRemoveHighlight,
    required this.onNote,
    required this.onShare,
    this.existingNote,
    this.isHighlighted = false,
    this.isFavorite = false,
  }) : super(key: key);

  @override
  State<VerseActionsDialog> createState() => _VerseActionsDialogState();
}

class _VerseActionsDialogState extends State<VerseActionsDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteInput = false;
  bool _showHighlightPalette = false;
  
  @override
  void initState() {
    super.initState();
    // Charger la note existante si elle existe
    if (widget.existingNote != null && widget.existingNote!.isNotEmpty) {
      _noteController.text = widget.existingNote!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(AppTheme.radius2),
            ),
          ),
          
          // En-tête avec référence du verset
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Text(
                  widget.verse.reference,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.grey50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    widget.verse.text,
                    style: GoogleFonts.crimsonText(
                      fontSize: AppTheme.fontSize16,
                      color: AppTheme.black100.withOpacity(0.87),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          if (!_showNoteInput) ...[
            // Actions principales
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Couleurs de surlignage
                  _buildHighlightColors(),
                  
                  const SizedBox(height: 12),
                  
                  // Actions rapides style YouVersion
                  if (_showHighlightPalette)
                    _buildYouVersionHighlightPalette()
                  else
                    _buildYouVersionActions(),
                  
                  // Prévisualisation de la note existante
                  if (widget.existingNote != null && widget.existingNote!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceMedium),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppTheme.orangeStandard.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: AppTheme.orangeStandard.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 16,
                                color: AppTheme.orangeStandard,
                              ),
                              const SizedBox(width: AppTheme.spaceXSmall),
                              Text(
                                'Note existante :',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSize12,
                                  fontWeight: AppTheme.fontSemiBold,
                                  color: AppTheme.orangeStandard,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spaceXSmall),
                          Text(
                            widget.existingNote!.length > 100 
                                ? '${widget.existingNote!.substring(0, 100)}...'
                                : widget.existingNote!,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              color: AppTheme.black100.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Interface d'ajout de note
            Expanded(
              child: SingleChildScrollView(
                child: _buildNoteInput(),
              ),
            ),
          ],
          
          const SizedBox(height: AppTheme.spaceMedium),
        ],
      ),
    );
  }

  Widget _buildActionSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.black100.withOpacity(0.87),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        content,
      ],
    );
  }

  Widget _buildHighlightColors() {
    // Couleurs exactes de YouVersion avec noms descriptifs
    final highlightColors = [
      {'color': const Color(0xFFFFE066), 'name': 'Jaune', 'description': 'Classique'}, // Jaune YouVersion signature
      {'color': const Color(0xFF81C784), 'name': 'Vert', 'description': 'Espoir'}, // Vert YouVersion  
      {'color': const Color(0xFF90CAF9), 'name': 'Bleu', 'description': 'Paix'}, // Bleu YouVersion
      {'color': const Color(0xFFFFB74D), 'name': 'Orange', 'description': 'Joie'}, // Orange YouVersion
      {'color': const Color(0xFFF8BBD9), 'name': 'Rose', 'description': 'Amour'}, // Rose YouVersion
      {'color': const Color(0xFFCE93D8), 'name': 'Violet', 'description': 'Sagesse'}, // Violet YouVersion
      {'color': const Color(0xFFEF5350), 'name': 'Rouge', 'description': 'Important'}, // Rouge YouVersion
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisir une couleur',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: highlightColors.map((colorData) {
            final color = colorData['color'] as Color;
            final name = colorData['name'] as String;
            
            return Expanded(
              child: Tooltip(
                message: name,
                child: GestureDetector(
                  onTap: () {
                    // Feedback haptique comme YouVersion
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    // Appeler le callback APRÈS la fermeture du dialogue
                    Future.microtask(() => widget.onHighlight(color));
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 48,
                    decoration: BoxDecoration(
                      // Effet de surlignement YouVersion parfaitement reproduit
                      color: color.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      // Bordure plus marquée comme YouVersion
                      border: Border.all(
                        color: color.withOpacity(0.7),
                        width: 2,
                      ),
                      // Ombre réaliste YouVersion
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Effet de brillance comme YouVersion
                        Positioned(
                          top: 4,
                          left: 4,
                          right: 4,
                          height: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        // Icône centrée
                        Center(
                          child: Icon(
                            Icons.brush,
                            color: color.withOpacity(0.9),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        // Légendes des couleurs comme YouVersion
        Row(
          children: highlightColors.map((colorData) {
            final name = colorData['name'] as String;
            
            return Expanded(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildYouVersionActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isActive 
            ? color.withOpacity(0.1) 
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
              ? color.withOpacity(0.4) 
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(
                  icon, 
                  color: isActive 
                    ? color 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  size: 18,
                ),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive 
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouVersionActions() {
    return Column(
      children: [
        // Actions principales
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildYouVersionActionButton(
                'Note',
                Icons.note_add_outlined,
                const Color(0xFF81C784),
                () {
                  setState(() {
                    _showNoteInput = true;
                    if (widget.existingNote?.isNotEmpty ?? false) {
                      _noteController.text = widget.existingNote!;
                    }
                  });
                },
                showBadge: widget.existingNote?.isNotEmpty ?? false,
              ),
              _buildYouVersionActionButton(
                'Favoris',
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                const Color(0xFFEF5350),
                () => widget.onFavorite(),
                isActive: widget.isFavorite,
              ),
              _buildYouVersionActionButton(
                'Partager',
                Icons.share_outlined,
                const Color(0xFF90CAF9),
                () => widget.onShare(),
              ),
            ],
          ),
        ),
        
        // Actions secondaires
        if (widget.isHighlighted || (widget.existingNote?.isNotEmpty ?? false))
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                Row(
                  children: [
                    if (widget.isHighlighted)
                      Flexible(
                        fit: FlexFit.tight,
                        child: _buildSecondaryAction(
                          'Surlignement',
                          Icons.format_color_reset,
                          () {
                            Navigator.of(context).pop();
                            if (widget.onRemoveHighlight != null) {
                              Future.microtask(() => widget.onRemoveHighlight!());
                            }
                          },
                        ),
                      ),
                    if (widget.isHighlighted && (widget.existingNote?.isNotEmpty ?? false))
                      const SizedBox(width: 12),
                    if (widget.existingNote?.isNotEmpty ?? false)
                      Flexible(
                        fit: FlexFit.tight,
                        child: _buildSecondaryAction(
                          'Note',
                          Icons.delete_outline,
                          () {
                            Navigator.of(context).pop();
                            Future.microtask(() => widget.onNote(''));
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSecondaryAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouVersionHighlightPalette() {
    final highlightColors = [
      {'color': const Color(0xFFFFE066), 'name': 'Jaune'},
      {'color': const Color(0xFF81C784), 'name': 'Vert'},
      {'color': const Color(0xFF90CAF9), 'name': 'Bleu'},
      {'color': const Color(0xFFFFB74D), 'name': 'Orange'},
      {'color': const Color(0xFFF8BBD9), 'name': 'Rose'},
      {'color': const Color(0xFFCE93D8), 'name': 'Violet'},
      {'color': const Color(0xFFEF5350), 'name': 'Rouge'},
      {'color': const Color(0xFFE0E0E0), 'name': 'Gris'},
    ];

    return Column(
      children: [
        // Header avec bouton retour
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showHighlightPalette = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Choisir une couleur',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Palette de couleurs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: highlightColors.length,
            itemBuilder: (context, index) {
              final colorData = highlightColors[index];
              final color = colorData['color'] as Color;
              final name = colorData['name'] as String;
              
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  // Appeler le callback APRÈS la fermeture du dialogue
                  Future.microtask(() => widget.onHighlight(color));
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.computeLuminance() > 0.5 
                            ? Colors.black.withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.format_color_text,
                          color: color.computeLuminance() > 0.5 
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.9),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  void _showHighlightOptions() {
    setState(() {
      _showNoteInput = false;
      _showHighlightPalette = true;
    });
  }



  Widget _buildNoteInput() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showNoteInput = false;
                    _noteController.clear();
                  });
                },
              ),
              Text(
                widget.existingNote != null && widget.existingNote!.isNotEmpty 
                    ? 'Modifier la note' 
                    : 'Ajouter une note',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Écrivez votre note ici...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            autofocus: true,
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showNoteInput = false;
                      if (widget.existingNote == null || widget.existingNote!.isEmpty) {
                        _noteController.clear();
                      }
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              // Bouton supprimer si une note existe
              if (widget.existingNote != null && widget.existingNote!.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Future.microtask(() => widget.onNote('')); // Passer une chaîne vide pour supprimer
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.redStandard,
                      side: BorderSide(color: AppTheme.redStandard),
                    ),
                    child: const Text('Supprimer'),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final noteText = _noteController.text.trim();
                    Navigator.pop(context);
                    Future.microtask(() => widget.onNote(noteText));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white100,
                  ),
                  child: Text(
                    widget.existingNote != null && widget.existingNote!.isNotEmpty 
                        ? 'Modifier' 
                        : 'Enregistrer'
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
