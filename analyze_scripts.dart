import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Analyse ciblée des scripts JavaScript...');
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/messageaudio'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15',
      },
    );
    
    if (response.statusCode == 200) {
      final content = response.body;
      
      // Chercher spécifiquement les fonctions qui gèrent les données de recherche
      final searchFunctionPattern = RegExp(r'function\s+searchdata\s*\([^)]*\)\s*{(.*?)}', dotAll: true);
      final searchFunctions = searchFunctionPattern.allMatches(content);
      
      print('🔍 Fonctions searchdata trouvées: ${searchFunctions.length}');
      
      for (final func in searchFunctions) {
        final funcContent = func.group(1) ?? '';
        print('📜 Contenu de la fonction searchdata:');
        print('🔍 Taille: ${funcContent.length} caractères');
        
        // Chercher des URLs ou des endpoints AJAX
        final urlPattern = RegExp(r'["\']([^"\']*(?:search|data|api|ajax)[^"\']*)["\']');
        final urls = urlPattern.allMatches(funcContent);
        
        print('🌐 URLs trouvées dans la fonction:');
        for (final urlMatch in urls) {
          print('   - ${urlMatch.group(1)}');
        }
        
        // Chercher des paramètres de recherche
        final paramPattern = RegExp(r'["\']([^"\']*(?:year|language|type|format)[^"\']*)["\']');
        final params = paramPattern.allMatches(funcContent);
        
        print('⚙️ Paramètres de recherche possibles:');
        for (final paramMatch in params) {
          print('   - ${paramMatch.group(1)}');
        }
      }
      
      // Chercher des données JSON directement dans le HTML
      print('\n🔍 Recherche de données JSON dans le HTML...');
      
      final jsonPattern = RegExp(r'\{[^{}]*"[^"]*"[^{}]*:[^{}]*\}');
      final jsonMatches = jsonPattern.allMatches(content);
      print('📄 Objets JSON simples trouvés: ${jsonMatches.length}');
      
      // Chercher des tableaux de données
      final arrayPattern = RegExp(r'\[[^\[\]]*(?:"[^"]*"|\d+)[^\[\]]*\]');
      final arrayMatches = arrayPattern.allMatches(content);
      print('📊 Tableaux de données trouvés: ${arrayMatches.length}');
      
      // Chercher des variables JavaScript qui pourraient contenir les données
      final varPattern = RegExp(r'var\s+(\w+)\s*=\s*([^;]+);');
      final varMatches = varPattern.allMatches(content);
      
      print('\n📋 Variables JavaScript intéressantes:');
      int count = 0;
      for (final varMatch in varMatches) {
        final varName = varMatch.group(1) ?? '';
        final varValue = varMatch.group(2) ?? '';
        
        if (varValue.contains('[') || varValue.contains('{') || 
            varValue.contains('audio') || varValue.contains('pdf') ||
            varName.toLowerCase().contains('data') || 
            varName.toLowerCase().contains('search')) {
          count++;
          if (count <= 10) {
            print('   $count. $varName = ${varValue.substring(0, varValue.length < 100 ? varValue.length : 100)}...');
          }
        }
      }
      
      print('\n🔍 Recherche d\'endpoints AJAX spécifiques...');
      
      // Chercher jQuery.post, jQuery.ajax, fetch, etc.
      final ajaxPattern = RegExp(r'(?:jQuery\.(?:post|ajax|get)|fetch)\s*\(\s*["\']([^"\']+)["\']');
      final ajaxMatches = ajaxPattern.allMatches(content);
      
      print('🌐 Endpoints AJAX trouvés:');
      for (final ajaxMatch in ajaxMatches) {
        print('   - ${ajaxMatch.group(1)}');
      }
      
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
    }
    
  } catch (e) {
    print('💥 Erreur: $e');
  }
}
