import 'package:flutter/material.dart';
import 'lib/models/page_model.dart';
import 'lib/widgets/custom_tabs_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Composant Onglets',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TestTabsPage(),
    );
  }
}

class TestTabsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Créer un composant onglets de test avec des données par défaut
    final tabsComponent = PageComponent(
      id: 'test_tabs',
      type: 'tabs',
      name: 'Test Onglets',
      order: 0,
      data: {
        'tabPosition': 'top',
        'showIcons': true,
        'tabStyle': 'material',
        'height': 400.0,
        'tabs': [
          {
            'id': 'tab_1',
            'title': 'Accueil',
            'icon': 'home',
            'components': [
              {
                'id': 'text_1',
                'type': 'text',
                'name': 'Texte de bienvenue',
                'order': 0,
                'data': {
                  'content': 'Bienvenue dans le premier onglet !',
                  'fontSize': 18,
                  'textAlign': 'center',
                  'fontWeight': 'bold',
                },
                'styling': {},
              }
            ],
            'isVisible': true,
            'settings': {},
          },
          {
            'id': 'tab_2',
            'title': 'À propos',
            'icon': 'info',
            'components': [
              {
                'id': 'text_2',
                'type': 'text',
                'name': 'Texte à propos',
                'order': 0,
                'data': {
                  'content': 'Ceci est le deuxième onglet avec du contenu différent.',
                  'fontSize': 16,
                  'textAlign': 'left',
                  'fontWeight': 'normal',
                },
                'styling': {},
              },
              {
                'id': 'button_1',
                'type': 'button',
                'name': 'Bouton test',
                'order': 1,
                'data': {
                  'text': 'Cliquez ici',
                  'url': '',
                  'style': 'primary',
                  'size': 'medium',
                },
                'styling': {},
              }
            ],
            'isVisible': true,
            'settings': {},
          },
        ],
      },
      styling: {
        'backgroundColor': '#FFFFFF',
        'indicatorColor': '#1976D2',
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Composant Onglets'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test du composant Onglets',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ce composant doit afficher deux onglets avec du contenu différent :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: CustomTabsWidget(
                component: tabsComponent,
                isPreview: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
