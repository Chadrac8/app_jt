import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../theme.dart';

class ReadingSettingsDialog extends StatefulWidget {
  final double fontSize;
  final bool isDarkMode;
  final double lineHeight;
  final String fontFamily;
  final bool showVerseNumbers;
  final bool versePerLine;
  final double paragraphSpacing;
  final bool showNavigationButtons;
  final Function(Map<String, dynamic> settings) onSettingsChanged;

  const ReadingSettingsDialog({
    Key? key,
    required this.fontSize,
    required this.isDarkMode,
    required this.lineHeight,
    required this.fontFamily,
    required this.showVerseNumbers,
    required this.versePerLine,
    required this.paragraphSpacing,
    required this.showNavigationButtons,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<ReadingSettingsDialog> createState() => _ReadingSettingsDialogState();
}

class _ReadingSettingsDialogState extends State<ReadingSettingsDialog> with TickerProviderStateMixin {
  late double _fontSize;
  late bool _isDarkMode;
  late double _lineHeight;
  late String _fontFamily;
  late bool _showVerseNumbers;
  late bool _versePerLine;
  late double _paragraphSpacing;
  late bool _showNavigationButtons;
  
  // Nouvelles fonctionnalités avancées
  String _selectedTheme = 'default';
  bool _autoScroll = false;
  double _autoScrollSpeed = 1.0;
  bool _immersiveMode = false;
  bool _showChapterProgress = true;
  String _defaultTranslation = 'LSG';
  bool _hapticFeedback = true;
  bool _keepScreenOn = false;
  double _marginSize = 16.0;
  
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _colorThemes = [
    {
      'name': 'Défaut',
      'value': 'default',
      'bgColor': Colors.white,
      'textColor': Colors.black87,
      'accentColor': AppTheme.primaryColor,
      'description': 'Thème clair standard'
    },
    {
      'name': 'Sombre',
      'value': 'dark',
      'bgColor': const Color(0xFF121212),
      'textColor': Colors.white70,
      'accentColor': Colors.amber,
      'description': 'Mode nuit classique'
    },
    {
      'name': 'Sépia',
      'value': 'sepia',
      'bgColor': const Color(0xFFF4F1E8),
      'textColor': const Color(0xFF5D4037),
      'accentColor': const Color(0xFF8D6E63),
      'description': 'Lecture vintage douce'
    },
    {
      'name': 'Nuit bleue',
      'value': 'blue_night',
      'bgColor': const Color(0xFF0D1421),
      'textColor': const Color(0xFFB3E5FC),
      'accentColor': const Color(0xFF64B5F6),
      'description': 'Mode nuit moins agressif'
    },
    {
      'name': 'Contraste élevé',
      'value': 'high_contrast',
      'bgColor': Colors.black,
      'textColor': Colors.white,
      'accentColor': Colors.yellow,
      'description': 'Accessibilité maximale'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fontSize = widget.fontSize;
    _isDarkMode = widget.isDarkMode;
    _lineHeight = widget.lineHeight;
    _fontFamily = widget.fontFamily;
    _showVerseNumbers = widget.showVerseNumbers;
    _versePerLine = widget.versePerLine;
    _paragraphSpacing = widget.paragraphSpacing;
    _showNavigationButtons = widget.showNavigationButtons;
    _loadAdvancedSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvancedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('bible_theme') ?? 'default';
      _autoScroll = prefs.getBool('bible_auto_scroll') ?? false;
      _autoScrollSpeed = prefs.getDouble('bible_auto_scroll_speed') ?? 1.0;
      _immersiveMode = prefs.getBool('bible_immersive_mode') ?? false;
      _showChapterProgress = prefs.getBool('bible_show_chapter_progress') ?? true;
      _defaultTranslation = prefs.getString('bible_default_translation') ?? 'LSG';
      _hapticFeedback = prefs.getBool('bible_haptic_feedback') ?? true;
      _keepScreenOn = prefs.getBool('bible_keep_screen_on') ?? false;
      _marginSize = prefs.getDouble('bible_margin_size') ?? 16.0;
    });
  }

  Future<void> _saveAdvancedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bible_theme', _selectedTheme);
    await prefs.setBool('bible_auto_scroll', _autoScroll);
    await prefs.setDouble('bible_auto_scroll_speed', _autoScrollSpeed);
    await prefs.setBool('bible_immersive_mode', _immersiveMode);
    await prefs.setBool('bible_show_chapter_progress', _showChapterProgress);
    await prefs.setString('bible_default_translation', _defaultTranslation);
    await prefs.setBool('bible_haptic_feedback', _hapticFeedback);
    await prefs.setBool('bible_keep_screen_on', _keepScreenOn);
    await prefs.setDouble('bible_margin_size', _marginSize);
  }

