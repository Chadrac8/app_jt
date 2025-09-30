import 'package:flutter/material.dart';
import 'modules/roles/models/role_template_model.dart';
import 'modules/roles/providers/role_template_provider.dart';

/// Script de test rapide pour vérifier les templates système
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 TEST DES TEMPLATES SYSTÈME');
  print('================================');
  
  // Test direct des templates système du modèle
  print('\n📋 Templates système du modèle (RoleTemplate.systemTemplates):');
  final systemTemplates = RoleTemplate.systemTemplates;
  print('Nombre de templates système: ${systemTemplates.length}');
  
  for (int i = 0; i < systemTemplates.length; i++) {
    final template = systemTemplates[i];
    print('${i + 1}. ${template.name} (${template.id})');
    print('   Catégorie: ${template.category}');
    print('   Permissions: ${template.permissionIds.length}');
    print('   Couleur: ${template.colorCode}');
    print('   Système: ${template.isSystemTemplate}');
    print('');
  }
  
  // Test du provider
  print('\n🔧 Test du RoleTemplateProvider:');
  final provider = RoleTemplateProvider();
  
  try {
    await provider.initialize();
    print('✅ Provider initialisé avec succès');
    
    final templates = provider.allTemplates;
    print('📊 Templates chargés: ${templates.length}');
    
    final systemCount = provider.systemTemplates.length;
    final customCount = provider.customTemplates.length;
    
    print('📈 Répartition:');
    print('   - Templates système: $systemCount');
    print('   - Templates personnalisés: $customCount');
    
    print('\n🏷️  Templates par catégorie:');
    for (final category in TemplateCategory.values) {
      final categoryTemplates = provider.getTemplatesByCategory(category.id);
      if (categoryTemplates.isNotEmpty) {
        print('   ${category.displayName}: ${categoryTemplates.length}');
        for (final template in categoryTemplates) {
          print('     - ${template.name}');
        }
      }
    }
    
    // Statistiques
    final stats = provider.usageStats;
    print('\n📊 Statistiques:');
    print('   Total: ${stats['totalTemplates'] ?? 0}');
    print('   Système: ${stats['systemTemplates'] ?? 0}');
    print('   Personnalisés: ${stats['customTemplates'] ?? 0}');
    print('   Actifs: ${stats['activeTemplates'] ?? 0}');
    
  } catch (e) {
    print('❌ Erreur lors du test du provider: $e');
  }
  
  print('\n🎯 CONCLUSION:');
  if (systemTemplates.length == 9) {
    print('✅ Les 9 templates système sont bien définis dans le modèle');
  } else {
    print('❌ Erreur: ${systemTemplates.length} templates trouvés au lieu de 9');
  }
  
  print('\n💡 Pour voir les templates dans l\'interface:');
  print('   flutter run lib/test_roles_main.dart');
  print('   Puis naviguez vers "Module Rôles" > Onglet "Templates"');
  print('');
  print('🏁 Test terminé.');
}