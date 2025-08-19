import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/songs/models/song_model.dart';
import '../services/chord_transposer.dart';

/// Page de projection des chants en plein écran
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
  // Personnalisation thème
  Color _bgColor = Colors.black;
  Color _textColor = Colors.white;
  double _fontSize = 24;
  String _fontFamily = 'Roboto';
  bool _highContrast = false;
  bool _autoScroll = false;
  int _autoScrollSeconds = 0;

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

  Color _colorFromString(String value) {
    switch (value) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'yellow':
        return Colors.yellowAccent;
      default:
        try {
          return Color(int.parse(value));
        } catch (_) {
          return Colors.black;
        }
    }
  }

  String _colorToString(Color color) {
    if (color == Colors.black) return 'black';
    if (color == Colors.white) return 'white';
    if (color == Colors.yellowAccent) return 'yellow';
    return color.value.toString();
  }
  void _startAutoScroll() async {
    while (_autoScroll && _currentSection < _sections.length - 1) {
      await Future.delayed(Duration(seconds: _autoScrollSeconds));
      if (!_autoScroll) break;
      _nextSection();
    }
    setState(() => _autoScroll = false);
  }
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.song.originalKey;
    _loadPreferences().then((_) {
      setState(() {});
    });
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
      _parseSections();
    });
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
      body: GestureDetector(
        onTap: _toggleControls,
        onPanEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 300) {
            _previousSection();
          } else if (details.velocity.pixelsPerSecond.dx < -300) {
            _nextSection();
          }
        },
        child: Stack(
          children: [
            // Contenu principal avec transition animée
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Titre du chant
                    Text(
                      widget.song.title,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: _fontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.song.authors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.song.authors,
                        style: TextStyle(
                          color: _textColor.withOpacity(0.7),
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontFamily: _fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Section courante avec animation
                    Expanded(
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
                              child: Text(
                                _sections[index],
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: _fontSize,
                                  height: 1.5,
                                  fontFamily: _fontFamily,
                                  fontWeight: _highContrast ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_sections.length > 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_sections.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentSection
                                  ? _textColor
                                  : _textColor.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Contrôles (affichés/masqués)
            if (_showControls) ...[
              // Barre de contrôle en haut
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Bouton retour
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: _textColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
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
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 8),
                        // Police
                        PopupMenuButton<String>(
                          icon: Icon(Icons.font_download, color: _textColor),
                          tooltip: 'Police',
                          onSelected: (value) {
                            setState(() => _fontFamily = value);
                            _savePreferences();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Roboto', child: Text('Roboto')),
                            const PopupMenuItem(value: 'Arial', child: Text('Arial')),
                            const PopupMenuItem(value: 'Georgia', child: Text('Georgia')),
                            const PopupMenuItem(value: 'Courier', child: Text('Courier')),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Mode auto-scroll
                        IconButton(
                          icon: Icon(_autoScroll ? Icons.timer : Icons.timer_off, color: _textColor),
                          tooltip: 'Déroulé automatique',
                          onPressed: () async {
                            if (_autoScroll) {
                              setState(() => _autoScroll = false);
                            } else {
                              final seconds = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  int value = 5;
                                  return AlertDialog(
                                    title: const Text('Déroulé automatique'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Temps par section (secondes)'),
                                        Slider(
                                          value: value.toDouble(),
                                          min: 2,
                                          max: 30,
                                          divisions: 14,
                                          label: '$value',
                                          onChanged: (v) => value = v.round(),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                                      ElevatedButton(onPressed: () => Navigator.pop(context, value), child: const Text('Démarrer')),
                                    ],
                                  );
                                },
                              );
                              if (seconds != null) {
                                setState(() {
                                  _autoScroll = true;
                                  _autoScrollSeconds = seconds;
                                });
                                _startAutoScroll();
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Sélecteur de tonalité
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _textColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _currentKey,
                            onChanged: (newKey) {
                              if (newKey != null) {
                                _transposeKey(newKey);
                              }
                            },
                            dropdownColor: _bgColor,
                            underline: Container(),
                            style: TextStyle(color: _textColor),
                            items: SongModel.availableKeys.map((key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(key),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bouton afficher/masquer accords (non fonctionnel pour l'instant)
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Contrôles de navigation en bas
              if (_sections.length > 1)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Bouton précédent
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                            onPressed: _currentSection > 0 ? _previousSection : null,
                          ),
                          
                          // Indicateur de progression
                          Text(
                            '${_currentSection + 1} / ${_sections.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          
                          // Bouton suivant
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
                            onPressed: _currentSection < _sections.length - 1 ? _nextSection : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Instructions d'utilisation (affichées temporairement)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Touchez l\'écran pour masquer/afficher les contrôles\n'
                    'Glissez à gauche/droite pour naviguer entre les sections',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            
            // Zones de navigation invisibles (pour les gestes)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 100,
              child: GestureDetector(
                onTap: _previousSection,
                child: Container(color: Colors.transparent),
              ),
            ),
            
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 100,
              child: GestureDetector(
                onTap: _nextSection,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}