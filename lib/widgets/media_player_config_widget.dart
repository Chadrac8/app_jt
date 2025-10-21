import 'package:flutter/material.dart';
import '../../theme.dart';

/// Widget de configuration pour les lecteurs de médias
class MediaPlayerConfigWidget extends StatefulWidget {
  final String componentType; // 'video' ou 'audio'
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;
  
  const MediaPlayerConfigWidget({
    super.key,
    required this.componentType,
    required this.data,
    required this.onDataChanged,
  });
  
  @override
  State<MediaPlayerConfigWidget> createState() => _MediaPlayerConfigWidgetState();
}

class _MediaPlayerConfigWidgetState extends State<MediaPlayerConfigWidget> {
  late Map<String, dynamic> _localData;
  
  @override
  void initState() {
    super.initState();
    _localData = Map<String, dynamic>.from(widget.data);
    
    // Initialiser les valeurs par défaut
    _localData['playbackMode'] ??= 'integrated'; // 'integrated' ou 'external'
    _localData['autoPlay'] ??= false;
    _localData['autoplay'] ??= false; // Compatibilité avec l'ancien nom
    _localData['showControls'] ??= true;
    _localData['loop'] ??= false;
  }
  
  void _updateData(String key, dynamic value) {
    setState(() {
      _localData[key] = value;
      
      // Synchronisation des noms de propriétés pour la compatibilité
      if (key == 'autoPlay') {
        _localData['autoplay'] = value;
      } else if (key == 'autoplay') {
        _localData['autoPlay'] = value;
      }
    });
    widget.onDataChanged(Map<String, dynamic>.from(_localData));
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode de lecture
        _buildSectionTitle('Mode de lecture'),
        _buildPlaybackModeSelector(),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Options de lecture (seulement pour le mode intégré)
        if (_localData['playbackMode'] == 'integrated') ...[
          _buildSectionTitle('Options de lecture'),
          _buildPlaybackOptions(),
          const SizedBox(height: AppTheme.spaceMedium),
        ],
        
        // Aperçu du mode sélectionné
        _buildModePreview(),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fontSize16,
          fontWeight: AppTheme.fontSemiBold,
        ),
      ),
    );
  }
  
  Widget _buildPlaybackModeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.grey300),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          // Mode intégré
          RadioListTile<String>(
            title: const Text('Lecteur intégré'),
            subtitle: Text(
              widget.componentType == 'video' 
                ? 'Lit la vidéo directement dans l\'application'
                : 'Lit l\'audio directement dans l\'application',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
            value: 'integrated',
            groupValue: _localData['playbackMode'],
            onChanged: (value) => _updateData('playbackMode', value),
            secondary: Icon(
              widget.componentType == 'video' ? Icons.play_circle_filled : Icons.audiotrack,
              color: Theme.of(context).primaryColor,
            ),
          ),
          
          Divider(height: 1, color: AppTheme.grey300),
          
          // Mode externe
          RadioListTile<String>(
            title: const Text('Ouvrir dans l\'application externe'),
            subtitle: Text(
              widget.componentType == 'video' 
                ? 'Ouvre la vidéo dans YouTube'
                : 'Ouvre l\'audio dans SoundCloud/navigateur',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
            value: 'external',
            groupValue: _localData['playbackMode'],
            onChanged: (value) => _updateData('playbackMode', value),
            secondary: const Icon(
              Icons.open_in_new,
              color: AppTheme.grey500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaybackOptions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        children: [
          // Lecture automatique
          SwitchListTile(
            title: const Text('Lecture automatique'),
            subtitle: const Text('Démarre automatiquement la lecture'),
            value: _localData['autoPlay'] ?? false,
            onChanged: (value) => _updateData('autoPlay', value),
            contentPadding: EdgeInsets.zero,
          ),
          
          // Afficher les contrôles
          SwitchListTile(
            title: const Text('Afficher les contrôles'),
            subtitle: const Text('Affiche les boutons de contrôle'),
            value: _localData['showControls'] ?? true,
            onChanged: (value) => _updateData('showControls', value),
            contentPadding: EdgeInsets.zero,
          ),
          
          // Lecture en boucle
          SwitchListTile(
            title: const Text('Lecture en boucle'),
            subtitle: const Text('Répète automatiquement'),
            value: _localData['loop'] ?? false,
            onChanged: (value) => _updateData('loop', value),
            contentPadding: EdgeInsets.zero,
          ),
          
          // Options spécifiques selon le type
          if (widget.componentType == 'video') ...[
            SwitchListTile(
              title: const Text('Muet par défaut'),
              subtitle: const Text('Démarre sans son'),
              value: _localData['mute'] ?? false,
              onChanged: (value) => _updateData('mute', value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          
          if (widget.componentType == 'audio' && 
              (_localData['source_type'] ?? 'direct') == 'soundcloud') ...[
            SwitchListTile(
              title: const Text('Afficher les commentaires'),
              subtitle: const Text('Affiche les commentaires SoundCloud'),
              value: _localData['showComments'] ?? true,
              onChanged: (value) => _updateData('showComments', value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildModePreview() {
    final isIntegrated = _localData['playbackMode'] == 'integrated';
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: isIntegrated ? AppTheme.grey50 : AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: isIntegrated ? AppTheme.grey200 : AppTheme.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIntegrated ? Icons.check_circle : Icons.open_in_new,
                color: isIntegrated ? AppTheme.grey600 : AppTheme.grey600,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                isIntegrated ? 'Mode intégré sélectionné' : 'Mode externe sélectionné',
                style: TextStyle(
                  fontWeight: AppTheme.fontSemiBold,
                  color: isIntegrated ? AppTheme.grey700 : AppTheme.grey700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            isIntegrated 
              ? _getIntegratedDescription()
              : _getExternalDescription(),
            style: TextStyle(
              fontSize: AppTheme.fontSize12,
              color: isIntegrated ? AppTheme.grey600 : AppTheme.grey600,
            ),
          ),
          
          // Avantages/inconvénients
          const SizedBox(height: AppTheme.spaceSmall),
          _buildProsCons(isIntegrated),
        ],
      ),
    );
  }
  
  String _getIntegratedDescription() {
    if (widget.componentType == 'video') {
      return 'La vidéo sera lue directement dans l\'application avec un lecteur YouTube intégré. '
             'Les utilisateurs pourront contrôler la lecture sans quitter l\'application.';
    } else {
      final sourceType = _localData['source_type'] ?? 'direct';
      if (sourceType == 'soundcloud') {
        return 'L\'audio SoundCloud sera lu via un lecteur intégré. '
               'Les utilisateurs pourront écouter sans quitter l\'application.';
      } else {
        return 'Le fichier audio sera lu avec un lecteur natif intégré. '
               'Contrôles complets disponibles dans l\'application.';
      }
    }
  }
  
  String _getExternalDescription() {
    if (widget.componentType == 'video') {
      return 'La vidéo s\'ouvrira dans l\'application YouTube ou le navigateur. '
             'Les utilisateurs quitteront temporairement votre application.';
    } else {
      final sourceType = _localData['source_type'] ?? 'direct';
      if (sourceType == 'soundcloud') {
        return 'L\'audio s\'ouvrira dans l\'application SoundCloud ou le navigateur. '
               'Accès à toutes les fonctionnalités SoundCloud.';
      } else {
        return 'Le fichier audio s\'ouvrira dans le lecteur par défaut du système. '
               'Utilise les applications préférées de l\'utilisateur.';
      }
    }
  }
  
  Widget _buildProsCons(bool isIntegrated) {
    final pros = isIntegrated ? _getIntegratedPros() : _getExternalPros();
    final cons = isIntegrated ? _getIntegratedCons() : _getExternalCons();
    
    return Column(
      children: [
        // Avantages
        _buildProsConsSection('Avantages', pros, AppTheme.greenStandard, Icons.check),
        const SizedBox(height: AppTheme.spaceSmall),
        // Inconvénients
        _buildProsConsSection('Inconvénients', cons, AppTheme.redStandard, Icons.close),
      ],
    );
  }
  
  Widget _buildProsConsSection(String title, List<String> items, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.fontSize12,
            fontWeight: AppTheme.fontSemiBold,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 12, color: color.withOpacity(0.8)),
              const SizedBox(width: AppTheme.spaceXSmall),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize11,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  List<String> _getIntegratedPros() {
    return [
      'Expérience fluide sans quitter l\'app',
      'Contrôles personnalisés disponibles',
      'Intégration native avec votre interface',
      'Pas de redirection externe',
    ];
  }
  
  List<String> _getIntegratedCons() {
    return [
      'Fonctionnalités limitées vs app native',
      'Consommation de ressources plus élevée',
      'Possible problème de compatibilité',
    ];
  }
  
  List<String> _getExternalPros() {
    return [
      'Accès à toutes les fonctionnalités natives',
      'Performance optimale',
      'Fiabilité garantie',
      'Familiarité pour l\'utilisateur',
    ];
  }
  
  List<String> _getExternalCons() {
    return [
      'Utilisateur quitte votre application',
      'Expérience moins fluide',
      'Retour à l\'app pas garanti',
    ];
  }
}