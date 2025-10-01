import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/page_model.dart';
import 'custom_tabs_widget.dart';
import 'page_components/component_editor.dart';
import '../../theme.dart';

/// Widget pour créer et éditer les onglets d'un composant TabsWidget
class TabPageBuilder extends StatefulWidget {
  final PageComponent component;
  final Function(PageComponent) onSave;

  const TabPageBuilder({
    super.key,
    required this.component,
    required this.onSave,
  });

  @override
  State<TabPageBuilder> createState() => _TabPageBuilderState();
}

class _TabPageBuilderState extends State<TabPageBuilder>
    with TickerProviderStateMixin {
  final _uuid = const Uuid();
  late List<TabData> _tabs;
  late Map<String, dynamic> _componentData;
  late Map<String, dynamic> _componentStyling;
  
  late TabController _mainTabController;
  late TabController _tabsPreviewController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _mainTabController = TabController(length: 2, vsync: this);
    _tabsPreviewController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _tabsPreviewController.dispose();
    super.dispose();
  }

  void _initializeData() {
    _componentData = Map.from(widget.component.data);
    _componentStyling = Map.from(widget.component.styling);
    
    final tabsData = _componentData['tabs'] as List<dynamic>? ?? [];
    _tabs = tabsData.map((tab) {
      final tabMap = tab as Map<String, dynamic>;
      return TabData.fromMap(tabMap);
    }).toList();

    // Si aucun onglet n'existe, en créer un par défaut
    if (_tabs.isEmpty) {
      _tabs = [
        TabData(
          id: _uuid.v4(),
          title: 'Onglet 1',
          icon: Icons.tab,
          components: [],
        ),
      ];
    }

    // Définir les valeurs par défaut pour le style
    _componentData['tabPosition'] ??= 'top';
    _componentData['showIcons'] ??= true;
    _componentData['tabStyle'] ??= 'material';
    _componentStyling['backgroundColor'] ??= '#FFFFFF';
    _componentStyling['indicatorColor'] ??= '#1976D2';
  }

  void _saveChanges() {
    // Mettre à jour les données des onglets
    _componentData['tabs'] = _tabs.map((tab) => tab.toMap()).toList();
    
    final updatedComponent = widget.component.copyWith(
      data: _componentData,
      styling: _componentStyling,
    );
    
    widget.onSave(updatedComponent);
    Navigator.pop(context);
  }

  void _addTab() {
    setState(() {
      final newTab = TabData(
        id: _uuid.v4(),
        title: 'Onglet ${_tabs.length + 1}',
        icon: Icons.tab,
        components: [],
      );
      _tabs.add(newTab);
      
      // Recréer le TabController avec la nouvelle longueur
      _tabsPreviewController.dispose();
      _tabsPreviewController = TabController(length: _tabs.length, vsync: this);
      _selectedTabIndex = _tabs.length - 1;
      _tabsPreviewController.animateTo(_selectedTabIndex);
    });
  }

  void _removeTab(int index) {
    if (_tabs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il faut au moins un onglet'),
          backgroundColor: AppTheme.orangeStandard,
        ),
      );
      return;
    }

    setState(() {
      _tabs.removeAt(index);
      
      // Ajuster l'index sélectionné
      if (_selectedTabIndex >= _tabs.length) {
        _selectedTabIndex = _tabs.length - 1;
      }
      
      // Recréer le TabController
      _tabsPreviewController.dispose();
      _tabsPreviewController = TabController(length: _tabs.length, vsync: this);
      _tabsPreviewController.animateTo(_selectedTabIndex);
    });
  }

  void _editTab(int index) {
    final tab = _tabs[index];
    showDialog(
      context: context,
      builder: (context) => _TabEditDialog(
        tab: tab,
        onSave: (updatedTab) {
          setState(() {
            _tabs[index] = updatedTab;
          });
        },
      ),
    );
  }

  void _addComponentToTab(int tabIndex) {
    showDialog(
      context: context,
      builder: (context) => _ComponentTypeSelector(
        onComponentTypeSelected: (componentType) {
          Navigator.pop(context);
          _createNewComponent(tabIndex, componentType);
        },
      ),
    );
  }

  void _createNewComponent(int tabIndex, String componentType) {
    final newComponent = PageComponent(
      id: _uuid.v4(),
      type: componentType,
      name: _getDefaultComponentName(componentType),
      order: _tabs[tabIndex].components.length,
      data: _getDefaultComponentData(componentType),
    );

    // Ouvrir l'éditeur de composant
    showDialog(
      context: context,
      builder: (context) => ComponentEditor(
        component: newComponent,
        onSave: (component) {
          setState(() {
            final updatedComponents = List<PageComponent>.from(_tabs[tabIndex].components);
            updatedComponents.add(component);
            _tabs[tabIndex] = _tabs[tabIndex].copyWith(components: updatedComponents);
          });
        },
      ),
    );
  }

  void _editComponent(int tabIndex, int componentIndex) {
    final component = _tabs[tabIndex].components[componentIndex];
    
    showDialog(
      context: context,
      builder: (context) => ComponentEditor(
        component: component,
        onSave: (updatedComponent) {
          setState(() {
            final updatedComponents = List<PageComponent>.from(_tabs[tabIndex].components);
            updatedComponents[componentIndex] = updatedComponent;
            _tabs[tabIndex] = _tabs[tabIndex].copyWith(components: updatedComponents);
          });
        },
      ),
    );
  }

  void _removeComponent(int tabIndex, int componentIndex) {
    setState(() {
      final updatedComponents = List<PageComponent>.from(_tabs[tabIndex].components);
      updatedComponents.removeAt(componentIndex);
      _tabs[tabIndex] = _tabs[tabIndex].copyWith(components: updatedComponents);
    });
  }

  void _reorderComponents(int tabIndex, int oldIndex, int newIndex) {
    setState(() {
      final updatedComponents = List<PageComponent>.from(_tabs[tabIndex].components);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final component = updatedComponents.removeAt(oldIndex);
      updatedComponents.insert(newIndex, component);
      
      // Mettre à jour les ordres
      for (int i = 0; i < updatedComponents.length; i++) {
        updatedComponents[i] = updatedComponents[i].copyWith(order: i);
      }
      
      _tabs[tabIndex] = _tabs[tabIndex].copyWith(components: updatedComponents);
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
                  const Icon(Icons.tab, color: AppTheme.white100),
                  const SizedBox(width: AppTheme.space12),
                  const Expanded(
                    child: Text(
                      'Éditeur d\'onglets',
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

            // Onglets principaux
            Container(
              color: AppTheme.primaryColor, // Couleur d'arrière-plan identique à l'AppBar
              child: TabBar(
                controller: _mainTabController,
                labelColor: AppTheme.onPrimaryColor, // Texte blanc sur fond primaire
                unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7), // Texte blanc semi-transparent
                indicatorColor: AppTheme.onPrimaryColor, // Indicateur blanc
                tabs: const [
                  Tab(text: 'Configuration'),
                  Tab(text: 'Composants'),
                ],
              ),
            ),

            // Contenu des onglets principaux
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
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
                  const SizedBox(width: AppTheme.spaceMedium),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                    ),
                    child: const Text('Enregistrer'),
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
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration générale des onglets
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration générale',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    // Position des onglets
                    Text('Position des onglets', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppTheme.spaceSmall),
                    DropdownButtonFormField<String>(
                      value: _componentData['tabPosition'],
                      items: const [
                        DropdownMenuItem(value: 'top', child: Text('En haut')),
                        DropdownMenuItem(value: 'bottom', child: Text('En bas')),
                        DropdownMenuItem(value: 'left', child: Text('À gauche')),
                        DropdownMenuItem(value: 'right', child: Text('À droite')),
                      ],
                      onChanged: (value) => setState(() => _componentData['tabPosition'] = value),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    // Afficher les icônes
                    SwitchListTile(
                      title: const Text('Afficher les icônes'),
                      value: _componentData['showIcons'] ?? true,
                      onChanged: (value) => setState(() => _componentData['showIcons'] = value),
                    ),
                    
                    // Style des onglets
                    Text('Style des onglets', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: AppTheme.spaceSmall),
                    DropdownButtonFormField<String>(
                      value: _componentData['tabStyle'],
                      items: const [
                        DropdownMenuItem(value: 'material', child: Text('Material')),
                        DropdownMenuItem(value: 'cupertino', child: Text('Cupertino')),
                        DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
                      ],
                      onChanged: (value) => setState(() => _componentData['tabStyle'] = value),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Style et apparence
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style et apparence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    // Couleur de fond
                    Row(
                      children: [
                        Expanded(
                          child: Text('Couleur de fond', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_componentStyling['backgroundColor']!.substring(1), radix: 16) + 0xFF000000),
                            border: Border.all(color: AppTheme.grey500),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    TextFormField(
                      initialValue: _componentStyling['backgroundColor'],
                      decoration: const InputDecoration(
                        labelText: 'Code couleur (ex: #FFFFFF)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _componentStyling['backgroundColor'] = value),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    // Couleur de l'indicateur
                    Row(
                      children: [
                        Expanded(
                          child: Text('Couleur de l\'indicateur', style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_componentStyling['indicatorColor']!.substring(1), radix: 16) + 0xFF000000),
                            border: Border.all(color: AppTheme.grey500),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    TextFormField(
                      initialValue: _componentStyling['indicatorColor'],
                      decoration: const InputDecoration(
                        labelText: 'Code couleur (ex: #1976D2)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _componentStyling['indicatorColor'] = value),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Gestion des onglets
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Liste des onglets',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: AppTheme.fontBold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addTab,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.white100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    
                    // Liste des onglets
                    ..._tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(tab.icon),
                          title: Text(tab.title),
                          subtitle: Text('${tab.components.length} composant(s)'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editTab(index),
                                icon: const Icon(Icons.edit),
                                tooltip: 'Modifier l\'onglet',
                              ),
                              IconButton(
                                onPressed: () => _removeTab(index),
                                icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                                tooltip: 'Supprimer l\'onglet',
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentsTab() {
    return Column(
      children: [
        // Sélecteur d'onglet
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.grey500,
            border: Border(bottom: BorderSide(color: AppTheme.grey500)),
          ),
          child: Row(
            children: [
              const Text(
                'Onglet sélectionné:',
                style: TextStyle(fontWeight: AppTheme.fontBold),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedTabIndex,
                  items: _tabs.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value.title),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTabIndex = value!;
                      _tabsPreviewController.animateTo(_selectedTabIndex);
                    });
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              ElevatedButton.icon(
                onPressed: () => _addComponentToTab(_selectedTabIndex),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter composant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                ),
              ),
            ],
          ),
        ),
        
        // Contenu de l'onglet sélectionné
        Expanded(
          child: _buildTabContent(_selectedTabIndex),
        ),
      ],
    );
  }

  Widget _buildTabContent(int tabIndex) {
    final tab = _tabs[tabIndex];
    
    if (tab.components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.widgets_outlined,
              size: 64,
              color: AppTheme.grey500,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucun composant dans cet onglet',
              style: TextStyle(
                color: AppTheme.grey500,
                fontSize: AppTheme.fontSize16,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ElevatedButton.icon(
              onPressed: () => _addComponentToTab(tabIndex),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
              ),
            ),
          ],
        ),
      );
    }
    
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: tab.components.length,
      onReorder: (oldIndex, newIndex) => _reorderComponents(tabIndex, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final component = tab.components[index];
        return Card(
          key: ValueKey(component.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _getComponentIcon(component.type),
            title: Text(component.name),
            subtitle: Text(_getComponentTypeDisplayName(component.type)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editComponent(tabIndex, index),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier le composant',
                ),
                IconButton(
                  onPressed: () => _removeComponent(tabIndex, index),
                  icon: const Icon(Icons.delete, color: AppTheme.redStandard),
                  tooltip: 'Supprimer le composant',
                ),
                const Icon(Icons.drag_handle, color: AppTheme.grey500),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _getDefaultComponentName(String componentType) {
    switch (componentType) {
      case 'text':
        return 'Texte';
      case 'image':
        return 'Image';
      case 'button':
        return 'Bouton';
      case 'list':
        return 'Liste';
      case 'form':
        return 'Formulaire';
      case 'video':
        return 'Vidéo';
      case 'audio':
        return 'Audio';
      case 'tabs':
        return 'Onglets';
      case 'grid_container':
        return 'Container Grid';
      default:
        return 'Composant';
    }
  }

  Map<String, dynamic> _getDefaultComponentData(String componentType) {
    switch (componentType) {
      case 'text':
        return {
          'content': 'Nouveau texte',
          'textAlign': 'left',
        };
      case 'image':
        return {
          'src': '',
          'alt': 'Image',
          'width': 200.0,
          'height': 200.0,
        };
      case 'button':
        return {
          'text': 'Bouton',
          'action': 'none',
        };
      case 'list':
        return {
          'items': ['Élément 1', 'Élément 2'],
          'listType': 'bullet',
        };
      case 'form':
        return {
          'fields': [],
          'submitText': 'Envoyer',
        };
      case 'video':
        return {
          'src': '',
          'autoplay': false,
          'controls': true,
        };
      case 'audio':
        return {
          'src': '',
          'autoplay': false,
          'controls': true,
        };
      case 'tabs':
        return {
          'tabs': [],
          'tabPosition': 'top',
          'showIcons': true,
          'tabStyle': 'material',
        };
      case 'grid_container':
        return {
          'columns': 2,
          'mainAxisSpacing': 12.0,
          'crossAxisSpacing': 12.0,
          'childAspectRatio': 1.0,
          'padding': 16.0,
          'autoHeight': true,
          'maxHeight': 400.0,
        };
      default:
        return {};
    }
  }

  Icon _getComponentIcon(String componentType) {
    switch (componentType) {
      case 'text':
        return const Icon(Icons.text_fields);
      case 'image':
        return const Icon(Icons.image);
      case 'button':
        return const Icon(Icons.smart_button);
      case 'list':
        return const Icon(Icons.list);
      case 'form':
        return const Icon(Icons.dynamic_form);
      case 'video':
        return const Icon(Icons.video_library);
      case 'audio':
        return const Icon(Icons.audio_file);
      case 'tabs':
        return const Icon(Icons.tab);
      case 'grid_container':
        return const Icon(Icons.grid_view);
      default:
        return const Icon(Icons.widgets);
    }
  }

  String _getComponentTypeDisplayName(String componentType) {
    switch (componentType) {
      case 'text':
        return 'Texte';
      case 'image':
        return 'Image';
      case 'button':
        return 'Bouton';
      case 'list':
        return 'Liste';
      case 'form':
        return 'Formulaire';
      case 'video':
        return 'Vidéo';
      case 'audio':
        return 'Audio';
      case 'tabs':
        return 'Onglets';
      case 'grid_container':
        return 'Container Grid';
      default:
        return 'Composant';
    }
  }
}

/// Dialog pour éditer un onglet
class _TabEditDialog extends StatefulWidget {
  final TabData tab;
  final Function(TabData) onSave;

  const _TabEditDialog({required this.tab, required this.onSave});

  @override
  State<_TabEditDialog> createState() => _TabEditDialogState();
}

class _TabEditDialogState extends State<_TabEditDialog> {
  late TextEditingController _titleController;
  late IconData _selectedIcon;

  final List<IconData> _availableIcons = [
    Icons.tab, Icons.home, Icons.person, Icons.settings, Icons.info,
    Icons.help, Icons.star, Icons.favorite, Icons.bookmark,
    Icons.calendar_today, Icons.phone, Icons.mail, Icons.location_on,
    Icons.photo, Icons.video_library, Icons.music_note, Icons.description,
    Icons.folder, Icons.cloud, Icons.dashboard, Icons.analytics,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tab.title);
    _selectedIcon = widget.tab.icon;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le titre ne peut pas être vide'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
      return;
    }

    final updatedTab = widget.tab.copyWith(
      title: _titleController.text.trim(),
      icon: _selectedIcon,
    );

    widget.onSave(updatedTab);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier l\'onglet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre de l\'onglet',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          const Text('Icône de l\'onglet'),
          const SizedBox(height: AppTheme.spaceSmall),
          Container(
            height: 200,
            width: double.maxFinite,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.grey500),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _availableIcons.length,
              itemBuilder: (context, index) {
                final icon = _availableIcons[index];
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? AppTheme.white100 : AppTheme.grey500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Dialog pour sélectionner le type de composant à ajouter
class _ComponentTypeSelector extends StatelessWidget {
  final Function(String) onComponentTypeSelected;

  _ComponentTypeSelector({required this.onComponentTypeSelected});

  final Map<String, List<Map<String, dynamic>>> _componentCategories = {
    'Contenu textuel': [
      {'type': 'text', 'label': 'Texte', 'icon': Icons.text_fields, 'color': AppTheme.blueStandard, 'description': 'Paragraphe de texte avec formatage'},
      {'type': 'scripture', 'label': 'Verset biblique', 'icon': Icons.menu_book, 'color': AppTheme.secondaryColor, 'description': 'Citation biblique avec référence'},
      {'type': 'banner', 'label': 'Bannière', 'icon': Icons.campaign, 'color': AppTheme.warningColor, 'description': 'Message d\'annonce avec style'},
      {'type': 'quote', 'label': 'Citation', 'icon': Icons.format_quote, 'color': AppTheme.primaryDark, 'description': 'Citation avec auteur et contexte'},
    ],
    'Médias': [
      {'type': 'image', 'label': 'Image', 'icon': Icons.image, 'color': AppTheme.greenStandard, 'description': 'Photo ou illustration'},
      {'type': 'video', 'label': 'Vidéo', 'icon': Icons.video_library, 'color': AppTheme.redStandard, 'description': 'Vidéo YouTube ou fichier'},
      {'type': 'audio', 'label': 'Audio', 'icon': Icons.music_note, 'color': AppTheme.pinkStandard, 'description': 'Fichier audio ou musique'},
    ],
    'Interactif': [
      {'type': 'button', 'label': 'Bouton', 'icon': Icons.smart_button, 'color': AppTheme.orangeStandard, 'description': 'Bouton d\'action cliquable'},
      {'type': 'html', 'label': 'HTML', 'icon': Icons.code, 'color': AppTheme.infoColor, 'description': 'Code HTML personnalisé'},
      {'type': 'webview', 'label': 'WebView', 'icon': Icons.web, 'color': AppTheme.blueStandard, 'description': 'Intégrer une page web externe dans votre application'},
    ],
    'Organisation': [
      {'type': 'list', 'label': 'Liste', 'icon': Icons.list, 'color': AppTheme.primaryColor, 'description': 'Liste d\'éléments à puces ou numérotée'},
      {'type': 'grid_container', 'label': 'Container Grid', 'icon': Icons.grid_view, 'color': AppTheme.primaryDark, 'description': 'Container configurable pour organiser des composants en grille'},
      {'type': 'map', 'label': 'Carte', 'icon': Icons.map, 'color': AppTheme.tertiaryColor, 'description': 'Carte géographique interactive'},
      {'type': 'googlemap', 'label': 'Google Map', 'icon': Icons.location_on, 'color': AppTheme.redStandard, 'description': 'Carte Google avec reconnaissance d\'adresse'},
      {'type': 'groups', 'label': 'Groupes', 'icon': Icons.groups, 'color': AppTheme.warningColor, 'description': 'Affichage et gestion des groupes d\'utilisateurs'},
      {'type': 'events', 'label': 'Evénements', 'icon': Icons.event, 'color': AppTheme.greenStandard, 'description': 'Calendrier et liste d\'événements'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    // Créer une liste plate de tous les composants
    List<Map<String, dynamic>> allComponents = [];
    _componentCategories.forEach((category, components) {
      allComponents.addAll(components);
    });

    return AlertDialog(
      title: const Text('Ajouter un composant'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
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
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize16,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.black100,
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
