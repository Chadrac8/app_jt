import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/songs/models/song_model.dart';
import '../services/chord_transposer.dart';

/// Page de projection des chants en plein écran - Version réorganisée
class SongProjectionPage extends StatefulWidget {
  final SongModel song;

  const SongProjectionPage({
    super.key,
    required this.song,
  });

  @override
  State<SongProjectionPage> createState() => _SongProjectionPageState();
}

class _SongProjectionPageState extends State<SongProjectionPage> {
  String _currentKey = '';
  bool _showChords = true;
  int _currentSection = 0;
  List<String> _sections = [];
  bool _showControls = true;
  late PageController _pageController;
  
  // Personnalisation thème
  Color _bgColor = Colors.black;
  Color _textColor = Colors.white;
  double _fontSize = 24;
  String _fontFamily = 'Roboto';
  bool _highContrast = false;

  // Chargement/sauvegarde des préférences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgColor = _colorFromString(prefs.getString('projection_bg_color') ?? 'black');
      _textColor = _colorFromString(prefs.getString('projection_text_color') ?? 'white');
      _fontSize = prefs.getDouble('projection_font_size') ?? 24;
      _fontFamily = prefs.getString('projection_font_family') ?? 'Roboto';
      _highContrast = prefs.getBool('projection_high_contrast') ?? false;
      _showChords = prefs.getBool('projection_show_chords') ?? true;
      _currentKey = prefs.getString('projection_current_key') ?? widget.song.originalKey;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('projection_bg_color', _colorToString(_bgColor));
    await prefs.setString('projection_text_color', _colorToString(_textColor));
    await prefs.setDouble('projection_font_size', _fontSize);
    await prefs.setString('projection_font_family', _fontFamily);
    await prefs.setBool('projection_high_contrast', _highContrast);
    await prefs.setBool('projection_show_chords', _showChords);
    await prefs.setString('projection_current_key', _currentKey);
  }

  String _colorToString(Color color) {
    if (color == Colors.black) return 'black';
    if (color == Colors.white) return 'white';
    if (color == Colors.yellowAccent) return 'yellow';
    return 'black';
  }

  Color _colorFromString(String colorString) {
    switch (colorString) {
      case 'white': return Colors.white;
      case 'yellow': return Colors.yellowAccent;
      default: return Colors.black;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentKey = widget.song.originalKey;
    _loadPreferences();
    _parseSections();
    _pageController = PageController(initialPage: _currentSection);
    // Masquer l'interface système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // Garder l'écran allumé
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restaurer l'interface système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _parseSections() {
    final lyrics = _currentKey == widget.song.originalKey
        ? widget.song.lyrics
        : ChordTransposer.transposeLyrics(
            widget.song.lyrics,
            widget.song.originalKey,
            _currentKey,
          );

    // Diviser les paroles en sections (séparées par des lignes vides)
    final sections = lyrics.split('\n\n');
    _sections = sections.where((section) => section.trim().isNotEmpty).toList();
    
    if (_sections.isEmpty) {
      _sections = [lyrics];
    }
  }

  void _nextSection() {
    if (_currentSection < _sections.length - 1) {
      setState(() {
        _currentSection++;
      });
      _pageController.animateToPage(_currentSection, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _previousSection() {
    if (_currentSection > 0) {
      setState(() {
        _currentSection--;
      });
      _pageController.animateToPage(_currentSection, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _transposeKey(String newKey) {
    setState(() {
      _currentKey = newKey;
    });
    _parseSections();
    _savePreferences();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx > 300) {
              _previousSection();
            } else if (details.velocity.pixelsPerSecond.dx < -300) {
              _nextSection();
            }
          },
          child: Column(
            children: [
              // Barre de contrôle en haut (visible selon _showControls)
              _buildTopControls(),
              
              // Zone de titre avec espacement approprié
              _buildTitleSection(),
              
              // Contenu principal (paroles) - prend tout l'espace disponible
              Expanded(
                child: _buildContentSection(),
              ),
              
              // Contrôles de navigation en bas
              if (_sections.length > 1 && _showControls) _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    // Si les contrôles sont masqués, on ne montre rien
    if (!_showControls) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour
          IconButton(
            icon: Icon(Icons.arrow_back, color: _textColor, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Contrôles supplémentaires
          ..._buildAdditionalControls(),
        ],
      ),
    );
  }

  List<Widget> _buildAdditionalControls() {
    return [
      // Personnalisation thème
      PopupMenuButton<String>(
        icon: Icon(Icons.color_lens, color: _textColor),
        tooltip: 'Thème',
        onSelected: (value) {
          setState(() {
            if (value == 'noir') {
              _bgColor = Colors.black;
              _textColor = Colors.white;
              _highContrast = false;
            } else if (value == 'blanc') {
              _bgColor = Colors.white;
              _textColor = Colors.black;
              _highContrast = false;
            } else if (value == 'contraste') {
              _bgColor = Colors.black;
              _textColor = Colors.yellowAccent;
              _highContrast = true;
            }
            _savePreferences();
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'noir', child: Text('Fond noir')), 
          const PopupMenuItem(value: 'blanc', child: Text('Fond blanc')), 
          const PopupMenuItem(value: 'contraste', child: Text('Contraste élevé')),
        ],
      ),
      
      // Taille de police
      PopupMenuButton<double>(
        icon: Icon(Icons.format_size, color: _textColor),
        tooltip: 'Taille du texte',
        onSelected: (value) {
          setState(() => _fontSize = value);
          _savePreferences();
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 20.0, child: Text('Petit')),
          const PopupMenuItem(value: 24.0, child: Text('Moyen')),
          const PopupMenuItem(value: 32.0, child: Text('Grand')),
          const PopupMenuItem(value: 40.0, child: Text('Très grand')),
        ],
      ),
      
      // Sélecteur de tonalité
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: DropdownButton<String>(
          value: _currentKey,
          onChanged: (newKey) {
            if (newKey != null) {
              _transposeKey(newKey);
            }
          },
          dropdownColor: _bgColor,
          underline: Container(),
          style: TextStyle(color: _textColor, fontSize: 14),
          items: SongModel.availableKeys.map((key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(key),
            );
          }).toList(),
        ),
      ),
      
      const SizedBox(width: 8),
      
      // Bouton accords
      IconButton(
        icon: Icon(
          _showChords ? Icons.music_note : Icons.music_off,
          color: _textColor,
        ),
        onPressed: () {
          setState(() {
            _showChords = !_showChords;
          });
          _savePreferences();
        },
        tooltip: _showChords ? 'Masquer accords' : 'Afficher accords',
      ),
    ];
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Titre du chant
          Text(
            widget.song.title,
            style: TextStyle(
              color: _textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: _fontFamily,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          
          // Auteur (avec espacement approprié)
          if (widget.song.authors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.song.authors,
              style: TextStyle(
                color: _textColor.withOpacity(0.7),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontFamily: _fontFamily,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _sections.length,
        onPageChanged: (i) {
          setState(() => _currentSection = i);
        },
        itemBuilder: (context, index) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: SingleChildScrollView(
              key: ValueKey(_sections[index]),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                child: Center(
                  child: _buildFormattedSection(_sections[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Indicateurs de points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_sections.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentSection
                      ? _textColor
                      : _textColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Contrôles de navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bouton précédent
              IconButton(
                icon: Icon(
                  Icons.chevron_left, 
                  color: _currentSection > 0 ? _textColor : _textColor.withOpacity(0.3),
                  size: 32,
                ),
                onPressed: _currentSection > 0 ? _previousSection : null,
              ),
              
              // Indicateur de progression textuel
              Text(
                '${_currentSection + 1} / ${_sections.length}',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Bouton suivant
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: _currentSection < _sections.length - 1 ? _textColor : _textColor.withOpacity(0.3),
                  size: 32,
                ),
                onPressed: _currentSection < _sections.length - 1 ? _nextSection : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une section formatée avec style spécial pour les chorus
  Widget _buildFormattedSection(String sectionText) {
    final lines = sectionText.split('\n');
    bool inChorusSection = false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: lines.map((line) {
          // Détecter le début d'une section chorus
          if (line.toLowerCase().contains('chorus') || line.toLowerCase().contains('refrain')) {
            inChorusSection = true;
          }
          
          // Si la ligne est vide, on sort de la section chorus
          if (line.trim().isEmpty && inChorusSection) {
            inChorusSection = false;
          }
          
          final isChorusLine = line.toLowerCase().contains('chorus') || 
                             line.toLowerCase().contains('refrain') || 
                             inChorusSection;
          
          return Container(
            margin: EdgeInsets.only(
              left: isChorusLine ? 20.0 : 0.0, // Retrait réduit pour chorus
              bottom: 8.0,
            ),
            child: Text(
              line,
              style: TextStyle(
                color: _textColor,
                fontSize: _fontSize,
                height: 1.5,
                fontFamily: _fontFamily,
                fontWeight: _highContrast ? FontWeight.bold : FontWeight.normal,
                fontStyle: isChorusLine ? FontStyle.italic : FontStyle.normal, // Italique pour chorus
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}
