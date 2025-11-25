import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/wb_sermon.dart';
import '../models/sermon_note.dart';
import '../models/sermon_highlight.dart';
import '../providers/notes_highlights_provider.dart';
import 'note_form_dialog.dart';

/// Widget pour afficher le texte d'un sermon avec surlignement et notes
/// Inspiré de La Table VGR et MessageHub
class SermonTextViewerWidget extends StatefulWidget {
  final WBSermon sermon;
  final String? initialSearchQuery;
  final VoidCallback? onCreateNote;

  const SermonTextViewerWidget({
    super.key,
    required this.sermon,
    this.initialSearchQuery,
    this.onCreateNote,
  });

  @override
  State<SermonTextViewerWidget> createState() => _SermonTextViewerWidgetState();
}

class _SermonTextViewerWidgetState extends State<SermonTextViewerWidget> {
  // État du texte
  String? _sermonText;
  bool _isLoading = true;
  String? _error;

  // Paramètres de lecture
  double _fontSize = 16.0;
  double _lineHeight = 1.5;
  bool _isDarkMode = false;

  // Sélection de texte par paragraphe
  String? _selectedParagraphText;
  int? _selectedParagraphStart;
  int? _selectedParagraphEnd;
  int? _selectedParagraphIndex;
  
  // Liste des paragraphes
  List<String> _paragraphs = [];

  // Couleurs de surlignement disponibles
  final List<HighlightColor> _availableColors = [
    HighlightColor('Jaune', Colors.yellow.shade200, '#FFEB3B'),
    HighlightColor('Vert', Colors.green.shade200, '#4CAF50'),
    HighlightColor('Bleu', Colors.blue.shade200, '#2196F3'),
    HighlightColor('Rose', Colors.pink.shade200, '#E91E63'),
    HighlightColor('Orange', Colors.orange.shade200, '#FF9800'),
    HighlightColor('Violet', Colors.purple.shade200, '#9C27B0'),
  ];

  String _selectedColor = '#FFEB3B'; // Jaune par défaut

  // Recherche dans le texte
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<TextRange> _searchMatches = [];
  int _currentMatchIndex = -1;
  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSermonText();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void didUpdateWidget(SermonTextViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger le texte si le sermon a changé
    if (oldWidget.sermon.id != widget.sermon.id) {
      _loadSermonText();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Charge le texte du sermon depuis le champ textContent
  Future<void> _loadSermonText() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Utiliser directement le textContent du sermon
      if (widget.sermon.textContent != null && widget.sermon.textContent!.isNotEmpty) {
        setState(() {
          _sermonText = widget.sermon.textContent;
          _isLoading = false;
        });
        debugPrint('✅ Texte chargé: ${widget.sermon.textContent!.length} caractères');
      } else {
        setState(() {
          _error = 'Aucun texte disponible pour ce sermon.\n'
                   'Veuillez ajouter le texte via le formulaire d\'administration.';
          _isLoading = false;
        });
        return;
      }

      // Effectuer la recherche initiale si query présente
      if (widget.initialSearchQuery != null) {
        _performSearch(widget.initialSearchQuery!);
      }
    } catch (e) {
      debugPrint('❌ Erreur générale: $e');
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  /// Extrait le texte d'un contenu HTML
  String _extractTextFromHtml(String html) {
    // Suppression basique des balises HTML
    String text = html;
    
    // Remplacer les balises de paragraphes par des sauts de ligne
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    text = text.replaceAll(RegExp(r'</p>'), '\n\n');
    text = text.replaceAll(RegExp(r'</div>'), '\n');
    
    // Supprimer toutes les balises HTML
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Décoder les entités HTML
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    
    // Nettoyer les espaces multiples
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    text = text.replaceAll(RegExp(r'\n\s+'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return text.trim();
  }

  /// Effectue une recherche dans le texte
  void _performSearch(String query) {
    if (_sermonText == null || query.isEmpty) {
      setState(() {
        _searchMatches.clear();
        _currentMatchIndex = -1;
      });
      return;
    }

    final matches = <TextRange>[];
    final lowerText = _sermonText!.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int index = lowerText.indexOf(lowerQuery);
    while (index >= 0) {
      matches.add(TextRange(start: index, end: index + query.length));
      index = lowerText.indexOf(lowerQuery, index + 1);
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isEmpty ? -1 : 0;
    });
    
    // Scroll automatiquement vers le premier résultat
    if (matches.isNotEmpty) {
      _scrollToCurrentMatch();
    }
  }

  /// Navigue vers la correspondance suivante
  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
    });
    _scrollToCurrentMatch();
  }

