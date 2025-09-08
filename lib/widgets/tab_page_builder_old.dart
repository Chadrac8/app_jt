import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/page_model.dart';
import 'custom_tabs_widget.dart';
import 'page_components/component_editor.dart';
import 'page_components/component_renderer.dart';
import '../theme.dart';

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
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
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
      _selectedTabIndex = _tabs.length - 1;
    });
  }

  void _removeTab(int index) {
    if (_tabs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il faut au moins un onglet'),
          backgroundColor: Colors.orange,
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
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tab, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Éditeur d\'onglets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Onglets principaux
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _mainTabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppTheme.primaryColor,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuration générale des onglets
          _buildSection(
            title: 'Configuration générale',
            icon: Icons.tab,
            children: [
              // Position des onglets
              Text('Position des onglets', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _componentData['tabPosition'],
                items: const [
                  DropdownMenuItem(value: 'top', child: Text('En haut')),
                  DropdownMenuItem(value: 'bottom', child: Text('En bas')),
                  DropdownMenuItem(value: 'left', child: Text('À gauche')),
                  DropdownMenuItem(value: 'right', child: Text('À droite')),
                ],
                onChanged: (value) => setState(() => _componentData['tabPosition'] = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              
              // Afficher les icônes
              SwitchListTile(
                title: const Text('Afficher les icônes'),
                value: _componentData['showIcons'] ?? true,
                onChanged: (value) => setState(() => _componentData['showIcons'] = value),
                contentPadding: EdgeInsets.zero,
              ),
              
              // Style des onglets
              Text('Style des onglets', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _componentData['tabStyle'],
                items: const [
                  DropdownMenuItem(value: 'material', child: Text('Material')),
                  DropdownMenuItem(value: 'cupertino', child: Text('Cupertino')),
                  DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
                ],
                onChanged: (value) => setState(() => _componentData['tabStyle'] = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Style et apparence
          _buildSection(
            title: 'Style et apparence',
            icon: Icons.palette,
            children: [
              // Couleur de fond
              _buildColorField(
                label: 'Couleur de fond',
                value: _componentStyling['backgroundColor']!,
                onChanged: (value) => setState(() => _componentStyling['backgroundColor'] = value),
              ),
              const SizedBox(height: 16),
              
              // Couleur de l'indicateur
              _buildColorField(
                label: 'Couleur de l\'indicateur',
                value: _componentStyling['indicatorColor']!,
                onChanged: (value) => setState(() => _componentStyling['indicatorColor'] = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gestion des onglets
          _buildSection(
            title: 'Liste des onglets',
            icon: Icons.list,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_tabs.length} onglet(s) configuré(s)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  ElevatedButton.icon(
                    onPressed: _addTab,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter onglet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
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
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Supprimer l\'onglet',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsTab() {
    return Column(
      children: [
        // Sélecteur d'onglet
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tab, color: Colors.grey),
              const SizedBox(width: 12),
              const Text(
                'Onglet sélectionné:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedTabIndex,
                  items: _tabs.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Row(
                        children: [
                          Icon(entry.value.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(entry.value.title),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTabIndex = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _addComponentToTab(_selectedTabIndex),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter composant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun composant dans "${tab.title}"',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des composants pour créer le contenu',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addComponentToTab(tabIndex),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
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
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Supprimer le composant',
                ),
                const Icon(Icons.drag_handle, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildColorField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    Color color;
    try {
      color = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      color = Colors.white;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            labelText: 'Code couleur (ex: #FFFFFF)',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: onChanged,
        ),
      ],
    );
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
          backgroundColor: Colors.red,
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
          const SizedBox(height: 16),
          const Text('Icône de l\'onglet'),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.maxFinite,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
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
      {'type': 'text', 'label': 'Texte', 'icon': Icons.text_fields, 'color': Colors.blue, 'description': 'Paragraphe de texte avec formatage'},
      {'type': 'scripture', 'label': 'Verset biblique', 'icon': Icons.menu_book, 'color': Colors.indigo, 'description': 'Citation biblique avec référence'},
      {'type': 'banner', 'label': 'Bannière', 'icon': Icons.campaign, 'color': Colors.amber, 'description': 'Message d\'annonce avec style'},
      {'type': 'quote', 'label': 'Citation', 'icon': Icons.format_quote, 'color': Colors.deepPurple, 'description': 'Citation avec auteur et contexte'},
    ],
    'Médias': [
      {'type': 'image', 'label': 'Image', 'icon': Icons.image, 'color': Colors.green, 'description': 'Photo ou illustration'},
      {'type': 'video', 'label': 'Vidéo', 'icon': Icons.video_library, 'color': Colors.red, 'description': 'Vidéo YouTube ou fichier'},
      {'type': 'audio', 'label': 'Audio', 'icon': Icons.music_note, 'color': Colors.pink, 'description': 'Fichier audio ou musique'},
    ],
    'Interactif': [
      {'type': 'button', 'label': 'Bouton', 'icon': Icons.smart_button, 'color': Colors.orange, 'description': 'Bouton d\'action cliquable'},
      {'type': 'html', 'label': 'HTML', 'icon': Icons.code, 'color': Colors.cyan, 'description': 'Code HTML personnalisé'},
      {'type': 'webview', 'label': 'WebView', 'icon': Icons.web, 'color': Colors.blue, 'description': 'Intégrer une page web externe dans votre application'},
    ],
    'Organisation': [
      {'type': 'list', 'label': 'Liste', 'icon': Icons.list, 'color': Colors.purple, 'description': 'Liste d\'éléments à puces ou numérotée'},
      {'type': 'grid_container', 'label': 'Container Grid', 'icon': Icons.grid_view, 'color': Colors.deepPurple, 'description': 'Container configurable pour organiser des composants en grille'},
      {'type': 'map', 'label': 'Carte', 'icon': Icons.map, 'color': Colors.brown, 'description': 'Carte géographique interactive'},
      {'type': 'googlemap', 'label': 'Google Map', 'icon': Icons.location_on, 'color': Colors.redAccent, 'description': 'Carte Google avec reconnaissance d\'adresse'},
      {'type': 'groups', 'label': 'Groupes', 'icon': Icons.groups, 'color': Colors.deepOrange, 'description': 'Affichage et gestion des groupes d\'utilisateurs'},
      {'type': 'events', 'label': 'Evénements', 'icon': Icons.event, 'color': Colors.green, 'description': 'Calendrier et liste d\'événements'},
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                          borderRadius: BorderRadius.circular(8),
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
                                const SizedBox(height: 4),
                                Text(
                                  componentType['label'],
                                  style: const TextStyle(fontSize: 10),
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
                  const SizedBox(height: 16),
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
      case 'scripture':
        return 'Verset biblique';
      case 'banner':
        return 'Bannière';
      case 'quote':
        return 'Citation';
      case 'html':
        return 'HTML';
      case 'webview':
        return 'WebView';
      case 'map':
        return 'Carte';
      case 'googlemap':
        return 'Google Map';
      case 'groups':
        return 'Groupes';
      case 'events':
        return 'Evénements';
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
      case 'scripture':
        return {
          'verse': '',
          'reference': '',
          'version': 'LSG',
        };
      case 'banner':
        return {
          'message': 'Message important',
          'type': 'info',
        };
      case 'quote':
        return {
          'text': 'Citation',
          'author': 'Auteur',
        };
      case 'html':
        return {
          'content': '<p>Contenu HTML</p>',
        };
      case 'webview':
        return {
          'url': 'https://example.com',
          'height': 400.0,
        };
      case 'map':
        return {
          'latitude': 0.0,
          'longitude': 0.0,
          'zoom': 10.0,
        };
      case 'googlemap':
        return {
          'address': '',
          'zoom': 15.0,
        };
      case 'groups':
        return {
          'showAll': true,
          'maxItems': 10,
        };
      case 'events':
        return {
          'showPast': false,
          'maxItems': 5,
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
      case 'scripture':
        return const Icon(Icons.menu_book);
      case 'banner':
        return const Icon(Icons.campaign);
      case 'quote':
        return const Icon(Icons.format_quote);
      case 'html':
        return const Icon(Icons.code);
      case 'webview':
        return const Icon(Icons.web);
      case 'map':
        return const Icon(Icons.map);
      case 'googlemap':
        return const Icon(Icons.location_on);
      case 'groups':
        return const Icon(Icons.groups);
      case 'events':
        return const Icon(Icons.event);
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
      case 'scripture':
        return 'Verset biblique';
      case 'banner':
        return 'Bannière';
      case 'quote':
        return 'Citation';
      case 'html':
        return 'HTML';
      case 'webview':
        return 'WebView';
      case 'map':
        return 'Carte';
      case 'googlemap':
        return 'Google Map';
      case 'groups':
        return 'Groupes';
      case 'events':
        return 'Evénements';
      default:
        return 'Composant';
    }
  }
}
