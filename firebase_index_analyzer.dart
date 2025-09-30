import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Analyse complète des erreurs Firebase Index...\n');
  
  // 1. Analyser les requêtes complexes dans le code
  await analyzeFirestoreQueries();
  
  // 2. Analyser le firestore.indexes.json existant
  await analyzeExistingIndexes();
  
  // 3. Générer les index manquants
  await generateMissingIndexes();
}

Future<void> analyzeFirestoreQueries() async {
  print('📁 ANALYSE DES REQUÊTES FIRESTORE COMPLEXES\n');
  
  final directory = Directory('lib');
  Map<String, List<Map<String, dynamic>>> complexQueries = {};
  
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      List<String> lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        
        // Détecter les requêtes nécessitant des index composites
        await detectCompositeIndexRequirements(entity.path, i, line, lines, complexQueries);
      }
    }
  }
  
  print('Résumé des requêtes complexes trouvées:');
  for (String filePath in complexQueries.keys) {
    print('📄 ${filePath.replaceFirst('/Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/', '')}:');
    for (Map<String, dynamic> query in complexQueries[filePath]!) {
      print('  ⚠️  Ligne ${query['line']}: ${query['type']} - ${query['description']}');
    }
    print('');
  }
}

Future<void> detectCompositeIndexRequirements(
  String filePath, 
  int lineIndex, 
  String line, 
  List<String> lines, 
  Map<String, List<Map<String, dynamic>>> complexQueries
) async {
  
  // Pattern 1: where + orderBy sur la même ligne
  if (line.contains('.where(') && line.contains('.orderBy(')) {
    complexQueries[filePath] = complexQueries[filePath] ?? [];
    complexQueries[filePath]!.add({
      'line': lineIndex + 1,
      'type': 'WHERE_ORDERBY',
      'description': 'Where + OrderBy sur la même ligne',
      'code': line
    });
  }
  
  // Pattern 2: where + orderBy sur des lignes consécutives
  if (line.contains('.where(') && lineIndex + 1 < lines.length) {
    String nextLine = lines[lineIndex + 1].trim();
    if (nextLine.contains('.orderBy(')) {
      complexQueries[filePath] = complexQueries[filePath] ?? [];
      complexQueries[filePath]!.add({
        'line': lineIndex + 1,
        'type': 'WHERE_ORDERBY_MULTILINE',
        'description': 'Where suivi d\'OrderBy',
        'code': '$line\\n$nextLine'
      });
    }
  }
  
  // Pattern 3: array-contains + orderBy
  if (line.contains('arrayContains') && 
      (line.contains('.orderBy(') || 
       (lineIndex + 1 < lines.length && lines[lineIndex + 1].contains('.orderBy(')))) {
    complexQueries[filePath] = complexQueries[filePath] ?? [];
    complexQueries[filePath]!.add({
      'line': lineIndex + 1,
      'type': 'ARRAY_CONTAINS_ORDERBY',
      'description': 'Array-contains + OrderBy',
      'code': line
    });
  }
  
  // Pattern 4: whereIn + orderBy
  if (line.contains('whereIn') && 
      (line.contains('.orderBy(') || 
       (lineIndex + 1 < lines.length && lines[lineIndex + 1].contains('.orderBy(')))) {
    complexQueries[filePath] = complexQueries[filePath] ?? [];
    complexQueries[filePath]!.add({
      'line': lineIndex + 1,
      'type': 'WHERE_IN_ORDERBY',
      'description': 'WhereIn + OrderBy',
      'code': line
    });
  }
  
  // Pattern 5: Plusieurs where conditions
  if (line.contains('.where(')) {
    int whereCount = 1;
    for (int j = lineIndex + 1; j < lines.length && j < lineIndex + 5; j++) {
      if (lines[j].contains('.where(')) {
        whereCount++;
      } else if (lines[j].contains('.get()') || lines[j].contains('.snapshots()')) {
        break;
      }
    }
    
    if (whereCount >= 2) {
      complexQueries[filePath] = complexQueries[filePath] ?? [];
      complexQueries[filePath]!.add({
        'line': lineIndex + 1,
        'type': 'MULTIPLE_WHERE',
        'description': 'Multiple conditions WHERE ($whereCount conditions)',
        'code': line
      });
    }
  }
}

Future<void> analyzeExistingIndexes() async {
  print('\n📋 ANALYSE DES INDEX EXISTANTS\n');
  
  try {
    final indexFile = File('firestore.indexes.json');
    if (!indexFile.existsSync()) {
      print('❌ Fichier firestore.indexes.json introuvable!');
      return;
    }
    
    String content = await indexFile.readAsString();
    Map<String, dynamic> indexData = json.decode(content);
    
    if (indexData['indexes'] != null) {
      List<dynamic> indexes = indexData['indexes'];
      print('✅ ${indexes.length} index(es) configuré(s):');
      
      Map<String, int> collectionsCount = {};
      for (var index in indexes) {
        String collectionId = index['collectionGroup'] ?? 'unknown';
        collectionsCount[collectionId] = (collectionsCount[collectionId] ?? 0) + 1;
      }
      
      for (String collection in collectionsCount.keys) {
        print('  📁 $collection: ${collectionsCount[collection]} index(es)');
      }
    }
  } catch (e) {
    print('❌ Erreur lors de l\'analyse des index existants: $e');
  }
}

