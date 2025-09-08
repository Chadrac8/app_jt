import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('🗑️ Vidage du cache du pain quotidien...');
  
  final prefs = await SharedPreferences.getInstance();
  
  // Supprimer les clés de cache du service Branham
  await prefs.remove('branham_quote_cache_v2');
  await prefs.remove('branham_last_update_v2');
  
  print('✅ Cache vidé avec succès');
  print('📱 Redémarrez l\'application pour récupérer les nouvelles données');
}