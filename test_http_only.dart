import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Test de la connexion au site branham.org...');
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/messageaudio'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15',
      },
    );
    
    print('✅ Statut de la réponse: ${response.statusCode}');
    print('📄 Taille du contenu: ${response.body.length} caractères');
    
    if (response.statusCode == 200) {
      // Test de parsing basique
      final content = response.body;
      final matches = RegExp(r'href="([^"]*\.pdf)"').allMatches(content);
      print('📋 Nombre de liens PDF trouvés: ${matches.length}');
      
      // Afficher les 3 premiers liens PDF trouvés
      int count = 0;
      for (final match in matches) {
        if (count >= 3) break;
        final pdfUrl = match.group(1);
        print('🔗 PDF ${count + 1}: $pdfUrl');
        count++;
      }
      
      // Test de parsing des prédications avec plusieurs patterns
      print('🔍 Test de différents patterns de parsing...');
      
      // Pattern 1: Recherche de lignes contenant FRN et PDF
      final frnLines = content.split('\n').where((line) => 
        line.contains('FRN') && line.contains('.pdf')).toList();
      print('📋 Lignes contenant FRN et PDF: ${frnLines.length}');
      
      if (frnLines.isNotEmpty) {
        print('🔍 Première ligne FRN: ${frnLines.first.trim().substring(0, 100)}...');
      }
      
      // Pattern 2: Recherche plus large
      final broadPattern = RegExp(r'href="([^"]*\.pdf)"[^>]*>([^<]*FRN[^<]*)</a>');
      final broadMatches = broadPattern.allMatches(content);
      print('🎯 Pattern large FRN: ${broadMatches.length} trouvées');
      
      // Pattern 3: Chercher dans les balises avec "fr" 
      final frPattern = RegExp(r'href="([^"]*\.pdf)"[^>]*>([^<]*\bfr[^<]*)</a>', caseSensitive: false);
      final frMatches = frPattern.allMatches(content);
      print('🎯 Pattern "fr": ${frMatches.length} trouvées');
      
      // Afficher quelques exemples trouvés
      count = 0;
      for (final match in frMatches) {
        if (count >= 3) break;
        final pdfUrl = match.group(1);
        final title = match.group(2)?.trim();
        print('📖 Exemple ${count + 1}: $title');
        print('🔗 URL: $pdfUrl');
        count++;
      }
      
      // Pattern 4: Rechercher autrement dans le HTML
      final altPattern = RegExp(r'<a[^>]+href="([^"]*\.pdf)"[^>]*>([^<]+)</a>');
      final altMatches = altPattern.allMatches(content);
      print('🎯 Pattern alternatif: ${altMatches.length} liens PDF avec texte');
      
      // Filtrer ceux qui semblent être des prédications françaises
      final frenchSermons = altMatches.where((match) {
        final text = match.group(2)?.toLowerCase() ?? '';
        return text.contains('fr') || text.contains('frn');
      }).toList();
      
      print('🇫🇷 Prédications françaises trouvées: ${frenchSermons.length}');
      
      count = 0;
      for (final match in frenchSermons) {
        if (count >= 5) break;
        final pdfUrl = match.group(1);
        final title = match.group(2)?.trim();
        print('📖 Prédication française ${count + 1}: $title');
        count++;
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
      print('📝 Réponse: ${response.body.substring(0, 200)}...');
    }
    
  } catch (e) {
    print('💥 Erreur lors de la connexion: $e');
  }
}
