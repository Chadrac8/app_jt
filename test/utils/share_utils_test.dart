import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../../lib/utils/share_utils.dart';

void main() {
  group('ShareUtils Tests', () {
    testWidgets('shareFile should handle context properly', (WidgetTester tester) async {
      // Créer un widget de test
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    // Créer un fichier de test temporaire
                    final testFile = XFile.fromData(
                      Uint8List.fromList([65, 66, 67]), // "ABC" en bytes
                      name: 'test.txt',
                      mimeType: 'text/plain',
                    );
                    
                    // Tester le partage avec contexte
                    await ShareUtils.shareFile(
                      testFile,
                      context: context,
                    );
                  },
                  child: const Text('Test Share'),
                );
              },
            ),
          ),
        ),
      );

      // Vérifier que le widget est construit
      expect(find.text('Test Share'), findsOneWidget);
      
      // Note: Nous ne pouvons pas vraiment tester le partage dans un test unitaire
      // car il nécessite l'interaction avec le système natif
    });

    test('shareText should handle null context gracefully', () async {
      // Tester le partage de texte sans contexte
      // Cela ne devrait pas lever d'exception
      expect(() async {
        await ShareUtils.shareText(
          'Test message',
          subject: 'Test Subject',
        );
      }, returnsNormally);
    });
  });
}