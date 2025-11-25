import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import '../models/wb_sermon.dart';
import '../models/sermon_highlight.dart';
import '../providers/notes_highlights_provider.dart';

/// Widget pour afficher et lire un PDF avec support de surlignage
class PdfViewerWidget extends StatefulWidget {
  final WBSermon sermon;
  final int? initialPage;
  final String? highlightId;

  const PdfViewerWidget({
    super.key,
    required this.sermon,
    this.initialPage,
    this.highlightId,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  final PdfViewerController _pdfController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _selectedText;
  PdfTextSelectionChangedDetails? _textSelectionDetails;

  @override
  void initState() {
    super.initState();
    if (widget.initialPage != null) {
      _currentPage = widget.initialPage!;
      // Naviguer à la page après le chargement
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfController.jumpToPage(widget.initialPage!);
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sermon.pdfUrl == null) {
      return const Center(
        child: Text('Aucun PDF disponible pour ce sermon'),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Barre d'outils PDF
            _buildToolbar(),
            
            // Viewer PDF
            Expanded(
              child: SfPdfViewer.network(
                widget.sermon.pdfUrl!,
                key: _pdfViewerKey,
                controller: _pdfController,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                canShowPaginationDialog: true,
                enableDoubleTapZooming: true,
                enableTextSelection: true,
                onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                    _isLoading = false;
                  });
                },
                onPageChanged: (PdfPageChangedDetails details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
                onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                  setState(() {
                    _selectedText = details.selectedText;
                    _textSelectionDetails = details;
                  });
                  
                  if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                    _showTextSelectionMenu(details);
                  }
                },
              ),
            ),
          ],
        ),
        
        // Indicateur de chargement
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Zoom out
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _pdfController.zoomLevel = _pdfController.zoomLevel - 0.25;
            },
            tooltip: 'Zoom arrière',
          ),
          
          // Zoom in
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfController.zoomLevel = _pdfController.zoomLevel + 0.25;
            },
            tooltip: 'Zoom avant',
          ),
          
          const VerticalDivider(),
          
          // Page précédente
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 1
                ? () {
                    _pdfController.previousPage();
                  }
                : null,
            tooltip: 'Page précédente',
          ),
          
          // Indicateur de page
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_currentPage / $_totalPages',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          
          // Page suivante
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < _totalPages
                ? () {
                    _pdfController.nextPage();
                  }
                : null,
            tooltip: 'Page suivante',
          ),
          
          const VerticalDivider(),
          
          // Aller à une page spécifique
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: () => _showGoToPageDialog(),
            tooltip: 'Aller à la page',
          ),
          
          const Spacer(),
          
          // Rotation
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: () {
              // Note: Syncfusion ne supporte pas la rotation directe
              // Alternative: utiliser un Transform wrapper
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rotation non supportée dans cette version'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Rotation',
          ),
          
          // Recherche dans le PDF
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
            tooltip: 'Recherche',
          ),
        ],
      ),
    );
  }

  void _showGoToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aller à la page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Numéro de page (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(pageController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Numéro de page invalide (1-$_totalPages)'),
                  ),
                );
              }
            },
            child: const Text('Aller'),
          ),
        ],
      ),
    );
  }

  void _showTextSelectionMenu(PdfTextSelectionChangedDetails details) {
    if (details.selectedText == null || details.selectedText!.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.highlight),
              title: const Text('Surligner en jaune'),
              onTap: () {
                _createHighlight(Colors.yellow, details);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.highlight, color: Colors.green[300]),
              title: const Text('Surligner en vert'),
              onTap: () {
                _createHighlight(Colors.green[300]!, details);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.highlight, color: Colors.orange[300]),
              title: const Text('Surligner en orange'),
              onTap: () {
                _createHighlight(Colors.orange[300]!, details);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.highlight, color: Colors.blue[300]),
              title: const Text('Surligner en bleu'),
              onTap: () {
                _createHighlight(Colors.blue[300]!, details);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier le texte'),
              onTap: () {
                // TODO: Implémenter copie dans presse-papier
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texte copié')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Créer une note'),
              onTap: () {
                Navigator.pop(context);
                _createNoteFromSelection(details);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createHighlight(Color color, PdfTextSelectionChangedDetails details) {
    final highlight = SermonHighlight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sermonId: widget.sermon.id,
      text: details.selectedText!,
      color: '#${color.value.toRadixString(16).padLeft(8, '0')}',
      pageNumber: _currentPage,
      startPosition: 0, // Syncfusion ne fournit pas la position exacte
      endPosition: details.selectedText!.length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<NotesHighlightsProvider>().saveHighlight(highlight);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Surlignement créé'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _createNoteFromSelection(PdfTextSelectionChangedDetails details) {
    // Cette méthode sera appelée depuis le parent via callback
    // ou on peut utiliser un callback passé en paramètre
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Créer une note avec ce texte'),
        action: SnackBarAction(
          label: 'CRÉER',
          onPressed: () {
            // Ouvrir le dialog de création de note
            // avec le texte sélectionné pré-rempli
          },
        ),
      ),
    );
  }
}
