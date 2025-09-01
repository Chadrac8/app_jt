import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../lib/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Captures d\'écran Jubilé Tabernacle', () {
    
    testWidgets('01 - Écran d\'accueil principal', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Attendre que l'interface soit complètement chargée
      await tester.pump(const Duration(seconds: 2));
      
      // Prendre la capture d'écran
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      
      // Sauvegarder
      await binding.takeScreenshot('01_accueil_principal');
    });
    
    testWidgets('02 - Module Bible & Message', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Naviguer vers le module Bible
      final bibleTile = find.text('Bible & Message');
      if (bibleTile.evaluate().isNotEmpty) {
        await tester.tap(bibleTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      await binding.takeScreenshot('02_bible_message');
    });
    
    testWidgets('03 - Vie de l\'Église', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Naviguer vers Vie de l'Église
      final vieEgliseTile = find.text('Vie de l\'Église');
      if (vieEgliseTile.evaluate().isNotEmpty) {
        await tester.tap(vieEgliseTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      await binding.takeScreenshot('03_vie_eglise');
    });
    
    testWidgets('04 - Pain Quotidien', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Naviguer vers Pain Quotidien  
      final painQuotidienTile = find.text('Pain Quotidien');
      if (painQuotidienTile.evaluate().isNotEmpty) {
        await tester.tap(painQuotidienTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      await binding.takeScreenshot('04_pain_quotidien');
    });
    
    testWidgets('05 - Prières & Témoignages', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Naviguer vers Vie de l'Église puis Prières
      final vieEgliseTile = find.text('Vie de l\'Église');
      if (vieEgliseTile.evaluate().isNotEmpty) {
        await tester.tap(vieEgliseTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Chercher l'onglet Prières
        final prieresTab = find.text('Prières');
        if (prieresTab.evaluate().isNotEmpty) {
          await tester.tap(prieresTab);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }
      }
      
      await binding.takeScreenshot('05_prieres_testimonages');
    });
    
    testWidgets('06 - Pour Vous (fonctionnalités)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Naviguer vers Pour Vous
      final pourVousTile = find.text('Pour Vous');
      if (pourVousTile.evaluate().isNotEmpty) {
        await tester.tap(pourVousTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      await binding.takeScreenshot('06_pour_vous_fonctionnalites');
    });
    
    testWidgets('07 - Configuration et Paramètres', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Chercher le menu de configuration
      final configIcon = find.byIcon(Icons.settings);
      if (configIcon.evaluate().isNotEmpty) {
        await tester.tap(configIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      await binding.takeScreenshot('07_configuration_parametres');
    });
    
    testWidgets('08 - Profil Utilisateur', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Chercher l'icône de profil
      final profilIcon = find.byIcon(Icons.person);
      if (profilIcon.evaluate().isNotEmpty) {
        await tester.tap(profilIcon);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      
      await binding.takeScreenshot('08_profil_utilisateur');
    });
    
  });
}
