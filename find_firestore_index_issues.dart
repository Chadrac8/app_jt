import 'dart:io';

void main() async {
  print('Recherche des erreurs d\'index Firebase potentielles...');
  
  final directory = Directory('lib');
  Map<String, List<String>> firestoreQueries = {};
  
  await for (FileSystemEntity entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      List<String> lines = content.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        
        // Rechercher les requêtes Firestore complexes
        if (line.contains('.where(') && line.contains('.orderBy(')) {
          firestoreQueries[entity.path] = firestoreQueries[entity.path] ?? [];
          firestoreQueries[entity.path]!.add('Ligne ${i+1}: $line');
        }
        
        // Rechercher les requêtes avec plusieurs where + orderBy
        if (line.contains('.where(') && 
            (lines.length > i+1 && lines[i+1].contains('.where(')) ||
            (lines.length > i+2 && lines[i+2].contains('.orderBy('))) {
          firestoreQueries[entity.path] = firestoreQueries[entity.path] ?? [];
          firestoreQueries[entity.path]!.add('Ligne ${i+1}: Requête complexe détectée: $line');
        }
        
        // Rechercher les requêtes array-contains avec orderBy
        if (line.contains('array-contains') && line.contains('.orderBy(')) {
          firestoreQueries[entity.path] = firestoreQueries[entity.path] ?? [];
          firestoreQueries[entity.path]!.add('Ligne ${i+1}: Array-contains + orderBy: $line');
        }
        
        // Rechercher les requêtes avec in et orderBy
        if (line.contains('whereIn') && line.contains('.orderBy(')) {
          firestoreQueries[entity.path] = firestoreQueries[entity.path] ?? [];
          firestoreQueries[entity.path]!.add('Ligne ${i+1}: WhereIn + orderBy: $line');
        }
      }
    }
  }
  
  print('\n=== REQUÊTES FIRESTORE COMPLEXES TROUVÉES ===\n');
  
  for (String filePath in firestoreQueries.keys) {
    print('📁 $filePath:');
    for (String query in firestoreQueries[filePath]!) {
      print('  ⚠️  $query');
    }
    print('');
  }
  
  print('Total: ${firestoreQueries.length} fichiers avec des requêtes complexes');
}