import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Analyse détaillée des appels AJAX...');
  
  try {
    final response = await http.get(
      Uri.parse('https://branham.org/fr/messageaudio'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15',
      },
    );
    
    if (response.statusCode == 200) {
      final content = response.body;
      final lines = content.split('\n');
      
      print('🔍 Extraction des appels AJAX...');
      
      // Analyser chaque ligne pour trouver les appels jQuery.ajax
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        if (line.contains('jQuery.ajax({')) {
          print('\n📍 Appel AJAX trouvé à la ligne ${i + 1}:');
          
          // Extraire le bloc AJAX complet
          int braceCount = 0;
          String ajaxBlock = '';
          bool inAjax = false;
          
          for (int j = i; j < lines.length && j < i + 20; j++) {
            final currentLine = lines[j].trim();
            
            if (currentLine.contains('jQuery.ajax({')) {
              inAjax = true;
            }
            
            if (inAjax) {
              ajaxBlock += currentLine + '\n';
              
              // Compter les accolades pour savoir quand l'appel se termine
              braceCount += '{'.allMatches(currentLine).length;
              braceCount -= '}'.allMatches(currentLine).length;
              
              if (braceCount <= 0 && currentLine.contains('}')) {
                break;
              }
            }
          }
          
          print('📄 Bloc AJAX:');
          print(ajaxBlock);
          
          // Extraire l'URL de l'appel AJAX
          final urlMatch = RegExp(r'url\s*:\s*[\'"]([^\'\"]+)[\'"]').firstMatch(ajaxBlock);
          if (urlMatch != null) {
            print('🌐 URL: ${urlMatch.group(1)}');
          }
          
          // Extraire le type de requête
          final typeMatch = RegExp(r'type\s*:\s*[\'"]([^\'\"]+)[\'"]').firstMatch(ajaxBlock);
          if (typeMatch != null) {
            print('📝 Type: ${typeMatch.group(1)}');
          }
          
          // Extraire les données
          final dataMatch = RegExp(r'data\s*:\s*([^,}]+)').firstMatch(ajaxBlock);
          if (dataMatch != null) {
            print('📊 Données: ${dataMatch.group(1)}');
          }
        }
      }
      
      // Chercher spécifiquement les paramètres de formulaire
      print('\n🔍 Analyse du formulaire de recherche...');
      
      final formMatch = RegExp(r'<form[^>]*id=[\'"]frmcms[\'"][^>]*>(.*?)</form>', dotAll: true).firstMatch(content);
      if (formMatch != null) {
        final formContent = formMatch.group(1) ?? '';
        print('📋 Formulaire frmcms trouvé');
        
        // Extraire les champs cachés
        final hiddenInputs = RegExp(r'<input[^>]*type=[\'"]hidden[\'"][^>]*>').allMatches(formContent);
        print('🔒 Champs cachés: ${hiddenInputs.length}');
        
        for (final input in hiddenInputs) {
          final inputHtml = input.group(0) ?? '';
          final nameMatch = RegExp(r'name=[\'"]([^\'\"]+)[\'"]').firstMatch(inputHtml);
          final valueMatch = RegExp(r'value=[\'"]([^\'\"]*)[\'"]').firstMatch(inputHtml);
          
          if (nameMatch != null) {
            final name = nameMatch.group(1);
            final value = valueMatch?.group(1) ?? '';
            print('   - $name: ${value.length > 20 ? value.substring(0, 20) + "..." : value}');
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
