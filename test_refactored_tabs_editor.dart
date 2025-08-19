import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'lib/models/page_model.dart';
import 'lib/widgets/tab_page_builder.dart';
import 'lib/theme.dart';

void main() {
  runApp(TabsEditorTestApp());
}

class TabsEditorTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Éditeur d\'Onglets Refactorisé',
      theme: AppTheme.lightTheme,
      home: TabsEditorDemo(),
    );
  }
}

class TabsEditorDemo extends StatefulWidget {
  @override
  State<TabsEditorDemo> createState() => _TabsEditorDemoState();
}

class _TabsEditorDemoState extends State<TabsEditorDemo> {
  final _uuid = const Uuid();
  late PageComponent _tabsComponent;

  @override
  void initState() {
    super.initState();
    _createDefaultTabsComponent();
  }

  void _createDefaultTabsComponent() {
    _tabsComponent = PageComponent(
      id: _uuid.v4(),
      type: 'tabs',
      name: 'Onglets de démonstration',
      order: 0,
      data: {
        'tabs': [
          {
            'id': _uuid.v4(),
            'title': 'Accueil',
            'icon': Icons.home.codePoint,
            'components': [
              {
                'id': _uuid.v4(),
                'type': 'text',
                'name': 'Texte d\'accueil',
                'order': 0,
                'data': {
                  'content': 'Bienvenue sur notre application!',
                  'textAlign': 'center',
                },
                'styling': {},
                'children': [],
              },
              {
                'id': _uuid.v4(),
                'type': 'button',
                'name': 'Bouton d\'action',
                'order': 1,
                'data': {
                  'text': 'Commencer',
                  'action': 'navigation',
                },
                'styling': {},
                'children': [],
              }
            ]
          },
          {
            'id': _uuid.v4(),
            'title': 'Informations',
            'icon': Icons.info.codePoint,
            'components': [
              {
                'id': _uuid.v4(),
                'type': 'text',
                'name': 'Description',
                'order': 0,
                'data': {
                  'content': 'Cette application vous permet de créer des pages dynamiques avec des composants variés.',
                  'textAlign': 'left',
                },
                'styling': {},
                'children': [],
              }
            ]
          }
        ],
        'tabPosition': 'top',
        'showIcons': true,
        'tabStyle': 'material',
        'height': 400.0,
      },
      styling: {
        'backgroundColor': '#FFFFFF',
        'indicatorColor': '#1976D2',
      },
    );
  }

  void _openTabsEditor() {
    showDialog(
      context: context,
      builder: (context) => TabPageBuilder(
        component: _tabsComponent,
        onSave: (updatedComponent) {
          setState(() {
            _tabsComponent = updatedComponent;
          });
          _showSuccessMessage();
        },
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Onglets mis à jour avec succès!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Éditeur d\'Onglets Refactorisé'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Éditeur d\'Onglets Refactorisé',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '✅ Interface à deux onglets : "Configuration" et "Composants"\n'
                      '✅ Onglet Configuration : paramètres généraux et style\n'
                      '✅ Onglet Composants : gestion des contenus de chaque onglet\n'
                      '✅ Sélection d\'onglet avec preview en temps réel\n'
                      '✅ Ajout/suppression/modification des composants\n'
                      '✅ Réorganisation par glisser-déposer\n'
                      '✅ Tous les types de composants disponibles\n'
                      '✅ Sauvegarde intégrée et gestion d\'état',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openTabsEditor,
                      icon: const Icon(Icons.edit),
                      label: const Text('Ouvrir l\'Éditeur d\'Onglets'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'État Actuel du Composant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildComponentSummary(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Améliorations de la Refactorisation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '🔄 Interface unifiée similaire au Container Grid\n'
                      '📊 Meilleure organisation avec onglets séparés\n'
                      '🎯 Configuration centralisée dans un onglet dédié\n'
                      '🧩 Gestion des composants simplifiée\n'
                      '🔧 Interface plus intuitive et cohérente\n'
                      '💾 Sauvegarde optimisée et fiable\n'
                      '🎨 Design moderne et responsive',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentSummary() {
    final tabs = _tabsComponent.data['tabs'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tab, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Nom: ${_tabsComponent.name}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.layers, color: Colors.green),
            const SizedBox(width: 8),
            Text('Nombre d\'onglets: ${tabs.length}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Position: ${_tabsComponent.data['tabPosition'] ?? 'top'}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.style, color: Colors.purple),
            const SizedBox(width: 8),
            Text('Style: ${_tabsComponent.data['tabStyle'] ?? 'material'}'),
          ],
        ),
        const SizedBox(height: 12),
        if (tabs.isNotEmpty) ...[
          const Text(
            'Onglets configurés:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value as Map<String, dynamic>;
            final components = tab['components'] as List<dynamic>? ?? [];
            
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text('${index + 1}. '),
                  Icon(
                    IconData(tab['icon'] ?? Icons.tab.codePoint, fontFamily: 'MaterialIcons'),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text('${tab['title']} (${components.length} composant${components.length > 1 ? 's' : ''})'),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
