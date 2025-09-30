import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _ReadingSettingsDialogState extends State<ReadingSettingsDialog> {
  late double _fontSize;
  late bool _isDarkMode;
  late double _lineHeight;
  late String _fontFamily;
  late bool _showVerseNumbers;
  late bool _versePerLine;
  late double _paragraphSpacing;
  late bool _showNavigationButtons;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _isDarkMode = widget.isDarkMode;
    _lineHeight = widget.lineHeight;
    _fontFamily = widget.fontFamily;
    _showVerseNumbers = widget.showVerseNumbers;
    _versePerLine = widget.versePerLine;
    _paragraphSpacing = widget.paragraphSpacing;
    _showNavigationButtons = widget.showNavigationButtons;
  }

  void _applySettings() {
    widget.onSettingsChanged({
      'fontSize': _fontSize,
      'isDarkMode': _isDarkMode,
      'lineHeight': _lineHeight,
      'fontFamily': _fontFamily,
      'showVerseNumbers': _showVerseNumbers,
      'versePerLine': _versePerLine,
      'paragraphSpacing': _paragraphSpacing,
      'showNavigationButtons': _showNavigationButtons,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Poignée de glissement
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppTheme.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // En-tête
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Paramètres de lecture',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
          
          // Contenu des paramètres
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aperçu du texte
                  _buildPreviewSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Paramètres de texte
                  _buildTextSettings(),
                  
                  const SizedBox(height: 24),
                  
                  // Paramètres d'affichage
                  _buildDisplaySettings(),
                  
                  const SizedBox(height: 24),
                  
                  // Paramètres de navigation
                  _buildNavigationSettings(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.black100.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF121212) : AppTheme.grey50,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.grey300!),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.crimsonText(
                fontSize: _fontSize,
                color: _isDarkMode ? AppTheme.white100.withOpacity(0.87) : AppTheme.black100.withOpacity(0.87),
                height: _lineHeight,
                fontWeight: AppTheme.fontRegular,
              ),
              children: [
                if (_showVerseNumbers)
                  TextSpan(
                    text: '16 ',
                    style: GoogleFonts.inter(
                      fontSize: _fontSize - 2,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                const TextSpan(
                  text: 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu\'il ait la vie éternelle.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres du texte',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.black100.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 16),
        
        // Taille de police
        _buildSliderSetting(
          'Taille de police',
          _fontSize,
          12.0,
          28.0,
          '${_fontSize.toInt()}pt',
          (value) {
            setState(() {
              _fontSize = value;
            });
            _applySettings();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Hauteur de ligne
        _buildSliderSetting(
          'Espacement des lignes',
          _lineHeight,
          1.0,
          2.5,
          _lineHeight.toStringAsFixed(1),
          (value) {
            setState(() {
              _lineHeight = value;
            });
            _applySettings();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Police
        _buildFontFamilySetting(),
      ],
    );
  }

  Widget _buildDisplaySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Affichage',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.black100.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 16),
        
        // Mode sombre
        _buildSwitchSetting(
          'Mode sombre',
          'Interface sombre pour la lecture nocturne',
          Icons.dark_mode,
          _isDarkMode,
          (value) {
            setState(() {
              _isDarkMode = value;
            });
            _applySettings();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Numéros de versets
        _buildSwitchSetting(
          'Numéros de versets',
          'Afficher les numéros de versets',
          Icons.format_list_numbered,
          _showVerseNumbers,
          (value) {
            setState(() {
              _showVerseNumbers = value;
            });
            _applySettings();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Un verset par ligne
        _buildSwitchSetting(
          'Un verset par ligne',
          'Afficher chaque verset sur une ligne séparée',
          Icons.format_line_spacing,
          _versePerLine,
          (value) {
            setState(() {
              _versePerLine = value;
            });
            _applySettings();
          },
        ),
      ],
    );
  }

  Widget _buildNavigationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.black100.withOpacity(0.87),
          ),
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
          },
        ),
        
        if (_versePerLine) ...[
          const SizedBox(height: 16),
          
          // Espacement des paragraphes
          _buildSliderSetting(
            'Espacement des versets',
            _paragraphSpacing,
            8.0,
            32.0,
            '${_paragraphSpacing.toInt()}px',
            (value) {
              setState(() {
                _paragraphSpacing = value;
              });
              _applySettings();
            },
          ),
        ],
      ],
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
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.black100.withOpacity(0.87),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                displayValue,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.grey200!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
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
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.black100.withOpacity(0.87),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFontFamilySetting() {
    final fonts = [
      {'name': 'Défaut', 'value': ''},
      {'name': 'Crimson Text', 'value': 'Crimson Text'},
      {'name': 'Lora', 'value': 'Lora'},
      {'name': 'Merriweather', 'value': 'Merriweather'},
      {'name': 'Playfair Display', 'value': 'Playfair Display'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Police de caractères',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.black100.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
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
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primaryColor 
                      : AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primaryColor 
                        : AppTheme.grey300!,
                  ),
                ),
                child: Text(
                  font['name']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: AppTheme.fontMedium,
                    color: isSelected ? AppTheme.white100 : AppTheme.black100.withOpacity(0.87),
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
