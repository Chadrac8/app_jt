import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/modules/vie_eglise/migration/pour_vous_data_migration.dart';

/// Script simple pour exécuter la migration des données "Pour Vous"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initialisation Firebase...');
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
  } catch (e) {
    print('❌ Erreur Firebase: $e');
    return;
  }
  
  print('📊 Début de la migration des données "Pour Vous"...');
  
  try {
    final migration = PourVousDataMigration();
    await migration.migrate();
    print('🎉 Migration terminée avec succès !');
    print('');
    print('📱 Vous pouvez maintenant :');
    print('1. Redémarrer l\'application');
    print('2. Aller dans l\'onglet "Pour Vous" côté membre');
    print('3. Les actions doivent maintenant apparaître !');
    
  } catch (e) {
    print('❌ Erreur lors de la migration: $e');
  }
}