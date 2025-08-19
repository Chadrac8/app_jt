import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/modules/vie_eglise/models/pour_vous_action.dart';

void main() {
  group('Pour Vous Module Tests (Unit Tests)', () {
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
      expect(defaultActions[4].title, 'Poser une question au pasteur');
      expect(defaultActions[5].title, 'Proposer une idée');
      expect(defaultActions[6].title, 'Chanter un chant spécial');
      expect(defaultActions[7].title, 'Informations sur l\'église');
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

    test('PourVousAction toFirestore', () {
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

    group('Icon Mapping Tests', () {
      test('All default actions have valid icons', () {
        final defaultActions = PourVousAction.getDefaultActions();
        
        for (final action in defaultActions) {
          expect(action.icon, isNotNull);
          expect(action.icon, isA<IconData>());
          expect(action.iconCodePoint, isNotNull);
          expect(action.iconCodePoint, isNotEmpty);
        }
      });

      test('Icon codes are properly stored', () {
        final baptismAction = PourVousAction.getDefaultActions()
            .firstWhere((action) => action.title == 'Prendre le baptême');
        
        expect(baptismAction.icon.codePoint, Icons.water_drop.codePoint);
        expect(baptismAction.iconCodePoint, Icons.water_drop.codePoint.toString());
        
        final pastorAction = PourVousAction.getDefaultActions()
            .firstWhere((action) => action.title == 'Rendez-vous avec le pasteur');
        
        expect(pastorAction.icon.codePoint, Icons.person_add.codePoint);
        expect(pastorAction.iconCodePoint, Icons.person_add.codePoint.toString());
      });
    });

    group('Navigation Tests', () {
      test('Action navigation mapping', () {
        final actions = PourVousAction.getDefaultActions();
        
        // Vérifier que chaque action a une navigation définie
        final baptismAction = actions.firstWhere(
          (action) => action.title == 'Prendre le baptême'
        );
        expect(baptismAction.actionType, 'form');
        
        final teamAction = actions.firstWhere(
          (action) => action.title == 'Rejoindre une équipe'
        );
        expect(teamAction.actionType, 'navigation');
        expect(teamAction.targetModule, 'groupes');
        
        final prayerAction = actions.firstWhere(
          (action) => action.title == 'Requêtes de prière'
        );
        expect(prayerAction.actionType, 'navigation');
        expect(prayerAction.targetModule, 'mur_priere');
      });
    });

    group('Admin Features Tests', () {
      test('Action reordering logic', () {
        final actions = PourVousAction.getDefaultActions();
        
        // Simuler un réordonnancement
        final reorderedActions = List<PourVousAction>.from(actions);
        final firstAction = reorderedActions.removeAt(0);
        reorderedActions.insert(2, firstAction);
        
        // Vérifier que les ordres sont différents après réordonnancement
        expect(reorderedActions[0].order, isNot(equals(actions[0].order)));
        expect(reorderedActions[2].title, actions[0].title);
      });

      test('Action status toggle', () {
        final action = PourVousAction.getDefaultActions().first;
        final toggledAction = action.copyWith(isActive: !action.isActive);
        
        expect(toggledAction.isActive, isNot(equals(action.isActive)));
      });

      test('Action colors are properly set', () {
        final actions = PourVousAction.getDefaultActions();
        
        for (final action in actions) {
          expect(action.color, isNotNull);
          expect(action.color, startsWith('#'));
          expect(action.color!.length, 7); // Format #RRGGBB
        }
      });
    });

    group('Action Types Tests', () {
      test('Form actions have correct type', () {
        final actions = PourVousAction.getDefaultActions();
        
        final formActions = actions.where((a) => a.actionType == 'form').toList();
        expect(formActions.length, greaterThan(0));
        
        final baptismAction = formActions.firstWhere(
          (action) => action.title == 'Prendre le baptême'
        );
        expect(baptismAction.actionType, 'form');
      });

      test('Navigation actions have target modules', () {
        final actions = PourVousAction.getDefaultActions();
        
        final navActions = actions.where((a) => a.actionType == 'navigation').toList();
        expect(navActions.length, greaterThan(0));
        
        for (final action in navActions) {
          expect(action.targetModule, isNotNull);
          expect(action.targetModule, isNotEmpty);
        }
      });
    });

    group('Data Validation Tests', () {
      test('All default actions have required fields', () {
        final actions = PourVousAction.getDefaultActions();
        
        for (final action in actions) {
          expect(action.id, isNotNull);
          expect(action.id, isNotEmpty);
          expect(action.title, isNotNull);
          expect(action.title, isNotEmpty);
          expect(action.description, isNotNull);
          expect(action.description, isNotEmpty);
          expect(action.icon, isNotNull);
          expect(action.iconCodePoint, isNotNull);
          expect(action.iconCodePoint, isNotEmpty);
          expect(action.isActive, isTrue);
          expect(action.order, greaterThan(0));
          expect(action.createdAt, isNotNull);
          expect(action.updatedAt, isNotNull);
        }
      });

      test('Actions have unique IDs', () {
        final actions = PourVousAction.getDefaultActions();
        final ids = actions.map((a) => a.id).toList();
        final uniqueIds = ids.toSet();
        
        expect(uniqueIds.length, equals(ids.length));
      });

      test('Actions have sequential order', () {
        final actions = PourVousAction.getDefaultActions();
        
        for (int i = 0; i < actions.length; i++) {
          expect(actions[i].order, equals(i + 1));
        }
      });
    });
  });
}
