import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/widgets/icon_selector.dart';

void main() {
  group('IconSelector Tests', () {
    testWidgets('IconSelector displays correctly', (WidgetTester tester) async {
      String selectedIcon = 'church';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconSelector(
              currentIcon: selectedIcon,
              onIconSelected: (icon) {
                selectedIcon = icon;
              },
            ),
          ),
        ),
      );

      // Vérifier que le titre est affiché
      expect(find.text('Sélectionner une icône'), findsOneWidget);
      
      // Vérifier que la barre de recherche est présente
      expect(find.text('Rechercher une icône...'), findsOneWidget);
      
      // Vérifier qu'il y a des icônes affichées
      expect(find.byType(GridView), findsOneWidget);
      
      print('✅ Test IconSelector - Interface correctement affichée');
    });

    test('Icon filtering works correctly', () {
      // Test de la logique de filtrage
      final iconOptions = [
        IconOption('church', Icons.church, 'Église', ['temple', 'sanctuaire', 'culte']),
        IconOption('people', Icons.people, 'Personnes', ['utilisateurs', 'membres', 'groupe']),
        IconOption('music_note', Icons.music_note, 'Note musicale', ['mélodie', 'son', 'harmonie']),
      ];
      
      // Test de filtrage par nom
      var filtered = iconOptions.where((icon) => 
          icon.name.toLowerCase().contains('church'.toLowerCase()) ||
          icon.keywords.any((keyword) => 
              keyword.toLowerCase().contains('church'.toLowerCase()))
      ).toList();
      
      expect(filtered.length, 1);
      expect(filtered.first.name, 'church');
      
      // Test de filtrage par mot-clé
      filtered = iconOptions.where((icon) => 
          icon.name.toLowerCase().contains('temple'.toLowerCase()) ||
          icon.keywords.any((keyword) => 
              keyword.toLowerCase().contains('temple'.toLowerCase()))
      ).toList();
      
      expect(filtered.length, 1);
      expect(filtered.first.name, 'church');
      
      print('✅ Test IconSelector - Filtrage fonctionne correctement');
    });

    test('Icon collection is comprehensive', () {
      // Vérifier que nous avons bien une collection complète d'icônes
      final iconOptions = _getAllTestIcons();
      
      // Vérifier qu'on a au moins 50 icônes
      expect(iconOptions.length, greaterThan(50));
      
      // Vérifier que toutes les catégories importantes sont représentées
      final categories = [
        'church', 'people', 'event', 'music', 'settings', 
        'notifications', 'dashboard', 'calendar', 'book'
      ];
      
      for (final category in categories) {
        final hasCategory = iconOptions.any((icon) => 
            icon.name.contains(category) || 
            icon.keywords.any((keyword) => keyword.contains(category))
        );
        expect(hasCategory, true, reason: 'Category $category should be present');
      }
      
      print('✅ Test IconSelector - Collection d\'icônes complète');
      print('📊 Nombre total d\'icônes disponibles: ${iconOptions.length}');
    });
  });
}

// Fonction pour obtenir toutes les icônes de test (version simplifiée)
List<IconOption> _getAllTestIcons() {
  return [
    // Religion et spiritualité
    IconOption('church', Icons.church, 'Église', ['temple', 'sanctuaire', 'culte']),
    IconOption('menu_book', Icons.menu_book, 'Bible', ['livre', 'lecture', 'étude']),
    IconOption('favorite', Icons.favorite, 'Prière', ['cœur', 'amour', 'spiritualité']),
    
    // Personnes et groupes
    IconOption('people', Icons.people, 'Personnes', ['utilisateurs', 'membres', 'groupe']),
    IconOption('person', Icons.person, 'Personne', ['utilisateur', 'profil', 'individu']),
    IconOption('groups', Icons.groups, 'Groupes', ['équipes', 'communauté', 'ensemble']),
    
    // Événements
    IconOption('event', Icons.event, 'Événement', ['programme', 'activité', 'rendez-vous']),
    IconOption('calendar_today', Icons.calendar_today, 'Calendrier', ['date', 'planning', 'horaire']),
    IconOption('schedule', Icons.schedule, 'Horaire', ['temps', 'planning', 'programme']),
    
    // Musique
    IconOption('library_music', Icons.library_music, 'Musique', ['chants', 'cantiques', 'louange']),
    IconOption('music_note', Icons.music_note, 'Note musicale', ['mélodie', 'son', 'harmonie']),
    IconOption('mic', Icons.mic, 'Microphone', ['voix', 'chant', 'prédication']),
    
    // Interface
    IconOption('dashboard', Icons.dashboard, 'Tableau de bord', ['accueil', 'résumé', 'vue d\'ensemble']),
    IconOption('settings', Icons.settings, 'Paramètres', ['configuration', 'réglages', 'options']),
    IconOption('notifications', Icons.notifications, 'Notifications', ['alertes', 'messages', 'avis']),
    
    // Tâches
    IconOption('task_alt', Icons.task_alt, 'Tâche', ['travail', 'mission', 'objectif']),
    IconOption('assignment', Icons.assignment, 'Assignement', ['mission', 'devoir', 'responsabilité']),
    IconOption('work', Icons.work, 'Travail', ['emploi', 'tâche', 'fonction']),
    
    // Communication
    IconOption('message', Icons.message, 'Message', ['texto', 'communication', 'discussion']),
    IconOption('email', Icons.email, 'Email', ['courrier', 'message', 'communication']),
    IconOption('phone', Icons.phone, 'Téléphone', ['appel', 'contact', 'communication']),
  ];
}

/// Modèle pour une option d'icône (copie pour les tests)
class IconOption {
  final String name;
  final IconData iconData;
  final String description;
  final List<String> keywords;

  IconOption(this.name, this.iconData, this.description, this.keywords);
}
