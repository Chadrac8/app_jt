import 'package:flutter/material.dart';
import '../../models/page_model.dart';
import '../../models/image_action_model.dart';
import '../../models/component_action_model.dart';
import '../../services/image_action_service.dart';
import '../../services/component_action_service.dart';
import '../../services/youtube_service.dart';
import '../../services/soundcloud_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme.dart';
import '../grid_container_builder.dart';
import '../image_picker_widget.dart';
import '../youtube_picker_widget.dart';
import '../soundcloud_picker_widget.dart';
import '../media_player_config_widget.dart';
import '../component_action_editor.dart';
import '../tab_page_builder.dart';

class ComponentEditor extends StatefulWidget {
  final PageComponent component;
  final Function(PageComponent) onSave;

  const ComponentEditor({
    super.key,
    required this.component,
    required this.onSave,
  });

  @override
  State<ComponentEditor> createState() => _ComponentEditorState();
}

class _ComponentEditorState extends State<ComponentEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  late Map<String, dynamic> _data;
  late Map<String, dynamic> _styling;
  late Map<String, dynamic> _settings;
  ComponentAction? _currentAction;
  late List<PageComponent> _children;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.component.name;
    _data = Map.from(widget.component.data);
    _styling = Map.from(widget.component.styling);
    _settings = Map.from(widget.component.settings);
    _currentAction = widget.component.action;
    _children = List<PageComponent>.from(widget.component.children);
    
    // Initialiser les paramètres de lecteur média par défaut
    if (widget.component.type == 'video' || widget.component.type == 'audio') {
      _data['playbackMode'] ??= 'integrated';
      _data['autoplay'] ??= false;
      _data['showControls'] ??= true;
      _data['loop'] ??= false;
      
      if (widget.component.type == 'video') {
        _data['mute'] ??= false;
        _data['hideControls'] ??= false;
      }
      
      if (widget.component.type == 'audio') {
        _data['showComments'] ??= true;
        _data['source_type'] ??= 'direct';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveComponent() {
    if (!_formKey.currentState!.validate()) return;

    // Validation supplémentaire pour les composants image
    if (widget.component.type == 'image') {
      final imageUrl = _data['url'];
      if (imageUrl == null || imageUrl.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une image'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
        return;
      }
    }

    final updatedComponent = widget.component.copyWith(
      name: _nameController.text.trim(),
      data: _data,
      styling: _styling,
      settings: _settings,
      action: _currentAction,
      children: _children,
    );

    widget.onSave(updatedComponent);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getComponentIcon(widget.component.type),
                    color: AppTheme.white100,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      'Modifier ${widget.component.typeLabel}',
                      style: const TextStyle(
                        color: AppTheme.white100,
                        fontSize: AppTheme.fontSize18,
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.white100),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du composant
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du composant',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spaceLarge),

                      // Éditeur spécifique au type
                      _buildTypeSpecificEditor(),
                      
                      const SizedBox(height: AppTheme.spaceLarge),
                      
                      // Éditeur d'actions (pour les composants supportés)
                      if (ComponentActionService.supportsActions(widget.component.type))
                        ComponentActionEditor(
                          action: _currentAction,
                          componentType: widget.component.type,
                          onActionChanged: (action) {
                            setState(() {
                              _currentAction = action;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.grey300!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  ElevatedButton(
                    onPressed: _saveComponent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                    ),
                    child: const Text('Sauvegarder'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificEditor() {
    switch (widget.component.type) {
      case 'text':
        return _buildTextEditor();
      case 'image':
        return _buildImageEditor();
      case 'button':
        return _buildButtonEditor();
      case 'video':
        return _buildVideoEditor();
      case 'list':
        return _buildListEditor();
      case 'tabs':
        return _buildTabsEditor();

      case 'scripture':
        return _buildScriptureEditor();
      case 'banner':
        return _buildBannerEditor();
      case 'map':
        return _buildMapEditor();
      case 'audio':
        return _buildAudioEditor();
      case 'googlemap':
        return _buildGoogleMapEditor();
      case 'html':
        return _buildHtmlEditor();
      case 'webview':
        return _buildWebViewEditor();
      case 'quote':
        return _buildQuoteEditor();
      case 'groups':
        return _buildGroupsEditor();
      case 'events':
        return _buildEventsEditor();







      case 'prayer_wall':
        return _buildPrayerWallEditor();
      case 'grid_card':
        return _buildGridCardEditor();
      case 'grid_stat':
        return _buildGridStatEditor();
      case 'grid_icon_text':
        return _buildGridIconTextEditor();
      case 'grid_image_card':
        return _buildGridImageCardEditor();
      case 'grid_progress':
        return _buildGridProgressEditor();
      case 'grid_container':
        return _buildGridContainerEditor();
      default:
        return _buildGenericEditor();
    }
  }

  Widget _buildTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contenu du texte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['content'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte',
            border: OutlineInputBorder(),
            helperText: 'Supporté: Markdown basique (##, **, *, [lien](url))',
          ),
          maxLines: 8,
          onChanged: (value) => _data['content'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['textAlign'] ?? 'left',
                decoration: const InputDecoration(
                  labelText: 'Alignement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'left', child: Text('Gauche')),
                  DropdownMenuItem(value: 'center', child: Text('Centre')),
                  DropdownMenuItem(value: 'right', child: Text('Droite')),
                  DropdownMenuItem(value: 'justify', child: Text('Justifié')),
                ],
                onChanged: (value) => setState(() => _data['textAlign'] = value),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: TextFormField(
                initialValue: (_data['fontSize'] ?? 16).toString(),
                decoration: const InputDecoration(
                  labelText: 'Taille de police',
                  border: OutlineInputBorder(),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['fontSize'] = int.tryParse(value) ?? 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de l\'image',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ImagePickerWidget(
          initialUrl: _data['url'] ?? '',
          onImageSelected: (url) {
            setState(() {
              if (url != null && url.isNotEmpty) {
                _data['url'] = url;
              } else {
                _data.remove('url');
              }
            });
          },
          isRequired: true,
          label: 'Source de l\'image',
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['alt'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte alternatif',
            border: OutlineInputBorder(),
            helperText: 'Description de l\'image pour l\'accessibilité',
          ),
          onChanged: (value) => _data['alt'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['height'] ?? 200).toString(),
                decoration: const InputDecoration(
                  labelText: 'Hauteur',
                  border: OutlineInputBorder(),
                  suffixText: 'px',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['height'] = int.tryParse(value) ?? 200,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['fit'] ?? 'cover',
                decoration: const InputDecoration(
                  labelText: 'Ajustement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cover', child: Text('Couvrir')),
                  DropdownMenuItem(value: 'contain', child: Text('Contenir')),
                  DropdownMenuItem(value: 'fill', child: Text('Remplir')),
                  DropdownMenuItem(value: 'fitWidth', child: Text('Largeur')),
                  DropdownMenuItem(value: 'fitHeight', child: Text('Hauteur')),
                ],
                onChanged: (value) => setState(() => _data['fit'] = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        _buildImageActionEditor(),
      ],
    );
  }

  Widget _buildImageActionEditor() {
    final hasAction = _data['action'] != null;
    final action = hasAction ? ImageAction.fromMap(_data['action']) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Action au clic',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const Spacer(),
            Switch(
              value: hasAction,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _data['action'] = const ImageAction(type: 'url').toMap();
                  } else {
                    _data.remove('action');
                  }
                });
              },
            ),
          ],
        ),
        if (hasAction) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          DropdownButtonFormField<String>(
            value: action?.type ?? 'url',
            decoration: const InputDecoration(
              labelText: 'Type d\'action',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'url', child: Text('Ouvrir un lien internet')),
              DropdownMenuItem(value: 'member_page', child: Text('Aller vers une page membre')),
            ],
            onChanged: (value) {
              setState(() {
                if (value != null) {
                  _data['action'] = ImageAction(type: value).toMap();
                }
              });
            },
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          if (action?.type == 'url') _buildUrlActionEditor(action!),
          if (action?.type == 'member_page') _buildMemberPageActionEditor(action!),
        ],
      ],
    );
  }

  Widget _buildUrlActionEditor(ImageAction action) {
    return TextFormField(
      initialValue: action.url ?? '',
      decoration: const InputDecoration(
        labelText: 'URL du lien',
        border: OutlineInputBorder(),
        helperText: 'URL complète (ex: https://example.com)',
        prefixIcon: Icon(Icons.link),
      ),
      onChanged: (value) {
        final currentAction = ImageAction.fromMap(_data['action']);
        _data['action'] = currentAction.copyWith(url: value).toMap();
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'L\'URL est requise';
        }
        if (!value.startsWith('http://') && !value.startsWith('https://')) {
          return 'L\'URL doit commencer par http:// ou https://';
        }
        return null;
      },
    );
  }

  Widget _buildMemberPageActionEditor(ImageAction action) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: action.memberPage,
          decoration: const InputDecoration(
            labelText: 'Page membre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pages),
          ),
          items: MemberPagesRegistry.availablePages
              .map((page) => DropdownMenuItem(
                    value: page.key,
                    child: Row(
                      children: [
                        if (page.icon != null) ...[
                          Icon(_getIconData(page.icon!), size: 16),
                          const SizedBox(width: AppTheme.spaceSmall),
                        ],
                        Expanded(child: Text(page.name)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            final currentAction = ImageAction.fromMap(_data['action']);
            _data['action'] = currentAction.copyWith(
              memberPage: value,
              parameters: {},
            ).toMap();
            setState(() {});
          },
          validator: (value) {
            if (value == null) {
              return 'Veuillez sélectionner une page membre';
            }
            return null;
          },
        ),
        if (action.memberPage != null) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          _buildMemberPageParameters(action),
        ],
      ],
    );
  }

  Widget _buildMemberPageParameters(ImageAction action) {
    final pageDefinition = MemberPagesRegistry.findByKey(action.memberPage!);
    if (pageDefinition?.supportedParameters == null ||
        pageDefinition!.supportedParameters!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ...pageDefinition.supportedParameters!.map((param) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildParameterField(action, param, pageDefinition),
          );
        }),
      ],
    );
  }

  Widget _buildParameterField(
    ImageAction action,
    String paramName,
    MemberPageDefinition pageDefinition,
  ) {
    final currentValue = action.parameters?[paramName]?.toString() ?? '';

    String labelText = paramName;
    String? helperText;
    IconData? icon;

    switch (paramName) {
      case 'category':
        labelText = 'Catégorie';
        helperText = 'Nom de la catégorie de blog';
        icon = Icons.category;
        break;
      case 'formId':
        labelText = 'ID du formulaire';
        helperText = 'Identifiant unique du formulaire';
        icon = Icons.assignment;
        break;
    }

    return TextFormField(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        helperText: helperText,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      onChanged: (value) {
        final currentAction = ImageAction.fromMap(_data['action']);
        final currentParams = Map<String, dynamic>.from(currentAction.parameters ?? {});
        currentParams[paramName] = value;
        _data['action'] = currentAction.copyWith(parameters: currentParams).toMap();
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$labelText est requis pour ${pageDefinition.name}';
        }
        return null;
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'group':
        return Icons.group;
      case 'event':
        return Icons.event;
      case 'music_note':
        return Icons.music_note;
      case 'article':
        return Icons.article;
      case 'favorite':
        return Icons.favorite;
      case 'schedule':
        return Icons.schedule;
      case 'work':
        return Icons.work;
      case 'assignment':
        return Icons.assignment;
      case 'task':
        return Icons.task;
      case 'dashboard':
        return Icons.dashboard;
      case 'person':
        return Icons.person;
      case 'calendar_today':
        return Icons.calendar_today;
      default:
        return Icons.pages;
    }
  }

  Widget _buildButtonEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration du bouton',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['text'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte du bouton',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['text'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le texte du bouton est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['url'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Lien URL',
            border: OutlineInputBorder(),
            helperText: 'URL externe ou chemin interne (/groupes, /events)',
          ),
          onChanged: (value) => _data['url'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['style'] ?? 'primary',
                decoration: const InputDecoration(
                  labelText: 'Style',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'primary', child: Text('Principal')),
                  DropdownMenuItem(value: 'secondary', child: Text('Secondaire')),
                  DropdownMenuItem(value: 'outline', child: Text('Contour')),
                  DropdownMenuItem(value: 'text', child: Text('Texte')),
                ],
                onChanged: (value) => setState(() => _data['style'] = value),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['size'] ?? 'medium',
                decoration: const InputDecoration(
                  labelText: 'Taille',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Petit')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                  DropdownMenuItem(value: 'large', child: Text('Grand')),
                ],
                onChanged: (value) => setState(() => _data['size'] = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la vidéo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Widget spécialisé YouTube
        YouTubePickerWidget(
          initialUrl: _data['url'] ?? '',
          onUrlChanged: (url) => setState(() => _data['url'] = url),
          isRequired: true,
          label: 'Source vidéo YouTube',
        ),
        
        const SizedBox(height: AppTheme.spaceLarge),
        
        // Titre personnalisé (optionnel)
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre personnalisé (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Laissez vide pour utiliser le titre YouTube',
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Options avancées
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Options de lecture',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                
                SwitchListTile(
                  title: const Text('Lecture automatique'),
                  subtitle: const Text('Démarrer la vidéo automatiquement'),
                  value: _data['autoplay'] ?? false,
                  onChanged: (value) => setState(() => _data['autoplay'] = value),
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: const Text('Lecture en boucle'),
                  subtitle: const Text('Répéter la vidéo en continu'),
                  value: _data['loop'] ?? false,
                  onChanged: (value) => setState(() => _data['loop'] = value),
                  contentPadding: EdgeInsets.zero,
                ),
                
                SwitchListTile(
                  title: const Text('Contrôles masqués'),
                  subtitle: const Text('Cacher les contrôles de lecture'),
                  value: _data['hideControls'] ?? false,
                  onChanged: (value) => setState(() => _data['hideControls'] = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Configuration du lecteur
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration du lecteur',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                MediaPlayerConfigWidget(
                  componentType: 'video',
                  data: Map<String, dynamic>.from(_data),
                  onDataChanged: (newData) {
                    setState(() {
                      // Mise à jour avec toutes les nouvelles données
                      _data.addAll(newData);
                      
                      // S'assurer que les clés importantes sont bien définies
                      _data['playbackMode'] ??= 'integrated';
                      _data['autoplay'] ??= newData['autoPlay'] ?? false;
                      _data['mute'] ??= newData['mute'] ?? false;
                      _data['hideControls'] ??= !(newData['showControls'] ?? true);
                      _data['loop'] ??= newData['loop'] ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Prévisualisation du type de contenu
        if (_data['url'] != null && (_data['url'] as String).isNotEmpty)
          _buildVideoPreviewCard(),
      ],
    );
  }
  
  Widget _buildVideoPreviewCard() {
    final url = _data['url'] as String;
    final urlInfo = YouTubeService.parseYouTubeUrl(url);
    
    if (!urlInfo.isValid) return const SizedBox.shrink();
    
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getVideoContentIcon(urlInfo.contentType),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Type: ${urlInfo.displayType}',
                  style: TextStyle(
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            if (urlInfo.videoId.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'ID Vidéo: ${urlInfo.videoId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
            
            if (urlInfo.playlistId.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                'ID Playlist: ${urlInfo.playlistId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getVideoContentIcon(YouTubeContentType contentType) {
    switch (contentType) {
      case YouTubeContentType.video:
        return Icons.play_circle_outline;
      case YouTubeContentType.playlist:
        return Icons.playlist_play;
      case YouTubeContentType.videoInPlaylist:
        return Icons.video_collection;
      default:
        return Icons.video_library;
    }
  }

  Widget _buildListEditor() {
    final items = List<Map<String, dynamic>>.from(_data['items'] ?? []);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la liste',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre de la liste',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        DropdownButtonFormField<String>(
          value: _data['listType'] ?? 'simple',
          decoration: const InputDecoration(
            labelText: 'Type de liste',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'simple', child: Text('Liste simple')),
            DropdownMenuItem(value: 'numbered', child: Text('Liste numérotée')),
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'links', child: Text('Liens')),
          ],
          onChanged: (value) => setState(() => _data['listType'] = value),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Éléments de la liste',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  items.add({
                    'title': 'Nouvel élément',
                    'description': '',
                    'icon': 'circle',
                    'action': '',
                  });
                  _data['items'] = items;
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: item['title'] ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            items[index]['title'] = value;
                            _data['items'] = items;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            items.removeAt(index);
                            _data['items'] = items;
                          });
                        },
                        icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  TextFormField(
                    initialValue: item['description'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      items[index]['description'] = value;
                      _data['items'] = items;
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTabsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration des onglets',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        
        Row(
          children: [
            const Text('Éditeur d\'onglets avancé'),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => TabPageBuilder(
                    component: widget.component,
                    onSave: (updatedComponent) {
                      setState(() {
                        _data = Map.from(updatedComponent.data);
                        _styling = Map.from(updatedComponent.styling);
                        _settings = Map.from(updatedComponent.settings);
                      });
                    },
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Ouvrir l\'éditeur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        const Divider(),
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Aperçu du nombre d'onglets
        if (_data['tabs'] != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tab, color: AppTheme.primaryColor),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Aperçu des onglets',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: AppTheme.fontBold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),
                  
                  // Informations sur les onglets
                  ...(_data['tabs'] as List<dynamic>).asMap().entries.map((entry) {
                    final index = entry.key;
                    final tab = entry.value as Map<String, dynamic>;
                    final componentsCount = (tab['components'] as List<dynamic>?)?.length ?? 0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSize12,
                                  fontWeight: AppTheme.fontBold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tab['title'] ?? 'Onglet ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: AppTheme.fontMedium,
                                  ),
                                ),
                                Text(
                                  '$componentsCount composant${componentsCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSize12,
                                    color: AppTheme.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            color: AppTheme.orangeStandard,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.orangeStandard),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      'Aucun onglet configuré. Utilisez l\'éditeur avancé pour créer des onglets.',
                      style: TextStyle(color: AppTheme.orangeStandard),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Options de style rapides
        Text(
          'Options de style',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['tabPosition'] ?? 'top',
                decoration: const InputDecoration(
                  labelText: 'Position des onglets',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'top', child: Text('En haut')),
                  DropdownMenuItem(value: 'bottom', child: Text('En bas')),
                  DropdownMenuItem(value: 'left', child: Text('À gauche')),
                  DropdownMenuItem(value: 'right', child: Text('À droite')),
                ],
                onChanged: (value) => setState(() => _data['tabPosition'] = value),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Afficher les icônes'),
                value: _data['showIcons'] ?? true,
                onChanged: (value) => setState(() => _data['showIcons'] = value),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildScriptureEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration du verset',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['verse'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte du verset',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) => _data['verse'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le texte du verset est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['reference'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Référence',
                  border: OutlineInputBorder(),
                  helperText: 'Ex: Jean 3:16',
                ),
                onChanged: (value) => _data['reference'] = value,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['version'] ?? 'LSG',
                decoration: const InputDecoration(
                  labelText: 'Version',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'LSG', child: Text('Louis Segond')),
                  DropdownMenuItem(value: 'NEG', child: Text('NEG 1979')),
                  DropdownMenuItem(value: 'S21', child: Text('Segond 21')),
                  DropdownMenuItem(value: 'BDS', child: Text('Bible du Semeur')),
                ],
                onChanged: (value) => setState(() => _data['version'] = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la bannière',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le titre est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['backgroundColor'] ?? '#6F61EF',
                decoration: const InputDecoration(
                  labelText: 'Couleur de fond',
                  border: OutlineInputBorder(),
                  helperText: 'Code couleur hex (#RRGGBB)',
                ),
                onChanged: (value) => _data['backgroundColor'] = value,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: TextFormField(
                initialValue: _data['textColor'] ?? '#FFFFFF',
                decoration: const InputDecoration(
                  labelText: 'Couleur du texte',
                  border: OutlineInputBorder(),
                  helperText: 'Code couleur hex (#RRGGBB)',
                ),
                onChanged: (value) => _data['textColor'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la carte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['address'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Adresse',
            border: OutlineInputBorder(),
            helperText: 'Adresse complète du lieu',
          ),
          onChanged: (value) => _data['address'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['latitude'] ?? 0.0).toString(),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['latitude'] = double.tryParse(value) ?? 0.0,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: TextFormField(
                initialValue: (_data['longitude'] ?? 0.0).toString(),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['longitude'] = double.tryParse(value) ?? 0.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: (_data['zoom'] ?? 15).toString(),
          decoration: const InputDecoration(
            labelText: 'Niveau de zoom',
            border: OutlineInputBorder(),
            helperText: '1-20 (15 recommandé)',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['zoom'] = int.tryParse(value) ?? 15,
        ),
      ],
    );
  }

  Widget _buildAudioEditor() {
    return DefaultTabController(
      length: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration audio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          // Onglets pour choisir le type d'audio
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor, // Couleur d'arrière-plan identique à l'AppBar
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: TabBar(
              labelColor: AppTheme.onPrimaryColor, // Texte blanc sur fond primaire
              unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
              indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
              tabs: [
                Tab(icon: Icon(Icons.audiotrack), text: 'SoundCloud'),
                Tab(icon: Icon(Icons.music_note), text: 'Fichier Direct'),
                Tab(icon: Icon(Icons.file_present), text: 'Fichier Appareil'),
                Tab(icon: Icon(Icons.cloud), text: 'OneDrive/Drive'),
                Tab(icon: Icon(Icons.album), text: 'Album'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          // Configuration du lecteur audio
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration du lecteur',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: AppTheme.fontBold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  MediaPlayerConfigWidget(
                    componentType: 'audio',
                    data: Map<String, dynamic>.from(_data),
                    onDataChanged: (newData) {
                      setState(() {
                        _data.addAll(newData);
                        _data['playbackMode'] ??= 'integrated';
                        _data['autoplay'] ??= newData['autoPlay'] ?? false;
                        _data['showComments'] ??= newData['showComments'] ?? true;
                        _data['loop'] ??= newData['loop'] ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          // Contenu des onglets
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildSoundCloudAudioEditor(),
                _buildDirectFileAudioEditor(),
                _buildDeviceFileAudioEditor(),
                _buildCloudAudioEditor(),
                _buildAlbumAudioEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Ajout : Sélection de fichier audio depuis l'appareil
  Widget _buildDeviceFileAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: AppTheme.grey700, size: 20),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Sélectionnez un fichier audio depuis votre appareil (MP3, WAV, etc.).',
                    style: TextStyle(color: AppTheme.grey800, fontSize: AppTheme.fontSize13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_upload),
            label: const Text('Joindre un fichier'),
            onPressed: () async {
              // Utilisation de file_picker pour sélectionner un fichier audio
              final result = await FilePicker.platform.pickFiles(type: FileType.audio);
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;
                setState(() {
                  _data['device_file_path'] = file.path;
                  _data['device_file_name'] = file.name;
                  _data['source_type'] = 'device';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fichier sélectionné : ${file.name}')),
                );
              }
            },
          ),
          const SizedBox(height: AppTheme.space20),
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  // Ajout : Lien OneDrive/Drive
  Widget _buildCloudAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.primaryColor.withAlpha(102)!),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Collez un lien OneDrive ou Google Drive vers un fichier audio ou un album.',
                    style: TextStyle(color: AppTheme.primaryColor, fontSize: AppTheme.fontSize13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          TextFormField(
            initialValue: _data['cloud_url'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Lien OneDrive ou Google Drive',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.cloud),
              helperText: 'Lien direct vers le fichier ou l’album',
            ),
            onChanged: (value) {
              setState(() {
                _data['cloud_url'] = value;
                _data['source_type'] = 'cloud';
              });
            },
          ),
          const SizedBox(height: AppTheme.space20),
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  // Ajout : Album (SoundCloud, OneDrive, Drive, fichiers locaux)
  Widget _buildAlbumAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Row(
              children: [
                Icon(Icons.album, color: AppTheme.grey700, size: 20),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Ajoutez un album audio (SoundCloud, OneDrive, Drive, fichiers téléchargés, etc.).',
                    style: TextStyle(color: AppTheme.grey800, fontSize: AppTheme.fontSize13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          TextFormField(
            initialValue: _data['album_url'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Lien ou sélection d’album',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.album),
              helperText: 'Lien SoundCloud, OneDrive, Drive ou sélection locale',
            ),
            onChanged: (value) {
              setState(() {
                _data['album_url'] = value;
                _data['source_type'] = 'album';
              });
            },
          ),
          const SizedBox(height: AppTheme.space12),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_upload),
            label: const Text('Joindre un album local'),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
              if (result != null && result.files.isNotEmpty) {
                setState(() {
                  _data['album_files'] = result.files.map((f) => {'path': f.path, 'name': f.name}).toList();
                  _data['source_type'] = 'album';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Album local sélectionné : ${result.files.length} fichiers')),
                );
              }
            },
          ),
          const SizedBox(height: AppTheme.space20),
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  Widget _buildSoundCloudAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section SoundCloud
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: AppTheme.grey700, size: 20),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Intégrez facilement des pistes, playlists ou profils SoundCloud. Collez simplement l\'URL depuis votre navigateur.',
                    style: TextStyle(
                      color: AppTheme.grey800,
                      fontSize: AppTheme.fontSize13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Widget de sélection SoundCloud
          SoundCloudPickerWidget(
            initialUrl: _data['soundcloud_url'] ?? '',
            onUrlSelected: (url) {
              setState(() {
                if (url != null && url.isNotEmpty) {
                  _data['soundcloud_url'] = url;
                  _data['source_type'] = 'soundcloud';
                  
                  // Analyse de l'URL pour extraire les métadonnées
                  final info = SoundCloudService.parseSoundCloudUrl(url);
                  if (info.isValid) {
                    _data['title'] = _data['title'] ?? info.userName;
                    _data['artist'] = _data['artist'] ?? info.userName;
                  }
                } else {
                  _data.remove('soundcloud_url');
                  if (_data['source_type'] == 'soundcloud') {
                    _data.remove('source_type');
                  }
                }
              });
            },
            isRequired: true,
            label: 'URL SoundCloud',
            helperText: 'Piste, playlist ou profil SoundCloud',
          ),
          
          const SizedBox(height: AppTheme.space20),
          
          // Options d'intégration SoundCloud
          if (_data['soundcloud_url'] != null) ...[
            Text(
              'Options d\'intégration',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            
            _buildSoundCloudOptions(),
          ],
          
          const SizedBox(height: AppTheme.space20),
          
          // Métadonnées personnalisables
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  Widget _buildSoundCloudOptions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.grey300!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lecture automatique
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lecture automatique',
                      style: TextStyle(fontWeight: AppTheme.fontMedium),
                    ),
                    Text(
                      'Démarre la lecture dès le chargement',
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _data['autoplay'] ?? false,
                onChanged: (value) => setState(() => _data['autoplay'] = value),
              ),
            ],
          ),
          
          const Divider(),
          
          // Masquer les éléments associés
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Masquer les contenus associés',
                      style: TextStyle(fontWeight: AppTheme.fontMedium),
                    ),
                    Text(
                      'Cache les suggestions de pistes similaires',
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _data['hide_related'] ?? false,
                onChanged: (value) => setState(() => _data['hide_related'] = value),
              ),
            ],
          ),
          
          const Divider(),
          
          // Affichage visuel
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mode visuel',
                      style: TextStyle(fontWeight: AppTheme.fontMedium),
                    ),
                    Text(
                      'Affiche la pochette de l\'album',
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _data['visual'] ?? true,
                onChanged: (value) => setState(() => _data['visual'] = value),
              ),
            ],
          ),
          
          const Divider(),
          
          // Couleur du lecteur
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Couleur du lecteur',
                      style: TextStyle(fontWeight: AppTheme.fontMedium),
                    ),
                    Text(
                      'Couleur de l\'interface SoundCloud',
                      style: TextStyle(
                        color: AppTheme.grey600,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _data['color'] ?? 'ff5500',
                items: const [
                  DropdownMenuItem(value: 'ff5500', child: Text('Orange (défaut)')),
                  DropdownMenuItem(value: '0066cc', child: Text('Bleu')),
                  DropdownMenuItem(value: '006600', child: Text('Vert')),
                  DropdownMenuItem(value: 'cc0000', child: Text('Rouge')),
                  DropdownMenuItem(value: '663399', child: Text('Violet')),
                  DropdownMenuItem(value: '000000', child: Text('Noir')),
                ],
                onChanged: (value) => setState(() => _data['color'] = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectFileAudioEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Information sur les fichiers directs
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.grey50,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: AppTheme.grey700, size: 20),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Text(
                    'Pour les fichiers audio hébergés directement (MP3, WAV, etc.). L\'URL doit pointer vers le fichier audio.',
                    style: TextStyle(
                      color: AppTheme.grey800,
                      fontSize: AppTheme.fontSize13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // URL du fichier
          TextFormField(
            initialValue: _data['url'] ?? '',
            decoration: const InputDecoration(
              labelText: 'URL du fichier audio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
              helperText: 'URL directe vers le fichier (MP3, WAV, OGG, etc.)',
            ),
            onChanged: (value) {
              setState(() {
                _data['url'] = value;
                _data['source_type'] = 'direct';
              });
            },
            validator: (value) {
              if (_data['source_type'] == 'direct' && (value == null || value.trim().isEmpty)) {
                return 'L\'URL du fichier audio est requise';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppTheme.space20),
          
          // Métadonnées
          _buildAudioMetadataEditor(),
        ],
      ),
    );
  }

  Widget _buildAudioMetadataEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations audio',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        
        // Titre personnalisé
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre de l\'audio',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
            helperText: 'Titre personnalisé (optionnel)',
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Artiste/Auteur
        TextFormField(
          initialValue: _data['artist'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Artiste/Auteur',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
            helperText: 'Nom de l\'artiste ou auteur',
          ),
          onChanged: (value) => _data['artist'] = value,
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Durée
        TextFormField(
          initialValue: _data['duration'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Durée',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.access_time),
            helperText: 'Format: 3:45 ou 3 min 45 sec',
          ),
          onChanged: (value) => _data['duration'] = value,
        ),
        
        const SizedBox(height: AppTheme.spaceMedium),
        
        // Description
        TextFormField(
          initialValue: _data['description'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            helperText: 'Description de l\'audio (optionnel)',
          ),
          maxLines: 3,
          onChanged: (value) => _data['description'] = value,
        ),
      ],
    );
  }

  Widget _buildGoogleMapEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Google Maps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.grey200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: AppTheme.grey700, size: 20),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Saisissez une adresse et elle sera automatiquement reconnue par Google Maps',
                  style: TextStyle(
                    color: AppTheme.grey700,
                    fontSize: AppTheme.fontSize12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['address'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Adresse',
            border: OutlineInputBorder(),
            helperText: 'Ex: 1 Rue de la Paix, 75001 Paris, France',
          ),
          onChanged: (value) => _data['address'] = value,
          validator: (value) {
            if ((value == null || value.trim().isEmpty) && 
                (_data['latitude'] == null || _data['longitude'] == null)) {
              return 'L\'adresse est requise';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Ou saisissez les coordonnées GPS :',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['latitude'] ?? '').toString(),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _data['latitude'] = value.isNotEmpty ? double.tryParse(value) : null,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: TextFormField(
                initialValue: (_data['longitude'] ?? '').toString(),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _data['longitude'] = value.isNotEmpty ? double.tryParse(value) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: (_data['zoom'] ?? 15).toString(),
                decoration: const InputDecoration(
                  labelText: 'Niveau de zoom',
                  border: OutlineInputBorder(),
                  helperText: '1-20 (15 recommandé)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _data['zoom'] = int.tryParse(value) ?? 15,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _data['mapType'] ?? 'roadmap',
                decoration: const InputDecoration(
                  labelText: 'Type de carte',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'roadmap', child: Text('Route')),
                  DropdownMenuItem(value: 'satellite', child: Text('Satellite')),
                  DropdownMenuItem(value: 'hybrid', child: Text('Hybride')),
                  DropdownMenuItem(value: 'terrain', child: Text('Terrain')),
                ],
                onChanged: (value) => setState(() => _data['mapType'] = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHtmlEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration HTML',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.grey200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: AppTheme.grey700, size: 20),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Attention : Le code HTML sera exécuté tel quel. Assurez-vous qu\'il soit sûr.',
                  style: TextStyle(
                    color: AppTheme.grey700,
                    fontSize: AppTheme.fontSize12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre du composant (optionnel)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['content'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Code HTML',
            border: OutlineInputBorder(),
            helperText: 'Saisissez votre code HTML personnalisé',
          ),
          maxLines: 10,
          onChanged: (value) => _data['content'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le contenu HTML est requis';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuoteEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration de la citation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['quote'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Texte de la citation',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) => _data['quote'] = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le texte de la citation est requis';
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['author'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Auteur de la citation',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['author'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['context'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Contexte (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Ex: Livre, discours, date, etc.',
          ),
          onChanged: (value) => _data['context'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Couleurs personnalisées',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['backgroundColor'] ?? '#F5F5F5',
                decoration: const InputDecoration(
                  labelText: 'Couleur de fond',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #FFFFFF',
                ),
                onChanged: (value) => _data['backgroundColor'] = value,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: TextFormField(
                initialValue: _data['textColor'] ?? '#333333',
                decoration: const InputDecoration(
                  labelText: 'Couleur du texte',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #000000',
                ),
                onChanged: (value) => _data['textColor'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration des groupes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? 'Nos Groupes',
          decoration: const InputDecoration(
            labelText: 'Titre de la section',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre (optionnel)',
            border: OutlineInputBorder(),
            helperText: 'Description courte des groupes',
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        DropdownButtonFormField<String>(
          value: _data['displayMode'] ?? 'cards',
          decoration: const InputDecoration(
            labelText: 'Mode d\'affichage',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'list', child: Text('Liste')),
            DropdownMenuItem(value: 'grid', child: Text('Grille')),
          ],
          onChanged: (value) => setState(() => _data['displayMode'] = value),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        SwitchListTile(
          title: const Text('Afficher les informations de contact'),
          subtitle: const Text('Email et téléphone des responsables'),
          value: _data['showContact'] ?? true,
          onChanged: (value) => setState(() => _data['showContact'] = value),
        ),
        SwitchListTile(
          title: const Text('Permettre l\'inscription directe'),
          subtitle: const Text('Bouton "Rejoindre" sur chaque groupe'),
          value: _data['allowDirectJoin'] ?? false,
          onChanged: (value) => setState(() => _data['allowDirectJoin'] = value),
        ),
        SwitchListTile(
          title: const Text('Afficher le nombre de membres'),
          subtitle: const Text('Compteur de membres par groupe'),
          value: _data['showMemberCount'] ?? true,
          onChanged: (value) => setState(() => _data['showMemberCount'] = value),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        DropdownButtonFormField<String>(
          value: _data['filterBy'] ?? 'all',
          decoration: const InputDecoration(
            labelText: 'Filtrer les groupes',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous les groupes')),
            DropdownMenuItem(value: 'active', child: Text('Groupes actifs seulement')),
            DropdownMenuItem(value: 'joinable', child: Text('Groupes ouverts à l\'inscription')),
            DropdownMenuItem(value: 'category', child: Text('Par catégorie')),
          ],
          onChanged: (value) => setState(() => _data['filterBy'] = value),
        ),
        if (_data['filterBy'] == 'category') ...[
          const SizedBox(height: AppTheme.spaceMedium),
          TextFormField(
            initialValue: _data['category'] ?? '',
            decoration: const InputDecoration(
              labelText: 'Catégorie à afficher',
              border: OutlineInputBorder(),
              helperText: 'Ex: Ministères, Études bibliques, Jeunesse, etc.',
            ),
            onChanged: (value) => _data['category'] = value,
          ),
        ],
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Couleurs personnalisées',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: AppTheme.fontMedium,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _data['cardBackgroundColor'] ?? '#FFFFFF',
                decoration: const InputDecoration(
                  labelText: 'Couleur de fond des cartes',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #FFFFFF',
                ),
                onChanged: (value) => _data['cardBackgroundColor'] = value,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: TextFormField(
                initialValue: _data['accentColor'] ?? '#2196F3',
                decoration: const InputDecoration(
                  labelText: 'Couleur d\'accent',
                  border: OutlineInputBorder(),
                  helperText: 'Format: #2196F3',
                ),
                onChanged: (value) => _data['accentColor'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenericEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration générique',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            'Éditeur spécialisé non disponible pour ce type de composant.\n'
            'Type: ${widget.component.type}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  // Éditeur pour les événements
  Widget _buildEventsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration des événements',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? 'Nos Événements',
          decoration: const InputDecoration(
            labelText: 'Titre de la section',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['subtitle'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Sous-titre (optionnel)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['subtitle'] = value,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        DropdownButtonFormField<String>(
          value: _data['displayMode'] ?? 'cards',
          decoration: const InputDecoration(
            labelText: 'Mode d\'affichage',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'cards', child: Text('Cartes')),
            DropdownMenuItem(value: 'list', child: Text('Liste')),
            DropdownMenuItem(value: 'calendar', child: Text('Calendrier')),
          ],
          onChanged: (value) => setState(() => _data['displayMode'] = value),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        SwitchListTile(
          title: const Text('Afficher les dates'),
          subtitle: const Text('Inclure les dates des événements'),
          value: _data['showDates'] ?? true,
          onChanged: (value) => setState(() => _data['showDates'] = value),
        ),
        SwitchListTile(
          title: const Text('Permettre inscription'),
          subtitle: const Text('Bouton d\'inscription sur les événements'),
          value: _data['allowRegistration'] ?? true,
          onChanged: (value) => setState(() => _data['allowRegistration'] = value),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['primaryColor'] ?? '#2196F3',
          decoration: const InputDecoration(
            labelText: 'Couleur principale',
            border: OutlineInputBorder(),
            hintText: '#2196F3',
          ),
          onChanged: (value) => _data['primaryColor'] = value,
        ),
      ],
    );
  }

  // Helper methods
  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.play_circle_filled;
      case 'button':
        return Icons.smart_button;
      case 'list':
        return Icons.list;
      case 'tabs':
        return Icons.tab;
      case 'form':
        return Icons.assignment;
      case 'news':
        return Icons.article;
      case 'scripture':
        return Icons.menu_book;
      case 'banner':
        return Icons.view_carousel;
      case 'map':
        return Icons.map;
      case 'audio':
        return Icons.audiotrack;
      case 'googlemap':
        return Icons.location_on;
      case 'html':
        return Icons.code;
      case 'webview':
        return Icons.web;
      case 'quote':
        return Icons.format_quote;
      case 'groups':
        return Icons.group;
      case 'events':
        return Icons.event;
      case 'prayer_wall':
        return Icons.favorite;
      case 'grid_card':
        return Icons.view_module;
      case 'grid_stat':
        return Icons.bar_chart;
      case 'grid_icon_text':
        return Icons.grid_view;
      case 'grid_image_card':
        return Icons.image_outlined;
      case 'grid_progress':
        return Icons.timeline;
      case 'grid_container':
        return Icons.dashboard;
      default:
        return Icons.extension;
    }
  }

  Widget _buildWebViewEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration WebView',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
                   ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['url'] ?? '',
          decoration: const InputDecoration(
            labelText: 'URL',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['url'] = value,
        ),
      ],
    );
  }

  Widget _buildPrayerWallEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Mur de Prière',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        SwitchListTile(
          title: const Text('Autoriser les nouvelles prières'),
          value: _data['allowNewPrayers'] ?? true,
          onChanged: (value) => setState(() => _data['allowNewPrayers'] = value),
        ),
      ],
    );
  }

  Widget _buildGridCardEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Grille de Cartes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['columns']?.toString() ?? '2',
          decoration: const InputDecoration(
            labelText: 'Nombre de colonnes',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['columns'] = int.tryParse(value) ?? 2,
        ),
      ],
    );
  }

  Widget _buildGridStatEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Grille de Statistiques',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
      ],
    );
  }

  Widget _buildGridIconTextEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Grille Icône-Texte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['columns']?.toString() ?? '3',
          decoration: const InputDecoration(
            labelText: 'Nombre de colonnes',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['columns'] = int.tryParse(value) ?? 3,
        ),
      ],
    );
  }

  Widget _buildGridImageCardEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Grille de Cartes Image',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['columns']?.toString() ?? '2',
          decoration: const InputDecoration(
            labelText: 'Nombre de colonnes',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['columns'] = int.tryParse(value) ?? 2,
        ),
      ],
    );
  }

  Widget _buildGridProgressEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Grille de Progression',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        TextFormField(
          initialValue: _data['title'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _data['title'] = value,
        ),
      ],
    );
  }

  Widget _buildGridContainerEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Conteneur de Grille',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.blueStandard,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.blueStandard),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.blueStandard),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Text(
                      'Le Container Grid permet d\'organiser des composants en grille.',
                      style: TextStyle(color: AppTheme.blueStandard),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGridContainerBuilder,
                  icon: const Icon(Icons.grid_view),
                  label: const Text('Ouvrir l\'éditeur avancé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.white100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Text(
          'Configuration rapide',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSmall),
        TextFormField(
          initialValue: _data['columns']?.toString() ?? '2',
          decoration: const InputDecoration(
            labelText: 'Nombre de colonnes',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _data['columns'] = int.tryParse(value) ?? 2,
        ),
      ],
    );
  }

  void _openGridContainerBuilder() {
    showDialog(
      context: context,
      builder: (context) => GridContainerBuilder(
        component: widget.component.copyWith(
          data: _data,
          styling: _styling,
          children: _children,
        ),
        onSave: (updatedComponent) {
          setState(() {
            _data = Map.from(updatedComponent.data);
            _styling = Map.from(updatedComponent.styling);
            _children = List.from(updatedComponent.children);
          });
          // Ne pas sauvegarder automatiquement, laisser l'utilisateur le faire via le bouton principal
        },
      ),
    );
  }
}