import 'package:flutter/material.dart';
import '../../theme.dart';

/// Widget simple pour basculer entre les modes de lecture média
class MediaPlayerModeToggle extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;
  final String componentType; // 'video' ou 'audio'

  const MediaPlayerModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.componentType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  componentType == 'video' ? Icons.video_settings : Icons.audiotrack,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode de lecture',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mode intégré
            Container(
              decoration: BoxDecoration(
                color: currentMode == 'integrated' ? AppTheme.grey50 : AppTheme.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: currentMode == 'integrated' ? AppTheme.greenStandard : AppTheme.grey300!,
                  width: currentMode == 'integrated' ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: const Text(
                  'Lecteur intégré',
                  style: TextStyle(fontWeight: AppTheme.fontSemiBold),
                ),
                subtitle: Text(
                  componentType == 'video' 
                    ? 'Lit la vidéo directement dans l\'application'
                    : 'Lit l\'audio directement dans l\'application',
                ),
                value: 'integrated',
                groupValue: currentMode,
                onChanged: (value) => onModeChanged(value!),
                activeColor: AppTheme.greenStandard,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.grey100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: AppTheme.grey700,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Mode externe
            Container(
              decoration: BoxDecoration(
                color: currentMode == 'external' ? AppTheme.grey50 : AppTheme.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: currentMode == 'external' ? AppTheme.blueStandard : AppTheme.grey300!,
                  width: currentMode == 'external' ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: const Text(
                  'Ouverture externe',
                  style: TextStyle(fontWeight: AppTheme.fontSemiBold),
                ),
                subtitle: Text(
                  componentType == 'video' 
                    ? 'Ouvre YouTube dans l\'application native'
                    : 'Ouvre l\'audio dans l\'application appropriée',
                ),
                value: 'external',
                groupValue: currentMode,
                onChanged: (value) => onModeChanged(value!),
                activeColor: AppTheme.blueStandard,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.grey100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.open_in_new,
                    color: AppTheme.grey700,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations sur le mode sélectionné
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppTheme.grey600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getModeDescription(),
                      style: TextStyle(
                        color: AppTheme.grey700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeDescription() {
    if (currentMode == 'integrated') {
      return componentType == 'video'
        ? 'Le lecteur YouTube sera intégré directement dans votre page avec tous les contrôles natifs.'
        : 'Le lecteur audio sera intégré avec des contrôles de lecture avancés.';
    } else {
      return componentType == 'video'
        ? 'Un aperçu sera affiché avec un bouton pour ouvrir la vidéo sur YouTube.'
        : 'Un aperçu sera affiché avec un bouton pour ouvrir l\'audio dans l\'application appropriée.';
    }
  }
}