import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🗑️ Vidage du cache pour forcer la récupération des nouvelles données...');
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Supprimer les clés de cache du service Branham
    await prefs.remove('branham_quote_cache_v2');
    await prefs.remove('branham_last_update_v2');
    
    print('✅ Cache vidé avec succès');
  } catch (e) {
    print('⚠️ Erreur lors du vidage du cache: $e');
    print('   Cela peut être normal en mode développement');
  }
  
  print('📱 Les nouvelles données seront récupérées au prochain lancement');
  print('');
  print('🔧 Modifications apportées:');
  print('   - Amélioration de l\'extraction de la citation de Branham');
  print('   - Gestion des erreurs CORS pour le navigateur');
  print('   - Citation par défaut mise à jour avec le vrai contenu');
  print('   - Filtrage amélioré pour éviter les contenus de navigation');
}
