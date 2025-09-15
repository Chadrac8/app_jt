class EncodingFixService {
  /// Fonction améliorée pour décoder les entités HTML et corriger l'encodage
  static String fixEncoding(String text) {
    if (text.isEmpty) return text;
    
    // Étape 1 : Nettoyer les artefacts de code qui pourraient corrompre le décodage
    String cleanText = text
        .replaceAll(RegExp(r'\s*\.\s*replaceAll\s*\([^)]*\)\s*[^;]*'), '')
        .replaceAll(RegExp(r'^\s*\)\s*'), '')
        .replaceAll(RegExp(r'\s*;\s*$'), '');
    
    // Étape 2 : Décoder les entités HTML
    cleanText = cleanText
        // Minuscules accentuées
        .replaceAll('&eacute;', 'é')
        .replaceAll('&ecirc;', 'ê')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&ucirc;', 'û')
        .replaceAll('&ocirc;', 'ô')
        .replaceAll('&acirc;', 'â')
        .replaceAll('&icirc;', 'î')
        .replaceAll('&iuml;', 'ï')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&ugrave;', 'ù')
        
        // Majuscules accentuées
        .replaceAll('&Eacute;', 'É')
        .replaceAll('&Ecirc;', 'Ê')
        .replaceAll('&Egrave;', 'È')
        .replaceAll('&Agrave;', 'À')
        .replaceAll('&Ucirc;', 'Û')
        .replaceAll('&Ocirc;', 'Ô')
        .replaceAll('&Acirc;', 'Â')
        .replaceAll('&Icirc;', 'Î')
        .replaceAll('&Ccedil;', 'Ç')
        
        // Guillemets et apostrophes
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#39;', "'")
        
        // Autres caractères spéciaux
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&hellip;', '…')
        .replaceAll('&#8230;', '…')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8211;', '–')
        
        // Entités numériques pour les caractères français
        .replaceAll('&#233;', 'é')
        .replaceAll('&#234;', 'ê')
        .replaceAll('&#232;', 'è')
        .replaceAll('&#224;', 'à')
        .replaceAll('&#251;', 'û')
        .replaceAll('&#244;', 'ô')
        .replaceAll('&#226;', 'â')
        .replaceAll('&#238;', 'î')
        .replaceAll('&#239;', 'ï')
        .replaceAll('&#246;', 'ö')
        .replaceAll('&#252;', 'ü')
        .replaceAll('&#231;', 'ç')
        .replaceAll('&#249;', 'ù')
        .replaceAll('&#201;', 'É')
        .replaceAll('&#202;', 'Ê')
        .replaceAll('&#200;', 'È')
        .replaceAll('&#192;', 'À')
        .replaceAll('&#219;', 'Û')
        .replaceAll('&#212;', 'Ô')
        .replaceAll('&#194;', 'Â')
        .replaceAll('&#206;', 'Î')
        .replaceAll('&#199;', 'Ç');
    
    // Étape 3 : Corriger les caractères UTF-8 mal encodés
    cleanText = _fixUtf8Encoding(cleanText);
    
    // Étape 4 : Nettoyage final des espaces
    cleanText = cleanText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    return cleanText;
  }
  
  /// Décode les entités HTML
  static String _decodeHtmlEntities(String text) {
    return text
        // Caractères accentués français
        .replaceAll('&eacute;', 'é')
        .replaceAll('&ecirc;', 'ê')
        .replaceAll('&egrave;', 'è')
        .replaceAll('&agrave;', 'à')
        .replaceAll('&ucirc;', 'û')
        .replaceAll('&ocirc;', 'ô')
        .replaceAll('&acirc;', 'â')
        .replaceAll('&icirc;', 'î')
        .replaceAll('&iuml;', 'ï')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&ugrave;', 'ù')
        
        // Majuscules accentuées
        .replaceAll('&Eacute;', 'É')
        .replaceAll('&Ecirc;', 'Ê')
        .replaceAll('&Egrave;', 'È')
        .replaceAll('&Agrave;', 'À')
        .replaceAll('&Ucirc;', 'Û')
        .replaceAll('&Ocirc;', 'Ô')
        .replaceAll('&Acirc;', 'Â')
        .replaceAll('&Icirc;', 'Î')
        .replaceAll('&Ccedil;', 'Ç')
        
        // Guillemets et apostrophes
        .replaceAll('&rsquo;', ''')
        .replaceAll('&lsquo;', ''')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', ''')
        .replaceAll('&#8216;', ''')
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#39;', "'")
        
        // Autres caractères spéciaux
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&hellip;', '…')
        .replaceAll('&#8230;', '…')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8211;', '–')
        
        // Entités numériques pour les caractères français
        .replaceAll('&#233;', 'é')
        .replaceAll('&#234;', 'ê')
        .replaceAll('&#232;', 'è')
        .replaceAll('&#224;', 'à')
        .replaceAll('&#251;', 'û')
        .replaceAll('&#244;', 'ô')
        .replaceAll('&#226;', 'â')
        .replaceAll('&#238;', 'î')
        .replaceAll('&#239;', 'ï')
        .replaceAll('&#231;', 'ç')
        .replaceAll('&#249;', 'ù')
        .replaceAll('&#201;', 'É')
        .replaceAll('&#200;', 'È')
        .replaceAll('&#192;', 'À')
        .replaceAll('&#199;', 'Ç');
  }
  
  /// Corrige les problèmes d'encodage UTF-8 mal décodé
  static String _fixUtf8Encoding(String text) {
    return text
        // Caractères mal encodés fréquents
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¨', 'è')
        .replaceAll('Ã´', 'ô')
        .replaceAll('Ã¢', 'â')
        .replaceAll('Ã¦', 'æ')
        .replaceAll('Ã ', 'à')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ãª', 'ê')
        .replaceAll('Ã®', 'î')
        .replaceAll('Ã¯', 'ï')
        .replaceAll('Ã»', 'û')
        .replaceAll('Ã¹', 'ù')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Ã‰', 'É')
        .replaceAll('Ã€', 'À')
        .replaceAll('Ã‡', 'Ç')
        
        // Apostrophes et guillemets mal encodés
        .replaceAll('â€™', "'")
        .replaceAll('â€˜', "'")
        .replaceAll('â€œ', '"')
        .replaceAll('â€', '"')
        .replaceAll('lâ€™', "l'")
        .replaceAll('câ€™', "c'")
        .replaceAll('Lâ€™', "L'")
        .replaceAll('dâ€™', "d'")
        .replaceAll('sâ€™', "s'")
        .replaceAll('jâ€™', "j'")
        .replaceAll('mâ€™', "m'")
        .replaceAll('nâ€™', "n'")
        .replaceAll('tâ€™', "t'")
        .replaceAll('quâ€™', "qu'")
        .replaceAll('â€¦', '…')
        .replaceAll('â€"', '–')
        .replaceAll('â€"', '—')
        
        // Autres caractères UTF-8 mal décodés
        .replaceAll('Â ', ' ')
        .replaceAll('Â', '')
        .replaceAll('ï¿½', ''); // Caractère de remplacement
  }
  
  /// Nettoie les caractères indésirables
  static String _cleanUnwantedCharacters(String text) {
    return text
        // Supprimer les caractères de contrôle
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        
        // Supprimer les séquences de caractères bizarres
        .replaceAll(RegExp(r'[^\x20-\x7E\u00A0-\u024F\u1E00-\u1EFF]'), '')
        
        // Nettoyer les artefacts de code potentiels
        .replaceAll(RegExp(r'\s*\.\s*replaceAll\([^)]*\)\s*[^;]*'), '')
        .replaceAll(RegExp(r'^\s*\)\s*'), '')
        .replaceAll(RegExp(r'\s*;\s*$'), '');
  }
  
  /// Normalise les espaces
  static String _normalizeSpaces(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }
  
  /// Test de décodage avec des exemples
  static void testDecoding() {
    print('=== Test de décodage des caractères ===');
    
    final testCases = [
      'Ã©glise',                    // église
      'â€™amour',                   // l'amour
      '&eacute;glise',              // église
      'prÃªtre',                    // prêtre
      'Dieu nous bÃ©nit',          // Dieu nous bénit
      'câ€™est merveilleux',        // c'est merveilleux
      'Jâ€™ai confiance',           // J'ai confiance
      '&agrave; travers les &acirc;ges', // à travers les âges
    ];
    
    for (String test in testCases) {
      final fixed = fixEncoding(test);
      print('Original: $test');
      print('Corrigé:  $fixed');
      print('---');
    }
  }
}
