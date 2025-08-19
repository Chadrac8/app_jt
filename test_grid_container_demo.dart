import 'package:flutter/material.dart';
import 'lib/models/page_model.dart';
import 'lib/widgets/page_components/component_renderer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Container Grid',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TestGridContainerPage(),
    );
  }
}

class TestGridContainerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Créer un composant Grid Container de test avec des composants enfants
    final gridContainerComponent = PageComponent(
      id: 'test_grid_container',
      type: 'grid_container',
      name: 'Test Grid Container',
      order: 0,
      data: {
        'columns': 3,
        'mainAxisSpacing': 16.0,
        'crossAxisSpacing': 16.0,
        'childAspectRatio': 1.0,
        'padding': 20.0,
        'autoHeight': true,
        'maxHeight': 400.0,
      },
      styling: {
        'backgroundColor': '#F5F5F5',
        'borderColor': '#E0E0E0',
        'borderWidth': 2.0,
        'borderRadius': 12.0,
        'elevation': 4.0,
      },
      children: [
        PageComponent(
          id: 'card_1',
          type: 'grid_card',
          name: 'Carte 1',
          order: 0,
          data: {
            'title': 'Bienvenue',
            'subtitle': 'Communauté',
            'description': 'Rejoignez notre église',
            'iconName': 'church',
            'backgroundColor': '#6F61EF',
            'textColor': '#FFFFFF',
          },
          styling: {},
        ),
        PageComponent(
          id: 'stat_1',
          type: 'grid_stat',
          name: 'Statistique 1',
          order: 1,
          data: {
            'title': 'Membres',
            'value': '350',
            'unit': 'personnes',
            'trend': 'up',
            'color': '#4CAF50',
            'iconName': 'people',
          },
          styling: {},
        ),
        PageComponent(
          id: 'icon_text_1',
          type: 'grid_icon_text',
          name: 'Culte',
          order: 2,
          data: {
            'iconName': 'schedule',
            'title': 'Culte Dominical',
            'description': 'Dimanche 10h00',
            'iconColor': '#FF5722',
            'textAlign': 'center',
          },
          styling: {},
        ),
        PageComponent(
          id: 'progress_1',
          type: 'grid_progress',
          name: 'Objectif',
          order: 3,
          data: {
            'title': 'Collecte de fonds',
            'progress': 0.75,
            'showPercentage': true,
            'color': '#2196F3',
            'backgroundColor': '#E3F2FD',
          },
          styling: {},
        ),
        PageComponent(
          id: 'text_1',
          type: 'text',
          name: 'Citation du jour',
          order: 4,
          data: {
            'content': 'Car Dieu a tant aimé le monde...',
            'fontSize': 14,
            'textAlign': 'center',
            'fontWeight': 'bold',
          },
          styling: {},
        ),
        PageComponent(
          id: 'button_1',
          type: 'button',
          name: 'Action',
          order: 5,
          data: {
            'text': 'S\'inscrire',
            'url': '',
            'style': 'primary',
            'size': 'medium',
          },
          styling: {},
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Container Grid'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test du composant Container Grid',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ce container grid affiche 6 composants différents organisés en 3 colonnes :',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Grid Card\n• Grid Stat\n• Grid Icon Text\n• Grid Progress\n• Text\n• Button',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ComponentRenderer(
              component: gridContainerComponent,
              isPreview: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Fonctionnalités du Container Grid :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '✅ Nombre de colonnes configurable (1-6)\n'
              '✅ Espacement personnalisable\n'
              '✅ Ratio hauteur/largeur ajustable\n'
              '✅ Tous les composants supportés\n'
              '✅ Style et apparence personnalisables\n'
              '✅ Hauteur automatique ou fixe\n'
              '✅ Éditeur avancé intégré',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
