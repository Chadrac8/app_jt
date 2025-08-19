import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Analyse détaillée du HTML du site branham.org...');
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/messageaudio'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15',
      },
    );
    
    if (response.statusCode == 200) {
      final content = response.body;
      
      // Chercher des structures JavaScript ou des données JSON
      print('🔍 Recherche de données JavaScript...');
      
      // Chercher des scripts qui pourraient contenir les données
      final scriptPattern = RegExp(r'<script[^>]*>(.*?)</script>', dotAll: true);
      final scripts = scriptPattern.allMatches(content);
      print('📜 Nombre de scripts trouvés: ${scripts.length}');
      
      // Analyser chaque script pour trouver des données de prédications
      int scriptIndex = 0;
      for (final script in scripts) {
        final scriptContent = script.group(1) ?? '';
        scriptIndex++;
        
        if (scriptContent.contains('pdf') || scriptContent.contains('FRN') || 
            scriptContent.contains('sermon') || scriptContent.contains('message')) {
          print('📜 Script ${scriptIndex} contient des données pertinentes');
          print('📄 Taille: ${scriptContent.length} caractères');
          
          // Afficher les 200 premiers caractères pour analyse
          final preview = scriptContent.trim().substring(0, scriptContent.length < 200 ? scriptContent.length : 200);
          print('👀 Aperçu: $preview...');
          
          // Chercher des patterns JSON ou JavaScript
          if (scriptContent.contains('[') && scriptContent.contains(']')) {
            print('🔍 Contient des tableaux JavaScript/JSON');
          }
          if (scriptContent.contains('{') && scriptContent.contains('}')) {
            print('🔍 Contient des objets JavaScript/JSON');
          }
          
          print('---');
        }
      }
      
      // Chercher des balises spécifiques qui pourraient contenir les données
      print('\n🔍 Recherche de balises data-* ou autres...');
      
      final dataPattern = RegExp(r'data-[^=]*="[^"]*"');
      final dataAttrs = dataPattern.allMatches(content);
      print('📊 Attributs data-* trouvés: ${dataAttrs.length}');
      
      // Chercher des classes CSS qui pourraient indiquer des éléments de prédication
      final classPattern = RegExp(r'class="([^"]*(?:sermon|message|audio|pdf|download)[^"]*)"', caseSensitive: false);
      final classMatches = classPattern.allMatches(content);
      print('🎨 Classes pertinentes trouvées: ${classMatches.length}');
      
      int count = 0;
      for (final match in classMatches) {
        if (count >= 5) break;
        print('🏷️ Classe ${count + 1}: ${match.group(1)}');
        count++;
      }
      
      // Chercher des divs ou autres éléments qui pourraient contenir les prédications
      print('\n🔍 Recherche de conteneurs de prédications...');
      
      final containerPattern = RegExp(r'<div[^>]*class="[^"]*(?:list|item|card|row)[^"]*"[^>]*>(.*?)</div>', dotAll: true);
      final containers = containerPattern.allMatches(content);
      print('📦 Conteneurs trouvés: ${containers.length}');
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('💥 Erreur: $e');
  }
}
