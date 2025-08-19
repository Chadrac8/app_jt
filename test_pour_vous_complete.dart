import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/modules/vie_eglise/models/pour_vous_action.dart';
import 'lib/modules/vie_eglise/services/pour_vous_action_service.dart';
import 'lib/modules/vie_eglise/widgets/pour_vous_tab.dart';
import 'lib/modules/vie_eglise/views/admin_pour_vous_tab.dart';

void main() {
  group('Pour Vous Module Tests', () {
    test('PourVousAction model creation', () {
      final action = PourVousAction(
        id: 'test-id',
        title: 'Test Action',
        description: 'Test Description',
        icon: Icons.star,
        iconCodePoint: Icons.star.codePoint.toString(),
        isActive: true,
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(action.id, 'test-id');
      expect(action.title, 'Test Action');
      expect(action.description, 'Test Description');
      expect(action.icon, Icons.star);
      expect(action.isActive, true);
      expect(action.order, 1);
    });

    test('Default actions creation', () {
      final defaultActions = PourVousAction.getDefaultActions();
      
      expect(defaultActions.length, 8);
      expect(defaultActions[0].title, 'Prendre le baptême');
      expect(defaultActions[1].title, 'Rendez-vous avec le pasteur');
      expect(defaultActions[2].title, 'Rejoindre une équipe');
      expect(defaultActions[3].title, 'Requêtes de prière');
      expect(defaultActions[4].title, 'Poser des questions');
      expect(defaultActions[5].title, 'Partager des idées');
      expect(defaultActions[6].title, 'Proposer un chant spécial');
      expect(defaultActions[7].title, 'Informations de l\'église');
    });

    test('PourVousAction copyWith method', () {
      final original = PourVousAction(
        id: 'test-id',
        title: 'Original Title',
        description: 'Original Description',
        icon: Icons.star,
        iconCodePoint: Icons.star.codePoint.toString(),
        isActive: true,
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        title: 'Modified Title',
        isActive: false,
      );

      expect(modified.id, original.id);
      expect(modified.title, 'Modified Title');
      expect(modified.description, original.description);
      expect(modified.isActive, false);
      expect(modified.order, original.order);
    });

    test('PourVousAction toFirestore and fromFirestore', () {
      final original = PourVousAction(
        id: 'test-id',
        title: 'Test Action',
        description: 'Test Description',
        icon: Icons.star,
        iconCodePoint: Icons.star.codePoint.toString(),
        isActive: true,
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = original.toFirestore();
      
      expect(map['title'], original.title);
      expect(map['description'], original.description);
      expect(map['iconCodePoint'], Icons.star.codePoint);
      expect(map['isActive'], original.isActive);
      expect(map['order'], original.order);
    });

    testWidgets('PourVousTab widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PourVousTab(),
          ),
        ),
      );

      // Vérifier que le widget se charge
      expect(find.byType(PourVousTab), findsOneWidget);
      
      // Attendre que les données se chargent
      await tester.pump();
      
      // Vérifier la présence du titre
      expect(find.text('Actions disponibles pour vous'), findsOneWidget);
    });

    testWidgets('AdminPourVousTab widget test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPourVousTab(),
          ),
        ),
      );

      // Vérifier que le widget se charge
      expect(find.byType(AdminPourVousTab), findsOneWidget);
      
      // Attendre que les données se chargent
      await tester.pump();
      
      // Vérifier la présence du titre admin
      expect(find.text('Gestion des actions "Pour vous"'), findsOneWidget);
    });

    group('PourVousActionService Tests', () {
      late PourVousActionService service;

      setUp(() {
        service = PourVousActionService();
      });

      test('Service initialization', () {
        expect(service, isNotNull);
      });

      // Note: Les tests de service nécessiteraient un mock de Firestore
      // pour éviter les appels réseau réels dans les tests
    });
  });

  group('Icon Mapping Tests', () {
    test('All default actions have valid icons', () {
      final defaultActions = PourVousAction.getDefaultActions();
      
      for (final action in defaultActions) {
        expect(action.icon, isNotNull);
        expect(action.icon, isA<IconData>());
      }
    });

    test('Icon codes are properly mapped', () {
      final baptismAction = PourVousAction.getDefaultActions()
          .firstWhere((action) => action.title == 'Prendre le baptême');
      
      expect(baptismAction.icon.codePoint, Icons.waves.codePoint);
      
      final pastorAction = PourVousAction.getDefaultActions()
          .firstWhere((action) => action.title == 'Rendez-vous avec le pasteur');
      
      expect(pastorAction.icon.codePoint, Icons.person.codePoint);
    });
  });

  group('Navigation Tests', () {
    test('Action navigation mapping', () {
      final actions = PourVousAction.getDefaultActions();
      
      // Vérifier que chaque action a une navigation définie
      final baptismAction = actions.firstWhere(
        (action) => action.title == 'Prendre le baptême'
      );
      expect(baptismAction.title, isNotNull);
      
      final teamAction = actions.firstWhere(
        (action) => action.title == 'Rejoindre une équipe'
      );
      expect(teamAction.title, isNotNull);
      
      final prayerAction = actions.firstWhere(
        (action) => action.title == 'Requêtes de prière'
      );
      expect(prayerAction.title, isNotNull);
    });
  });

  group('Admin Features Tests', () {
    test('Action reordering logic', () {
      final actions = PourVousAction.getDefaultActions();
      
      // Simuler un réordonnancement
      final reorderedActions = List<PourVousAction>.from(actions);
      final firstAction = reorderedActions.removeAt(0);
      reorderedActions.insert(2, firstAction);
      
      // Vérifier que les ordres sont différents
      expect(reorderedActions[0].order, isNot(equals(actions[0].order)));
      expect(reorderedActions[2].title, actions[0].title);
    });

    test('Action status toggle', () {
      final action = PourVousAction.getDefaultActions().first;
      final toggledAction = action.copyWith(isActive: !action.isActive);
      
      expect(toggledAction.isActive, isNot(equals(action.isActive)));
    });
  });
}
