import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../modules/songs/models/song_model.dart';
import '../services/chord_transposer.dart';
import '../../theme.dart';

/// Page de projection des chants en plein écran - Version Material Design 3
class SongProjectionPage extends StatefulWidget {
  final SongModel song;

  const SongProjectionPage({
    super.key,
    required this.song,
  });

  @override
  State<SongProjectionPage> createState() => _SongProjectionPageState();
}

class _SongProjectionPageState extends State<SongProjectionPage>
    with TickerProviderStateMixin {
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
  String _fontFamily = 'Inter';
  bool _highContrast = false;

  // Animation controllers pour les transitions Material Design 3
  late AnimationController _controlsAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _controlsFadeAnimation;
  late Animation<Offset> _controlsSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.song.originalKey;
    _loadPreferences();
    _parseSections();
    _pageController = PageController(initialPage: _currentSection);
    
    // Initialiser les contrôleurs d'animation
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _controlsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    _controlsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Démarrer les animations
    _controlsAnimationController.forward();
    _contentAnimationController.forward();
    
    // Masquer l'interface système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlsAnimationController.dispose();
    _contentAnimationController.dispose();
    
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

  // Chargement/sauvegarde des préférences avec Material Design 3 colors
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgColor = _colorFromString(prefs.getString('projection_bg_color') ?? 'black');
      _textColor = _colorFromString(prefs.getString('projection_text_color') ?? 'white');
      _fontSize = prefs.getDouble('projection_font_size') ?? 24;
      _fontFamily = prefs.getString('projection_font_family') ?? 'Inter';
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
    if (color == Theme.of(context).colorScheme.surface) return 'surface';
    if (color == Theme.of(context).colorScheme.inverseSurface) return 'inverseSurface';
    return 'black';
  }

  Color _colorFromString(String colorString) {
    switch (colorString) {
      case 'white': return Colors.white;
      case 'surface': return Theme.of(context).colorScheme.surface;
      case 'inverseSurface': return Theme.of(context).colorScheme.inverseSurface;
      default: return Colors.black;
    }
  }

  void _parseSections() {
    final lyrics = _currentKey == widget.song.originalKey
        ? widget.song.lyrics
        : ChordTransposer.transposeLyrics(
            widget.song.lyrics,
            widget.song.originalKey,
            _currentKey,
          );

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
      _pageController.animateToPage(
        _currentSection, 
        duration: const Duration(milliseconds: 400), 
        curve: Curves.easeInOutCubic
      );
    }
  }

  void _previousSection() {
    if (_currentSection > 0) {
      setState(() {
        _currentSection--;
      });
      _pageController.animateToPage(
        _currentSection, 
        duration: const Duration(milliseconds: 400), 
        curve: Curves.easeInOutCubic
      );
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
    
    if (_showControls) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Theme(
      // Créer un thème personnalisé pour la projection avec les couleurs choisies
      data: Theme.of(context).copyWith(
        colorScheme: colorScheme.copyWith(
          surface: _bgColor,
          onSurface: _textColor,
          primary: _textColor,
          onPrimary: _bgColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: GestureDetector(
            onTap: _toggleControls,
            onPanEnd: (details) {
              // Gestes de navigation avec haptic feedback
              if (details.velocity.pixelsPerSecond.dx > 300) {
                HapticFeedback.selectionClick();
                _previousSection();
              } else if (details.velocity.pixelsPerSecond.dx < -300) {
                HapticFeedback.selectionClick();
                _nextSection();
              }
            },
            child: Column(
              children: [
                // Contrôles en haut avec animation Material Design 3
                _buildTopControls(colorScheme),
                
                // Zone de titre
                _buildTitleSection(),
                
                // Contenu principal avec fade animation
                Expanded(
                  child: FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: _buildContentSection(),
                  ),
                ),
                
                // Contrôles de navigation en bas
                if (_sections.length > 1) _buildBottomControls(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(ColorScheme colorScheme) {
    if (!_showControls) {
      return const SizedBox.shrink();
    }
    
    return SlideTransition(
      position: _controlsSlideAnimation,
      child: FadeTransition(
        opacity: _controlsFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium, vertical: AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: _bgColor.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bouton retour Material Design 3
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceSmall),
                    child: Icon(
                      Icons.arrow_back,
                      color: _textColor,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ..._buildAdditionalControls(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAdditionalControls(ColorScheme colorScheme) {
    return [
      // Menu thème avec Material Design 3
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: PopupMenuButton<String>(
          icon: Icon(Icons.palette_outlined, color: _textColor, size: 24),
          tooltip: 'Thème de projection',
          onSelected: (value) {
            setState(() {
              switch (value) {
                case 'dark':
                  _bgColor = Colors.black;
                  _textColor = Colors.white;
                  _highContrast = false;
                  break;
                case 'light':
                  _bgColor = Colors.white;
                  _textColor = Colors.black;
                  _highContrast = false;
                  break;
                case 'surface':
                  _bgColor = colorScheme.surface;
                  _textColor = colorScheme.onSurface;
                  _highContrast = false;
                  break;
                case 'contrast':
                  _bgColor = Colors.black;
                  _textColor = Colors.yellowAccent;
                  _highContrast = true;
                  break;
              }
              _savePreferences();
            });
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'dark',
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text('Sombre', style: GoogleFonts.inter()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'light',
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text('Clair', style: GoogleFonts.inter()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'surface',
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outline),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text('Surface', style: GoogleFonts.inter()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'contrast',
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Text('Contraste élevé', style: GoogleFonts.inter()),
                ],
              ),
            ),
          ],
        ),
      ),
      
      const SizedBox(width: AppTheme.spaceSmall),
      
      // Sélecteur de taille de police
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: PopupMenuButton<double>(
          icon: Icon(Icons.format_size, color: _textColor, size: 24),
          tooltip: 'Taille du texte',
          onSelected: (value) {
            setState(() => _fontSize = value);
            _savePreferences();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 20.0,
              child: Text('Petit (20pt)', style: GoogleFonts.inter(fontSize: 14)),
            ),
            PopupMenuItem(
              value: 24.0,
              child: Text('Moyen (24pt)', style: GoogleFonts.inter(fontSize: 16)),
            ),
            PopupMenuItem(
              value: 32.0,
              child: Text('Grand (32pt)', style: GoogleFonts.inter(fontSize: 18)),
            ),
            PopupMenuItem(
              value: 40.0,
              child: Text('Très grand (40pt)', style: GoogleFonts.inter(fontSize: 20)),
            ),
          ],
        ),
      ),
      
      const SizedBox(width: AppTheme.spaceSmall),
      
      // Sélecteur de tonalité avec style MD3
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: DropdownButton<String>(
          value: _currentKey,
          onChanged: (newKey) {
            if (newKey != null) {
              HapticFeedback.selectionClick();
              _transposeKey(newKey);
            }
          },
          dropdownColor: colorScheme.surfaceContainerHighest,
          underline: Container(),
          style: GoogleFonts.inter(
            color: _textColor,
            fontSize: 14,
            fontWeight: AppTheme.fontMedium,
          ),
          items: SongModel.availableKeys.map((key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(
                key,
                style: GoogleFonts.inter(
                  color: _textColor,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      
      const SizedBox(width: AppTheme.spaceSmall),
      
      // Bouton accords avec Material Design 3
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _showChords = !_showChords;
            });
            _savePreferences();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            child: Icon(
              _showChords ? Icons.music_note : Icons.music_off,
              color: _textColor,
              size: 24,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLarge,
        vertical: AppTheme.spaceMedium,
      ),
      child: Column(
        children: [
          // Titre du chant avec Google Fonts
          Text(
            widget.song.title,
            style: GoogleFonts.inter(
              color: _textColor,
              fontSize: 28,
              fontWeight: AppTheme.fontSemiBold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          
          // Auteur
          if (widget.song.authors.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              widget.song.authors,
              style: GoogleFonts.inter(
                color: _textColor.withOpacity(0.7),
                fontSize: 16,
                fontWeight: AppTheme.fontRegular,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.1,
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
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
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
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

  Widget _buildBottomControls(ColorScheme colorScheme) {
    if (!_showControls) return const SizedBox.shrink();
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _controlsFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          decoration: BoxDecoration(
            color: _bgColor.withOpacity(0.95),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Indicateurs de progression Material Design 3
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_sections.length, (index) {
                  final isActive = index == _currentSection;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive 
                          ? _textColor 
                          : _textColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: AppTheme.spaceSmall),
              
              // Contrôles de navigation avec Material Design 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton précédent
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      onTap: _currentSection > 0 ? () {
                        HapticFeedback.selectionClick();
                        _previousSection();
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        child: Icon(
                          Icons.chevron_left,
                          color: _currentSection > 0 
                              ? _textColor 
                              : _textColor.withOpacity(0.3),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  
                  // Indicateur de progression textuel
                  Text(
                    '${_currentSection + 1} / ${_sections.length}',
                    style: GoogleFonts.inter(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: AppTheme.fontMedium,
                      letterSpacing: 0.1,
                    ),
                  ),
                  
                  // Bouton suivant
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      onTap: _currentSection < _sections.length - 1 ? () {
                        HapticFeedback.selectionClick();
                        _nextSection();
                      } : null,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        child: Icon(
                          Icons.chevron_right,
                          color: _currentSection < _sections.length - 1 
                              ? _textColor 
                              : _textColor.withOpacity(0.3),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedSection(String sectionText) {
    final lines = sectionText.split('\n');
    bool inChorusSection = false;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: Column(
        children: lines.map((line) {
          // Détecter le début d'une section chorus
          if (line.toLowerCase().contains('chorus') || 
              line.toLowerCase().contains('refrain')) {
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
              left: isChorusLine ? 20.0 : 0.0,
              bottom: AppTheme.spaceSmall,
            ),
            child: Text(
              line,
              style: GoogleFonts.inter(
                color: _textColor,
                fontSize: _fontSize,
                height: 1.5,
                fontWeight: _highContrast 
                    ? AppTheme.fontSemiBold 
                    : AppTheme.fontRegular,
                fontStyle: isChorusLine ? FontStyle.italic : FontStyle.normal,
                letterSpacing: 0.1,
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