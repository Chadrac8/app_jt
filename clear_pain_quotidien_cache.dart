import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🗑️ Script de vidage du cache du pain quotidien');
  print('=' * 50);
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Lister toutes les clés existantes
    final keys = prefs.getKeys();
    print('📋 Clés existantes dans le cache:');
    
    int branhamKeys = 0;
    for (String key in keys) {
      if (key.contains('branham') || 
          key.contains('daily_bread') || 
          key.contains('pain_quotidien') ||
          key.contains('quote_cache') ||
          key.contains('last_update')) {
        print('   📝 $key: ${prefs.get(key)}');
        branhamKeys++;
      }
    }
    
    print('\n📊 Trouvé $branhamKeys clés liées au pain quotidien sur ${keys.length} total');
    
    // Supprimer spécifiquement les clés du cache
    bool removed = false;
    
    // Clés du service BranhamScrapingService
    if (prefs.containsKey('branham_quote_cache_v2')) {
      await prefs.remove('branham_quote_cache_v2');
      print('❌ Supprimé: branham_quote_cache_v2');
      removed = true;
    }
    
    if (prefs.containsKey('branham_last_update_v2')) {
      await prefs.remove('branham_last_update_v2');
      print('❌ Supprimé: branham_last_update_v2');
      removed = true;
    }
    
    // Supprimer toutes les autres clés liées
    for (String key in keys.toList()) {
      if (key.contains('branham') || 
          key.contains('daily_bread') || 
          key.contains('pain_quotidien') ||
          key.contains('quote_')) {
        await prefs.remove(key);
        print('❌ Supprimé: $key');
        removed = true;
      }
    }
    
    if (removed) {
      print('\n✅ Cache vidé avec succès!');
      print('🔄 Redémarrez l\'application pour voir les corrections d\'encodage.');
    } else {
      print('\n📝 Aucune donnée de cache trouvée à supprimer');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
