import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reading_preferences_provider.dart';
import '../services/reading_preferences_service.dart';

/// Widget de panneau de paramètres de lecture
class ReadingSettingsPanel extends StatelessWidget {
  const ReadingSettingsPanel({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingPreferencesProvider>(
      builder: (context, prefsProvider, _) {
        final prefs = prefsProvider.preferences;
        
        return Container(
          decoration: BoxDecoration(
            color: prefs.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: prefs.secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Titre
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: prefs.textColor),
                      const SizedBox(width: 12),
                      Text(
                        'Paramètres de lecture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: prefs.textColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.refresh, color: prefs.textColor),
                        onPressed: () async {
                          await prefsProvider.reset();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Paramètres réinitialisés'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        tooltip: 'Réinitialiser',
                      ),
                    ],
                  ),
                ),
                
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mode sombre
                        _buildSwitchTile(
                          context,
                          title: 'Mode lecture nocturne',
                          subtitle: 'Réduit la fatigue oculaire',
                          icon: prefs.darkMode ? Icons.dark_mode : Icons.light_mode,
                          value: prefs.darkMode,
                          onChanged: (value) => prefsProvider.setDarkMode(value),
                        ),
                        
                        const Divider(height: 32),
                        
                        // Taille de police
                        _buildSliderSection(
                          context,
                          title: 'Taille de police',
                          icon: Icons.format_size,
                          value: prefs.fontSize,
                          min: 14.0,
                          max: 32.0,
                          divisions: 9,
                          label: '${prefs.fontSize.toInt()}',
                          onChanged: (value) => prefsProvider.setFontSize(value),
                          quickActions: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => prefsProvider.decreaseFontSize(),
                                tooltip: 'Diminuer',
                              ),
                              Text(
                                '${prefs.fontSize.toInt()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: prefs.textColor,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => prefsProvider.increaseFontSize(),
                                tooltip: 'Augmenter',
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Hauteur de ligne
                        _buildSliderSection(
                          context,
                          title: 'Espacement des lignes',
                          icon: Icons.format_line_spacing,
                          value: prefs.lineHeight,
                          min: 1.0,
                          max: 2.0,
                          divisions: 10,
                          label: prefs.lineHeight.toStringAsFixed(1),
                          onChanged: (value) => prefsProvider.setLineHeight(value),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Luminosité
                        _buildSliderSection(
                          context,
                          title: 'Luminosité',
                          icon: Icons.brightness_6,
                          value: prefs.brightness,
                          min: 0.3,
                          max: 1.0,
                          divisions: 7,
                          label: '${(prefs.brightness * 100).toInt()}%',
                          onChanged: (value) => prefsProvider.setBrightness(value),
                        ),
                        
                        const Divider(height: 32),
                        
                        // Police de caractères
                        _buildFontFamilySelector(context, prefs, prefsProvider),
                        
                        const SizedBox(height: 16),
                        
                        // Aperçu
                        _buildPreview(context, prefs),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Consumer<ReadingPreferencesProvider>(
      builder: (context, prefsProvider, _) {
        final prefs = prefsProvider.preferences;
        
        return SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: prefs.textColor,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: prefs.secondaryTextColor),
          ),
          secondary: Icon(icon, color: prefs.textColor),
          value: value,
          onChanged: onChanged,
        );
      },
    );
  }
  
  Widget _buildSliderSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
    Widget? quickActions,
  }) {
    return Consumer<ReadingPreferencesProvider>(
      builder: (context, prefsProvider, _) {
        final prefs = prefsProvider.preferences;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: prefs.textColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: prefs.textColor,
                  ),
                ),
                const Spacer(),
                if (quickActions != null) quickActions,
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildFontFamilySelector(
    BuildContext context,
    ReadingPreferences prefs,
    ReadingPreferencesProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.font_download, color: prefs.textColor, size: 20),
            const SizedBox(width: 12),
            Text(
              'Police de caractères',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: prefs.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FontFamilies.available.map((fontName) {
            final isSelected = prefs.fontFamily == fontName;
            
            return ChoiceChip(
              label: Text(fontName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  provider.setFontFamily(fontName);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildPreview(BuildContext context, ReadingPreferences prefs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: prefs.backgroundColor,
        border: Border.all(
          color: prefs.secondaryTextColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: prefs.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Exemple de titre de sermon',
            style: prefs.titleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Ceci est un exemple de texte de sermon pour visualiser vos paramètres de lecture. Les paramètres que vous ajustez ci-dessus seront appliqués lors de la lecture des sermons.',
            style: prefs.contentTextStyle,
          ),
        ],
      ),
    );
  }
}

/// Bouton flottant pour ouvrir les paramètres de lecture
class ReadingSettingsButton extends StatelessWidget {
  const ReadingSettingsButton({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingPreferencesProvider>(
      builder: (context, prefsProvider, _) {
        final prefs = prefsProvider.preferences;
        
        return FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) => const ReadingSettingsPanel(),
              ),
            );
          },
          backgroundColor: prefs.backgroundColor,
          child: Icon(
            Icons.text_fields,
            color: prefs.textColor,
          ),
        );
      },
    );
  }
}
