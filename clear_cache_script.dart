import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🗑️ Vidage du cache du pain quotidien...');
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Supprimer toutes les clés liées au cache du pain quotidien
    final keys = prefs.getKeys();
    int removed = 0;
    
    for (String key in keys) {
      if (key.contains('daily_bread') || 
          key.contains('branham') || 
          key.contains('pain_quotidien') ||
          key.contains('quote_')) {
        await prefs.remove(key);
        removed++;
        print('   ❌ Supprimé: $key');
      }
    }
    
    print('\n✅ Cache vidé! $removed entrées supprimées.');
    print('📱 Redémarrez l\'application pour voir les corrections d\'encodage.');
    
  } catch (e) {
    print('❌ Erreur lors du vidage du cache: $e');
  }
}