  /// Navigue vers la correspondance précédente
  void _previousMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
    });
    _scrollToCurrentMatch();
  }

  /// Scroll vers le résultat de recherche actuel de manière professionnelle
  void _scrollToCurrentMatch() {
    if (_currentMatchIndex < 0 || _searchMatches.isEmpty || _sermonText == null) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      
      try {
        final match = _searchMatches[_currentMatchIndex];
        final textBeforeMatch = _sermonText!.substring(0, match.start);
        
        // Calcul précis basé sur les retours à la ligne et les caractères
        final linesBefore = '\n'.allMatches(textBeforeMatch).length;
        final baseLineHeight = _fontSize * _lineHeight;
        
        // Estimation plus précise avec padding et facteur de correction
        // +16 pour le padding top du container
        final estimatedPosition = (linesBefore * baseLineHeight) + 16;
        
        // Obtenir la hauteur de la barre d'outils pour compenser
        final toolbarHeight = 56.0; // Hauteur approximative de la toolbar
        
        // Obtenir la hauteur de la fenêtre visible
        final screenHeight = MediaQuery.of(context).size.height;
        final viewportHeight = (screenHeight * 0.5) - toolbarHeight; // Ajuster pour la toolbar
        
        // Position cible : centrer le résultat dans le viewport, en dessous de la toolbar
        final targetPosition = (estimatedPosition - viewportHeight - toolbarHeight)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        
        // Animation fluide et professionnelle
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } catch (e) {
        debugPrint('Erreur lors du scroll vers le résultat: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du texte...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSermonText,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_sermonText == null) {
      return const Center(
        child: Text('Aucun texte disponible'),
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _buildTextContent(),
        ),
      ],
    );
  }

  /// Barre d'outils de lecture
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Recherche
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans le texte...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: _performSearch,
            ),
          ),
          
          // Affichage conditionnel : résultats de recherche OU outils de lecture
          if (_searchController.text.isNotEmpty && _searchMatches.isNotEmpty) ...[
            // Navigation de recherche
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentMatchIndex + 1}/${_searchMatches.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Résultat précédent',
              iconSize: 22,
              onPressed: _previousMatch,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Résultat suivant',
              iconSize: 22,
              onPressed: _nextMatch,
            ),
          ] else if (_searchController.text.isEmpty) ...[
            // Outils de lecture (affichés uniquement quand pas de recherche)
            const SizedBox(width: 8),
            const VerticalDivider(),
            const SizedBox(width: 8),

            // Taille de police
            IconButton(
              icon: const Icon(Icons.text_decrease),
              tooltip: 'Réduire la taille',
              iconSize: 20,
              onPressed: () {
                setState(() {
                  _fontSize = (_fontSize - 1).clamp(12.0, 24.0);
                });
              },
            ),
            Text('${_fontSize.toInt()}', style: const TextStyle(fontSize: 12)),
            IconButton(
              icon: const Icon(Icons.text_increase),
              tooltip: 'Augmenter la taille',
              iconSize: 20,
              onPressed: () {
                setState(() {
                  _fontSize = (_fontSize + 1).clamp(12.0, 24.0);
                });
              },
            ),

            const SizedBox(width: 8),
            const VerticalDivider(),
            const SizedBox(width: 8),

            // Mode sombre
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: _isDarkMode ? 'Mode clair' : 'Mode sombre',
              iconSize: 20,
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),

            // Couleur de surlignement
            PopupMenuButton<String>(
              icon: Icon(
                Icons.color_lens,
                color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
              ),
              tooltip: 'Couleur de surlignement',
              iconSize: 20,
              onSelected: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              itemBuilder: (context) => _availableColors.map((color) {
                return PopupMenuItem<String>(
                  value: color.hex,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.color,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(color.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Contenu du texte avec surlignements
  Widget _buildTextContent() {
    return Container(
      color: _isDarkMode ? Colors.grey[900] : Colors.white,
      child: Consumer<NotesHighlightsProvider>(
        builder: (context, provider, _) {
          final highlights = provider.highlights
              .where((h) => h.sermonId == widget.sermon.id)
              .toList();
          final notes = provider.notes
              .where((n) => n.sermonId == widget.sermon.id)
              .toList();

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: SelectableText.rich(
              _buildHighlightedText(highlights, notes),
              style: TextStyle(
                fontSize: _fontSize,
                height: _lineHeight,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              onSelectionChanged: (selection, cause) {
                if (selection.isCollapsed) {
                  setState(() {
                    _selectedParagraphText = null;
                    _selectedParagraphStart = null;
                    _selectedParagraphEnd = null;
                  });
                } else if (_sermonText != null) {
                  final start = selection.start.clamp(0, _sermonText!.length);
                  final end = selection.end.clamp(0, _sermonText!.length);
                  
                  if (start < end && start < _sermonText!.length) {
                    final text = _sermonText!.substring(start, end);
                    
                    debugPrint('✅ Sélection (positions garanties exactes):');
                    debugPrint('   $start → $end: "${text.substring(0, text.length > 40 ? 40 : text.length)}..."');
                    
                    setState(() {
                      _selectedParagraphText = text;
                      _selectedParagraphStart = start;
                      _selectedParagraphEnd = end;
                    });
                  }
                }
              },
              contextMenuBuilder: (context, editableTextState) {
                if (_selectedParagraphText == null || _selectedParagraphText!.isEmpty) {
                  return AdaptiveTextSelectionToolbar.buttonItems(
                    anchors: editableTextState.contextMenuAnchors,
                    buttonItems: editableTextState.contextMenuButtonItems,
                  );
                }

                return _buildCustomSelectionMenu(context, editableTextState);
              },
            ),
          );
        },
      ),
    );
  }

  /// Construit le texte avec surlignements et correspondances de recherche
  /// IMPORTANT: Le TextSpan doit contenir EXACTEMENT le même texte caractère par caractère
  /// que _sermonText pour que les positions de sélection correspondent
  TextSpan _buildHighlightedText(List<SermonHighlight> highlights, List<SermonNote> notes) {
    if (_sermonText == null || _sermonText!.isEmpty) {
      return const TextSpan(text: '');
    }

    // Si pas de highlights et pas de notes, retourner le texte simple
    if (highlights.isEmpty && _searchMatches.isEmpty && notes.isEmpty) {
      return TextSpan(text: _sermonText!);
    }

    final spans = <InlineSpan>[];
    int currentIndex = 0;

    // Créer une liste de tous les segments à surligner
    final segments = <_TextSegment>[];
    
    // Créer une map des positions de notes basées sur le texte de référence
    final notePositions = <int, SermonNote>{};
    for (final note in notes) {
      if (note.referenceText != null && note.referenceText!.isNotEmpty) {
        final position = _sermonText!.indexOf(note.referenceText!);
        if (position >= 0) {
          // Placer l'icône à la fin du texte de référence
          final noteEndPosition = position + note.referenceText!.length;
          notePositions[noteEndPosition] = note;
        }
      }
    }

    // Ajouter les surlignements
    for (final highlight in highlights) {
      if (highlight.startPosition != null && highlight.endPosition != null) {
        final start = highlight.startPosition!.clamp(0, _sermonText!.length);
        final end = highlight.endPosition!.clamp(0, _sermonText!.length);
        
        if (start < end) {
          segments.add(_TextSegment(
            start: start,
            end: end,
            color: Color(int.parse(highlight.color!.replaceFirst('#', '0xFF'))),
            isHighlight: true,
            highlightId: highlight.id,
          ));
        }
      }
    }

    // Ajouter les correspondances de recherche
    for (int i = 0; i < _searchMatches.length; i++) {
      final match = _searchMatches[i];
      final start = match.start.clamp(0, _sermonText!.length);
      final end = match.end.clamp(0, _sermonText!.length);
      
      if (start < end) {
        segments.add(_TextSegment(
          start: start,
          end: end,
          color: i == _currentMatchIndex ? Colors.orange : Colors.yellow,
          isHighlight: false,
        ));
      }
    }

    // Trier par position de début, puis par fin (pour gérer les chevauchements)
    segments.sort((a, b) {
      final startCompare = a.start.compareTo(b.start);
      if (startCompare != 0) return startCompare;
      return a.end.compareTo(b.end);
    });

    // Obtenir toutes les positions importantes (segments + notes) triées
    final allPositions = <int>{};
    for (final segment in segments) {
      allPositions.add(segment.start);
      allPositions.add(segment.end);
    }
    allPositions.addAll(notePositions.keys);
    allPositions.add(_sermonText!.length);
    final sortedPositions = allPositions.toList()..sort();

    // Construire le texte segment par segment
    for (int i = 0; i < sortedPositions.length; i++) {
      final position = sortedPositions[i];
      
      // Ajouter le texte jusqu'à cette position
      if (currentIndex < position) {
        // Vérifier si ce texte est dans un segment surligné
        final activeSegment = segments.where((s) => 
          currentIndex >= s.start && position <= s.end
        ).firstOrNull;
        
        if (activeSegment != null) {
          // Texte surligné
          spans.add(TextSpan(
            text: _sermonText!.substring(currentIndex, position),
            style: TextStyle(
              backgroundColor: activeSegment.isHighlight 
                  ? activeSegment.color.withOpacity(0.35)
                  : activeSegment.color,
              fontWeight: activeSegment.isHighlight ? FontWeight.w500 : null,
              decorationColor: activeSegment.isHighlight ? activeSegment.color : null,
              decoration: activeSegment.isHighlight ? TextDecoration.underline : null,
              decorationThickness: activeSegment.isHighlight ? 2.5 : null,
            ),
          ));
        } else {
          // Texte normal
          spans.add(TextSpan(text: _sermonText!.substring(currentIndex, position)));
        }
        
        currentIndex = position;
      }
      
      // Ajouter l'icône de note si présente à cette position
      if (notePositions.containsKey(position)) {
        final note = notePositions[position]!;
        final isHighlighted = segments.any((s) => 
          position >= s.start && position <= s.end && s.isHighlight
        );
        
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => _showNoteDialog(note),
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 2),
              child: _buildNoteIndicator(isHighlighted),
            ),
          ),
        ));
      }
    }

    return TextSpan(children: spans);
  }





  /// Barre d'outils de sélection (obsolète mais gardée pour compatibilité)
  Widget _buildSelectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          top: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '"${_selectedParagraphText!.substring(0, _selectedParagraphText!.length > 50 ? 50 : _selectedParagraphText!.length)}${_selectedParagraphText!.length > 50 ? '...' : ''}"',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _highlightSelectedText,
            icon: Icon(
              Icons.highlight,
              color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
            ),
            label: const Text('Surligner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _createNoteFromSelection,
            icon: const Icon(Icons.note_add),
            label: const Text('Note'),
          ),
        ],
      ),
    );
  }

  /// Surligne le texte sélectionné (obsolète, remplacé par _highlightParagraph)
  Future<void> _highlightSelectedText() async {
    // Méthode gardée pour compatibilité mais non utilisée

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texte surligné'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  /// Éditer ou supprimer un surlignement existant
  Future<void> _editHighlight(String highlightId) async {
    final provider = context.read<NotesHighlightsProvider>();
    final highlights = provider.highlights.where((h) => h.sermonId == widget.sermon.id).toList();
    final highlight = highlights.firstWhere((h) => h.id == highlightId);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Modifier le surlignement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                highlight.text,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              const Text(
                'Changer la couleur :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((colorOption) {
                  final isSelected = colorOption.hex == highlight.color;
                  return GestureDetector(
                    onTap: () async {
                      final updatedHighlight = highlight.copyWith(
                        color: colorOption.hex,
                        updatedAt: DateTime.now(),
                      );
                      await provider.saveHighlight(updatedHighlight);
                      if (modalContext.mounted) {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(modalContext).showSnackBar(
                          const SnackBar(
                            content: Text('Couleur modifiée'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorOption.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(modalContext);
                    
                    debugPrint('🗑️ Tentative de suppression du highlight: $highlightId');
                    
                    final confirmed = await showDialog<bool>(
                      context: modalContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Supprimer le surlignement'),
                        content: const Text('Voulez-vous vraiment supprimer ce surlignement ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );

                    debugPrint('🗑️ Confirmation: $confirmed');

                    if (confirmed == true) {
                      try {
                        debugPrint('🗑️ Appel de deleteHighlight...');
                        await provider.deleteHighlight(highlightId);
                        debugPrint('✅ Highlight supprimé avec succès');
                        
                        if (modalContext.mounted) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            const SnackBar(
                              content: Text('Surlignement supprimé'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('❌ Erreur lors de la suppression: $e');
                        if (modalContext.mounted) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              duration: const Duration(seconds: 3),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Supprimer le surlignement',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Crée une note à partir du texte sélectionné
  Future<void> _createNoteFromSelection() async {
    if (_selectedParagraphText == null) return;

    final titleController = TextEditingController();
    final contentController = TextEditingController(text: _selectedParagraphText);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenu',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 8),
              Text(
                'Référence: "${_selectedParagraphText!.substring(0, _selectedParagraphText!.length > 50 ? 50 : _selectedParagraphText!.length)}..."',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      final note = SermonNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sermonId: widget.sermon.id,
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        referenceText: _selectedParagraphText,
        createdAt: DateTime.now(),
      );

      final provider = context.read<NotesHighlightsProvider>();
      await provider.saveNote(note);

      setState(() {
        _selectedParagraphText = null;
        _selectedParagraphStart = null;
        _selectedParagraphEnd = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note créée'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }

    titleController.dispose();
    contentController.dispose();
  }

  /// Construit le menu de sélection personnalisé élégant et professionnel
  Widget _buildCustomSelectionMenu(BuildContext context, EditableTextState editableTextState) {
    // Vérifier si le texte sélectionné contient un surlignement
    final provider = context.read<NotesHighlightsProvider>();
    final highlights = provider.highlights.where((h) => h.sermonId == widget.sermon.id).toList();
    SermonHighlight? existingHighlight;
    
    if (_selectedParagraphStart != null && _selectedParagraphEnd != null) {
      for (final highlight in highlights) {
        if (highlight.startPosition != null && highlight.endPosition != null) {
          // Vérifier si la sélection chevauche ce surlignement
          if (_selectedParagraphStart! <= highlight.endPosition! && _selectedParagraphEnd! >= highlight.startPosition!) {
            existingHighlight = highlight;
            break;
          }
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextSelectionToolbar(
      anchorAbove: editableTextState.contextMenuAnchors.primaryAnchor,
      anchorBelow: editableTextState.contextMenuAnchors.secondaryAnchor ?? editableTextState.contextMenuAnchors.primaryAnchor,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildElegantActionButton(
                    icon: Icons.highlight_outlined,
                    label: 'Surligner',
                    onTap: () {
                      ContextMenuController.removeAny();
                      _showHighlightColorPicker();
                    },
                  ),
                  if (existingHighlight != null)
                    _buildElegantActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Modifier',
                      onTap: () {
                        ContextMenuController.removeAny();
                        _editHighlight(existingHighlight!.id);
                      },
                    ),
                  _buildElegantActionButton(
                    icon: Icons.copy_outlined,
                    label: 'Copier',
                    onTap: () {
                      ContextMenuController.removeAny();
                      if (_selectedParagraphText != null) {
                        final formattedText = _formatTextForCopy(_selectedParagraphText!);
                        Clipboard.setData(ClipboardData(text: formattedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Texte copié avec référence'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  _buildElegantActionButton(
                    icon: Icons.note_add_outlined,
                    label: 'Note',
                    onTap: () {
                      ContextMenuController.removeAny();
                      if (widget.onCreateNote != null) widget.onCreateNote!();
                    },
                  ),
                  _buildElegantActionButton(
                    icon: Icons.search_outlined,
                    label: 'Chercher',
                    onTap: () {
                      ContextMenuController.removeAny();
                      if (_selectedParagraphText != null) {
                        setState(() {
                          _searchController.text = _selectedParagraphText!;
                          _performSearch(_selectedParagraphText!);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showHighlightColorPicker() {
    if (_selectedParagraphText == null || 
        _selectedParagraphStart == null || 
        _selectedParagraphEnd == null ||
        _sermonText == null) return;

    // VALIDATION CRITIQUE: Vérifier que les positions correspondent au texte sélectionné
    final actualText = _sermonText!.substring(
      _selectedParagraphStart!.clamp(0, _sermonText!.length),
      _selectedParagraphEnd!.clamp(0, _sermonText!.length),
    );
    
    if (actualText != _selectedParagraphText) {
      debugPrint('🚨 ERREUR CRITIQUE: Décalage de positions détecté!');
      debugPrint('   Texte sélectionné: "$_selectedParagraphText"');
      debugPrint('   Texte aux positions $_selectedParagraphStart-$_selectedParagraphEnd: "$actualText"');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Le texte sélectionné ne correspond pas aux positions. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir une couleur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '"${_selectedParagraphText!.substring(0, _selectedParagraphText!.length > 60 ? 60 : _selectedParagraphText!.length)}${_selectedParagraphText!.length > 60 ? "..." : ""}"',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _availableColors.map((c) {
                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    
                    debugPrint('💾 Sauvegarde du highlight:');
                    debugPrint('   Texte: "${_selectedParagraphText!.substring(0, _selectedParagraphText!.length > 40 ? 40 : _selectedParagraphText!.length)}..."');
                    debugPrint('   Positions: $_selectedParagraphStart → $_selectedParagraphEnd');
                    debugPrint('   Couleur: ${c.name} (${c.hex})');
                    
                    final highlight = SermonHighlight(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      sermonId: widget.sermon.id,
                      text: actualText, // Utiliser le texte VÉRIFIÉ
                      color: c.hex,
                      startPosition: _selectedParagraphStart,
                      endPosition: _selectedParagraphEnd,
                      createdAt: DateTime.now(),
                    );
                    await this.context.read<NotesHighlightsProvider>().saveHighlight(highlight);
                    setState(() {
                      _selectedParagraphText = null;
                      _selectedParagraphStart = null;
                      _selectedParagraphEnd = null;
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Texte surligné')),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(c.name, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Bouton d'action élégant et professionnel pour le menu de sélection
  Widget _buildElegantActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          constraints: const BoxConstraints(minWidth: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit l'indicateur de note (icône professionnelle)
  Widget _buildNoteIndicator(bool isHighlighted) {
    const orangeStandard = Color(0xFFF97316);
    const orangeIntense = Color(0xFFEA580C);
    
    final indicatorColor = isHighlighted ? orangeIntense : orangeStandard;
    
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: indicatorColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.sticky_note_2_rounded,
        size: 12,
        color: indicatorColor,
      ),
    );
  }

  /// Affiche le dialogue de note
  void _showNoteDialog(SermonNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.note, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.title.isNotEmpty ? note.title : 'Note',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.referenceText != null && note.referenceText!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  '"${note.referenceText!.substring(0, note.referenceText!.length > 100 ? 100 : note.referenceText!.length)}${note.referenceText!.length > 100 ? '...' : ''}"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              note.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Formate le texte sélectionné avec les métadonnées du sermon pour la copie
  String _formatTextForCopy(String selectedText) {
    // Informations du sermon
    final sermonTitle = widget.sermon.title;
    final sermonDate = widget.sermon.date;
    final sermonLocation = widget.sermon.location ?? '';
    
    // Référence complète sur une seule ligne
    final reference = '$sermonDate - $sermonTitle${sermonLocation.isNotEmpty ? ', $sermonLocation' : ''}';
    
    // Diviser le texte sélectionné en paragraphes
    final paragraphs = selectedText.split('\n').where((p) => p.trim().isNotEmpty).toList();
    
    // Construire le texte formaté
    final buffer = StringBuffer();
    buffer.writeln(reference);
    buffer.writeln();
    
    // Ajouter les paragraphes
    if (paragraphs.length == 1) {
      buffer.write(paragraphs[0]);
    } else {
      for (int i = 0; i < paragraphs.length; i++) {
        buffer.writeln('¶ ${i + 1}');
        buffer.write(paragraphs[i]);
        if (i < paragraphs.length - 1) {
          buffer.writeln();
          buffer.writeln();
        }
      }
    }
    
    return buffer.toString();
  }
}

/// Classe helper pour les couleurs de surlignement
class HighlightColor {
  final String name;
  final Color color;
  final String hex;

  HighlightColor(this.name, this.color, this.hex);
}

/// Classe helper pour les segments de texte
class _TextSegment {
  final int start;
  final int end;
  final Color color;
  final bool isHighlight;
  final String? highlightId; // ID du highlight pour permettre l'édition

  _TextSegment({
    required this.start,
    required this.end,
    required this.color,
    required this.isHighlight,
    this.highlightId,
  });
}


