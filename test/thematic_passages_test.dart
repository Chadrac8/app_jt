import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/modules/bible/services/predefined_themes.dart';
import '../lib/modules/bible/models/thematic_passage_model.dart';

void main() {
  group('Passages Thématiques Tests', () {
    
    test('PredefinedThemes should return 10 themes', () {
      final themes = PredefinedThemes.getDefaultThemes();
      expect(themes.length, equals(10));
    });

    test('Each theme should have required fields', () {
      final themes = PredefinedThemes.getDefaultThemes();
      
      for (final themeData in themes) {
        expect(themeData['name'], isNotNull);
        expect(themeData['description'], isNotNull);
        expect(themeData['color'], isNotNull);
        expect(themeData['iconCodePoint'], isNotNull);
        expect(themeData['iconFontFamily'], isNotNull);
        expect(themeData['passages'], isNotNull);
        expect(themeData['passages'], isA<List>());
      }
    });

    test('Each theme should have at least 5 passages', () {
      final themes = PredefinedThemes.getDefaultThemes();
      
      for (final themeData in themes) {
        final passages = themeData['passages'] as List;
        expect(passages.length, greaterThanOrEqualTo(5));
      }
    });

    test('Each passage should have required fields', () {
      final themes = PredefinedThemes.getDefaultThemes();
      
      for (final themeData in themes) {
        final passages = themeData['passages'] as List;
        
        for (final passageData in passages) {
          expect(passageData['reference'], isNotNull);
          expect(passageData['book'], isNotNull);
          expect(passageData['chapter'], isNotNull);
          expect(passageData['startVerse'], isNotNull);
          expect(passageData['description'], isNotNull);
        }
      }
    });

    test('Passage references should be properly formatted', () {
      final themes = PredefinedThemes.getDefaultThemes();
      
      for (final themeData in themes) {
        final passages = themeData['passages'] as List;
        
        for (final passageData in passages) {
          final reference = passageData['reference'] as String;
          
          // Should contain book name and chapter:verse
          expect(reference, contains(':'));
          
          // Should not be empty
          expect(reference.trim(), isNotEmpty);
        }
      }
    });

    test('Theme names should be unique', () {
      final themes = PredefinedThemes.getDefaultThemes();
      final names = themes.map((t) => t['name'] as String).toList();
      final uniqueNames = names.toSet();
      
      expect(uniqueNames.length, equals(names.length));
    });

    test('Expected themes should be present', () {
      final themes = PredefinedThemes.getDefaultThemes();
      final names = themes.map((t) => t['name'] as String).toList();
      
      final expectedThemes = [
        'Amour',
        'Espoir', 
        'Paix',
        'Sagesse',
        'Force',
        'Pardon',
        'Foi',
        'Gratitude',
        'Protection',
        'Guidance',
      ];
      
      for (final expectedTheme in expectedThemes) {
        expect(names, contains(expectedTheme));
      }
    });

    test('Passages should have valid chapter and verse numbers', () {
      final themes = PredefinedThemes.getDefaultThemes();
      
      for (final themeData in themes) {
        final passages = themeData['passages'] as List;
        
        for (final passageData in passages) {
          final chapter = passageData['chapter'] as int;
          final startVerse = passageData['startVerse'] as int;
          final endVerse = passageData['endVerse'] as int?;
          
          expect(chapter, greaterThan(0));
          expect(startVerse, greaterThan(0));
          
          if (endVerse != null) {
            expect(endVerse, greaterThanOrEqualTo(startVerse));
          }
        }
      }
    });

    test('ThematicPassage model should be constructible', () {
      final passage = ThematicPassage(
        id: 'test-id',
        reference: 'Jean 3:16',
        book: 'Jean',
        chapter: 3,
        startVerse: 16,
        endVerse: null,
        text: 'Car Dieu a tant aimé le monde...',
        theme: 'amour',
        description: 'Test passage',
        tags: ['test'],
        createdAt: DateTime.now(),
        createdBy: 'test-user',
        createdByName: 'Test User',
      );
      
      expect(passage.reference, equals('Jean 3:16'));
      expect(passage.book, equals('Jean'));
      expect(passage.chapter, equals(3));
      expect(passage.startVerse, equals(16));
    });

    test('BiblicalTheme model should be constructible', () {
      final theme = BiblicalTheme(
        id: 'test-theme-id',
        name: 'Test Theme',
        description: 'A test theme',
        color: Colors.blue,
        icon: Icons.star,
        passages: [],
        createdAt: DateTime.now(),
        createdBy: 'test-user',
        createdByName: 'Test User',
        isPublic: true,
      );
      
      expect(theme.name, equals('Test Theme'));
      expect(theme.color, equals(Colors.blue));
      expect(theme.icon, equals(Icons.star));
      expect(theme.isPublic, isTrue);
    });

    test('Total passages count should be as expected', () {
      final themes = PredefinedThemes.getDefaultThemes();
      int totalPassages = 0;
      
      for (final themeData in themes) {
        final passages = themeData['passages'] as List;
        totalPassages += passages.length;
      }
      
      // Vérifier qu'on a au moins 50 passages au total
      expect(totalPassages, greaterThanOrEqualTo(50));
      print('Total passages created: $totalPassages');
    });

    test('Bible books should be valid', () {
      final themes = PredefinedThemes.getDefaultThemes();
      
      final validBooks = [
        'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
        'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
        '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
        'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaumes',
        'Proverbes', 'Ecclésiaste', 'Cantique des cantiques',
        'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel',
        'Daniel', 'Osée', 'Joël', 'Amos', 'Abdias',
        'Jonas', 'Michée', 'Nahum', 'Habacuc', 'Sophonie',
        'Aggée', 'Zacharie', 'Malachie',
        'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
        'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates',
        'Éphésiens', 'Philippiens', 'Colossiens',
        '1 Thessaloniciens', '2 Thessaloniciens',
        '1 Timothée', '2 Timothée', 'Tite', 'Philémon',
        'Hébreux', 'Jacques', '1 Pierre', '2 Pierre',
        '1 Jean', '2 Jean', '3 Jean', 'Jude', 'Apocalypse'
      ];
      
      for (final themeData in themes) {
        final passages = themeData['passages'] as List;
        
        for (final passageData in passages) {
          final book = passageData['book'] as String;
          expect(validBooks, contains(book), 
                 reason: 'Book "$book" is not in valid books list');
        }
      }
    });
  });
}