  void _applySettings() {
    final settings = {
      'fontSize': _fontSize,
      'isDarkMode': _isDarkMode,
      'lineHeight': _lineHeight,
      'fontFamily': _fontFamily,
      'showVerseNumbers': _showVerseNumbers,
      'versePerLine': _versePerLine,
      'paragraphSpacing': _paragraphSpacing,
      'showNavigationButtons': _showNavigationButtons,
      // Nouveaux paramètres
      'selectedTheme': _selectedTheme,
      'autoScroll': _autoScroll,
      'autoScrollSpeed': _autoScrollSpeed,
      'immersiveMode': _immersiveMode,
      'showChapterProgress': _showChapterProgress,
      'defaultTranslation': _defaultTranslation,
      'hapticFeedback': _hapticFeedback,
      'keepScreenOn': _keepScreenOn,
      'marginSize': _marginSize,
    };
    
    widget.onSettingsChanged(settings);
    _saveAdvancedSettings();
  }

  void _triggerHaptic() {
    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header avec titre et actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Paramètres de lecture',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showPresetsDialog,
                  icon: const Icon(Icons.bookmark_border),
                  tooltip: 'Préréglages',
                ),
                IconButton(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Réinitialiser',
                ),
              ],
            ),
          ),
          
          // Aperçu du texte
          _buildCompactPreview(),
          
          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.text_fields), text: 'Texte'),
              Tab(icon: Icon(Icons.visibility), text: 'Affichage'),
              Tab(icon: Icon(Icons.palette), text: 'Thème'),
              Tab(icon: Icon(Icons.settings), text: 'Avancé'),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextSettingsTab(),
                _buildDisplaySettingsTab(),
                _buildThemeSettingsTab(),
                _buildAdvancedSettingsTab(),
              ],
            ),
          ),
          
          // Footer avec boutons d'action
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCompactPreview() {
    final colorScheme = Theme.of(context).colorScheme;
    final currentTheme = _colorThemes.firstWhere(
      (theme) => theme['value'] == _selectedTheme,
      orElse: () => _colorThemes.first,
    );
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme['bgColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 16,
                color: currentTheme['textColor'],
              ),
              const SizedBox(width: 8),
              Text(
                'Aperçu - Jean 3:16',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: currentTheme['textColor'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: _buildPreviewTextStyle(currentTheme),
              children: [
                if (_showVerseNumbers)
                  TextSpan(
                    text: '16 ',
                    style: GoogleFonts.inter(
                      fontSize: _fontSize * 0.8,
                      fontWeight: FontWeight.bold,
                      color: currentTheme['accentColor'],
                    ),
                  ),
                const TextSpan(
                  text: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _buildPreviewTextStyle(Map<String, dynamic> theme) {
    return GoogleFonts.getFont(
      _fontFamily.isEmpty ? 'Crimson Text' : _fontFamily,
      fontSize: _fontSize * 0.9,
      color: theme['textColor'],
      height: _lineHeight,
      fontWeight: FontWeight.w400,
    );
  }

  Widget _buildTextSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Typographie', Icons.text_fields),
          const SizedBox(height: 16),
          
          // Taille de police
          _buildSliderSetting(
            'Taille de police',
            _fontSize,
            12.0,
            32.0,
            '${_fontSize.toStringAsFixed(0)}pt',
            (value) {
              setState(() {
                _fontSize = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Hauteur de ligne
          _buildSliderSetting(
            'Interligne',
            _lineHeight,
            1.0,
            2.5,
            '${_lineHeight.toStringAsFixed(1)}x',
            (value) {
              setState(() {
                _lineHeight = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Espacement des paragraphes
          if (_versePerLine)
            _buildSliderSetting(
              'Espacement des versets',
              _paragraphSpacing,
              8.0,
              40.0,
              '${_paragraphSpacing.toStringAsFixed(0)}px',
              (value) {
                setState(() {
                  _paragraphSpacing = value;
                });
                _applySettings();
                _triggerHaptic();
              },
            ),
          
          if (_versePerLine) const SizedBox(height: 20),
          
          // Marges
          _buildSliderSetting(
            'Marges horizontales',
            _marginSize,
            8.0,
            32.0,
            '${_marginSize.toStringAsFixed(0)}px',
            (value) {
              setState(() {
                _marginSize = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Police de caractères
          _buildFontFamilySetting(),
        ],
      ),
    );
  }

  Widget _buildDisplaySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Affichage du contenu', Icons.visibility),
          const SizedBox(height: 16),
          
          // Numéros de versets
          _buildSwitchSetting(
            'Numéros de versets',
            'Afficher les numéros devant chaque verset',
            Icons.format_list_numbered,
            _showVerseNumbers,
            (value) {
              setState(() {
                _showVerseNumbers = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Un verset par ligne
          _buildSwitchSetting(
            'Un verset par ligne',
            'Séparer chaque verset sur sa propre ligne',
            Icons.format_line_spacing,
            _versePerLine,
            (value) {
              setState(() {
                _versePerLine = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Boutons de navigation
          _buildSwitchSetting(
            'Boutons de navigation',
            'Afficher les boutons précédent/suivant',
            Icons.navigation,
            _showNavigationButtons,
            (value) {
              setState(() {
                _showNavigationButtons = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Barre de progression du chapitre
          _buildSwitchSetting(
            'Progression du chapitre',
            'Afficher la barre de progression de lecture',
            Icons.linear_scale,
            _showChapterProgress,
            (value) {
              setState(() {
                _showChapterProgress = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Mode immersif
          _buildSwitchSetting(
            'Mode immersif',
            'Masquer les éléments de l\'interface pendant la lecture',
            Icons.fullscreen,
            _immersiveMode,
            (value) {
              setState(() {
                _immersiveMode = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Thèmes visuels', Icons.palette),
          const SizedBox(height: 16),
          
          Text(
            'Choisissez un thème adapté à votre environnement de lecture',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Grille des thèmes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _colorThemes.length,
            itemBuilder: (context, index) {
              final theme = _colorThemes[index];
              final isSelected = _selectedTheme == theme['value'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTheme = theme['value'];
                    _isDarkMode = theme['value'] == 'dark' || 
                                 theme['value'] == 'blue_night' || 
                                 theme['value'] == 'high_contrast';
                  });
                  _applySettings();
                  _triggerHaptic();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: theme['bgColor'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: theme['accentColor'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    theme['name'],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme['textColor'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                'Exemple de texte biblique dans ce thème',
                                style: GoogleFonts.crimsonText(
                                  fontSize: 12,
                                  color: theme['textColor'],
                                  height: 1.3,
                                ),
                              ),
                            ),
                            Text(
                              theme['description'],
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: (theme['textColor'] as Color).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Fonctionnalités avancées', Icons.settings),
          const SizedBox(height: 16),
          
          // Auto-scroll
          _buildSwitchSetting(
            'Défilement automatique',
            'Faire défiler le texte automatiquement',
            Icons.play_arrow,
            _autoScroll,
            (value) {
              setState(() {
                _autoScroll = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          if (_autoScroll) ...[
            const SizedBox(height: 16),
            _buildSliderSetting(
              'Vitesse de défilement',
              _autoScrollSpeed,
              0.5,
              3.0,
              '${_autoScrollSpeed.toStringAsFixed(1)}x',
              (value) {
                setState(() {
                  _autoScrollSpeed = value;
                });
                _applySettings();
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Retour haptique
          _buildSwitchSetting(
            'Retour haptique',
            'Vibrations lors des interactions',
            Icons.vibration,
            _hapticFeedback,
            (value) {
              setState(() {
                _hapticFeedback = value;
              });
              _applySettings();
            },
          ),
          
          const SizedBox(height: 16),
          
          // Garder l'écran allumé
          _buildSwitchSetting(
            'Écran toujours allumé',
            'Empêcher la mise en veille pendant la lecture',
            Icons.screen_lock_portrait,
            _keepScreenOn,
            (value) {
              setState(() {
                _keepScreenOn = value;
              });
              _applySettings();
              _triggerHaptic();
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Version par défaut', Icons.book),
          const SizedBox(height: 16),
          
          // Sélecteur de version de Bible
          _buildTranslationSelector(),
          
          const SizedBox(height: 24),
          
          _buildSectionHeader('Gestion des données', Icons.storage),
          const SizedBox(height: 16),
          
          // Boutons d'export/import
          _buildDataManagementButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationSelector() {
    final translations = [
      {'name': 'Louis Segond 1910', 'value': 'LSG'},
      {'name': 'Nouvelle Edition de Genève', 'value': 'NEG'},
      {'name': 'Bible du Semeur', 'value': 'BDS'},
      {'name': 'Traduction Œcuménique', 'value': 'TOB'},
      {'name': 'Nouvelle Bible Segond', 'value': 'NBS'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version préférée pour l\'ouverture',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...translations.map((translation) {
            final isSelected = _defaultTranslation == translation['value'];
            return RadioListTile<String>(
              value: translation['value']!,
              groupValue: _defaultTranslation,
              onChanged: (value) {
                setState(() {
                  _defaultTranslation = value!;
                });
                _applySettings();
                _triggerHaptic();
              },
              title: Text(
                translation['name']!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDataManagementButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportSettings,
                icon: const Icon(Icons.file_upload),
                label: const Text('Exporter'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importSettings,
                icon: const Icon(Icons.file_download),
                label: const Text('Importer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Restaurer les paramètres par défaut'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                _applySettings();
                Navigator.pop(context);
                _triggerHaptic();
              },
              icon: const Icon(Icons.check),
              label: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes d'actions
  void _showPresetsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Préréglages'),
        content: const Text('Fonctionnalité à venir : Sauvegarder et charger des configurations prédéfinies.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text('Voulez-vous vraiment restaurer tous les paramètres par défaut ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _fontSize = 16.0;
                _isDarkMode = false;
                _lineHeight = 1.5;
                _fontFamily = '';
                _showVerseNumbers = true;
                _versePerLine = false;
                _paragraphSpacing = 16.0;
                _showNavigationButtons = true;
                _selectedTheme = 'default';
                _autoScroll = false;
                _autoScrollSpeed = 1.0;
                _immersiveMode = false;
                _showChapterProgress = true;
                _defaultTranslation = 'LSG';
                _hapticFeedback = true;
                _keepScreenOn = false;
                _marginSize = 16.0;
              });
              _applySettings();
              Navigator.pop(context);
              _triggerHaptic();
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    // TODO: Implémenter l'export des paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export des paramètres - Fonctionnalité à venir')),
    );
  }

  void _importSettings() {
    // TODO: Implémenter l'import des paramètres
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import des paramètres - Fonctionnalité à venir')),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    String displayValue,
    Function(double) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFontFamilySetting() {
    final colorScheme = Theme.of(context).colorScheme;
    final fonts = [
      {'name': 'Défaut', 'value': ''},
      {'name': 'Crimson Text', 'value': 'Crimson Text'},
      {'name': 'Lora', 'value': 'Lora'},
      {'name': 'Merriweather', 'value': 'Merriweather'},
      {'name': 'Playfair Display', 'value': 'Playfair Display'},
      {'name': 'Source Serif Pro', 'value': 'Source Serif Pro'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Police de caractères',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fonts.map((font) {
            final isSelected = _fontFamily == font['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _fontFamily = font['value']!;
                });
                _applySettings();
                _triggerHaptic();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  font['name']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
