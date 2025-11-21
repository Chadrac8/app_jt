import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role_template_model.dart';

/// Service pour la gestion des templates de rôles
class RoleTemplateService {
  static const String _collection = 'role_templates';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialiser les templates système
  static Future<void> initializeSystemTemplates() async {
    try {
      final batch = _firestore.batch();
      
      for (final template in RoleTemplate.systemTemplates) {
        final docRef = _firestore.collection(_collection).doc(template.id);
        
        // Vérifier si le template existe déjà
        final doc = await docRef.get();
        if (!doc.exists) {
          batch.set(docRef, template.toFirestore());
        }
      }
      
      await batch.commit();
      
      print('Templates système initialisés avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation des templates système: $e');
      rethrow;
    }
  }

  /// Obtenir tous les templates
  static Future<List<RoleTemplate>> getAllTemplates({
    bool includeInactive = false,
  }) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (!includeInactive) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      query = query.orderBy('category').orderBy('name');
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => RoleTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des templates: $e');
      return [];
    }
  }

  /// Obtenir les templates par catégorie
  static Future<List<RoleTemplate>> getTemplatesByCategory(
    String category, {
    bool includeInactive = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('category', isEqualTo: category);
      
      if (!includeInactive) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      query = query.orderBy('name');
      
      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => RoleTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des templates par catégorie: $e');
      return [];
    }
  }

  /// Obtenir un template spécifique
  static Future<RoleTemplate?> getTemplate(String templateId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(templateId)
          .get();
      
      if (doc.exists) {
        return RoleTemplate.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du template: $e');
      return null;
    }
  }

  /// Créer un nouveau template personnalisé
  static Future<String> createTemplate(RoleTemplate template) async {
    try {
      // Valider le template
      if (!template.isConfigurationValid()) {
        throw Exception('Configuration du template invalide');
      }

      // Vérifier que le nom n'existe pas déjà
      final existingTemplates = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: template.name)
          .where('category', isEqualTo: template.category)
          .get();

      if (existingTemplates.docs.isNotEmpty) {
        throw Exception('Un template avec ce nom existe déjà dans cette catégorie');
      }

      final docRef = await _firestore
          .collection(_collection)
          .add(template.toFirestore());
      
      await _logTemplateAction('CREATE', docRef.id, template.createdBy);
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création du template: $e');
      rethrow;
    }
  }

  /// Mettre à jour un template
  static Future<void> updateTemplate(RoleTemplate template) async {
    try {
      // Vérifier que ce n'est pas un template système
      if (template.isSystemTemplate) {
        throw Exception('Impossible de modifier un template système');
      }

      // Valider le template
      if (!template.isConfigurationValid()) {
        throw Exception('Configuration du template invalide');
      }

      final updatedTemplate = template.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: template.updatedBy ?? 'unknown',
      );

      await _firestore
          .collection(_collection)
          .doc(template.id)
          .update(updatedTemplate.toFirestore());
      
      await _logTemplateAction('UPDATE', template.id, template.updatedBy ?? 'unknown');
    } catch (e) {
      print('Erreur lors de la mise à jour du template: $e');
      rethrow;
    }
  }

  /// Supprimer un template (soft delete)
  static Future<void> deleteTemplate(String templateId, String deletedBy) async {
    try {
      // Vérifier que le template existe et n'est pas système
      final template = await getTemplate(templateId);
      if (template == null) {
        throw Exception('Template non trouvé');
      }

      if (template.isSystemTemplate) {
        throw Exception('Impossible de supprimer un template système');
      }

      // Vérifier qu'aucun rôle n'utilise ce template
      final rolesUsingTemplate = await _firestore
          .collection('roles')
          .where('templateId', isEqualTo: templateId)
          .get();

      if (rolesUsingTemplate.docs.isNotEmpty) {
        throw Exception(
          'Impossible de supprimer ce template car ${rolesUsingTemplate.docs.length} rôle(s) l\'utilisent'
        );
      }

      // Soft delete
      await _firestore
          .collection(_collection)
          .doc(templateId)
          .update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': deletedBy,
      });
      
      await _logTemplateAction('DELETE', templateId, deletedBy);
    } catch (e) {
      print('Erreur lors de la suppression du template: $e');
      rethrow;
    }
  }

  /// Dupliquer un template
  static Future<String> duplicateTemplate(
    String templateId,
    String newName,
    String createdBy,
  ) async {
    try {
      final originalTemplate = await getTemplate(templateId);
      if (originalTemplate == null) {
        throw Exception('Template original non trouvé');
      }

      final duplicatedTemplate = RoleTemplate(
        id: '', // Sera assigné automatiquement
        name: newName,
        description: '${originalTemplate.description} (Copie)',
        category: originalTemplate.category,
        permissionIds: List<String>.from(originalTemplate.permissionIds),
        configuration: Map<String, dynamic>.from(originalTemplate.configuration),
        iconName: originalTemplate.iconName,
        colorCode: originalTemplate.colorCode,
        isSystemTemplate: false, // Les duplicatas ne sont jamais système
        createdAt: DateTime.now(),
        createdBy: createdBy,
        localizations: Map<String, String>.from(originalTemplate.localizations),
      );

      final newTemplateId = await createTemplate(duplicatedTemplate);
      
      await _logTemplateAction('DUPLICATE', newTemplateId, createdBy, {
        'originalTemplateId': templateId,
      });
      
      return newTemplateId;
    } catch (e) {
      print('Erreur lors de la duplication du template: $e');
      rethrow;
    }
  }

  /// Rechercher des templates
  static Future<List<RoleTemplate>> searchTemplates(
    String query, {
    String? category,
    bool includeInactive = false,
  }) async {
    try {
      final allTemplates = await getAllTemplates(includeInactive: includeInactive);
      
      var filteredTemplates = allTemplates;
      
      // Filtre par catégorie
      if (category != null && category.isNotEmpty) {
        filteredTemplates = filteredTemplates
            .where((template) => template.category == category)
            .toList();
      }
      
      // Filtre par recherche textuelle
      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        filteredTemplates = filteredTemplates.where((template) {
          return template.name.toLowerCase().contains(queryLower) ||
                 template.description.toLowerCase().contains(queryLower) ||
                 template.permissionIds.any((perm) => 
                     perm.toLowerCase().contains(queryLower));
        }).toList();
      }
      
      return filteredTemplates;
    } catch (e) {
      print('Erreur lors de la recherche de templates: $e');
      return [];
    }
  }

  /// Obtenir les statistiques d'utilisation des templates
  static Future<Map<String, dynamic>> getTemplateUsageStats() async {
    try {
      // Statistiques des templates
      final templatesSnapshot = await _firestore.collection(_collection).get();
      final totalTemplates = templatesSnapshot.docs.length;
      final activeTemplates = templatesSnapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .length;
      final systemTemplates = templatesSnapshot.docs
          .where((doc) => doc.data()['isSystemTemplate'] == true)
          .length;

      // Statistiques d'utilisation des rôles
      final rolesSnapshot = await _firestore.collection('roles').get();
      final templatesUsage = <String, int>{};
      
      for (final roleDoc in rolesSnapshot.docs) {
        final templateId = roleDoc.data()['templateId'] as String?;
        if (templateId != null) {
          templatesUsage[templateId] = (templatesUsage[templateId] ?? 0) + 1;
        }
      }

      // Templates par catégorie
      final templatesByCategory = <String, int>{};
      for (final doc in templatesSnapshot.docs) {
        final category = doc.data()['category'] as String? ?? 'unknown';
        templatesByCategory[category] = (templatesByCategory[category] ?? 0) + 1;
      }

      return {
        'totalTemplates': totalTemplates,
        'activeTemplates': activeTemplates,
        'systemTemplates': systemTemplates,
        'customTemplates': totalTemplates - systemTemplates,
        'templatesUsage': templatesUsage,
        'templatesByCategory': templatesByCategory,
        'mostUsedTemplate': templatesUsage.entries
            .fold<MapEntry<String, int>?>(null, (prev, curr) {
          if (prev == null || curr.value > prev.value) return curr;
          return prev;
        }),
        'unusedTemplates': templatesSnapshot.docs
            .where((doc) => !templatesUsage.containsKey(doc.id))
            .map((doc) => doc.id)
            .toList(),
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {};
    }
  }

  /// Valider qu'un template peut créer un rôle valide
  static Future<Map<String, dynamic>> validateTemplateForRole(
    String templateId,
  ) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) {
        return {
          'isValid': false,
          'errors': ['Template non trouvé'],
        };
      }

      final errors = <String>[];
      final warnings = <String>[];

      // Vérifier la configuration de base
      if (!template.isConfigurationValid()) {
        errors.add('Configuration du template invalide');
      }

      // Vérifier que les permissions existent
      final permissionsSnapshot = await _firestore
          .collection('permissions')
          .where(FieldPath.documentId, whereIn: template.permissionIds.take(10))
          .get();

      final existingPermissions = permissionsSnapshot.docs
          .map((doc) => doc.id)
          .toSet();

      final missingPermissions = template.permissionIds
          .where((perm) => !existingPermissions.contains(perm))
          .toList();

      if (missingPermissions.isNotEmpty) {
        errors.add('Permissions manquantes: ${missingPermissions.join(', ')}');
      }

      // Vérifications de cohérence
      final maxUsers = template.configuration['maxUsers'] as int?;
      if (maxUsers != null && maxUsers == 0) {
        warnings.add('Nombre maximum d\'utilisateurs défini à 0');
      }

      final restrictedModules = template.configuration['restrictedModules'] as List<String>?;
      if (restrictedModules != null && restrictedModules.isNotEmpty) {
        warnings.add('Modules restreints configurés: ${restrictedModules.join(', ')}');
      }

      return {
        'isValid': errors.isEmpty,
        'errors': errors,
        'warnings': warnings,
        'template': template.toFirestore(),
      };
    } catch (e) {
      return {
        'isValid': false,
        'errors': ['Erreur lors de la validation: $e'],
      };
    }
  }

  /// Créer un rôle à partir d'un template
  static Future<String> createRoleFromTemplate(
    String templateId, {
    String? customName,
    String? customDescription,
    Map<String, dynamic>? additionalConfig,
    required String createdBy,
  }) async {
    try {
      final template = await getTemplate(templateId);
      if (template == null) {
        throw Exception('Template non trouvé');
      }

      // Valider le template
      final validation = await validateTemplateForRole(templateId);
      if (validation['isValid'] != true) {
        throw Exception('Template invalide: ${validation['errors'].join(', ')}');
      }

      // Créer les données du rôle
      final roleData = template.toRoleData(
        customName: customName,
        customDescription: customDescription,
        additionalConfig: additionalConfig,
      );

      // Ajouter les métadonnées de création
      roleData['createdBy'] = createdBy;
      roleData['createdAt'] = FieldValue.serverTimestamp();

      // Créer le rôle dans Firestore
      final roleRef = await _firestore.collection('roles').add(roleData);
      
      // Journaliser l'action
      await _logTemplateAction('CREATE_ROLE', templateId, createdBy, {
        'roleId': roleRef.id,
        'roleName': customName ?? template.name,
      });

      return roleRef.id;
    } catch (e) {
      print('Erreur lors de la création du rôle à partir du template: $e');
      rethrow;
    }
  }

  /// Synchroniser un rôle avec son template
  static Future<void> syncRoleWithTemplate(String roleId) async {
    try {
      // Récupérer le rôle
      final roleDoc = await _firestore.collection('roles').doc(roleId).get();
      if (!roleDoc.exists) {
        throw Exception('Rôle non trouvé');
      }

      final roleData = roleDoc.data()!;
      final templateId = roleData['templateId'] as String?;
      
      if (templateId == null) {
        throw Exception('Ce rôle n\'est pas basé sur un template');
      }

      // Récupérer le template
      final template = await getTemplate(templateId);
      if (template == null) {
        throw Exception('Template source non trouvé');
      }

      // Mettre à jour les permissions du rôle
      await _firestore.collection('roles').doc(roleId).update({
        'permissions': template.permissionIds,
        'configuration': {
          ...Map<String, dynamic>.from(roleData['configuration'] ?? {}),
          ...template.configuration,
        },
        'syncedAt': FieldValue.serverTimestamp(),
      });
      
      await _logTemplateAction('SYNC_ROLE', templateId, 'system', {
        'roleId': roleId,
      });
    } catch (e) {
      print('Erreur lors de la synchronisation du rôle: $e');
      rethrow;
    }
  }

  /// Exporter les templates en JSON
  static Future<Map<String, dynamic>> exportTemplates({
    List<String>? templateIds,
    String? category,
  }) async {
    try {
      List<RoleTemplate> templates;
      
      if (templateIds != null && templateIds.isNotEmpty) {
        templates = [];
        for (final id in templateIds) {
          final template = await getTemplate(id);
          if (template != null) templates.add(template);
        }
      } else if (category != null) {
        templates = await getTemplatesByCategory(category);
      } else {
        templates = await getAllTemplates(includeInactive: true);
      }

      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
        'totalTemplates': templates.length,
        'templates': templates.map((t) => t.toFirestore()).toList(),
      };
    } catch (e) {
      print('Erreur lors de l\'export des templates: $e');
      rethrow;
    }
  }

  /// Importer des templates depuis JSON
  static Future<List<String>> importTemplates(
    Map<String, dynamic> importData,
    String importedBy,
  ) async {
    try {
      final templatesList = importData['templates'] as List<dynamic>?;
      if (templatesList == null || templatesList.isEmpty) {
        throw Exception('Aucun template à importer');
      }

      final importedIds = <String>[];
      final batch = _firestore.batch();

      for (final templateData in templatesList) {
        final data = Map<String, dynamic>.from(templateData);
        
        // Créer un nouveau template (sans l'ID original)
        data.remove('id');
        data['createdBy'] = importedBy;
        data['createdAt'] = FieldValue.serverTimestamp();
        data['isSystemTemplate'] = false; // Les imports ne sont pas système
        
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, data);
        importedIds.add(docRef.id);
      }

      await batch.commit();
      
      await _logTemplateAction('IMPORT', 'batch', importedBy, {
        'importedCount': importedIds.length,
        'importedIds': importedIds,
      });

      return importedIds;
    } catch (e) {
      print('Erreur lors de l\'import des templates: $e');
      rethrow;
    }
  }

  /// Journaliser les actions sur les templates
  static Future<void> _logTemplateAction(
    String action,
    String templateId,
    String userId, [
    Map<String, dynamic>? additionalData,
  ]) async {
    try {
      await _firestore.collection('template_audit_logs').add({
        'action': action,
        'templateId': templateId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData ?? {},
      });
    } catch (e) {
      print('Erreur lors de la journalisation: $e');
      // Ne pas faire échouer l'opération principale
    }
  }

  /// Stream pour écouter les changements de templates
  static Stream<List<RoleTemplate>> getTemplatesStream({
    String? category,
    bool includeInactive = false,
  }) {
    Query query = _firestore.collection(_collection);
    
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }
    
    query = query.orderBy('category').orderBy('name');
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RoleTemplate.fromFirestore(doc))
          .toList();
    });
  }

  /// Nettoyer les templates obsolètes
  static Future<int> cleanupObsoleteTemplates() async {
    try {
      // Trouver les templates inactifs depuis plus de 90 jours
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      
      final obsoleteTemplates = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: false)
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('isSystemTemplate', isEqualTo: false)
          .get();

      if (obsoleteTemplates.docs.isEmpty) return 0;

      final batch = _firestore.batch();
      
      for (final doc in obsoleteTemplates.docs) {
        // Vérifier qu'aucun rôle n'utilise encore ce template
        final rolesUsingTemplate = await _firestore
            .collection('roles')
            .where('templateId', isEqualTo: doc.id)
            .get();

        if (rolesUsingTemplate.docs.isEmpty) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      
      await _logTemplateAction('CLEANUP', 'batch', 'system', {
        'cleanedCount': obsoleteTemplates.docs.length,
      });

      return obsoleteTemplates.docs.length;
    } catch (e) {
      print('Erreur lors du nettoyage des templates: $e');
      return 0;
    }
  }
}