Future<void> generateMissingIndexes() async {
  print('\n🔧 GÉNÉRATION DES INDEX MANQUANTS\n');
  
  // Index couramment nécessaires pour les requêtes trouvées
  List<Map<String, dynamic>> recommendedIndexes = [
    // Pour les requêtes de personnes actives avec tri
    {
      'collectionGroup': 'persons',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'isActive', 'order': 'ASCENDING'},
        {'fieldPath': 'lastName', 'order': 'ASCENDING'}
      ]
    },
    // Pour les requêtes d'événements publiés avec tri par date
    {
      'collectionGroup': 'events',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'status', 'order': 'ASCENDING'},
        {'fieldPath': 'startDate', 'order': 'DESCENDING'}
      ]
    },
    // Pour les requêtes de tâches par statut et date
    {
      'collectionGroup': 'tasks',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'status', 'order': 'ASCENDING'},
        {'fieldPath': 'dueDate', 'order': 'ASCENDING'}
      ]
    },
    // Pour les requêtes de prières approuvées
    {
      'collectionGroup': 'prayers',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'isApproved', 'order': 'ASCENDING'},
        {'fieldPath': 'createdAt', 'order': 'DESCENDING'}
      ]
    },
    // Pour les requêtes de blog par statut et date
    {
      'collectionGroup': 'blogPosts',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'status', 'order': 'ASCENDING'},
        {'fieldPath': 'publishedAt', 'order': 'DESCENDING'}
      ]
    },
    // Pour les services par date
    {
      'collectionGroup': 'services',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'startDate', 'order': 'ASCENDING'},
        {'fieldPath': 'endDate', 'order': 'ASCENDING'}
      ]
    },
    // Pour les assignations de rôles
    {
      'collectionGroup': 'userRoles',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'userId', 'order': 'ASCENDING'},
        {'fieldPath': 'roleId', 'order': 'ASCENDING'}
      ]
    },
    // Pour les segments utilisateurs
    {
      'collectionGroup': 'userSegments',
      'queryScope': 'COLLECTION',
      'fields': [
        {'fieldPath': 'isActive', 'order': 'ASCENDING'},
        {'fieldPath': 'createdAt', 'order': 'DESCENDING'}
      ]
    }
  ];
  
  print('📝 Index recommandés à ajouter:');
  for (int i = 0; i < recommendedIndexes.length; i++) {
    var index = recommendedIndexes[i];
    print('${i + 1}. Collection: ${index['collectionGroup']}');
    print('   Champs: ${index['fields'].map((f) => '${f['fieldPath']} (${f['order']})').join(', ')}');
    print('');
  }
  
  // Sauvegarder les index recommandés dans un fichier
  await saveRecommendedIndexes(recommendedIndexes);
}

Future<void> saveRecommendedIndexes(List<Map<String, dynamic>> recommendedIndexes) async {
  try {
    // Lire le fichier existant
    final indexFile = File('firestore.indexes.json');
    Map<String, dynamic> currentIndexData = {};
    
    if (indexFile.existsSync()) {
      String content = await indexFile.readAsString();
      currentIndexData = json.decode(content);
    }
    
    // Initialiser la structure si nécessaire
    currentIndexData['indexes'] = currentIndexData['indexes'] ?? [];
    
    List<dynamic> existingIndexes = currentIndexData['indexes'];
    List<Map<String, dynamic>> newIndexes = [];
    
    // Vérifier quels index sont nouveaux
    for (var recommendedIndex in recommendedIndexes) {
      bool indexExists = existingIndexes.any((existing) => 
        existing['collectionGroup'] == recommendedIndex['collectionGroup'] &&
        _compareIndexFields(existing['fields'], recommendedIndex['fields'])
      );
      
      if (!indexExists) {
        newIndexes.add(recommendedIndex);
      }
    }
    
    if (newIndexes.isNotEmpty) {
      print('✨ ${newIndexes.length} nouveaux index à ajouter:');
      for (var index in newIndexes) {
        print('  + ${index['collectionGroup']}: ${index['fields'].map((f) => f['fieldPath']).join(', ')}');
        existingIndexes.add(index);
      }
      
      // Sauvegarder le fichier mis à jour
      String updatedContent = JsonEncoder.withIndent('  ').convert(currentIndexData);
      await indexFile.writeAsString(updatedContent);
      
      print('\n✅ Fichier firestore.indexes.json mis à jour!');
      print('🚀 Pour déployer les index, exécutez: firebase deploy --only firestore:indexes');
    } else {
      print('✅ Tous les index recommandés sont déjà configurés!');
    }
    
  } catch (e) {
    print('❌ Erreur lors de la sauvegarde des index: $e');
  }
}

bool _compareIndexFields(List<dynamic>? existing, List<Map<String, dynamic>> recommended) {
  if (existing == null || existing.length != recommended.length) return false;
  
  for (int i = 0; i < existing.length; i++) {
    if (existing[i]['fieldPath'] != recommended[i]['fieldPath'] ||
        existing[i]['order'] != recommended[i]['order']) {
      return false;
    }
  }
  return true;
}