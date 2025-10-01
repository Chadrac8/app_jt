import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/bible_verse.dart';
import '../../../theme.dart';

class VerseActionsDialog extends StatefulWidget {
  final BibleVerse verse;
  final Function(Color color) onHighlight;
  final VoidCallback onFavorite;
  final Function(String note) onNote;
  final VoidCallback onShare;

  const VerseActionsDialog({
    Key? key,
    required this.verse,
    required this.onHighlight,
    required this.onFavorite,
    required this.onNote,
    required this.onShare,
  }) : super(key: key);

  @override
  State<VerseActionsDialog> createState() => _VerseActionsDialogState();
}

class _VerseActionsDialogState extends State<VerseActionsDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _showNoteInput = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              children: [
                Text(
                  widget.verse.reference,
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
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
                  // Surlignage avec couleurs
                  _buildActionSection(
                    'Surligner',
                    Icons.highlight,
                    _buildHighlightColors(),
                  ),
                  
                  const SizedBox(height: AppTheme.spaceMedium),
                  
                  // Actions rapides
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Favori',
                          Icons.favorite_border,
                          AppTheme.redStandard,
                          widget.onFavorite,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: _buildActionButton(
                          'Note',
                          Icons.note_add,
                          AppTheme.orangeStandard,
                          () {
                            setState(() {
                              _showNoteInput = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: _buildActionButton(
                          'Partager',
                          Icons.share,
                          AppTheme.blueStandard,
                          () {
                            widget.onShare();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Interface d'ajout de note
            _buildNoteInput(),
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
    final colors = [
      Colors.yellow,
      AppTheme.greenStandard,
      AppTheme.blueStandard,
      AppTheme.orangeStandard,
      AppTheme.pinkStandard,
      AppTheme.primaryColor,
    ];

    return Row(
      children: colors.map((color) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              widget.onHighlight(color);
              Navigator.pop(context);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.palette,
                color: color.withOpacity(0.8),
                size: 20,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize12,
                fontWeight: AppTheme.fontMedium,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
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
                'Ajouter une note',
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
                      _noteController.clear();
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_noteController.text.trim().isNotEmpty) {
                      widget.onNote(_noteController.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white100,
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
