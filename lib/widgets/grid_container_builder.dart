import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/page_model.dart';
import 'page_components/component_editor.dart';
import 'page_components/component_renderer.dart';
import '../../theme.dart';

/// Widget pour créer et éditer un composant Container Grid
class GridContainerBuilder extends StatefulWidget {
  final PageComponent component;
  final Function(PageComponent) onSave;

  const GridContainerBuilder({
    super.key,
    required this.component,
    required this.onSave,
  });

  @override
  State<GridContainerBuilder> createState() => _GridContainerBuilderState();
}

class _GridContainerBuilderState extends State<GridContainerBuilder>
    with TickerProviderStateMixin {
  final _uuid = const Uuid();
  Timer? _updateDebounce;
  late List<PageComponent> _children;
  late Map<String, dynamic> _containerData;
  late Map<String, dynamic> _containerStyling;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _containerData = Map.from(widget.component.data);
    _containerStyling = Map.from(widget.component.styling);
    _children = List.from(widget.component.children);

    // Valeurs par défaut
    _containerData['columns'] ??= 2;
    _containerData['mainAxisSpacing'] ??= 12.0;
    _containerData['crossAxisSpacing'] ??= 12.0;
    _containerData['childAspectRatio'] ??= 1.0;
    _containerData['padding'] ??= 16.0;
    _containerData['autoHeight'] ??= true;
    _containerData['maxHeight'] ??= 400.0;
    
    _containerStyling['backgroundColor'] ??= '#FFFFFF';
    _containerStyling['borderColor'] ??= '#E0E0E0';
    _containerStyling['borderWidth'] ??= 1.0;
    _containerStyling['borderRadius'] ??= 8.0;
    _containerStyling['elevation'] ??= 0.0;
  }

  void _saveChanges() {
    final updatedComponent = widget.component.copyWith(
      data: _containerData,
      styling: _containerStyling,
      children: _children,
    );
    
    widget.onSave(updatedComponent);
    Navigator.pop(context);
  }

  void _addComponent() {
    showDialog(
      context: context,
      builder: (context) => _ComponentTypeSelector(
        onComponentTypeSelected: (componentType) {
          Navigator.pop(context);
          _createNewComponent(componentType);
        },
      ),
    );
  }

  void _createNewComponent(String componentType) {
    final newComponent = PageComponent(
      id: _uuid.v4(),
      type: componentType,
      name: _getDefaultComponentName(componentType),
      order: _children.length,
      data: _getDefaultComponentData(componentType),
    );

    // Ouvrir l'éditeur de composant
    showDialog(
      context: context,
      builder: (context) => ComponentEditor(
        component: newComponent,
        onSave: (component) {
          _debouncedUpdate(() {
            _children.add(component);
          });
        },
      ),
    );
  }

  void _debouncedUpdate(VoidCallback update) {
    _updateDebounce?.cancel();
    _updateDebounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(update);
      }
    });
  }

  void _editComponent(int index) {
    final component = _children[index];
    
    showDialog(
      context: context,
      builder: (context) => ComponentEditor(
        component: component,
        onSave: (updatedComponent) {
          _debouncedUpdate(() {
            _children[index] = updatedComponent;
          });
        },
      ),
    );
  }

  void _removeComponent(int index) {
    setState(() {
      _children.removeAt(index);
      // Mettre à jour les ordres
      for (int i = 0; i < _children.length; i++) {
        _children[i] = _children[i].copyWith(order: i);
      }
    });
  }

  void _reorderComponents(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final component = _children.removeAt(oldIndex);
      _children.insert(newIndex, component);
      
      // Mettre à jour les ordres
      for (int i = 0; i < _children.length; i++) {
        _children[i] = _children[i].copyWith(order: i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
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
                  const Icon(Icons.grid_view, color: AppTheme.white100),
                  const SizedBox(width: AppTheme.space12),
                  const Expanded(
                    child: Text(
                      'Éditeur de Container Grid',
                      style: TextStyle(
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

            // Onglets
            Container(
              color: AppTheme.primaryColor, // Couleur d'arrière-plan identique à l'AppBar
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.onPrimaryColor, // Texte blanc sur fond primaire
                unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
                indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
                tabs: const [
                  Tab(
                    icon: Icon(Icons.settings),
                    text: 'Configuration',
                  ),
                  Tab(
                    icon: Icon(Icons.extension),
                    text: 'Composants',
                  ),
                ],
              ),
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConfigurationTab(),
                  _buildComponentsTab(),
                ],
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.grey500,
                border: Border(top: BorderSide(color: AppTheme.grey500)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  ElevatedButton(
                    onPressed: _saveChanges,
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

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuration de la grille
          _buildSection(
            title: 'Configuration de la grille',
            icon: Icons.grid_4x4,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nombre de colonnes: ${_containerData['columns']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerData['columns'] ?? 2).toDouble(),
                          min: 1,
                          max: 6,
                          divisions: 5,
                          label: '${_containerData['columns']} colonnes',
                          onChanged: (value) {
                            setState(() {
                              _containerData['columns'] = value.round();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapport hauteur/largeur: ${_containerData['childAspectRatio']?.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerData['childAspectRatio'] ?? 1.0).toDouble(),
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          label: '${_containerData['childAspectRatio']?.toStringAsFixed(1)}',
                          onChanged: (value) {
                            setState(() {
                              _containerData['childAspectRatio'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Espacement
          _buildSection(
            title: 'Espacement',
            icon: Icons.space_bar,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Espacement vertical: ${_containerData['mainAxisSpacing']?.round()}px',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerData['mainAxisSpacing'] ?? 12.0).toDouble(),
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${_containerData['mainAxisSpacing']?.round()}px',
                          onChanged: (value) {
                            setState(() {
                              _containerData['mainAxisSpacing'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Espacement horizontal: ${_containerData['crossAxisSpacing']?.round()}px',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerData['crossAxisSpacing'] ?? 12.0).toDouble(),
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${_containerData['crossAxisSpacing']?.round()}px',
                          onChanged: (value) {
                            setState(() {
                              _containerData['crossAxisSpacing'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Padding interne: ${_containerData['padding']?.round()}px',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerData['padding'] ?? 16.0).toDouble(),
                          min: 0,
                          max: 50,
                          divisions: 50,
                          label: '${_containerData['padding']?.round()}px',
                          onChanged: (value) {
                            setState(() {
                              _containerData['padding'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Apparence
          _buildSection(
            title: 'Apparence',
            icon: Icons.palette,
            children: [
              TextFormField(
                initialValue: _containerStyling['backgroundColor'] ?? '#FFFFFF',
                decoration: const InputDecoration(
                  labelText: 'Couleur d\'arrière-plan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens),
                  helperText: 'Format: #FFFFFF',
                ),
                onChanged: (value) {
                  _containerStyling['backgroundColor'] = value;
                },
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _containerStyling['borderColor'] ?? '#E0E0E0',
                      decoration: const InputDecoration(
                        labelText: 'Couleur de bordure',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.border_color),
                      ),
                      onChanged: (value) {
                        _containerStyling['borderColor'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: TextFormField(
                      initialValue: _containerStyling['borderWidth']?.toString() ?? '1.0',
                      decoration: const InputDecoration(
                        labelText: 'Épaisseur bordure',
                        border: OutlineInputBorder(),
                        suffixText: 'px',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _containerStyling['borderWidth'] = double.tryParse(value) ?? 1.0;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rayon des coins: ${_containerStyling['borderRadius']?.round()}px',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerStyling['borderRadius'] ?? 8.0).toDouble(),
                          min: 0,
                          max: 30,
                          divisions: 30,
                          label: '${_containerStyling['borderRadius']?.round()}px',
                          onChanged: (value) {
                            setState(() {
                              _containerStyling['borderRadius'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Élévation: ${_containerStyling['elevation']?.round()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        Slider(
                          value: (_containerStyling['elevation'] ?? 0.0).toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: '${_containerStyling['elevation']?.round()}',
                          onChanged: (value) {
                            setState(() {
                              _containerStyling['elevation'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Hauteur
          _buildSection(
            title: 'Dimensions',
            icon: Icons.height,
            children: [
              SwitchListTile(
                title: const Text('Hauteur automatique'),
                subtitle: const Text('Ajuste la hauteur selon le contenu'),
                value: _containerData['autoHeight'] ?? true,
                onChanged: (value) {
                  setState(() {
                    _containerData['autoHeight'] = value;
                  });
                },
              ),
              if (!(_containerData['autoHeight'] ?? true)) ...[
                const SizedBox(height: AppTheme.spaceMedium),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hauteur maximale: ${_containerData['maxHeight']?.round()}px',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppTheme.spaceSmall),
                          Slider(
                            value: (_containerData['maxHeight'] ?? 400.0).toDouble(),
                            min: 200,
                            max: 1000,
                            divisions: 40,
                            label: '${_containerData['maxHeight']?.round()}px',
                            onChanged: (value) {
                              setState(() {
                                _containerData['maxHeight'] = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Aperçu
          _buildSection(
            title: 'Aperçu',
            icon: Icons.visibility,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: AppTheme.grey500,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.grey500),
                ),
                child: Column(
                  children: [
                    Text(
                      'Configuration actuelle',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      '${_containerData['columns']} colonnes • ${_children.length} composants',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Container(
                      height: 100,
                      child: ComponentRenderer(
                        component: widget.component.copyWith(
                          data: _containerData,
                          styling: _containerStyling,
                          children: _children,
                        ),
                        isPreview: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsTab() {
    return Column(
      children: [
        // En-tête avec bouton d'ajout
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.grey500,
            border: Border(bottom: BorderSide(color: AppTheme.grey500)),
          ),
          child: Row(
            children: [
              Icon(Icons.extension, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Composants dans la grille',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    Text(
                      '${_children.length} composant(s) • ${_containerData['columns']} colonnes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addComponent,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                ),
              ),
            ],
          ),
        ),

        // Liste des composants
        Expanded(
          child: _children.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dashboard_customize_outlined,
                        size: 64,
                        color: AppTheme.grey500,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Aucun composant dans la grille',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize18,
                          color: AppTheme.grey500,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Ajoutez des composants pour les organiser en grille',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          color: AppTheme.grey500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLarge),
                      ElevatedButton.icon(
                        onPressed: _addComponent,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter le premier composant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.white100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  onReorder: _reorderComponents,
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final component = _children[index];
                    return Card(
                      key: ValueKey(component.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceSmall),
                          decoration: BoxDecoration(
                            color: _getComponentColor(component.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Icon(
                            _getComponentIcon(component.type),
                            color: _getComponentColor(component.type),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          component.name,
                          style: const TextStyle(fontWeight: AppTheme.fontMedium),
                        ),
                        subtitle: Text(
                          _getComponentTypeName(component.type),
                          style: TextStyle(
                            color: AppTheme.grey500,
                            fontSize: AppTheme.fontSize12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _editComponent(index),
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              onPressed: () => _removeComponent(index),
                              icon: const Icon(Icons.delete, size: 18),
                              tooltip: 'Supprimer',
                              color: AppTheme.redStandard,
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: AppTheme.spaceSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        ...children,
      ],
    );
  }

  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'text': return Icons.text_fields;
      case 'image': return Icons.image;
      case 'button': return Icons.smart_button;
      case 'video': return Icons.video_library;
      case 'audio': return Icons.music_note;
      case 'list': return Icons.list;
      case 'banner': return Icons.campaign;
      case 'quote': return Icons.format_quote;
      case 'scripture': return Icons.menu_book;
      case 'html': return Icons.code;
      case 'webview': return Icons.web;
      case 'map': return Icons.map;
      case 'googlemap': return Icons.location_on;
      case 'groups': return Icons.groups;
      case 'events': return Icons.event;
      case 'prayer_wall': return Icons.favorite;
      case 'grid_card': return Icons.crop_landscape;
      case 'grid_stat': return Icons.analytics;
      case 'grid_icon_text': return Icons.text_rotate_vertical;
      case 'grid_image_card': return Icons.image_aspect_ratio;
      case 'grid_progress': return Icons.pie_chart;
      default: return Icons.extension;
    }
  }

  Color _getComponentColor(String type) {
    switch (type) {
      case 'text': return AppTheme.blueStandard;
      case 'image': return AppTheme.greenStandard;
      case 'button': return AppTheme.orangeStandard;
      case 'video': return AppTheme.redStandard;
      case 'audio': return AppTheme.pinkStandard;
      case 'list': return AppTheme.primaryColor;
      case 'banner': return AppTheme.warningColor;
      case 'quote': return AppTheme.primaryDark;
      case 'scripture': return AppTheme.secondaryColor;
      case 'html': return AppTheme.infoColor;
      case 'webview': return AppTheme.blueStandard;
      case 'map': return AppTheme.tertiaryColor;
      case 'googlemap': return AppTheme.redStandard;
      case 'groups': return AppTheme.warningColor;
      case 'events': return AppTheme.greenStandard;
      case 'prayer_wall': return AppTheme.pinkStandard;
      case 'grid_card': return AppTheme.primaryDark;
      case 'grid_stat': return AppTheme.secondaryColor;
      case 'grid_icon_text': return AppTheme.secondaryColor;
      case 'grid_image_card': return AppTheme.orangeStandard;
      case 'grid_progress': return AppTheme.greenStandard;
      default: return AppTheme.grey500;
    }
  }

  String _getComponentTypeName(String type) {
    switch (type) {
      case 'text': return 'Texte';
      case 'image': return 'Image';
      case 'button': return 'Bouton';
      case 'video': return 'Vidéo';
      case 'audio': return 'Audio';
      case 'list': return 'Liste';
      case 'banner': return 'Bannière';
      case 'quote': return 'Citation';
      case 'scripture': return 'Verset biblique';
      case 'html': return 'HTML';
      case 'webview': return 'WebView';
      case 'map': return 'Carte';
      case 'googlemap': return 'Google Map';
      case 'groups': return 'Groupes';
      case 'events': return 'Événements';
      case 'prayer_wall': return 'Prières & Témoignages';
      case 'grid_card': return 'Carte Grid';
      case 'grid_stat': return 'Statistique Grid';
      case 'grid_icon_text': return 'Icône + Texte Grid';
      case 'grid_image_card': return 'Image Card Grid';
      case 'grid_progress': return 'Progression Grid';
      default: return 'Composant';
    }
  }

  String _getDefaultComponentName(String type) {
    return 'Nouveau ${_getComponentTypeName(type)}';
  }

  Map<String, dynamic> _getDefaultComponentData(String type) {
    switch (type) {
      case 'text':
        return {
          'content': 'Votre texte ici...',
          'fontSize': 16,
          'textAlign': 'left',
          'fontWeight': 'normal',
        };
      case 'image':
        return {
          'url': '',
          'alt': '',
          'width': double.infinity,
          'height': 200,
          'fit': 'cover',
        };
      case 'button':
        return {
          'text': 'Cliquez ici',
          'url': '',
          'style': 'primary',
          'size': 'medium',
        };
      case 'video':
        return {
          'url': '',
          'title': '',
          'playbackMode': 'integrated',
          'autoplay': false,
          'autoPlay': false,
          'loop': false,
          'mute': false,
          'hideControls': false,
          'showControls': true,
        };
      case 'audio':
        return {
          'source_type': 'direct',
          'url': '',
          'soundcloud_url': '',
          'title': '',
          'artist': '',
          'duration': '',
          'description': '',
          'playbackMode': 'integrated',
          'autoplay': false,
          'autoPlay': false,
          'showComments': true,
          'color': 'ff5500',
        };
      case 'list':
        return {
          'title': 'Liste d\'éléments',
          'items': [],
          'listType': 'simple',
        };
      case 'scripture':
        return {
          'verse': '',
          'reference': '',
          'version': 'LSG',
        };
      case 'banner':
        return {
          'title': 'Titre de la bannière',
          'subtitle': '',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        };
      case 'quote':
        return {
          'quote': 'Votre citation ici...',
          'author': 'Auteur',
          'context': '',
        };
      case 'html':
        return {
          'content': '<p>Votre code HTML ici...</p>',
        };
      case 'webview':
        return {
          'url': '',
          'height': 400,
        };
      case 'map':
        return {
          'address': '',
          'latitude': 0.0,
          'longitude': 0.0,
          'zoom': 15,
        };
      case 'googlemap':
        return {
          'address': '',
          'latitude': 0.0,
          'longitude': 0.0,
          'zoom': 15,
        };
      case 'groups':
        return {
          'showAll': true,
          'groupIds': [],
        };
      case 'events':
        return {
          'showUpcoming': true,
          'limit': 10,
        };
      case 'prayer_wall':
        return {
          'showRequests': true,
          'showTestimonies': true,
          'limit': 20,
        };
      case 'grid_card':
        return {
          'title': 'Titre de la carte',
          'subtitle': 'Sous-titre',
          'description': 'Description courte...',
          'iconName': 'star',
          'backgroundColor': '#6F61EF',
          'textColor': '#FFFFFF',
        };
      case 'grid_stat':
        return {
          'title': 'Statistique',
          'value': '42',
          'unit': '',
          'trend': 'up',
          'color': '#4CAF50',
          'iconName': 'trending_up',
        };
      case 'grid_icon_text':
        return {
          'iconName': 'favorite',
          'title': 'Titre',
          'description': 'Description',
          'iconColor': '#FF5722',
          'textAlign': 'center',
        };
      case 'grid_image_card':
        return {
          'imageUrl': '',
          'title': 'Titre de l\'image',
          'description': 'Description de l\'image',
          'imageHeight': 120,
        };
      case 'grid_progress':
        return {
          'title': 'Progression',
          'progress': 0.75,
          'showPercentage': true,
          'color': '#2196F3',
          'backgroundColor': '#E3F2FD',
        };
      default:
        return {};
    }
  }
}

/// Dialog pour sélectionner le type de composant à ajouter
class _ComponentTypeSelector extends StatelessWidget {
  final Function(String) onComponentTypeSelected;

  _ComponentTypeSelector({required this.onComponentTypeSelected});

  final Map<String, List<Map<String, dynamic>>> _componentCategories = {
    'Contenu textuel': [
      {'type': 'text', 'label': 'Texte', 'icon': Icons.text_fields, 'color': AppTheme.blueStandard},
      {'type': 'scripture', 'label': 'Verset biblique', 'icon': Icons.menu_book, 'color': AppTheme.secondaryColor},
      {'type': 'banner', 'label': 'Bannière', 'icon': Icons.campaign, 'color': AppTheme.warningColor},
      {'type': 'quote', 'label': 'Citation', 'icon': Icons.format_quote, 'color': AppTheme.primaryDark},
    ],
    'Médias': [
      {'type': 'image', 'label': 'Image', 'icon': Icons.image, 'color': AppTheme.greenStandard},
      {'type': 'video', 'label': 'Vidéo', 'icon': Icons.video_library, 'color': AppTheme.redStandard},
      {'type': 'audio', 'label': 'Audio', 'icon': Icons.music_note, 'color': AppTheme.pinkStandard},
    ],
    'Interactif': [
      {'type': 'button', 'label': 'Bouton', 'icon': Icons.smart_button, 'color': AppTheme.orangeStandard},
      {'type': 'html', 'label': 'HTML', 'icon': Icons.code, 'color': AppTheme.infoColor},
      {'type': 'webview', 'label': 'WebView', 'icon': Icons.web, 'color': AppTheme.blueStandard},
    ],
    'Organisation': [
      {'type': 'list', 'label': 'Liste', 'icon': Icons.list, 'color': AppTheme.primaryColor},
      {'type': 'map', 'label': 'Carte', 'icon': Icons.map, 'color': AppTheme.tertiaryColor},
      {'type': 'googlemap', 'label': 'Google Map', 'icon': Icons.location_on, 'color': AppTheme.redStandard},
      {'type': 'groups', 'label': 'Groupes', 'icon': Icons.groups, 'color': AppTheme.warningColor},
      {'type': 'events', 'label': 'Événements', 'icon': Icons.event, 'color': AppTheme.greenStandard},
      {'type': 'prayer_wall', 'label': 'Prières & Témoignages', 'icon': Icons.pan_tool, 'color': AppTheme.pinkStandard},
    ],
    'Composants Grid': [
      {'type': 'grid_card', 'label': 'Carte Grid', 'icon': Icons.crop_landscape, 'color': AppTheme.primaryDark},
      {'type': 'grid_stat', 'label': 'Statistique Grid', 'icon': Icons.analytics, 'color': AppTheme.secondaryColor},
      {'type': 'grid_icon_text', 'label': 'Icône + Texte Grid', 'icon': Icons.text_rotate_vertical, 'color': AppTheme.secondaryColor},
      {'type': 'grid_image_card', 'label': 'Image Card Grid', 'icon': Icons.image_aspect_ratio, 'color': AppTheme.orangeStandard},
      {'type': 'grid_progress', 'label': 'Progression Grid', 'icon': Icons.pie_chart, 'color': AppTheme.greenStandard},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un composant'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _componentCategories.entries.map((entry) {
              final categoryName = entry.key;
              final components = entry.value;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.black100.withOpacity(0.87),
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: components.length,
                    itemBuilder: (context, index) {
                      final componentType = components[index];
                      return Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: () => onComponentTypeSelected(componentType['type']),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  componentType['icon'],
                                  size: 28,
                                  color: componentType['color'] ?? AppTheme.primaryColor,
                                ),
                                const SizedBox(height: AppTheme.spaceXSmall),
                                Text(
                                  componentType['label'],
                                  style: const TextStyle(fontSize: AppTheme.fontSize10),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
