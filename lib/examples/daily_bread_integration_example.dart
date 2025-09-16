import 'package:flutter/material.dart';
import '../modules/pain_quotidien/pain_quotidien.dart';

/// Exemple d'intégration du pain quotidien dans la page d'accueil
class HomePageWithDailyBread extends StatelessWidget {
  const HomePageWithDailyBread({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jubilé Tabernacle France'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // Autres widgets de la page d'accueil...
            
            // Widget de prévisualisation du pain quotidien
            const DailyBreadPreviewWidget(),
            
            const SizedBox(height: 24),
            
            // Autres widgets...
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Le pain quotidien est maintenant intégré à votre application ! '
                'Le widget affiche automatiquement le verset et la citation du jour '
                'récupérés depuis branham.org.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exemple de navigation directe vers la page du pain quotidien
class NavigationExample extends StatelessWidget {
  const NavigationExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_stories),
      title: const Text('Pain Quotidien'),
      subtitle: const Text('Verset et citation du jour'),
      trailing: const Icon(Icons.book_outlined),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DailyBreadPage(),
          ),
        );
      },
    );
  }
}
