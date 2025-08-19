import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Analyse simple des scripts...');
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/messageaudio'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15',
      },
    );
    
    if (response.statusCode == 200) {
      final content = response.body;
      
      // Chercher des mots-clés dans le contenu
      print('🔍 Recherche de mots-clés...');
      
      if (content.contains('searchdata')) {
        print('✅ Fonction searchdata trouvée');
      }
      
      if (content.contains('jQuery.post')) {
        print('✅ Appels jQuery.post trouvés');
      }
      
      if (content.contains('Ajax') || content.contains('ajax')) {
        print('✅ Références AJAX trouvées');
      }
      
      // Chercher des URLs potentielles
      final simpleUrlPattern = RegExp(r'["\x27]([^"\x27]*\.php[^"\x27]*)["\x27]');
      final phpUrls = simpleUrlPattern.allMatches(content);
      
      print('🌐 URLs PHP trouvées: ${phpUrls.length}');
      for (final url in phpUrls.take(10)) {
        print('   - ${url.group(1)}');
      }
      
      // Chercher des endpoints de recherche
      if (content.contains('search.php')) {
        print('✅ Endpoint search.php détecté');
      }
      
      if (content.contains('messageaudio')) {
        print('✅ Références messageaudio trouvées');
      }
      
      // Chercher des paramètres de formulaire
      final inputPattern = RegExp(r'<input[^>]*name="([^"]*)"');
      final inputs = inputPattern.allMatches(content);
      
      print('📝 Champs de formulaire trouvés: ${inputs.length}');
      for (final input in inputs.take(10)) {
        print('   - ${input.group(1)}');
      }
      
      // Analyser le contenu pour trouver comment les données sont chargées
      print('\n🔍 Analyse du mécanisme de chargement des données...');
      
      // Diviser le contenu en lignes pour une meilleure analyse
      final lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.contains('jQuery.post') || line.contains('ajax')) {
          print('📍 Ligne ${i + 1}: ${line.length > 100 ? line.substring(0, 100) + "..." : line}');
        }
        
        if (line.contains('searchdata') && line.contains('function')) {
          print('🎯 Fonction searchdata à la ligne ${i + 1}');
          
          // Afficher les 5 lignes suivantes pour contexte
          for (int j = 1; j <= 5 && (i + j) < lines.length; j++) {
            final nextLine = lines[i + j].trim();
            if (nextLine.isNotEmpty) {
              print('   +$j: ${nextLine.length > 80 ? nextLine.substring(0, 80) + "..." : nextLine}');
            }
          }
        }
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('💥 Erreur: $e');
  }
}
